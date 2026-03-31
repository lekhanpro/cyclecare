import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/domain/engines/cycle_prediction_engine.dart';

void main() {
  group('CyclePredictionEngine', () {
    test('returns default prediction when no period data', () {
      final prediction = CyclePredictionEngine.predict(
        periodStartDates: [],
        defaultCycleLength: 28,
        defaultPeriodLength: 5,
      );
      expect(prediction.confidenceScore, 0.3);
      expect(prediction.daysUntilPeriod, 28);
    });

    test('predicts based on single period', () {
      final lastPeriod = DateTime.now().subtract(const Duration(days: 14));
      final prediction = CyclePredictionEngine.predict(
        periodStartDates: [lastPeriod],
        defaultCycleLength: 28,
      );
      expect(prediction.cycleDay, closeTo(15, 1));
      expect(prediction.daysUntilPeriod, closeTo(14, 1));
      expect(prediction.currentPhase, isNotEmpty);
    });

    test('predicts with multiple cycles using weighted average', () {
      final now = DateTime.now();
      final dates = [
        now.subtract(const Duration(days: 84)),
        now.subtract(const Duration(days: 56)),
        now.subtract(const Duration(days: 28)),
      ];
      final prediction = CyclePredictionEngine.predict(
        periodStartDates: dates,
      );
      expect(prediction.confidenceScore, greaterThan(0.5));
      expect(prediction.cycleDay, closeTo(29, 1));
    });

    test('identifies cycle phases correctly', () {
      final lastPeriod = DateTime.now().subtract(const Duration(days: 2));
      final prediction = CyclePredictionEngine.predict(
        periodStartDates: [lastPeriod],
        defaultPeriodLength: 5,
      );
      expect(prediction.currentPhase, 'Menstrual');
    });

    test('fertile window is around ovulation day', () {
      final lastPeriod = DateTime.now().subtract(const Duration(days: 10));
      final prediction = CyclePredictionEngine.predict(
        periodStartDates: [lastPeriod],
        defaultCycleLength: 28,
      );
      final ovulationDay = 28 - 14; // day 14
      expect(prediction.fertileWindowStart.difference(lastPeriod).inDays, ovulationDay - 5);
    });

    test('perimenopause prediction has lower confidence', () {
      final dates = [
        DateTime.now().subtract(const Duration(days: 70)),
        DateTime.now().subtract(const Duration(days: 35)),
      ];
      final normal = CyclePredictionEngine.predict(periodStartDates: dates);
      final peri = CyclePredictionEngine.predictPerimenopause(periodStartDates: dates);
      expect(peri.confidenceScore, lessThan(normal.confidenceScore));
    });
  });
}
