import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_prediction_service.dart';

void main() {
  group('CyclePredictionService', () {
    const service = CyclePredictionService();
    const preferences = CyclePreferences();

    test('returns null when no period data exists', () {
      final prediction = service.buildPrediction(
        periods: const [],
        preferences: preferences,
      );
      expect(prediction, isNull);
    });

    test('predicts based on single period', () {
      final reference = DateTime(2026, 4, 29);
      final lastPeriod = DateTime(2026, 4, 15);
      final prediction = service.buildPrediction(
        periods: [
          CycleEvent(id: '1', startDate: lastPeriod),
        ],
        preferences: preferences,
        referenceDate: reference,
      );
      expect(prediction!.cycleDay, 15);
      expect(prediction.daysUntilPeriod, 14);
      expect(prediction.nextPeriodStart, DateTime(2026, 5, 13));
    });

    test('predicts with multiple cycles using weighted average', () {
      final prediction = service.buildPrediction(
        periods: [
          CycleEvent(id: '3', startDate: DateTime(2026, 4, 1)),
          CycleEvent(id: '2', startDate: DateTime(2026, 3, 4)),
          CycleEvent(id: '1', startDate: DateTime(2026, 2, 5)),
        ],
        preferences: preferences,
        referenceDate: DateTime(2026, 4, 29),
      );
      expect(prediction!.averageCycleLength, 28);
      expect(prediction.confidence, greaterThan(0.4));
    });

    test('fertile window is around ovulation day', () {
      final prediction = service.buildPrediction(
        periods: [
          CycleEvent(id: '1', startDate: DateTime(2026, 4, 1)),
        ],
        preferences: preferences,
        referenceDate: DateTime(2026, 4, 10),
      );
      expect(prediction!.ovulationDate, DateTime(2026, 4, 15));
      expect(prediction.fertileWindowStart, DateTime(2026, 4, 10));
      expect(prediction.fertileWindowEnd, DateTime(2026, 4, 16));
    });
  });
}
