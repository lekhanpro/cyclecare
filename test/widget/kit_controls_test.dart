// Behaviour of the shared controls and the bottom navigation.
//
// A screenshot proves layout only; these hold what the controls do: a toggle
// flips and reports its state, a busy button does not dispatch, the unsaved
// dialog resolves to each of its three outcomes, a ListRow survives 200% text,
// and the nav switches branches without losing a branch's scroll position.

import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_icons.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/app/main_shell.dart';
import 'package:cyclecare/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _host(Widget child, {double textScale = 1}) => MaterialApp(
      theme: AppTheme.light(AppPalette.pinkRose.seed),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  testWidgets('AppToggle flips on tap and reports its state', (tester) async {
    final semantics = tester.ensureSemantics();
    var value = false;
    final reported = <bool>[];
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => Center(
        child: AppToggle(
          value: value,
          semanticLabel: 'Reminders',
          onChanged: (next) {
            reported.add(next);
            setState(() => value = next);
          },
        ),
      ),
    )));

    await tester.tap(find.byType(AppToggle));
    await tester.pumpAndSettle();

    expect(reported, [true]);
    expect(value, isTrue);
    expect(
      tester.getSemantics(find.byType(AppToggle)),
      containsSemantics(label: 'Reminders', isToggled: true),
    );
    semantics.dispose();
  });

  testWidgets('a busy or disabled PrimaryButton does not dispatch',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(Column(
      children: [
        PrimaryButton(label: 'Saving', loading: true, onPressed: () => taps++),
        const PrimaryButton(label: 'Unavailable', onPressed: null),
        const FilledButton(onPressed: null, child: Text('Filled off')),
      ],
    )));

    await tester.tap(find.byType(PrimaryButton).first, warnIfMissed: false);
    await tester.tap(find.text('Unavailable'), warnIfMissed: false);
    await tester.tap(find.text('Filled off'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));

    expect(taps, 0);
  });

  testWidgets('the unsaved-changes dialog returns each of its three outcomes',
      (tester) async {
    UnsavedChangesChoice? result;
    await tester.pumpWidget(_host(Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async {
            result = await showUnsavedChangesDialog(context);
          },
          child: const Text('Leave'),
        ),
      ),
    )));

    final outcomes = {
      'Save and leave': UnsavedChangesChoice.save,
      'Keep editing': UnsavedChangesChoice.keepEditing,
      'Discard my changes': UnsavedChangesChoice.discard,
    };
    for (final entry in outcomes.entries) {
      result = null;
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(result, entry.value, reason: entry.key);
    }
  });

  testWidgets('a ListRow at 200% text on a narrow phone does not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      ListView(
        children: [
          ListRow(
            title: 'Period and fertile window predictions',
            subtitle: 'Shown on Today and in the calendar as estimates',
            icon: AppIcons.calendar,
            value: 'Weekly',
            showChevron: true,
            onTap: () {},
          ),
          SwitchRow(
            title: 'Remind me before my period is due',
            description: 'A gentle note two days ahead',
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
      textScale: 2,
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Weekly'), findsOneWidget);
  });

  testWidgets('the nav switches branches and keeps each branch scrolled',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/b0',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            for (var i = 0; i < 5; i++)
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/b$i',
                  builder: (context, state) => ListView.builder(
                    key: PageStorageKey<String>('b$i'),
                    itemCount: 100,
                    itemBuilder: (context, j) => SizedBox(
                      height: 60,
                      child: Text('b$i item $j'),
                    ),
                  ),
                ),
              ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light(AppPalette.pinkRose.seed),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    for (final label in ['Today', 'Calendar', 'Log', 'Insights', 'Companion']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final scrolled =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(scrolled, greaterThan(0));

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('b1 item 0'), findsOneWidget);
    expect(find.text('b0 item 0'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      scrolled,
    );
  });
}
