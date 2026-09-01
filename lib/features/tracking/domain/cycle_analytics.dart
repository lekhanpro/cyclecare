import 'dart:math';

import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cycle analytics
//
// Pure functions over logged history. No Flutter imports, no I/O — everything
// here is derived from the periods and daily logs already in memory, so it is
// cheap to recompute and trivial to test.
//
// The guiding constraint: never present a pattern the data cannot support.
// Menstrual tracking data is small and noisy — a handful of cycles, sparse
// logging, self-reported severity. Each result below carries the sample size
// that produced it, and the thresholds are set so a coincidence in three data
// points does not get rendered as a finding.
// ─────────────────────────────────────────────────────────────────────────────

/// One completed cycle, bounded by two consecutive period starts.
class CycleRecord {
  const CycleRecord({
    required this.index,
    required this.start,
    required this.end,
    required this.length,
    this.periodLength,
  });

  /// 1 = most recent completed cycle.
  final int index;

  final DateTime start;

  /// Day before the next period began.
  final DateTime end;

  /// Total days from this period's start to the next one.
  final int length;

  /// Bleeding days, when an end date was recorded.
  final int? periodLength;

  /// Deviation from a supplied average, in days. Positive means longer.
  int deviationFrom(int average) => length - average;
}

/// How strongly a symptom clusters in one phase of the cycle.
class SymptomPattern {
  const SymptomPattern({
    required this.symptom,
    required this.occurrences,
    required this.dominantPhase,
    required this.lift,
    required this.shareInDominantPhase,
  });

  final String symptom;

  /// Total number of days this symptom was logged.
  final int occurrences;

  final CyclePhase dominantPhase;

  /// How much more often the symptom appears in [dominantPhase] than chance
  /// would predict. 1.0 means exactly as often as that phase's share of days;
  /// 2.0 means twice as often.
  ///
  /// Expressed as lift rather than a raw count because phases have very
  /// different lengths — the luteal phase is roughly twice the menstrual
  /// phase, so a raw tally would always crown it.
  final double lift;

  /// Fraction of this symptom's occurrences that fell in [dominantPhase].
  final double shareInDominantPhase;

  /// Whether this is worth showing the user.
  ///
  /// Requires both a real effect (40% more often than chance) and enough
  /// observations that the effect isn't one coincidental week.
  bool get isMeaningful => lift >= 1.4 && occurrences >= 4;

  /// Plain-language summary. Avoids implying causation — the data supports
  /// "these co-occur", never "this causes that".
  String get description {
    final percent = (shareInDominantPhase * 100).round();
    return '$percent% of your $symptom logs land in your '
        '${dominantPhase.label.toLowerCase()} phase.';
  }
}

/// A basal body temperature reading placed within its cycle.
class TemperaturePoint {
  const TemperaturePoint({
    required this.date,
    required this.celsius,
    required this.cycleDay,
  });

  final DateTime date;
  final double celsius;
  final int cycleDay;
}

/// Fertility-awareness temperature analysis for the current cycle.
class TemperatureAnalysis {
  const TemperatureAnalysis({
    required this.points,
    this.coverline,
    this.thermalShiftDay,
  });

  final List<TemperaturePoint> points;

  /// The classic fertility-awareness coverline: slightly above the highest of
  /// the six readings preceding the rise. Temperatures sustained above it
  /// indicate ovulation has already happened.
  final double? coverline;

  /// Cycle day the sustained rise began, when one is detectable.
  final int? thermalShiftDay;

  bool get hasEnoughData => points.length >= 8;
}

/// A single value plotted over time, for the trend charts.
class TrendPoint {
  const TrendPoint({required this.label, required this.value, this.date});

  final String label;
  final double value;
  final DateTime? date;
}

class CycleAnalytics {
  const CycleAnalytics({
    required this.periods,
    required this.logs,
    required this.preferences,
  });

  final List<CycleEvent> periods;
  final List<DailyLog> logs;
  final CyclePreferences preferences;

  // ── Cycle history ─────────────────────────────────────────────────────────

  /// Completed cycles, most recent first.
  ///
  /// The in-progress cycle is excluded: its length isn't known until the next
  /// period arrives, and including a partial value would drag every average
  /// downward.
  List<CycleRecord> cycleHistory() {
    final starts = _sortedPeriodStarts();
    if (starts.length < 2) return const [];

    final records = <CycleRecord>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final start = starts[i + 1];
      final next = starts[i];
      final length = next.difference(start).inDays;
      // Physiologically implausible gaps are almost always a mis-logged date
      // or a gap in tracking, not a real cycle.
      if (length < 15 || length > 90) continue;

      records.add(CycleRecord(
        index: records.length + 1,
        start: start,
        end: next.subtract(const Duration(days: 1)),
        length: length,
        periodLength: _periodLengthFor(start),
      ));
    }
    return records;
  }

  List<TrendPoint> cycleLengthTrend() {
    final history = cycleHistory().reversed.toList();
    return [
      for (final record in history)
        TrendPoint(
          label: shortDate(record.start),
          value: record.length.toDouble(),
          date: record.start,
        ),
    ];
  }

  List<TrendPoint> periodLengthTrend() {
    final history = cycleHistory().reversed.toList();
    return [
      for (final record in history)
        if (record.periodLength != null)
          TrendPoint(
            label: shortDate(record.start),
            value: record.periodLength!.toDouble(),
            date: record.start,
          ),
    ];
  }

  // ── Symptom / phase correlation ───────────────────────────────────────────

  /// Symptoms ranked by how strongly they cluster in a single phase.
  ///
  /// Only logs that fall inside a known cycle are counted; a symptom logged
  /// before the first recorded period has no phase to belong to.
  List<SymptomPattern> symptomPatterns() {
    final phaseByDate = _phaseByDate();
    if (phaseByDate.isEmpty) return const [];

    // Denominator: how many tracked days each phase accounts for. Without
    // this the longest phase always looks the most symptomatic.
    final daysPerPhase = <CyclePhase, int>{};
    for (final phase in phaseByDate.values) {
      daysPerPhase[phase] = (daysPerPhase[phase] ?? 0) + 1;
    }
    final totalDays = phaseByDate.length;

    final countsBySymptom = <String, Map<CyclePhase, int>>{};
    for (final log in logs) {
      final phase = phaseByDate[dateOnly(log.date)];
      if (phase == null) continue;
      for (final symptom in log.symptoms) {
        final byPhase = countsBySymptom.putIfAbsent(symptom, () => {});
        byPhase[phase] = (byPhase[phase] ?? 0) + 1;
      }
    }

    final patterns = <SymptomPattern>[];
    countsBySymptom.forEach((symptom, byPhase) {
      final total = byPhase.values.fold(0, (sum, value) => sum + value);
      if (total == 0) return;

      CyclePhase? best;
      var bestLift = 0.0;
      var bestShare = 0.0;

      byPhase.forEach((phase, count) {
        final phaseDays = daysPerPhase[phase] ?? 0;
        if (phaseDays == 0) return;
        final expectedShare = phaseDays / totalDays;
        final actualShare = count / total;
        final lift = actualShare / expectedShare;
        if (lift > bestLift) {
          best = phase;
          bestLift = lift;
          bestShare = actualShare;
        }
      });

      if (best == null) return;
      patterns.add(SymptomPattern(
        symptom: symptom,
        occurrences: total,
        dominantPhase: best!,
        lift: bestLift,
        shareInDominantPhase: bestShare,
      ));
    });

    patterns.sort((a, b) => b.lift.compareTo(a.lift));
    return patterns;
  }

  /// Most frequently logged symptoms overall, highest first.
  List<({String symptom, int count})> topSymptoms({int limit = 6}) {
    final counts = <String, int>{};
    for (final log in logs) {
      for (final symptom in log.symptoms) {
        counts[symptom] = (counts[symptom] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries.take(limit))
        (symptom: entry.key, count: entry.value),
    ];
  }

  /// How often each mood was logged.
  List<({String mood, int count})> moodDistribution() {
    final counts = <String, int>{};
    for (final log in logs) {
      final mood = log.mood;
      if (mood == null || mood.isEmpty) continue;
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries) (mood: entry.key, count: entry.value),
    ];
  }

  // ── Temperature ───────────────────────────────────────────────────────────

  /// Basal temperature analysis for the cycle containing [reference].
  TemperatureAnalysis temperatureAnalysis({DateTime? reference}) {
    final today = dateOnly(reference ?? DateTime.now());
    final cycleStart = _cycleStartFor(today);
    if (cycleStart == null) {
      return const TemperatureAnalysis(points: []);
    }

    final points = <TemperaturePoint>[];
    for (final log in logs) {
      final temperature = log.temperatureCelsius;
      if (temperature == null) continue;
      final date = dateOnly(log.date);
      if (date.isBefore(cycleStart) || date.isAfter(today)) continue;
      points.add(TemperaturePoint(
        date: date,
        celsius: temperature,
        cycleDay: date.difference(cycleStart).inDays + 1,
      ));
    }
    points.sort((a, b) => a.cycleDay.compareTo(b.cycleDay));

    final shift = _detectThermalShift(points);
    return TemperatureAnalysis(
      points: points,
      coverline: shift?.coverline,
      thermalShiftDay: shift?.day,
    );
  }

  /// Finds a sustained post-ovulatory temperature rise.
  ///
  /// The rule mirrors symptothermal fertility-awareness practice: three
  /// consecutive readings above the highest of the previous six, with the
  /// coverline drawn just above that six-day high. Requiring three days is
  /// what separates ovulation from a single restless night.
  ({double coverline, int day})? _detectThermalShift(
    List<TemperaturePoint> points,
  ) {
    const lookback = 6;
    const sustained = 3;
    if (points.length < lookback + sustained) return null;

    for (var i = lookback; i <= points.length - sustained; i++) {
      final baseline = points
          .sublist(i - lookback, i)
          .map((point) => point.celsius)
          .reduce(max);
      final coverline = baseline + 0.1;

      final risen = points
          .sublist(i, i + sustained)
          .every((point) => point.celsius >= coverline);

      if (risen) {
        return (coverline: coverline, day: points[i].cycleDay);
      }
    }
    return null;
  }

  // ── Wellness averages ─────────────────────────────────────────────────────

  double? averagePainLevel() => _average(
        logs.where((log) => log.painLevel > 0).map((log) => log.painLevel.toDouble()),
      );

  double? averageSleepHours() => _average(
        logs.map((log) => log.sleepHours).whereType<double>(),
      );

  double? averageWaterMl() {
    final values = logs.where((log) => log.waterMl > 0).map((log) => log.waterMl.toDouble());
    return _average(values);
  }

  List<TrendPoint> weightTrend({int limit = 30}) {
    final entries = logs.where((log) => log.weightKg != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent =
        entries.length > limit ? entries.sublist(entries.length - limit) : entries;
    return [
      for (final log in recent)
        TrendPoint(
          label: shortDate(log.date),
          value: log.weightKg!,
          date: log.date,
        ),
    ];
  }

  List<TrendPoint> painTrend({int limit = 30}) {
    final entries = logs.where((log) => log.painLevel > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent =
        entries.length > limit ? entries.sublist(entries.length - limit) : entries;
    return [
      for (final log in recent)
        TrendPoint(
          label: shortDate(log.date),
          value: log.painLevel.toDouble(),
          date: log.date,
        ),
    ];
  }

  /// Consecutive days logged up to and including today.
  ///
  /// Counted backwards from today and stopping at the first gap, so the number
  /// always means "streak I could break tomorrow" rather than a personal best.
  int loggingStreak({DateTime? reference}) {
    if (logs.isEmpty) return 0;
    final logged = logs.map((log) => dateOnly(log.date)).toSet();
    var cursor = dateOnly(reference ?? DateTime.now());

    // Today not being logged yet shouldn't zero a real streak before bedtime.
    if (!logged.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (logged.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Share of the last [days] days that have a log, 0–1.
  double loggingConsistency({int days = 30, DateTime? reference}) {
    if (days <= 0) return 0;
    final today = dateOnly(reference ?? DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    final logged = logs
        .map((log) => dateOnly(log.date))
        .where((date) => !date.isBefore(start) && !date.isAfter(today))
        .toSet();
    return logged.length / days;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Unique period start dates, most recent first.
  List<DateTime> _sortedPeriodStarts() {
    final unique = <DateTime>{
      for (final period in periods) dateOnly(period.startDate),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return unique;
  }

  int? _periodLengthFor(DateTime start) {
    for (final period in periods) {
      if (dateOnly(period.startDate) != start) continue;
      final end = period.endDate;
      if (end == null) return null;
      final length = dateOnly(end).difference(start).inDays + 1;
      if (length < 1 || length > 14) return null;
      return length;
    }
    return null;
  }

  /// The period start that opens the cycle containing [date].
  DateTime? _cycleStartFor(DateTime date) {
    final target = dateOnly(date);
    for (final start in _sortedPeriodStarts()) {
      if (!start.isAfter(target)) return start;
    }
    return null;
  }

  /// Maps every tracked day to the phase it fell in.
  ///
  /// Phase boundaries are derived per cycle from that cycle's own length rather
  /// than from a global average — an irregular cycle's luteal phase stays
  /// anchored to when the next period actually arrived, which is the whole
  /// point of tracking it.
  Map<DateTime, CyclePhase> _phaseByDate() {
    final starts = _sortedPeriodStarts();
    if (starts.length < 2) return const {};

    final result = <DateTime, CyclePhase>{};
    final luteal = preferences.lutealPhaseLength;

    for (var i = 0; i < starts.length - 1; i++) {
      final start = starts[i + 1];
      final nextStart = starts[i];
      final length = nextStart.difference(start).inDays;
      if (length < 15 || length > 90) continue;

      final periodLength = _periodLengthFor(start) ??
          preferences.averagePeriodLength.clamp(2, 10);
      final ovulationDay = length - luteal;

      for (var day = 1; day <= length; day++) {
        final date = start.add(Duration(days: day - 1));
        result[date] = switch (day) {
          _ when day <= periodLength => CyclePhase.menstrual,
          _ when day >= ovulationDay - 1 && day <= ovulationDay + 1 =>
            CyclePhase.ovulation,
          _ when day < ovulationDay - 1 => CyclePhase.follicular,
          _ => CyclePhase.luteal,
        };
      }
    }

    return result;
  }

  double? _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
