import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/presentation/insights_extra_cards.dart';
import 'package:cyclecare/features/tracking/presentation/insights_phase_cards.dart';
import 'package:cyclecare/features/tracking/presentation/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Five cycles of history with daily logs, enough for every new card to have
/// data rather than its empty state.
class _SeededController extends CycleTrackerController {
  @override
  Future<CycleTrackerState> build() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStart = today.subtract(const Duration(days: 3));
    const lengths = [28, 30, 27, 29, 28];
    final starts = <DateTime>[lastStart];
    for (final l in lengths) {
      starts.add(starts.last.subtract(Duration(days: l)));
    }
    final periods = [
      for (var i = 0; i < starts.length; i++)
        CycleEvent(
          id: 'p$i',
          startDate: starts[i],
          endDate: starts[i].add(const Duration(days: 4)),
        ),
    ];
    const moods = ['Calm', 'Tired', 'Happy', 'Irritable'];
    final logs = [
      for (var d = 0; d < 150; d++)
        if (d % 3 != 0)
          DailyLog(
            date: today.subtract(Duration(days: d)),
            mood: moods[d % moods.length],
            symptoms: d % 28 < 3 ? const ['Cramps'] : const ['Bloating'],
            painLevel: d % 28 < 3 ? 5 : 1,
            sleepHours: 6.5 + (d % 4) * 0.5,
            waterMl: 1200 + (d % 3) * 400,
          ),
    ];
    const prefs = CyclePreferences(onboardingCompleted: true);
    return CycleTrackerState(
      periods: periods,
      logs: logs,
      preferences: prefs,
      prediction: const CyclePredictionService()
          .buildPrediction(periods: periods, preferences: prefs),
      selectedDate: today,
    );
  }
}

Widget _app() => ProviderScope(
      overrides: [
        cycleTrackerControllerProvider.overrideWith(_SeededController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: const InsightsScreen(),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Future<void> _openAnalysisGroups(WidgetTester tester) async {
  for (final title in [
    'Your cycle, measured',
    'Patterns',
    'Through your cycle',
  ]) {
    final header = find.descendant(
      of: find.byKey(PageStorageKey('insight-group-$title')),
      matching: find.text(title),
    ).first;
    await tester.ensureVisible(header);
    await tester.tap(header);
    await _settle(tester);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  void size(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('new cards render with data, not their empty states',
      (tester) async {
    // Very tall, so the whole ListView builds at once.
    size(tester, const Size(430, 12000));
    await tester.pumpWidget(_app());
    await _settle(tester);
    await _openAnalysisGroups(tester);

    for (final type in [
      RegularityCard,
      PredictionAccuracyCard,
      CycleComparisonCard,
      SymptomHeatmapCard,
      ByPhaseCard,
      LoggingPerCycleCard,
    ]) {
      expect(find.byType(type), findsOneWidget, reason: '$type');
    }
    expect(find.textContaining('complete cycles'), findsNothing);
    expect(find.text('How regular your cycle is'), findsOneWidget);
    expect(find.textContaining('Off by about'), findsOneWidget);
  });

  testWidgets('no overflow on a small phone at large text', (tester) async {
    size(tester, const Size(360, 12000));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await _settle(tester);
    await _openAnalysisGroups(tester);
    expect(tester.takeException(), isNull);
  });
}
