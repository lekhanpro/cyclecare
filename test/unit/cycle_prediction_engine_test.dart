import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';

void main() {
  const service = CyclePredictionService();
  const prefs =
      CyclePreferences(averageCycleLength: 28, averagePeriodLength: 5);

  /// Builds N period starts spaced [cycleLength] days apart, most recent first,
  /// with the newest starting [daysAgo] before today.
  List<CycleEvent> regularPeriods({
    required int count,
    required int cycleLength,
    required int daysAgo,
  }) {
    final today = DateTime.now();
    return [
      for (var i = 0; i < count; i++)
        CycleEvent(
          id: '$i',
          startDate: today.subtract(
            Duration(days: daysAgo + cycleLength * i),
          ),
        ),
    ];
  }

  group('CyclePredictionService', () {
    test('returns null with no periods', () {
      final result = service.buildPrediction(periods: [], preferences: prefs);
      expect(result, isNull);
    });

    test('predicts from single period', () {
      final start = DateTime.now().subtract(const Duration(days: 14));
      final periods = [CycleEvent(id: '1', startDate: start)];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result, isNotNull);
      expect(result!.cycleDay, greaterThan(0));
    });

    test('detects late period', () {
      final start = DateTime.now().subtract(const Duration(days: 40));
      final periods = [CycleEvent(id: '1', startDate: start)];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result?.isLate, isTrue);
      expect(result?.daysLate, greaterThan(0));
    });

    test('fertile window sits before ovulation', () {
      final start = DateTime.now().subtract(const Duration(days: 14));
      final periods = [CycleEvent(id: '1', startDate: start)];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.fertileWindowStart.isBefore(result.ovulationDate), isTrue);
      expect(result.fertileWindowEnd.isAfter(result.ovulationDate), isTrue);
    });

    test('learns cycle length from history instead of the preference', () {
      // Four cycles of 31 days, while the stored preference still says 28.
      final periods =
          regularPeriods(count: 5, cycleLength: 31, daysAgo: 5);
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.averageCycleLength, 31);
      expect(result.cyclesTracked, 4);
    });

    test('flags a consistent cycle as regular', () {
      final periods = regularPeriods(count: 5, cycleLength: 28, daysAgo: 3);
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.isIrregular, isFalse);
      expect(result.cycleLengthVariation, lessThan(1));
      expect(result.shortestCycle, 28);
      expect(result.longestCycle, 28);
    });

    test('flags a widely varying cycle as irregular', () {
      // Gaps of 22, 45, 26 and 38 days — a standard deviation well past the
      // 4.5-day threshold.
      final today = DateTime.now();
      var cursor = today.subtract(const Duration(days: 4));
      final gaps = [22, 45, 26, 38];
      final periods = <CycleEvent>[
        CycleEvent(id: 'latest', startDate: cursor),
      ];
      for (var i = 0; i < gaps.length; i++) {
        cursor = cursor.subtract(Duration(days: gaps[i]));
        periods.add(CycleEvent(id: '$i', startDate: cursor));
      }

      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.isIrregular, isTrue);
      expect(result.cycleLengthVariation, greaterThan(4.5));
      expect(result.shortestCycle, 22);
      expect(result.longestCycle, 45);
    });

    test('averages period length from recorded end dates', () {
      final today = DateTime.now();
      final periods = [
        // 7 days inclusive.
        CycleEvent(
          id: '1',
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today,
        ),
        CycleEvent(
          id: '2',
          startDate: today.subtract(const Duration(days: 34)),
          endDate: today.subtract(const Duration(days: 28)),
        ),
      ];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.averagePeriodLength, 7);
    });

    test('PMS window is the five days before the next period', () {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final periods = [CycleEvent(id: '1', startDate: start)];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);

      expect(result!.pmsWindowStart, isNotNull);
      expect(result.pmsWindowEnd, isNotNull);
      // Ends the day before bleeding is expected.
      expect(
        result.nextPeriodStart.difference(result.pmsWindowEnd!).inDays,
        1,
      );
      // Spans five days inclusive.
      expect(
        result.pmsWindowEnd!.difference(result.pmsWindowStart!).inDays,
        4,
      );
      expect(result.isPmsOn(result.pmsWindowStart!), isTrue);
      expect(result.isPmsOn(result.nextPeriodStart), isFalse);
    });

    test('projects three future cycles, each a cycle length apart', () {
      final periods = regularPeriods(count: 4, cycleLength: 30, daysAgo: 2);
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);

      expect(result!.upcomingCycles.length, 3);
      expect(result.upcomingCycles.first.periodStart, result.nextPeriodStart);

      final first = result.upcomingCycles[0];
      final second = result.upcomingCycles[1];
      expect(
        second.periodStart.difference(first.periodStart).inDays,
        result.averageCycleLength,
      );
      // Ovulation stays anchored to the luteal phase before the *following*
      // period, not a fixed day number.
      for (final cycle in result.upcomingCycles) {
        expect(cycle.fertileWindowStart.isBefore(cycle.ovulationDate), isTrue);
        expect(cycle.pmsWindowEnd.isAfter(cycle.pmsWindowStart), isTrue);
      }
    });

    test('confidence label reflects how much history exists', () {
      final thin = service.buildPrediction(
        periods: [
          CycleEvent(
            id: '1',
            startDate: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        preferences: prefs,
      );
      expect(thin!.confidenceLabel, 'Learning');

      final rich = service.buildPrediction(
        periods: regularPeriods(count: 7, cycleLength: 28, daysAgo: 3),
        preferences: prefs,
      );
      expect(rich!.confidenceLabel, isNot('Learning'));
      expect(rich.confidence, greaterThan(thin.confidence));
    });

    test('ignores implausible gaps when learning cycle length', () {
      final today = DateTime.now();
      final periods = [
        CycleEvent(id: '1', startDate: today.subtract(const Duration(days: 3))),
        CycleEvent(id: '2', startDate: today.subtract(const Duration(days: 31))),
        // A 400-day gap: almost certainly a mis-logged year, and must not drag
        // the average.
        CycleEvent(
          id: '3',
          startDate: today.subtract(const Duration(days: 431)),
        ),
      ];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.averageCycleLength, 28);
      expect(result.cyclesTracked, 1);
    });

    test('phase resolves to a typed CyclePhase', () {
      final periods = [
        CycleEvent(
          id: '1',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(result!.currentPhase, CyclePhase.menstrual);
      expect(result.phase, 'Menstrual');
    });
  });
}
