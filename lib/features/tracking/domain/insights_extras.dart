import 'dart:math';

import '../../../core/utils/date_helpers.dart';
import 'cycle_analytics.dart';
import 'cycle_models.dart';
import 'prediction_evaluation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Extra insights
//
// Pure functions over CycleAnalytics, kept out of that file so each one can be
// read and tested on its own. Every result carries enough of its own inputs
// (sample sizes, the number behind a label) for the screen to explain itself
// rather than present a bare verdict.
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum completed cycles before a cycle-level insight is shown at all.
const minCyclesForInsight = 3;

enum Regularity { veryRegular, regular, somewhatIrregular, irregular }

extension RegularityLabel on Regularity {
  String get label => switch (this) {
    Regularity.veryRegular => 'Very regular',
    Regularity.regular => 'Regular',
    Regularity.somewhatIrregular => 'Somewhat variable',
    Regularity.irregular => 'Variable',
  };
}

class RegularityScore {
  const RegularityScore({
    required this.bucket,
    required this.spreadDays,
    required this.shortest,
    required this.longest,
    required this.cycles,
  });

  final Regularity bucket;

  /// Standard deviation of cycle length, in days.
  final double spreadDays;
  final int shortest;
  final int longest;
  final int cycles;
}

/// Null below [minCyclesForInsight]. The buckets follow the common clinical
/// reading that cycle lengths varying by more than about 7-9 days are
/// "irregular"; the labels stay soft because this is a pattern, not a finding.
RegularityScore? regularityScore(CycleAnalytics a) {
  final lengths = a.cycleHistory().map((c) => c.length).toList();
  if (lengths.length < minCyclesForInsight) return null;
  final mean = lengths.reduce((x, y) => x + y) / lengths.length;
  final sd = sqrt(
    lengths.map((l) => pow(l - mean, 2)).reduce((x, y) => x + y) /
        lengths.length,
  );
  final range = lengths.reduce(max) - lengths.reduce(min);
  final bucket = range <= 3
      ? Regularity.veryRegular
      : range <= 7
      ? Regularity.regular
      : range <= 9
      ? Regularity.somewhatIrregular
      : Regularity.irregular;
  return RegularityScore(
    bucket: bucket,
    spreadDays: sd,
    shortest: lengths.reduce(min),
    longest: lengths.reduce(max),
    cycles: lengths.length,
  );
}

class PredictionCheck {
  const PredictionCheck({
    required this.cycleStart,
    required this.predictedNext,
    required this.actualNext,
  });

  final DateTime cycleStart;
  final DateTime predictedNext;
  final DateTime actualNext;

  /// Positive when the period came later than predicted.
  int get errorDays => actualNext.difference(predictedNext).inDays;
}

class PredictionAccuracy {
  const PredictionAccuracy(this.checks);

  /// Oldest first.
  final List<PredictionCheck> checks;

  double get averageAbsoluteError => checks.isEmpty
      ? 0
      : checks.map((c) => c.errorDays.abs()).reduce((a, b) => a + b) /
            checks.length;

  int get withinTwoDays => checks.where((c) => c.errorDays.abs() <= 2).length;
}

/// Replays the actual on-device predictor with only earlier available starts.
/// Current preferences/exclusions are used because their edit history is not
/// stored; this is a retrospective check, not a saved historical forecast.
PredictionAccuracy? predictionAccuracy(CycleAnalytics a) {
  final replay = PredictionEvaluation.run(
    periods: a.periods,
    preferences: a.preferences,
  );
  final checks = [
    for (final point in replay.points)
      if (point.trainingCycles >= 2)
        PredictionCheck(
          cycleStart: point.cycleStart,
          predictedNext: point.predictedStart,
          actualNext: point.actualStart,
        ),
  ];
  return checks.isEmpty ? null : PredictionAccuracy(checks);
}

// ── By phase ─────────────────────────────────────────────────────────────────

/// Logs paired with the phase of the day they were logged. Logs outside a
/// completed cycle have no phase and are skipped.
List<(CyclePhase, DailyLog)> _logsByPhase(CycleAnalytics a) {
  final phases = a.phaseByDate();
  return [
    for (final log in a.logs)
      if (phases[dateOnly(log.date)] case final phase?) (phase, log),
  ];
}

/// For each phase, the share of each mood among days with a mood logged.
/// Phases with no mood logs are absent.
Map<CyclePhase, Map<String, double>> moodByPhase(CycleAnalytics a) {
  final counts = <CyclePhase, Map<String, int>>{};
  for (final (phase, log) in _logsByPhase(a)) {
    final mood = log.mood;
    if (mood == null || mood.isEmpty) continue;
    final byMood = counts.putIfAbsent(phase, () => {});
    byMood[mood] = (byMood[mood] ?? 0) + 1;
  }
  return {
    for (final MapEntry(key: phase, value: byMood) in counts.entries)
      phase: {
        for (final e in byMood.entries)
          e.key: e.value / byMood.values.reduce((x, y) => x + y),
      },
  };
}

class PhaseAverage {
  const PhaseAverage({required this.value, required this.days});
  final double value;

  /// How many logged days the average is built from.
  final int days;
}

Map<CyclePhase, PhaseAverage> _averageByPhase(
  CycleAnalytics a,
  double? Function(DailyLog) pick,
) {
  final sums = <CyclePhase, (double, int)>{};
  for (final (phase, log) in _logsByPhase(a)) {
    final v = pick(log);
    if (v == null) continue;
    final (sum, n) = sums[phase] ?? (0.0, 0);
    sums[phase] = (sum + v, n + 1);
  }
  return {
    for (final MapEntry(key: phase, value: (sum, n)) in sums.entries)
      phase: PhaseAverage(value: sum / n, days: n),
  };
}

Map<CyclePhase, PhaseAverage> sleepByPhase(CycleAnalytics a) =>
    _averageByPhase(a, (l) => l.sleepHours);

/// Days without a water entry are skipped; an explicit 0 ml is counted.
/// Legacy records that saved 0 by default are read as not logged (see
/// `DailyLog.fromJson`).
Map<CyclePhase, PhaseAverage> waterByPhase(CycleAnalytics a) =>
    _averageByPhase(a, (l) => l.waterMl?.toDouble());

// ── Symptom heatmap ──────────────────────────────────────────────────────────

class SymptomHeatmap {
  const SymptomHeatmap({
    required this.symptoms,
    required this.cycleLength,
    required this.counts,
    required this.cycles,
  });

  /// Rows, most logged first.
  final List<String> symptoms;

  /// Columns: cycle day 1 to this.
  final int cycleLength;

  /// counts[symptom][cycleDay - 1] = how many cycles logged it on that day.
  final Map<String, List<int>> counts;

  /// Completed cycles the map is built from; the most any cell can reach.
  final int cycles;
}

/// Null below [minCyclesForInsight] or with no symptoms logged.
SymptomHeatmap? symptomHeatmap(CycleAnalytics a, {int top = 6}) {
  final history = a.cycleHistory();
  if (history.length < minCyclesForInsight) return null;
  final length =
      (history.map((c) => c.length).reduce((x, y) => x + y) / history.length)
          .round();

  final counts = <String, List<int>>{};
  for (final log in a.logs) {
    final day = dateOnly(log.date);
    for (final cycle in history) {
      if (day.isBefore(cycle.start) || day.isAfter(cycle.end)) continue;
      final cd = day.difference(cycle.start).inDays; // 0-based
      if (cd >= length) break;
      for (final s in log.symptoms) {
        (counts[s] ??= List.filled(length, 0))[cd]++;
      }
      break;
    }
  }
  if (counts.isEmpty) return null;
  int total(String s) => counts[s]!.reduce((x, y) => x + y);
  final ranked = counts.keys.toList()..sort((x, y) => total(y) - total(x));
  final rows = ranked.take(top).toList();
  return SymptomHeatmap(
    symptoms: rows,
    cycleLength: length,
    counts: {for (final s in rows) s: counts[s]!},
    cycles: history.length,
  );
}

// ── This cycle vs your average ───────────────────────────────────────────────

class CycleComparison {
  const CycleComparison({
    required this.dayToday,
    required this.averageLength,
    required this.symptomDaysThisCycle,
    required this.averageSymptomDaysByNow,
    required this.averagePainThisCycle,
    required this.averagePainOverall,
  });

  /// Cycle day of today in the cycle in progress.
  final int dayToday;
  final int averageLength;

  /// Days so far this cycle with at least one symptom.
  final int symptomDaysThisCycle;

  /// The same count, averaged over past cycles up to the same cycle day, so
  /// the comparison is like for like rather than a part cycle against whole
  /// ones. Only past cycles with at least one log in that window count: an
  /// unlogged cycle is missing data, not a cycle with no symptoms, and
  /// counting it as zero made "usually" read 0.1 against a real 3.
  /// Null when no past cycle was logged that early.
  final double? averageSymptomDaysByNow;
  final double? averagePainThisCycle;
  final double? averagePainOverall;
}

CycleComparison? cycleComparison(CycleAnalytics a, {DateTime? today}) {
  final history = a.cycleHistory();
  if (history.length < minCyclesForInsight || a.periods.isEmpty) return null;
  final now = dateOnly(today ?? DateTime.now());
  final starts = a.periods.map((p) => dateOnly(p.startDate)).toList()..sort();
  final current = starts.lastWhere((s) => !s.isAfter(now), orElse: () => now);
  final day = now.difference(current).inDays + 1;

  bool hasSymptom(DailyLog l) => l.symptoms.isNotEmpty;
  bool within(DailyLog l, DateTime start, int days) {
    final d = dateOnly(l.date);
    return !d.isBefore(start) && d.difference(start).inDays < days;
  }

  final thisCycle = a.logs.where((l) => within(l, current, day)).toList();
  final pastCounts = [
    for (final c in history)
      if (a.logs.any((l) => within(l, c.start, day)))
        a.logs.where((l) => within(l, c.start, day) && hasSymptom(l)).length,
  ];
  // Recorded ratings only (explicit 0 included); unrated days are skipped.
  double? avgPain(Iterable<DailyLog> logs) {
    final v = logs.map((l) => l.painLevel).whereType<int>().toList();
    return v.isEmpty ? null : v.reduce((x, y) => x + y) / v.length;
  }

  return CycleComparison(
    dayToday: day,
    averageLength:
        (history.map((c) => c.length).reduce((x, y) => x + y) / history.length)
            .round(),
    symptomDaysThisCycle: thisCycle.where(hasSymptom).length,
    averageSymptomDaysByNow: pastCounts.isEmpty
        ? null
        : pastCounts.reduce((x, y) => x + y) / pastCounts.length,
    averagePainThisCycle: avgPain(thisCycle),
    averagePainOverall: avgPain(a.logs),
  );
}

// ── Logging per cycle ────────────────────────────────────────────────────────

class CycleLogging {
  const CycleLogging({required this.cycle, required this.daysLogged});
  final CycleRecord cycle;
  final int daysLogged;
  double get share => daysLogged / cycle.length;
}

/// Oldest first.
List<CycleLogging> loggingPerCycle(CycleAnalytics a) {
  final days = {for (final l in a.logs) dateOnly(l.date)};
  return [
    for (final c in a.cycleHistory().reversed)
      CycleLogging(
        cycle: c,
        daysLogged: days
            .where((d) => !d.isBefore(c.start) && !d.isAfter(c.end))
            .length,
      ),
  ];
}
