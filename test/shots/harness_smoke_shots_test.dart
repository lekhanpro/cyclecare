// Smoke test for the shot harness itself: renders Home and Settings in both
// appearances. Run with --dart-define=SHOTS=true.

import 'package:flutter_test/flutter_test.dart';

import 'shot_harness.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testShot('home $theme', (tester) async {
      await pumpShotApp(tester, route: '/home', dark: dark, height: designHeight('home'));
      await captureShot(tester, 'harness-home-$theme');
    });

    testShot('settings $theme', (tester) async {
      await pumpShotApp(tester, route: '/settings', dark: dark);
      await captureShot(tester, 'harness-settings-$theme');
    });
  }
}
