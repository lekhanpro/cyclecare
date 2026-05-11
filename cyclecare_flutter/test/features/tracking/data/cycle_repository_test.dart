import 'package:cyclecare_flutter/features/tracking/data/cycle_repository.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CycleRepository', () {
    test('persists periods, logs, and preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = CycleRepository(prefs);

      final period = CycleEvent(
        id: 'p1',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 5),
      );
      final log = DailyLog(
        date: DateTime(2026, 5, 2),
        flow: FlowIntensity.medium,
        mood: 'Calm',
        symptoms: const ['Cramps'],
        painLevel: 4,
        waterMl: 1000,
        medicineTaken: true,
      );
      const preferences = CyclePreferences(
        averageCycleLength: 30,
        averagePeriodLength: 6,
        goal: TrackingGoal.symptomWellness,
        onboardingCompleted: true,
      );

      await repository.savePeriods([period]);
      await repository.saveLogs([log]);
      await repository.savePreferences(preferences);

      expect(repository.loadPeriods(), hasLength(1));
      expect(repository.loadPeriods().single.endDate, DateTime(2026, 5, 5));
      expect(repository.loadLogs().single.painLevel, 4);
      expect(repository.loadLogs().single.medicineTaken, isTrue);
      expect(repository.loadPreferences().averageCycleLength, 30);
      expect(repository.loadPreferences().goal, TrackingGoal.symptomWellness);
    });

    test('deleteAll clears local tracking data', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = CycleRepository(prefs);

      await repository.savePeriods([
        CycleEvent(id: 'p1', startDate: DateTime(2026, 5, 1)),
      ]);
      await repository.saveLogs([
        DailyLog(date: DateTime(2026, 5, 1), mood: 'Happy'),
      ]);
      await repository.savePreferences(
        const CyclePreferences(onboardingCompleted: true),
      );

      await repository.deleteAll();

      expect(repository.loadPeriods(), isEmpty);
      expect(repository.loadLogs(), isEmpty);
      expect(repository.loadPreferences().onboardingCompleted, isFalse);
    });
  });
}
