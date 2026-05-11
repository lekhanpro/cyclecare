import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cyclecare_flutter/features/tracking/presentation/home_screen.dart';
import 'package:cyclecare_flutter/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_models.dart';

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
      await tester.pumpAndSettle();
      expect(find.text('CycleCare'), findsOneWidget);
      expect(find.byType(AmenorrheaBanner), findsNothing);
    });
  });
}

class FakeCycleTrackerController extends CycleTrackerController {
  @override
  Future<CycleTrackerState> build() async {
    return CycleTrackerState(
      periods: const [],
      logs: const [],
      preferences: const CyclePreferences(),
      prediction: null,
      selectedDate: DateTime.now(),
    );
  }
}
