import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/domain/cycle_windows.dart';
import 'package:flutter_test/flutter_test.dart';

/// A regular 28-day history with 5-day periods, last period starting [lastStart].
List<CycleEvent> _history(DateTime lastStart, {int cycles = 4, int length = 28}) {
  return [
    for (var i = 0; i < cycles; i++)
      CycleEvent(
        id: 'p$i',
        startDate: lastStart.subtract(Duration(days: length * i)),
        endDate: lastStart.subtract(Duration(days: length * i - 4)),
      ),
  ];
}

CyclePrediction _predict(DateTime lastStart, DateTime today, {int length = 28}) {
  return const CyclePredictionService().buildPrediction(
    periods: _history(lastStart, length: length),
    preferences: const CyclePreferences(),
    referenceDate: today,
  )!;
}

void main() {
  final lastStart = DateTime(2026, 10, 1);

  group('CycleWindows.fromPrediction', () {
    test('lays out a 28-day cycle in order with correct dates', () {
      final w = CycleWindows.fromPrediction(
        _predict(lastStart, DateTime(2026, 10, 3)),
      );

      expect(w.cycleStart, DateTime(2026, 10, 1));
      expect(w.cycleLength, 28);
      expect(w.windows.map((x) => x.kind).toList(), [
        CycleWindowKind.period,
        CycleWindowKind.follicular,
        CycleWindowKind.fertile,
        CycleWindowKind.ovulation,
        CycleWindowKind.luteal,
        CycleWindowKind.pms,
        CycleWindowKind.nextPeriod,
      ]);

      // Period: days 1-5.
      expect(w.of(CycleWindowKind.period)!.start, DateTime(2026, 10, 1));
      expect(w.of(CycleWindowKind.period)!.end, DateTime(2026, 10, 5));
      // Ovulation: next period (Oct 29) minus 14-day luteal phase.
      expect(w.of(CycleWindowKind.ovulation)!.start, DateTime(2026, 10, 15));
      // Fertile: ovulation -5 .. +1.
      expect(w.of(CycleWindowKind.fertile)!.start, DateTime(2026, 10, 10));
      expect(w.of(CycleWindowKind.fertile)!.end, DateTime(2026, 10, 16));
      // Follicular fills the gap between period and fertile window.
      expect(w.of(CycleWindowKind.follicular)!.start, DateTime(2026, 10, 6));
      expect(w.of(CycleWindowKind.follicular)!.end, DateTime(2026, 10, 9));
      // Luteal runs from the day after ovulation to the day before the period.
      expect(w.of(CycleWindowKind.luteal)!.start, DateTime(2026, 10, 16));
      expect(w.of(CycleWindowKind.luteal)!.end, DateTime(2026, 10, 28));
      // PMS: the 5 days before the next period.
      expect(w.of(CycleWindowKind.pms)!.start, DateTime(2026, 10, 24));
      expect(w.of(CycleWindowKind.pms)!.end, DateTime(2026, 10, 28));
      expect(w.of(CycleWindowKind.nextPeriod)!.start, DateTime(2026, 10, 29));
    });

    test('timing and countdown relative to a day', () {
      final w = CycleWindows.fromPrediction(
        _predict(lastStart, DateTime(2026, 10, 3)),
      );
      final today = DateTime(2026, 10, 3);

      expect(w.of(CycleWindowKind.period)!.timingOn(today), WindowTiming.now);
      expect(w.of(CycleWindowKind.fertile)!.timingOn(today),
          WindowTiming.upcoming);
      expect(w.of(CycleWindowKind.fertile)!.daysUntil(today), 7);
      expect(w.of(CycleWindowKind.period)!.timingOn(DateTime(2026, 10, 20)),
          WindowTiming.past);
      expect(w.cycleDayOf(today), 3);
    });

    test('an old last log anchors on the rolled-forward cycle', () {
      // Last log is two cycles ago; the service rolls nextPeriodStart forward,
      // and the windows must describe that same cycle, not the logged one.
      final w = CycleWindows.fromPrediction(
        _predict(lastStart, DateTime(2026, 11, 10)),
      );
      final next = w.of(CycleWindowKind.nextPeriod)!.start;
      expect(w.cycleStart, next.subtract(const Duration(days: 28)));
      expect(w.of(CycleWindowKind.period)!.start, w.cycleStart);
    });

    test('a short cycle drops the follicular window instead of inverting it',
        () {
      final w = CycleWindows.fromPrediction(
        _predict(lastStart, DateTime(2026, 10, 3), length: 21),
      );
      for (final window in w.windows) {
        expect(window.end.isBefore(window.start), isFalse,
            reason: '${window.kind} has a negative length');
      }
      expect(w.of(CycleWindowKind.follicular), isNull);
    });
  });
}
