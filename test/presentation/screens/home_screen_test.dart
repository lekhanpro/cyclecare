import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/features/tracking/presentation/home_screen.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';

void main() {
  testWidgets('HomeScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cycleTrackerControllerProvider.overrideWith(
            () => _FakeController(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    // Should render without throwing
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

class _FakeController extends CycleTrackerController {
  @override
  Future<CycleTrackerState> build() async {
    return CycleTrackerState(
      periods: const [],
      logs: const [],
      preferences: const CyclePreferences(onboardingCompleted: true),
      prediction: null,
      selectedDate: DateTime.now(),
    );
  }
}
