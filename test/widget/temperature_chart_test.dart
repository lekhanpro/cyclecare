import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/presentation/insights_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TemperatureController extends CycleTrackerController {
  _TemperatureController({this.single = false});
  final bool single;

  @override
  Future<CycleTrackerState> build() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 12));
    final periods = [CycleEvent(id: 'current', startDate: start)];
    const preferences = CyclePreferences(onboardingCompleted: true);
    return CycleTrackerState(
      periods: periods,
      logs: [
        DailyLog(
          date: start,
          temperatureCelsius: 36.4,
          temperatureContext: const ['Usual conditions'],
        ),
        if (!single) ...[
          DailyLog(
            date: start.add(const Duration(days: 2)),
            temperatureCelsius: 36.6,
            temperatureContext: const ['Disrupted sleep'],
          ),
          DailyLog(
            date: start.add(const Duration(days: 3)),
            temperatureCelsius: 36.5,
          ),
        ],
      ],
      preferences: preferences,
      prediction: const CyclePredictionService().buildPrediction(
        periods: periods,
        preferences: preferences,
      ),
      selectedDate: today,
    );
  }
}

Future<LineChartData> _chart(WidgetTester tester, {bool single = false}) async {
  tester.view.physicalSize = const Size(390, 18000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cycleTrackerControllerProvider.overrideWith(
          () => _TemperatureController(single: single),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: const InsightsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return tester
      .widgetList<LineChart>(find.byType(LineChart))
      .singleWhere(
        (chart) => chart.data.lineBarsData.any(
          (bar) => bar.spots.any((spot) => spot.y == 36.4),
        ),
      )
      .data;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'recorded temperatures retain day gaps and context before nine readings',
    (tester) async {
      final data = await _chart(tester);
      final bar = data.lineBarsData.single;
      expect(bar.spots, [
        const FlSpot(1, 36.4),
        FlSpot.nullSpot,
        const FlSpot(3, 36.6),
        const FlSpot(4, 36.5),
      ]);
      expect(data.minX, 1);
      expect(data.maxX, 4);
      expect(data.extraLinesData.horizontalLines, isEmpty);
      expect(find.textContaining('3 of 9 readings'), findsOneWidget);
      expect(find.text('Disturbed conditions'), findsOneWidget);
      expect(find.text('Context not logged (unknown)'), findsOneWidget);
      expect(
        bar.dotData.getDotPainter(bar.spots[2], 0, bar, 2),
        isA<FlDotCirclePainter>(),
      );
      expect(
        bar.dotData.getDotPainter(bar.spots[3], 0, bar, 3),
        isA<FlDotSquarePainter>(),
      );
      final tooltips = data.lineTouchData.touchTooltipData.getTooltipItems([
        LineBarSpot(bar, 0, bar.spots[2]),
        LineBarSpot(bar, 0, bar.spots[3]),
      ]);
      expect(tooltips[0]!.text, contains('Disrupted sleep'));
      expect(tooltips[1]!.text, contains('Context not logged (unknown)'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a single reading has a usable plot and no descriptive coverline',
    (tester) async {
      final data = await _chart(tester, single: true);
      expect(data.minX, lessThan(data.maxX));
      expect(data.lineBarsData.single.spots, [const FlSpot(1, 36.4)]);
      expect(data.extraLinesData.horizontalLines, isEmpty);
      expect(find.textContaining('1 of 9 readings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('temperature chart and context legend fit at 200 percent text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _chart(tester);
    expect(find.text('Context not logged (unknown)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
