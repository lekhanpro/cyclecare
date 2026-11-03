import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/presentation/calendar_screen.dart';
import 'package:cyclecare/features/tracking/presentation/calendar_year_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeededController extends CycleTrackerController {
  @override
  Future<CycleTrackerState> build() async {
    final now = DateTime.now();
    final lastStart =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
    final periods = [
      for (var i = 0; i < 4; i++)
        CycleEvent(
          id: 'p$i',
          startDate: lastStart.subtract(Duration(days: 28 * i)),
          endDate: lastStart.subtract(Duration(days: 28 * i - 4)),
        ),
    ];
    const prefs = CyclePreferences(onboardingCompleted: true);
    return CycleTrackerState(
      periods: periods,
      logs: [DailyLog(date: now, mood: 'Calm')],
      preferences: prefs,
      prediction: const CyclePredictionService()
          .buildPrediction(periods: periods, preferences: prefs),
      selectedDate: now,
    );
  }
}

Widget _app() => ProviderScope(
      overrides: [
        cycleTrackerControllerProvider.overrideWith(_SeededController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: const CalendarScreen(),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  void size(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows the month summary strip', (tester) async {
    size(tester, const Size(430, 2400));
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(find.text('Fertile days'), findsOneWidget);
    expect(find.text('Days logged'), findsOneWidget);
  });

  testWidgets('year view opens and a month tap returns to it',
      (tester) async {
    size(tester, const Size(430, 2400));
    await tester.pumpWidget(_app());
    await _settle(tester);

    await tester.tap(find.text('Year'));
    await _settle(tester);
    expect(find.byType(CalendarYearView), findsOneWidget);
    expect(find.text('${DateTime.now().year}'), findsOneWidget);

    // Open January of this year from the overview.
    await tester.tap(find.text('Jan'));
    await _settle(tester);
    expect(find.byType(CalendarYearView), findsNothing);
    final january = DateFormat('MMMM yyyy')
        .format(DateTime(DateTime.now().year, 1));
    expect(find.textContaining(january.split(' ').first), findsWidgets);
  });

  testWidgets('no overflow on a small phone at large text', (tester) async {
    size(tester, const Size(360, 2400));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await _settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Year'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });
}
