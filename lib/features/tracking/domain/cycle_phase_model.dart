import 'dart:math' as math;

import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';
import 'cycle_windows.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The four-phase cycle model
//
// One layout of the current cycle, built from one [CyclePrediction], so Home,
// Calendar, Insights and the phase detail panels cannot disagree about where a
// phase starts.
//
// The shape is deliberate and comes from the design: the cycle is **four
// contiguous, non-overlapping segments** covering day 1 to day `cycleLength` —
//
//     menstrual → follicular → ovulation → luteal
//
// and the fertile and PMS windows are **overlays on top of that sequence, not
// extra phases**. They overlap the segments by nature: the fertile window
// straddles late follicular, ovulation and early luteal; the PMS window sits
// inside the luteal phase. Modelling them as segments would either double-count
// days or hide one window behind another.
//
// Why this exists next to [CycleWindows] rather than replacing it:
// `CycleWindows` answers "what windows is the user in or near", and its
// `follicular` entry is the **early follicular gap between the period and the
// fertile window** (Oct 13-16 in the design's example cycle), which ends well
// before the fertile window opens. That is the right answer for a countdown
// list and the wrong answer for a phase bar, where follicular runs Oct 13-21,
// all the way to the day before ovulation. This model composes with
// `CycleWindows` for the cycle anchor and the overlay dates, and derives the
// four segments itself.
//
// Everything here is an estimate except the logged period length. The segment
// boundaries move when the next period actually arrives; nothing in this file
// should be rendered as a certainty.
// ─────────────────────────────────────────────────────────────────────────────

/// Adds whole calendar days without drifting across a daylight-saving change,
/// which `DateTime.add(Duration(days: n))` does.
DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// A window drawn over the phase sequence rather than inside it.
enum CycleOverlayKind {
  fertile,
  pms;

  String get label => switch (this) {
        CycleOverlayKind.fertile => 'Fertile window',
        CycleOverlayKind.pms => 'PMS window',
      };
}

/// How much observed history the layout rests on.
///
/// Surfaced so a screen can say so instead of presenting a cycle built from
/// the user's settings as if it had been measured.
enum CycleHistoryState {
  /// No logged period at all: there is no model to show.
  none,

  /// A prediction exists, but from fewer than two complete cycles — the
  /// lengths come mostly from the user's own settings.
  learning,

  /// Two or more complete observed cycles.
  established;

  bool get isSufficient => this == CycleHistoryState.established;

  String get label => switch (this) {
        CycleHistoryState.none => 'No cycles logged yet',
        CycleHistoryState.learning => 'Learning your cycle',
        CycleHistoryState.established => 'Based on your logged cycles',
      };
}

/// A contiguous run of cycle days in one phase, with both its day range and
/// its real dates, plus the fractions the segmented bar is laid out from.
class CyclePhaseSegment {
  const CyclePhaseSegment({
    required this.phase,
    required this.start,
    required this.end,
    required this.startDay,
    required this.endDay,
    required this.fractionStart,
    required this.fractionWidth,
  });

  final CyclePhase phase;

  /// Inclusive, date-only.
  final DateTime start;

  /// Inclusive, date-only.
  final DateTime end;

  /// 1-based cycle day of [start]. Always >= 1.
  final int startDay;

  /// 1-based cycle day of [end], inclusive. Always >= [startDay].
  final int endDay;

  /// Where the segment begins along the bar, 0 at day 1 and 1 at the end of
  /// the cycle.
  final double fractionStart;

  /// How much of the bar the segment covers. Always greater than zero.
  final double fractionWidth;

  int get lengthInDays => endDay - startDay + 1;

  bool containsDay(int cycleDay) => cycleDay >= startDay && cycleDay <= endDay;

  bool contains(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// "Oct 8–12" / "Oct 23–Nov 4", matching the design's detail panel.
  String get dateRangeLabel => start == end
      ? shortDate(start)
      : start.month == end.month
          ? '${shortDate(start)}–${end.day}'
          : '${shortDate(start)}–${shortDate(end)}';

  /// "days 6 to 14", or "day 15" for a single day.
  String get dayRangeLabel =>
      startDay == endDay ? 'day $startDay' : 'days $startDay to $endDay';
}

/// The fertile or PMS window, positioned against the same bar as the segments.
class CycleOverlay {
  const CycleOverlay({
    required this.kind,
    required this.start,
    required this.end,
    required this.startDay,
    required this.endDay,
    required this.fractionStart,
    required this.fractionWidth,
  });

  final CycleOverlayKind kind;

  /// Inclusive, date-only, clamped into the cycle.
  final DateTime start;

  /// Inclusive, date-only, clamped into the cycle.
  final DateTime end;

  final int startDay;
  final int endDay;
  final double fractionStart;
  final double fractionWidth;

  int get lengthInDays => endDay - startDay + 1;

  bool containsDay(int cycleDay) => cycleDay >= startDay && cycleDay <= endDay;

  bool contains(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  String get dateRangeLabel => start == end
      ? shortDate(start)
      : start.month == end.month
          ? '${shortDate(start)}–${end.day}'
          : '${shortDate(start)}–${shortDate(end)}';

  String get dayRangeLabel =>
      startDay == endDay ? 'day $startDay' : 'days $startDay to $endDay';
}

/// The current cycle as four phase segments plus its overlays.
class CyclePhaseModel {
  const CyclePhaseModel({
    required this.cycleStart,
    required this.cycleLength,
    required this.segments,
    required this.today,
    required this.cycleDay,
    required this.nextPeriodStart,
    required this.history,
    required this.isIrregular,
    required this.cyclesTracked,
    required this.showsFertileWindow,
    required this.showsOvulation,
    required this.wasClamped,
    this.fertile,
    this.pms,
  });

  /// Day 1 of the cycle the model describes, date-only.
  final DateTime cycleStart;

  /// Days in the cycle. At least 4 — see [wasClamped].
  final int cycleLength;

  /// Exactly four segments, in cycle order, contiguous and non-overlapping,
  /// together covering day 1 to [cycleLength]. Each is at least one day long.
  final List<CyclePhaseSegment> segments;

  /// The day the model was built for, date-only.
  final DateTime today;

  /// 1-based cycle day of [today], clamped into the cycle.
  final int cycleDay;

  final DateTime nextPeriodStart;

  final CycleHistoryState history;
  final bool isIrregular;
  final int cyclesTracked;

  /// Whether the fertile overlay is included, per the user's preference.
  final bool showsFertileWindow;

  /// Whether the ovulation estimate may be called out.
  ///
  /// False does **not** remove the ovulation segment: the four segments have
  /// to keep covering every day of the cycle or the bar stops adding up. It
  /// suppresses the callout — the marker, the named label and the ovulation
  /// clause in [spokenSummary].
  final bool showsOvulation;

  /// True when the prediction's cycle length was below the four days four
  /// sequential phases need, and the layout was clamped up to four.
  ///
  /// The prediction service cannot produce this (it clamps cycle length to
  /// 21-45); a hand-built [CyclePrediction] can.
  final bool wasClamped;

  /// Null when [showsFertileWindow] is false.
  final CycleOverlay? fertile;

  /// Null when the prediction carries no premenstrual window.
  final CycleOverlay? pms;

  /// Last day of the cycle, date-only.
  DateTime get cycleEnd => _addDays(cycleStart, cycleLength - 1);

  /// The visible overlays, in cycle order. May be empty.
  List<CycleOverlay> get overlays => [
        if (fertile != null) fertile!,
        if (pms != null) pms!,
      ]..sort((a, b) => a.startDay.compareTo(b.startDay));

  CyclePhaseSegment segmentOf(CyclePhase phase) =>
      segments.firstWhere((segment) => segment.phase == phase);

  /// The segment [date] falls in, or null when it is outside this cycle.
  CyclePhaseSegment? segmentFor(DateTime date) {
    final d = dateOnly(date);
    if (d.isBefore(cycleStart) || d.isAfter(cycleEnd)) return null;
    return segmentOnDay(d.difference(cycleStart).inDays + 1);
  }

  /// The segment holding [cycleDay], clamped into the cycle.
  CyclePhaseSegment segmentOnDay(int cycleDay) {
    final day = cycleDay.clamp(1, cycleLength);
    for (final segment in segments) {
      if (segment.containsDay(day)) return segment;
    }
    return segments.last;
  }

  CyclePhaseSegment get currentSegment => segmentOnDay(cycleDay);

  CyclePhase get currentPhase => currentSegment.phase;

  /// Where the today marker sits along the bar: the *centre* of the current
  /// day, which is what the design's 80.357% on day 23 of 28 measures.
  double get todayFraction => (cycleDay - 0.5) / cycleLength;

  /// Whether [day] falls in the fertile overlay. False when it is hidden.
  bool isFertileOn(DateTime day) => fertile?.contains(day) ?? false;

  /// Whether [day] falls in the premenstrual overlay.
  bool isPmsOn(DateTime day) => pms?.contains(day) ?? false;

  bool get isInFertileWindow => isFertileOn(today);

  bool get isInPmsWindow => isPmsOn(today);

  /// One sentence covering the whole bar, for assistive technology. The bar is
  /// a single picture; reading it out as a dozen nodes is worse than one
  /// sentence. Mirrors the design's `aria-label` on `.home-timeline`.
  String get spokenSummary {
    final parts = <String>[];
    for (final segment in segments) {
      final name = segment.phase.label.toLowerCase();
      if (segment.phase == CyclePhase.ovulation) {
        if (!showsOvulation) continue;
        parts.add('estimated ovulation ${segment.dayRangeLabel}');
      } else {
        parts.add('$name ${segment.dayRangeLabel}');
      }
    }
    if (parts.isNotEmpty) {
      parts[0] = parts.first[0].toUpperCase() + parts.first.substring(1);
    }
    final sentences = <String>[
      'Cycle day $cycleDay of $cycleLength.',
      if (parts.isNotEmpty) '${parts.join(', ')}.',
      for (final overlay in overlays)
        '${overlay.kind.label} ${overlay.dayRangeLabel}.',
    ];
    return sentences.join(' ');
  }

  /// How much history [prediction] rests on, including the no-prediction case.
  static CycleHistoryState historyFor(CyclePrediction? prediction) {
    if (prediction == null) return CycleHistoryState.none;
    return prediction.cyclesTracked >= 2
        ? CycleHistoryState.established
        : CycleHistoryState.learning;
  }

  /// Null when there is nothing logged to predict from — the
  /// [CycleHistoryState.none] case, which a screen renders as an empty state
  /// rather than as a cycle.
  static CyclePhaseModel? maybeFromPrediction(
    CyclePrediction? prediction, {
    DateTime? today,
    bool showFertileWindow = true,
    bool showOvulation = true,
  }) {
    if (prediction == null) return null;
    return fromPrediction(
      prediction,
      today: today,
      showFertileWindow: showFertileWindow,
      showOvulation: showOvulation,
    );
  }

  /// Lays out [prediction] as four segments and its overlays.
  ///
  /// Boundaries, in priority order, with the reasoning for each:
  ///
  ///  * The cycle anchor is [CycleWindows]'s: `nextPeriodStart - cycleLength`,
  ///    not the last logged start, because the prediction service rolls
  ///    `nextPeriodStart` forward a whole cycle when the last log is old.
  ///  * The menstrual segment is the period length, which comes from logged
  ///    bleeding. It is the only measured boundary here, so it wins.
  ///  * Ovulation is exactly one day, derived from `ovulationDate` — the date
  ///    is the single source of truth for the estimate.
  ///  * Follicular fills the gap between them; luteal runs from the day after
  ///    ovulation to the end of the cycle.
  ///
  /// Short and irregular cycles never produce a negative or zero-width
  /// segment. The four segments each keep at least one day, by clamping in
  /// that same priority order: the period gives up its last days before the
  /// estimate does (`periodEnd <= length - 3`), and the ovulation estimate
  /// then moves to stay at least one day after the period and one day before
  /// the end of the cycle. A 21-day cycle with a 5-day period and a 14-day
  /// luteal phase lays out as 1-5 / 6-7 / 8 / 9-21. The overlays are clamped
  /// into the cycle and may legitimately overlap the period on a short cycle,
  /// which is a fact about the cycle rather than a layout failure.
  static CyclePhaseModel fromPrediction(
    CyclePrediction prediction, {
    DateTime? today,
    bool showFertileWindow = true,
    bool showOvulation = true,
  }) {
    final windows = CycleWindows.fromPrediction(prediction);
    final reference = dateOnly(today ?? DateTime.now());
    final cycleStart = windows.cycleStart;

    // Four sequential phases need four days. Nothing the prediction service
    // produces is shorter (it clamps to 21-45), so this only guards a
    // hand-built prediction.
    final rawLength = windows.cycleLength;
    final length = math.max(4, rawLength);

    int dayOf(DateTime date) => dateOnly(date).difference(cycleStart).inDays + 1;

    // The period is logged, so it only gives up days when the cycle cannot
    // hold the other three phases.
    final periodEnd = prediction.averagePeriodLength.clamp(1, length - 3);
    // The ovulation *date* is the source of truth; the integer follows it.
    final ovulationDay =
        dayOf(prediction.ovulationDate).clamp(periodEnd + 2, length - 1);

    CyclePhaseSegment segment(CyclePhase phase, int startDay, int endDay) =>
        CyclePhaseSegment(
          phase: phase,
          start: _addDays(cycleStart, startDay - 1),
          end: _addDays(cycleStart, endDay - 1),
          startDay: startDay,
          endDay: endDay,
          fractionStart: (startDay - 1) / length,
          fractionWidth: (endDay - startDay + 1) / length,
        );

    final segments = <CyclePhaseSegment>[
      segment(CyclePhase.menstrual, 1, periodEnd),
      segment(CyclePhase.follicular, periodEnd + 1, ovulationDay - 1),
      segment(CyclePhase.ovulation, ovulationDay, ovulationDay),
      segment(CyclePhase.luteal, ovulationDay + 1, length),
    ];

    CycleOverlay? overlay(CycleOverlayKind kind, DateTime? from, DateTime? to) {
      if (from == null || to == null) return null;
      final startDay = dayOf(from).clamp(1, length);
      final endDay = dayOf(to).clamp(startDay, length);
      return CycleOverlay(
        kind: kind,
        start: _addDays(cycleStart, startDay - 1),
        end: _addDays(cycleStart, endDay - 1),
        startDay: startDay,
        endDay: endDay,
        fractionStart: (startDay - 1) / length,
        fractionWidth: (endDay - startDay + 1) / length,
      );
    }

    final fertileWindow = windows.of(CycleWindowKind.fertile);
    final pmsWindow = windows.of(CycleWindowKind.pms);

    return CyclePhaseModel(
      cycleStart: cycleStart,
      cycleLength: length,
      segments: segments,
      today: reference,
      cycleDay:
          (reference.difference(cycleStart).inDays + 1).clamp(1, length),
      nextPeriodStart: dateOnly(prediction.nextPeriodStart),
      history: historyFor(prediction),
      isIrregular: prediction.isIrregular,
      cyclesTracked: prediction.cyclesTracked,
      showsFertileWindow: showFertileWindow,
      showsOvulation: showOvulation,
      wasClamped: rawLength < 4,
      fertile: showFertileWindow
          ? overlay(
              CycleOverlayKind.fertile,
              fertileWindow?.start,
              fertileWindow?.end,
            )
          : null,
      pms: overlay(CycleOverlayKind.pms, pmsWindow?.start, pmsWindow?.end),
    );
  }
}
