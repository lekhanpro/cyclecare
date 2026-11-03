import 'package:cyclecare/features/tracking/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../shots/shot_harness.dart';

void main() {
  testWidgets('five full navigation names remain readable and usable at 200 percent', (tester) async {
    await tester.runAsync(loadShotFonts);
    await pumpShotApp(tester, route: '/home', width: 320, height: 1000, textScale: 2);
    for (final label in ['Today', 'Calendar', 'Log', 'Insights', 'Companion']) {
      final text = find.text(label).last;
      expect(text, findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse,
        reason: '$label navigation caption must remain complete');
      expect(tester.getSize(text).height, greaterThan(0));
    }
    await tester.tap(find.text('Calendar').last);
    await settleShot(tester);
    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
