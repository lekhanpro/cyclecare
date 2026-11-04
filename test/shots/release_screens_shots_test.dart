// Production Flutter screens with fictional local records, not prototype exports.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/features/education/education_screen.dart';
import 'shot_harness.dart';

void main() {
  for (final dark in [false, true]) {
    for (final route in [
      'home',
      'calendar',
      'log',
      'insights',
      'pet',
      'settings',
      'birth-control',
      'pregnancy',
      'partner',
      'health',
      'education',
      'health-report',
      'reminders',
    ]) {
      testShot('$route ${dark ? 'dark' : 'light'} compact large text', (
        tester,
      ) async {
        await pumpShotApp(
          tester,
          route: '/$route',
          dark: dark,
          width: 320,
          height: 1400,
          textScale: 2,
        );
        await captureShot(
          tester,
          'release-$route-${dark ? 'dark' : 'light'}-320-large',
        );
        if (route == 'home') {
          await tester.ensureVisible(find.text('Explore hormone patterns'));
          await tester.tap(find.text('Explore hormone patterns'));
          await settleShot(tester);
          await tester.ensureVisible(
            find.byKey(const ValueKey('hormone-range')),
          );
          await settleShot(tester);
          await captureShot(
            tester,
            'release-home-chart-${dark ? 'dark' : 'light'}-320-large',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final dark in [false, true]) {
    testShot('article reader ${dark ? 'dark' : 'light'}', (tester) async {
      await pumpShotScreen(
        tester,
        ArticleReaderScreen(
          article: kArticles.firstWhere((a) => a.id == 'real-world-cycles'),
        ),
        dark: dark,
        width: 390,
        height: 3200,
      );
      await captureShot(tester, 'release-reader-${dark ? 'dark' : 'light'}');
      expect(tester.takeException(), isNull);
    });
    for (final route in ['home', 'calendar', 'log', 'insights', 'pet', 'settings', 'birth-control', 'pregnancy', 'partner', 'health', 'education', 'health-report', 'reminders']) {
      testShot('$route ${dark ? 'dark' : 'light'} normal', (tester) async {
        await pumpShotApp(tester, route: '/$route', dark: dark, height: 1400);
        await captureShot(tester, 'release-$route-${dark ? 'dark' : 'light'}');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
