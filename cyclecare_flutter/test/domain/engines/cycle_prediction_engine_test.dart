import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/domain/engines/cycle_prediction_engine.dart';

void main() {
  group('CyclePredictionEngine', () {
    test('predicts next period from single start date', () {
      final start = DateTime(2024, 1, 1);
      final result = CyclePredictionEngine.predict(periodStartDates: [start]);
      expect(result.cycleDay, greaterThanOrEqualTo(0));
      expect(result.nextPeriodStart, isNotNull);
    });

    test('averages multiple periods for cycle length', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 30),
        DateTime(2024, 2, 28),
      ];
      final result = CyclePredictionEngine.predict(periodStartDates: dates);
      expect(result.averageCycleLength, closeTo(29, 1));
      expect(result.confidence, greaterThan(0));
    });

    test('handles irregular cycles with lower confidence', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 20),
        DateTime(2024, 2, 25),
        DateTime(2024, 3, 30),
      ];
      final result = CyclePredictionEngine.predict(periodStartDates: dates);
      expect(result.confidence, lessThan(0.9));
    });

    test('identifies ovulation as 14 days before next period', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 29),
      ];
      final result = CyclePredictionEngine.predict(periodStartDates: dates);
      final ovulationDate = result.ovulationDate;
      final daysToOvulation = ovulationDate.difference(DateTime(2024, 1, 29)).inDays;
      expect(daysToOvulation, closeTo(28 - 14, 1));
    });

    test('returns default values when no periods provided', () {
      final result = CyclePredictionEngine.predict(periodStartDates: []);
      expect(result.averageCycleLength, 28);
      expect(result.averagePeriodLength, 5);
      expect(result.confidence, 0.0);
    });
  });
}
