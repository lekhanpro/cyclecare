import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cyclecare_flutter/features/tracking/presentation/home_screen.dart';
import 'package:cyclecare_flutter/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare_flutter/presentation/providers/app_providers.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders loading state initially', (tester) async {
      final container = ProviderContainer(
        overrides: [
          cycleTrackerControllerProvider.overrideWith(
            () => FakeCycleTrackerController(),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      expect(find.text('CycleCare'), findsOneWidget);
    });

    testWidgets('renders empty state when no periods', (tester) async {
      final container = ProviderContainer(
        overrides: [
          cycleTrackerControllerProvider.overrideWith(
            () => FakeCycleTrackerController.loaded(
              periods: [],
              logs: [],
              preferences: const CyclePreferences(),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CycleCare'), findsOneWidget);
      expect(find.byType(AmenorrheaBanner), findsNothing);
    });
  });
}

class FakeCycleTrackerController extends AsyncNotifier<CycleTrackerState> {
  @override
  Future<CycleTrackerState> build() async {
    return const CycleTrackerState(
      periods: [],
      logs: [],
      preferences: CyclePreferences(),
      prediction: null,
      selectedDate: null,
    );
  }

  static AsyncNotifierProvider<FakeCycleTrackerController, CycleTrackerState> loaded({
    required List<PeriodLog> periods,
    required List<DailyLog> logs,
    required CyclePreferences preferences,
  }) {
    return AsyncNotifierProvider<FakeCycleTrackerController, CycleTrackerState>(() {
      final controller = FakeCycleTrackerController();
      // ignore: invalid_use_of_protected_member
      controller.state = AsyncData(CycleTrackerState(
        periods: periods,
        logs: logs,
        preferences: preferences,
        prediction: null,
        selectedDate: DateTime.now(),
      ));
      return controller;
    });
  }
}
