import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';

void main() {
  const service = CyclePredictionService();
  const prefs =
      CyclePreferences(averageCycleLength: 28, averagePeriodLength: 5);

  group('CyclePredictionService', () {
    test('returns null with no periods', () {
      final result = service.buildPrediction(periods: [], preferences: prefs);
      expect(result, isNull);
    });

    test('predicts from single period', () {
      final start = DateTime.now().subtract(const Duration(days: 14));
      final periods = [
        CycleEvent(id: '1', startDate: start),
      ];
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
    });

    test('fertile window before ovulation', () {
      final start = DateTime.now().subtract(const Duration(days: 14));
      final periods = [CycleEvent(id: '1', startDate: start)];
      final result =
          service.buildPrediction(periods: periods, preferences: prefs);
      expect(
        result!.fertileWindowStart.isBefore(result.ovulationDate),
        isTrue,
      );
    });
  });
}
