import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shots/shot_harness.dart';

/// Behaviour of the redesigned Home, on the harness seeds. The view is tall so
/// the whole page is built without scrolling.
void main() {
  const tall = 5200.0;

  Finder row(String name) => find.byKey(ValueKey('home-window-$name'));

  Future<void> pumpHome(
    WidgetTester tester, {
    Map<String, Object>? prefs,
  }) =>
      pumpShotScreen(tester, const HomeScreen(), prefs: prefs, height: tall);

  testWidgets('all seven windows render for the typical cycle', (tester) async {
    await pumpHome(tester);

    for (final name in const [
      'Menstrual',
      'Follicular',
      'Fertile window',
      'Ovulation',
      'Luteal',
      'PMS window',
      'Next period',
    ]) {
      expect(row(name), findsOneWidget, reason: name);
    }
    expect(find.text('Every phase. Every window.'), findsOneWidget);
  });

  testWidgets('the recorded period, passed estimates and "You’re here"',
      (tester) async {
    await pumpHome(tester);

    expect(
      find.descendant(of: row('Menstrual'), matching: find.text('Recorded')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row('Follicular'),
        matching: find.text('Estimated · passed'),
      ),
      findsOneWidget,
    );
    // Cycle day 23 of 28 is luteal: the badge lands there and nowhere else.
    expect(
      find.descendant(of: row('Luteal'), matching: find.text('You’re here')),
      findsOneWidget,
    );
    expect(find.text('You’re here'), findsOneWidget);
    expect(
      find.descendant(
        of: row('Next period'),
        matching: find.textContaining('Estimated · in about'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('visibility off removes the fertile and ovulation rows',
      (tester) async {
    await pumpHome(tester, prefs: {
      ...ShotSeed.typical(),
      'cc.show_fertile': false,
      'cc.show_ovulation': false,
    });

    expect(row('Fertile window'), findsNothing);
    expect(row('Ovulation'), findsNothing);
    expect(row('Menstrual'), findsOneWidget);
    expect(row('Luteal'), findsOneWidget);
    expect(row('PMS window'), findsOneWidget);
    expect(row('Next period'), findsOneWidget);
  });

  testWidgets('a late period shows the gentle check-in alert', (tester) async {
    await pumpHome(tester, prefs: ShotSeed.late());

    expect(find.byKey(const ValueKey('home-late-alert')), findsOneWidget);
    expect(find.text('Your period hasn’t been logged yet.'), findsOneWidget);
    expect(find.text('Log my period'), findsOneWidget);
    // Past the estimate no phase is claimed as current.
    expect(find.text('You’re here'), findsNothing);
  });

  testWidgets('empty history shows the insufficient state, no dates',
      (tester) async {
    await pumpHome(tester, prefs: ShotSeed.empty());

    expect(find.text('Let’s find your rhythm.'), findsOneWidget);
    expect(find.text('Every phase. Every window.'), findsNothing);
    expect(find.text('Next period estimates'), findsNothing);
    expect(find.byKey(const ValueKey('home-late-alert')), findsNothing);
  });

  testWidgets('the check-in card flips once today is logged', (tester) async {
    await pumpHome(tester, prefs: ShotSeed.empty());
    expect(find.byKey(const ValueKey('home-checkin-open')), findsOneWidget);
    expect(find.text('A moment for you, today.'), findsOneWidget);

    // Save today's log through the real controller; the card must flip in
    // place without a reload. (Re-pumping with another seed keeps the same
    // ProviderScope, so it cannot test this.)
    final container =
        ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    await tester.runAsync(() => container
        .read(cycleTrackerControllerProvider.notifier)
        .saveLog(DailyLog(date: ShotSeed.today, mood: 'Calm')));
    await settleShot(tester);
    expect(find.byKey(const ValueKey('home-checkin-open')), findsNothing);
    expect(find.byKey(const ValueKey('home-checkin-done')), findsOneWidget);
    expect(find.text('Checked in for today.'), findsOneWidget);
  });

  testWidgets('companion motion starts paused under reduced motion',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('Play motion'), findsOneWidget);
    expect(find.text('Pause motion'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-companion-motion')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pause motion'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-companion-motion')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Play motion'), findsOneWidget);
  });
}
