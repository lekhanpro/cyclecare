import 'package:cyclecare/features/tracking/presentation/home_hormone_chart.dart';
import 'package:cyclecare/features/tracking/presentation/home_screen.dart';
import 'package:cyclecare/features/tracking/presentation/insights_extra_cards.dart';
import 'package:cyclecare/features/tracking/presentation/insights_phase_cards.dart';
import 'package:cyclecare/features/tracking/presentation/insights_screen.dart';
import 'package:cyclecare/features/tracking/presentation/record_summary_card.dart';
import 'package:cyclecare/widgets/phase_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shots/shot_harness.dart';

void main() {
  testWidgets('Home leads with cycle and actions; explorer remains available', (
    tester,
  ) async {
    await pumpShotScreen(tester, const HomeScreen(), height: 5200);
    expect(find.text('Log today'), findsOneWidget);
    expect(find.byType(PhaseBar), findsOneWidget);
    expect(find.byType(HormoneChart), findsNothing);
    expect(find.text('Illustrative · not your hormone levels'), findsOneWidget);
    await tester.tap(find.text('Explore hormone patterns'));
    await settleShot(tester);
    expect(find.byType(HormoneChart), findsOneWidget);
    expect(find.byKey(const ValueKey('hormone-range')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-window-PMS window')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Insights groups retain every analysis behind a named control', (
    tester,
  ) async {
    await pumpShotScreen(tester, const InsightsScreen(), height: 5200);
    expect(find.byType(RegularityCard), findsNothing);
    expect(find.byType(RecordSummaryCard), findsNothing);
    for (final group in <(String, Type)>[
      ('Your cycle, measured', RegularityCard),
      ('Patterns', RecordSummaryCard),
      ('Through your cycle', ByPhaseCard),
    ]) {
      final header = find.descendant(
        of: find.byKey(PageStorageKey('insight-group-${group.$1}')),
        matching: find.text(group.$1),
      ).first;
      await tester.ensureVisible(header);
      await tester.tap(header);
      await settleShot(tester);
      expect(find.byType(group.$2), findsOneWidget);
      await tester.ensureVisible(header);
      await tester.tap(header);
      await settleShot(tester);
    }
    for (final label in ['Cycle trends', 'Body signals', 'Cycle history']) {
      final header = find.descendant(
        of: find.byKey(PageStorageKey('insight-group-$label')),
        matching: find.text(label),
      ).first;
      await tester.ensureVisible(header);
      await tester.tap(header);
      await settleShot(tester);
      expect(tester.takeException(), isNull, reason: label);
      await tester.ensureVisible(header);
      await tester.tap(header);
      await settleShot(tester);
    }
  });

  testWidgets('Insights overview and opened explanation wrap at 200% text', (
    tester,
  ) async {
    await pumpShotScreen(
      tester,
      const InsightsScreen(),
      width: 320,
      height: 5200,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('About your numbers'));
    await tester.tap(find.text('About your numbers'));
    await settleShot(tester);
    expect(tester.takeException(), isNull);
  });
}
