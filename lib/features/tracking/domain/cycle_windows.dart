import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cycle windows
//
// Every phase window of the *current* cycle, with real dates, so the home
// screen can show the whole cycle at once instead of only the phase you are in.
//
// The prediction model carries the fertile window, ovulation day, PMS window
// and next period directly. Follicular and luteal are not on the model, so they
// are derived here from the windows around them:
//
//   follicular = day after the period ends  → day before the fertile window
//   luteal     = day after ovulation        → day before the next period
//
// Everything hangs off one anchor, `nextPeriodStart - averageCycleLength`,
// rather than the last logged period start. The prediction service rolls
// nextPeriodStart forward a whole cycle at a time when the last log is old, so
// anchoring on the logged start would mix dates from two different cycles.
// ─────────────────────────────────────────────────────────────────────────────

enum CycleWindowKind {
  period,
  follicular,
  fertile,
  ovulation,
  luteal,
  pms,
  nextPeriod;

  String get label => switch (this) {
        CycleWindowKind.period => 'Period',
        CycleWindowKind.follicular => 'Follicular phase',
        CycleWindowKind.fertile => 'Fertile window',
        CycleWindowKind.ovulation => 'Ovulation day',
        CycleWindowKind.luteal => 'Luteal phase',
        CycleWindowKind.pms => 'PMS window',
        CycleWindowKind.nextPeriod => 'Next period',
      };
}

/// Where a window sits relative to a given day.
enum WindowTiming { past, now, upcoming }

class CycleWindow {
  const CycleWindow({
    required this.kind,
    required this.start,
    required this.end,
  });

  final CycleWindowKind kind;

  /// Inclusive, date-only.
  final DateTime start;

  /// Inclusive, date-only.
  final DateTime end;

  int get lengthInDays => end.difference(start).inDays + 1;

  WindowTiming timingOn(DateTime day) {
    final d = dateOnly(day);
    if (d.isBefore(start)) return WindowTiming.upcoming;
    if (d.isAfter(end)) return WindowTiming.past;
    return WindowTiming.now;
  }

  /// Days from [day] until the window opens. Zero or negative once open.
  int daysUntil(DateTime day) => start.difference(dateOnly(day)).inDays;
}

/// The current cycle laid out as windows, with its day range.
class CycleWindows {
  const CycleWindows({
    required this.cycleStart,
    required this.cycleLength,
    required this.windows,
  });

  final DateTime cycleStart;
  final int cycleLength;

  /// Ordered by start date. [CycleWindowKind.nextPeriod] is last and sits just
  /// outside the cycle range — it is the cycle's end marker.
  final List<CycleWindow> windows;

  CycleWindow? of(CycleWindowKind kind) {
    for (final window in windows) {
      if (window.kind == kind) return window;
    }
    return null;
  }

  /// 1-based cycle day for [day], clamped to the cycle.
  int cycleDayOf(DateTime day) {
    final value = dateOnly(day).difference(cycleStart).inDays + 1;
    return value.clamp(1, cycleLength);
  }

  static CycleWindows fromPrediction(CyclePrediction prediction) {
    final length = prediction.averageCycleLength;
    final nextStart = dateOnly(prediction.nextPeriodStart);
    final cycleStart = nextStart.subtract(Duration(days: length));

    final periodEnd = cycleStart.add(
      Duration(days: prediction.averagePeriodLength - 1),
    );
    final fertileStart = dateOnly(prediction.fertileWindowStart);
    final fertileEnd = dateOnly(prediction.fertileWindowEnd);
    final ovulation = dateOnly(prediction.ovulationDate);
    final pmsStart = dateOnly(prediction.pmsWindowStart ??
        nextStart.subtract(const Duration(days: 5)));
    final pmsEnd = dateOnly(
        prediction.pmsWindowEnd ?? nextStart.subtract(const Duration(days: 1)));

    const day = Duration(days: 1);
    final windows = <CycleWindow>[
      CycleWindow(kind: CycleWindowKind.period, start: cycleStart, end: periodEnd),
      // Short cycles can leave no room between the period and the fertile
      // window; the window is then omitted rather than given a negative length.
      if (fertileStart.subtract(day).isAfter(periodEnd))
        CycleWindow(
          kind: CycleWindowKind.follicular,
          start: periodEnd.add(day),
          end: fertileStart.subtract(day),
        ),
      CycleWindow(kind: CycleWindowKind.fertile, start: fertileStart, end: fertileEnd),
      CycleWindow(kind: CycleWindowKind.ovulation, start: ovulation, end: ovulation),
      if (nextStart.subtract(day).isAfter(ovulation))
        CycleWindow(
          kind: CycleWindowKind.luteal,
          start: ovulation.add(day),
          end: nextStart.subtract(day),
        ),
      CycleWindow(kind: CycleWindowKind.pms, start: pmsStart, end: pmsEnd),
      CycleWindow(
        kind: CycleWindowKind.nextPeriod,
        start: nextStart,
        end: dateOnly(prediction.nextPeriodEnd),
      ),
    ]..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        return byStart != 0 ? byStart : a.kind.index.compareTo(b.kind.index);
      });

    return CycleWindows(
      cycleStart: cycleStart,
      cycleLength: length,
      windows: windows,
    );
  }
}
