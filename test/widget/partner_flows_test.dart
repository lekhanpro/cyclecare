import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/partner/domain/partner_share_code.dart';
import 'package:cyclecare/features/partner/partner_flows.dart';
import 'package:cyclecare/features/partner/partner_screen.dart';
import 'package:cyclecare/features/partner/partner_view.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeededController extends CycleTrackerController {
  @override
  Future<CycleTrackerState> build() async {
    final today = DateTime.now();
    final lastStart = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 2));
    final periods = [
      for (var i = 0; i < 4; i++)
        CycleEvent(
          id: 'p$i',
          startDate: lastStart.subtract(Duration(days: 28 * i)),
          endDate: lastStart.subtract(Duration(days: 28 * i - 4)),
        ),
    ];
    const prefs = CyclePreferences(
      profileName: 'Ava',
      onboardingCompleted: true,
    );
    return CycleTrackerState(
      periods: periods,
      logs: [DailyLog(date: today, mood: 'Calm', painLevel: 2)],
      preferences: prefs,
      prediction: const CyclePredictionService()
          .buildPrediction(periods: periods, preferences: prefs),
      selectedDate: today,
    );
  }
}

Widget _app(Widget home) => ProviderScope(
      overrides: [
        cycleTrackerControllerProvider.overrideWith(_SeededController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppPalette.pinkRose.seed),
        home: home,
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('switching mood on adds it to the live preview', (tester) async {
    tall(tester);
    await tester.pumpWidget(_app(const PartnerScreen()));
    await _settle(tester);

    await tester.tap(find.text('Preview as your partner'));
    await _settle(tester);
    expect(find.text('This is what your partner sees'), findsOneWidget);
    expect(find.text('Calm'), findsNothing);

    // Back, switch mood on, preview again.
    Navigator.of(tester.element(find.byType(PartnerDashboard))).pop();
    await _settle(tester);
    await tester.tap(find.text("Today's mood"));
    await _settle(tester);
    await tester.tap(find.text('Preview as your partner'));
    await _settle(tester);
    expect(find.text('Calm'), findsOneWidget);
  });

  testWidgets('sharing explanations open without hiding selection or preview',
      (tester) async {
    tall(tester);
    await tester.pumpWidget(_app(const PartnerScreen()));
    await _settle(tester);

    expect(find.text('How sharing works'), findsOneWidget);
    expect(find.text('A snapshot, not a live link'), findsNothing);
    expect(find.text("Today's mood"), findsOneWidget);
    expect(find.text('Preview as your partner'), findsOneWidget);

    await tester.tap(find.text('How sharing works'));
    await tester.pumpAndSettle();
    expect(find.text('A snapshot, not a live link'), findsOneWidget);
    expect(find.text('Only what you switch on'), findsOneWidget);
  });

  testWidgets('a code from encode() opens the dashboard', (tester) async {
    tall(tester);
    final now = DateTime.now();
    final code = encodeShareCode(PartnerSnapshot(
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      ownerName: 'Ava',
      phase: 'Luteal',
      cycleDay: 20,
      note: 'Pizza tonight?',
    ));

    await tester.pumpWidget(_app(const PartnerOpenCodeScreen()));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('partner-code-field')), code);
    await tester.tap(find.text('Open'));
    await _settle(tester);

    expect(find.text('Luteal phase'), findsOneWidget);
    expect(find.text('Cycle day 20'), findsOneWidget);
    expect(find.text('Pizza tonight?'), findsOneWidget);
  });

  testWidgets('a mistyped code shows the checksum error', (tester) async {
    tall(tester);
    final now = DateTime.now();
    final code = encodeShareCode(PartnerSnapshot(
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      phase: 'Luteal',
    ));
    final broken = code.replaceRange(6, 7, code[6] == 'A' ? 'B' : 'A');

    await tester.pumpWidget(_app(const PartnerOpenCodeScreen()));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('partner-code-field')), broken);
    await tester.tap(find.text('Open'));
    await _settle(tester);

    expect(
      find.text(const ShareCodeException(ShareCodeError.checksum).message),
      findsOneWidget,
    );
    expect(find.byType(PartnerDashboard), findsNothing);
  });
}
