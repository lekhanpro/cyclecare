import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/app/main_shell.dart';
import 'package:cyclecare/features/pet/pet_companion.dart';
import 'package:cyclecare/features/tracking/presentation/home_cycle_dial.dart';
import 'package:cyclecare/widgets/cycle_calendar.dart';
import 'package:cyclecare/widgets/primary_button.dart';
import 'package:cyclecare/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shots/shot_harness.dart';

void main() {
  const configurations = <(double, double, double)>[
    (320, 740, 1),
    (320, 740, 2),
    (360, 800, 1),
    (360, 800, 2),
    (393, 852, 1.3),
    (412, 915, 2),
    (600, 960, 2),
    (844, 390, 2),
  ];
  for (final config in configurations) {
    for (final route in ['home', 'calendar', 'insights', 'log', 'pet']) {
      testWidgets('$route centers within safe width at $config', (
        tester,
      ) async {
        await tester.runAsync(loadShotFonts);
        await pumpShotApp(
          tester,
          route: '/$route',
          width: config.$1,
          height: config.$2,
          textScale: config.$3,
        );
        // An asymmetric cutout exposes accidental use of screen width instead
        // of layout constraints. Insets are physical pixels at the harness DPR2.
        tester.view.padding = const FakeViewPadding(
          left: 56,
          right: 16,
          top: 48,
          bottom: 48,
        );
        tester.view.viewPadding = const FakeViewPadding(
          left: 56,
          right: 16,
          top: 48,
          bottom: 48,
        );
        await settleShot(tester);
        final viewport = tester.getRect(
          find.byKey(const ValueKey('app-safe-viewport')),
        );
        expect(viewport.left, closeTo(28, 0.01));
        expect(viewport.right, closeTo(config.$1 - 8, 0.01));
        final dock = tester.getRect(
          find.byKey(const ValueKey('floating-navigation-surface')),
        );
        expect(dock.center.dx, closeTo(viewport.center.dx, 0.01));
        expect(dock.left, greaterThan(viewport.left));
        expect(dock.right, lessThan(viewport.right));
        final body = tester.getRect(
          find.byKey(const ValueKey('main-safe-content')),
        );
        expect(body.bottom, lessThanOrEqualTo(dock.top));
        for (var i = 0; i < 5; i++) {
          final item = find.byKey(ValueKey('main-nav-$i'));
          final bounds = tester.getRect(item);
          expect(bounds.width, greaterThanOrEqualTo(48));
          expect(bounds.height, greaterThanOrEqualTo(48));
          final label = find.descendant(of: item, matching: find.byType(Text));
          final text = tester.renderObject<RenderParagraph>(label);
          expect(text.didExceedMaxLines, isFalse);
          expect(
            bounds.inflate(0.1).contains(tester.getRect(label).center),
            isTrue,
          );
        }
        if (route == 'home') {
          expect(
            tester.getRect(find.byType(CycleDial)).center.dx,
            closeTo(viewport.center.dx, 0.1),
          );
        } else if (route == 'calendar') {
          final grids = find.byType(CycleCalendar).evaluate();
          expect(
            grids.any(
              (e) =>
                  ((e.renderObject as RenderBox).localToGlobal(Offset.zero).dx +
                          (e.renderObject as RenderBox).size.width / 2 -
                          viewport.center.dx)
                      .abs() <
                  0.1,
            ),
            isTrue,
          );
        } else if (route == 'insights') {
          final group = find.byKey(
            const PageStorageKey('insight-group-Your cycle, measured'),
          );
          await tester.ensureVisible(group);
          expect(
            tester.getRect(group).center.dx,
            closeTo(viewport.center.dx, 0.1),
          );
        } else if (route == 'log') {
          expect(
            tester.getRect(find.byType(PageHeader)).center.dx,
            closeTo(viewport.center.dx, 0.1),
          );
        } else if (route == 'pet') {
          expect(
            tester.getRect(find.byType(PetCompanion)).center.dx,
            closeTo(viewport.center.dx, 0.1),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }

  testWidgets('pushed pages share the same safe viewport', (tester) async {
    await tester.runAsync(loadShotFonts);
    await pumpShotApp(tester, route: '/settings', width: 393, height: 852);
    tester.view.padding = const FakeViewPadding(left: 64, top: 48, right: 20);
    tester.view.viewPadding = const FakeViewPadding(
      left: 64,
      top: 48,
      right: 20,
    );
    await settleShot(tester);
    final viewport = tester.getRect(
      find.byKey(const ValueKey('app-safe-viewport')),
    );
    expect(viewport.left, 32);
    expect(viewport.right, 383);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily save remains above the keyboard and dock', (tester) async {
    await tester.runAsync(loadShotFonts);
    await pumpShotApp(
      tester,
      route: '/log',
      width: 360,
      height: 800,
      textScale: 2,
    );
    final save = find.byType(PrimaryButton).last;
    final dock = tester.getRect(find.byType(CycleNavigationBar));
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(dock.top));
    tester.view.viewInsets = const FakeViewPadding(bottom: 520);
    await settleShot(tester);
    expect(find.byType(CycleNavigationBar), findsNothing);
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(800 - 260));
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary actions grow instead of truncating enlarged labels', (
    tester,
  ) async {
    await tester.runAsync(loadShotFonts);
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Color(0xff793f58)),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 600),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Save my complete check-in',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final label = find.text('Save my complete check-in');
    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isFalse,
    );
    expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThan(52));
    expect(tester.takeException(), isNull);
  });
}
