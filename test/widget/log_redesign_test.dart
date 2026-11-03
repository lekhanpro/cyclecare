import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/presentation/log_screen.dart';
import 'package:cyclecare/features/tracking/presentation/log_tiles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the screen saves instead of writing to storage.
class _RecordingController extends CycleTrackerController {
  static final saved = <DailyLog>[];

  @override
  Future<CycleTrackerState> build() async => CycleTrackerState(
        periods: const [],
        logs: const [],
        preferences: const CyclePreferences(onboardingCompleted: true),
        prediction: null,
        selectedDate: DateTime.now(),
      );

  @override
  Future<void> saveLog(DailyLog log) async {
    saved.add(log);
    final current = state.requireValue;
    state = AsyncData(CycleTrackerState(
      periods: current.periods,
      logs: [log],
      preferences: current.preferences,
      prediction: current.prediction,
      selectedDate: current.selectedDate,
    ));
  }
}

Widget _app() => ProviderScope(
      overrides: [
        cycleTrackerControllerProvider.overrideWith(_RecordingController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: const LogScreen(),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Catalogue option tiles carry a stable key, so a test never depends on a
/// label appearing only once across 204 choices.
Finder _option(String field, String label) =>
    find.byKey(ValueKey('log-option-$field-$label'));

Future<void> _tapOption(
  WidgetTester tester,
  String field,
  String label,
) async {
  final finder = _option(field, label);
  await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _save(WidgetTester tester) async {
  final button = find.text('Save my check-in');
  expect(button, findsOneWidget);
  await tester.tap(button);
  await _settle(tester);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _RecordingController.saved.clear();
  });

  void size(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('flow and mood tiles save into the log', (tester) async {
    size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app());
    await _settle(tester);

    // Flow and mood are the two groups the screen opens with.
    expect(find.byType(LogTile), findsWidgets);

    await _tapOption(tester, 'flow', 'Medium');
    await _tapOption(tester, 'mood', 'Calm');

    // Two observations, reported as such beside the save button.
    // The key is on the Text itself, so match the root of the subtree.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('log-save-count')),
        matching: find.textContaining('2 things'),
        matchRoot: true,
      ),
      findsOneWidget,
    );

    await _save(tester);

    expect(_RecordingController.saved, hasLength(1));
    final log = _RecordingController.saved.single;
    expect(log.flow, FlowIntensity.medium);
    expect(log.mood, 'Calm');
  });

  testWidgets('re-tapping a recorded tile leaves the field unlogged',
      (tester) async {
    size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app());
    await _settle(tester);

    await _tapOption(tester, 'mood', 'Calm');
    await _tapOption(tester, 'mood', 'Calm');
    // Something else has to change, or there is nothing to save.
    await _tapOption(tester, 'flow', 'Medium');
    await _save(tester);

    final log = _RecordingController.saved.single;
    expect(log.mood, isNull, reason: 'a cleared field is not logged');
    expect(log.flow, FlowIntensity.medium);
  });

  testWidgets('a closed group opens and records into it', (tester) async {
    size(tester, const Size(430, 6000));
    await tester.pumpWidget(_app());
    await _settle(tester);

    // Symptoms starts closed, so its options are not built at all.
    expect(_option('symptomsBody', 'Cramps'), findsNothing);

    final header = find.byKey(const ValueKey('log-group-symptoms'));
    await tester.scrollUntilVisible(header, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(header);
    await _settle(tester);

    await _tapOption(tester, 'symptomsBody', 'Cramps');
    await _save(tester);

    expect(_RecordingController.saved.single.symptoms, contains('Cramps'));
  });

  testWidgets('no overflow on a small phone at large text', (tester) async {
    size(tester, const Size(360, 3000));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await _settle(tester);

    final error = tester.takeException();
    if (error is FlutterError) {
      // Name the widget behind an overflow instead of only its pixel count.
      for (final node in error.diagnostics) {
        debugPrint('OVERFLOW DETAIL: ${node.toStringDeep()}');
      }
    }
    expect(error, isNull);
  });
}
