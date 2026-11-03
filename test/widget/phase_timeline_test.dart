import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/domain/cycle_windows.dart';
import 'package:cyclecare/widgets/phase_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // The theme asks google_fonts for Google Sans Flex; tests have no network.
  GoogleFonts.config.allowRuntimeFetching = false;

  final lastStart = DateTime(2026, 10, 1);
  final today = DateTime(2026, 10, 3);

  CycleWindows windows() {
    final prediction = const CyclePredictionService().buildPrediction(
      periods: [
        for (var i = 0; i < 4; i++)
          CycleEvent(
            id: 'p$i',
            startDate: lastStart.subtract(Duration(days: 28 * i)),
            endDate: lastStart.subtract(Duration(days: 28 * i - 4)),
          ),
      ],
      preferences: const CyclePreferences(),
      referenceDate: today,
    )!;
    return CycleWindows.fromPrediction(prediction);
  }

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 900)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhaseTimeline(windows: windows(), today: today),
          ),
        ),
      ),
    );
  }

  testWidgets('lists every window with its status', (tester) async {
    await pump(tester);

    for (final label in [
      'Period',
      'Follicular phase',
      'Fertile window',
      'Ovulation day',
      'Luteal phase',
      'PMS window',
      'Next period',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Now'), findsOneWidget); // the period, on day 3
    expect(find.text('In about 7 days'), findsOneWidget); // fertile window
    expect(find.text('Today · day 3'), findsOneWidget);
  });

  testWidgets('fits a narrow phone at large text without overflow',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, size: const Size(320, 1400));
    expect(tester.takeException(), isNull);
  });
}
