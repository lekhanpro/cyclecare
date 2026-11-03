import 'dart:math' as math;

import 'cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Educational hormone illustration.
//
// Four hand-shaped curves (Estrogen, Progesterone, LH, FSH) over a 28-day
// reference cycle, ported from the design prototype (redesign/
// home-precision.js). Each curve is normalised independently to [0, 1], so the
// relative Low / Mid / High scale cannot compare one hormone with another.
//
// These are design examples, not a dataset, a lab reference range or a
// prediction of anyone's levels. Nothing here is stored, and nothing here has
// a unit. The narrative follows UCSF's explanation of the menstrual cycle:
// https://crh.ucsf.edu/about-fertility/normal-menstrual-cycle
// ─────────────────────────────────────────────────────────────────────────────

/// The educational source the copy is based on.
const String hormoneIllustrationSourceUrl =
    'https://crh.ucsf.edu/about-fertility/normal-menstrual-cycle';

/// Length of the reference cycle the control points are drawn on.
const int hormoneReferenceLength = 28;

/// Reference day on which the illustration's ovulation falls.
const double hormoneReferenceOvulationDay = 15;

enum HormoneKind {
  estrogen,
  progesterone,
  lh,
  fsh;

  String get label => switch (this) {
        HormoneKind.estrogen => 'Estrogen',
        HormoneKind.progesterone => 'Progesterone',
        HormoneKind.lh => 'LH',
        HormoneKind.fsh => 'FSH',
      };

  /// Short tag drawn next to a curve, so colour is never the only signal.
  String get shortLabel => switch (this) {
        HormoneKind.estrogen => 'E2',
        HormoneKind.progesterone => 'P4',
        HormoneKind.lh => 'LH',
        HormoneKind.fsh => 'FSH',
      };

  String get patternCopy => switch (this) {
        HormoneKind.estrogen =>
          'A larger rise before ovulation and a smaller rise during the luteal phase.',
        HormoneKind.progesterone =>
          'Usually low before ovulation, then higher during the luteal phase.',
        HormoneKind.lh =>
          'A short, distinct surge around ovulation, rather than a sustained rise.',
        HormoneKind.fsh =>
          'Supports follicle development, with a smaller rise around ovulation.',
      };
}

/// Educational copy for each phase in the pattern note.
String hormonePhaseCopy(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => 'The period at the start of the cycle.',
      CyclePhase.follicular =>
        'Estrogen generally rises as a dominant follicle develops.',
      CyclePhase.ovulation =>
        'The short LH surge is associated with ovulation. Timing varies.',
      CyclePhase.luteal =>
        'Progesterone generally rises after ovulation and falls before the next period.',
    };

enum HormoneLevel {
  low,
  mid,
  high;

  String get label => switch (this) {
        HormoneLevel.low => 'Low',
        HormoneLevel.mid => 'Mid',
        HormoneLevel.high => 'High',
      };
}

enum HormoneDirection {
  rising,
  falling,
  steady;

  String get label => switch (this) {
        HormoneDirection.rising => 'Rising',
        HormoneDirection.falling => 'Falling',
        HormoneDirection.steady => 'Steady',
      };
}

/// A qualitative reading of one curve on one day.
class HormoneTrend {
  const HormoneTrend({required this.level, required this.direction});

  final HormoneLevel level;
  final HormoneDirection direction;

  /// "Mid in the illustration" — never a measurement.
  String get levelText => '${level.label} in the illustration';

  @override
  bool operator ==(Object other) =>
      other is HormoneTrend && other.level == level && other.direction == direction;

  @override
  int get hashCode => Object.hash(level, direction);
}

/// One curve: control points plus Fritsch–Carlson style tangents, which keep
/// cubic Hermite interpolation monotone between points (no overshoot, so no
/// invented peaks and no values outside the control-point range).
class HormoneCurve {
  HormoneCurve._(this.kind, this.points) : tangents = _tangents(points);

  final HormoneKind kind;

  /// (reference day, normalised value), days ascending within [1, 28].
  final List<(double, double)> points;
  final List<double> tangents;

  static List<double> _tangents(List<(double, double)> p) {
    final n = p.length;
    final dx = <double>[];
    final s = <double>[];
    for (var i = 0; i < n - 1; i++) {
      dx.add(p[i + 1].$1 - p[i].$1);
      s.add((p[i + 1].$2 - p[i].$2) / dx[i]);
    }
    return [
      for (var i = 0; i < n; i++)
        if (i == 0)
          s[0]
        else if (i == n - 1)
          s[n - 2]
        else if (s[i - 1] * s[i] <= 0)
          0
        else
          _harmonic(dx[i - 1], dx[i], s[i - 1], s[i]),
    ];
  }

  static double _harmonic(double dx0, double dx1, double s0, double s1) {
    final a = 2 * dx1 + dx0;
    final b = dx1 + 2 * dx0;
    return (a + b) / (a / s0 + b / s1);
  }

  /// Normalised value on reference day [day] (clamped into [1, 28]).
  double valueAt(double day) {
    final d = day.clamp(1.0, hormoneReferenceLength.toDouble());
    var i = 0;
    while (i < points.length - 2 && d > points[i + 1].$1) {
      i++;
    }
    final x0 = points[i].$1;
    final x1 = points[i + 1].$1;
    final w = x1 - x0;
    final t = ((d - x0) / w).clamp(0.0, 1.0);
    final t2 = t * t;
    final t3 = t2 * t;
    final v = (2 * t3 - 3 * t2 + 1) * points[i].$2 +
        (t3 - 2 * t2 + t) * w * tangents[i] +
        (-2 * t3 + 3 * t2) * points[i + 1].$2 +
        (t3 - t2) * w * tangents[i + 1];
    return v.clamp(0.0, 1.0);
  }

  /// Qualitative reading on reference day [day].
  HormoneTrend trendAt(double day) {
    final v = valueAt(day);
    final delta =
        valueAt(math.min(28.0, day + 0.35)) - valueAt(math.max(1.0, day - 0.35));
    final level = v < 0.22
        ? HormoneLevel.low
        : v < 0.6
            ? HormoneLevel.mid
            : HormoneLevel.high;
    final direction = delta.abs() < 0.016
        ? HormoneDirection.steady
        : delta > 0
            ? HormoneDirection.rising
            : HormoneDirection.falling;
    return HormoneTrend(level: level, direction: direction);
  }
}

/// The four illustration curves, resampled onto a user's cycle.
class HormoneIllustration {
  HormoneIllustration({required int cycleLength, int? ovulationDay})
      : cycleLength = math.max(2, cycleLength),
        ovulationDay = _clampOvulation(ovulationDay, math.max(2, cycleLength));

  /// The default 28-day reference, ovulation on day 15.
  factory HormoneIllustration.reference() =>
      HormoneIllustration(cycleLength: hormoneReferenceLength, ovulationDay: 15);

  final int cycleLength;

  /// The cycle day the reference ovulation (day 15) is pinned to, so the LH
  /// surge lands on the user's ovulation segment rather than drifting.
  final double ovulationDay;

  static double _clampOvulation(int? day, int length) {
    final fallback = 1 + (hormoneReferenceOvulationDay - 1) / 27 * (length - 1);
    if (day == null) return fallback;
    // Keep at least one day either side so both halves of the map are valid.
    return day.clamp(2, math.max(2, length - 1)).toDouble();
  }

  static final Map<HormoneKind, HormoneCurve> curves = {
    HormoneKind.estrogen: HormoneCurve._(HormoneKind.estrogen, const [
      (1, .12), (4, .10), (7, .24), (10, .49), (12.5, .9), (14, .63), //
      (16, .26), (19, .38), (21, .47), (24, .35), (26, .16), (28, .10),
    ]),
    HormoneKind.progesterone: HormoneCurve._(HormoneKind.progesterone, const [
      (1, .055), (8, .05), (12, .055), (14, .075), (15, .13), (17, .4), //
      (20, .8), (22, .9), (24, .73), (26, .37), (28, .075),
    ]),
    HormoneKind.lh: HormoneCurve._(HormoneKind.lh, const [
      (1, .09), (7, .10), (11, .12), (12.5, .15), (13.3, .3), (14.2, .94), //
      (15, .5), (15.8, .18), (17, .095), (23, .08), (28, .09),
    ]),
    HormoneKind.fsh: HormoneCurve._(HormoneKind.fsh, const [
      (1, .26), (3, .32), (6, .22), (9, .15), (12, .20), (14, .40), //
      (15.5, .29), (18, .16), (22, .12), (26, .17), (28, .24),
    ]),
  };

  /// Maps a (fractional) cycle day onto the reference cycle, piecewise
  /// linearly either side of ovulation.
  double referenceDay(double cycleDay) {
    final d = cycleDay.clamp(1.0, cycleLength.toDouble());
    const ov = hormoneReferenceOvulationDay;
    if (d <= ovulationDay) {
      return 1 + (d - 1) / (ovulationDay - 1) * (ov - 1);
    }
    return ov + (d - ovulationDay) / (cycleLength - ovulationDay) * (28 - ov);
  }

  /// Normalised illustration value for [kind] on [cycleDay].
  double valueAt(HormoneKind kind, double cycleDay) =>
      curves[kind]!.valueAt(referenceDay(cycleDay));

  HormoneTrend trendAt(HormoneKind kind, int cycleDay) =>
      curves[kind]!.trendAt(referenceDay(cycleDay.toDouble()));
}
