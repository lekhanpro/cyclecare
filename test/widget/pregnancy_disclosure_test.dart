import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/pregnancy/pregnancy_content.dart';
import 'package:cyclecare/features/pregnancy/pregnancy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final scale in [1.0, 2.0]) {
    testWidgets('weekly guide retains full content at ${scale}x text', (
      tester,
    ) async {
      final due = DateTime.now().add(const Duration(days: 112));
      SharedPreferences.setMockInitialValues({
        'cc.preg.active': true,
        'cc.preg.dueDate': due.toIso8601String(),
      });
      final week = PregnancyState(dueDate: due).weeksPregnant;
      final entry = PregnancyContent.forWeek(week);
      tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(const Color(0xff79516a)),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const PregnancyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.babyUpdate), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Week $week guide'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Week $week guide'));
      await tester.pumpAndSettle();
      expect(find.text(entry.babyUpdate), findsOneWidget);
      expect(find.text(entry.bodyUpdate), findsOneWidget);
      expect(find.text(entry.tip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
