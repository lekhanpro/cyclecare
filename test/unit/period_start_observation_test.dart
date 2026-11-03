import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_health_report.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'quick start persists an unknown end while forecasts use settings',
    () async {
      final container = ProviderContainer();
      final start = DateTime.now().subtract(const Duration(days: 1));
      final controller = container.read(
        cycleTrackerControllerProvider.notifier,
      );
      await controller.logPeriodStart(start);
      final state = await container.read(cycleTrackerControllerProvider.future);
      expect(state.periods.single.endDate, isNull);
      expect(state.prediction?.averagePeriodLength, 5);
      expect(state.periodFor(start.add(const Duration(days: 1))), isNull);
      expect(
        state.statusFor(start.add(const Duration(days: 1))),
        isNot(DayStatus.period),
      );
      container.dispose();
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(
        (await reopened.read(
          cycleTrackerControllerProvider.future,
        )).periods.single.endDate,
        isNull,
      );
    },
  );
  test(
    'onboarding usual duration does not become an observed period end',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(cycleTrackerControllerProvider.notifier)
          .completeOnboarding(
            lastPeriodStart: DateTime(2026, 10, 1),
            cycleLength: 28,
            periodLength: 6,
          );
      final state = await container.read(cycleTrackerControllerProvider.future);
      expect(state.periods.single.endDate, isNull);
      expect(state.preferences.averagePeriodLength, 6);
    },
  );
  test(
    'report preserves a saved future end but labels duration unconfirmed',
    () {
      final start = DateTime(2026, 11, 3);
      final text = buildCycleHealthReport(
        periods: [
          CycleEvent(
            id: 'old',
            startDate: start,
            endDate: DateTime(2026, 11, 7),
          ),
        ],
        logs: [],
        options: HealthReportOptions(start: start, end: start),
        referenceDate: start,
      );
      expect(text, contains('2026-11-07; duration unconfirmed'));
      expect(text, isNot(contains('duration 5 days')));
    },
  );
}
