import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/data/cycle_repository.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final knownEnd in [true, false]) {
    testWidgets(
      'calendar exclusion preserves ${knownEnd ? 'recorded' : 'unknown'} end date through reversal',
      (tester) async {
        tester.view.physicalSize = const Size(430, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final repository = CycleRepository(
          await SharedPreferences.getInstance(),
        );
        final now = DateUtils.dateOnly(DateTime.now());
        await repository.savePeriods([
          CycleEvent(
            id: 'retained',
            startDate: now,
            endDate: knownEnd ? now.add(const Duration(days: 2)) : null,
            flow: FlowIntensity.heavy,
            symptoms: const ['Cramps'],
            notes: 'Original note',
          ),
        ]);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cycleRepositoryProvider.overrideWith((ref) async => repository),
            ],
            child: MaterialApp(
              theme: AppTheme.light(AppPalette.pinkRose.seed),
              home: const CalendarScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit dates'));
        await tester.pumpAndSettle();
        if (!knownEnd) {
          expect(
            find.text('Duration unknown — end not recorded'),
            findsOneWidget,
          );
          expect(find.text('Ended'), findsNothing);
        }
        await tester.tap(find.text('Exclude this cycle from estimates'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Travel');
        await tester.tap(find.text('Save period'));
        await tester.pumpAndSettle();
        var saved = repository.loadPeriods().single;
        expect(saved.excludeFromPredictions, isTrue);
        expect(saved.predictionExclusionReason, 'Travel');
        expect(
          saved.endDate,
          knownEnd ? now.add(const Duration(days: 2)) : isNull,
        );
        expect(saved.flow, FlowIntensity.heavy);
        expect(saved.notes, 'Original note');
        expect(saved.symptoms, ['Cramps']);
        expect(
          find.textContaining('Cycle excluded from estimates'),
          findsOneWidget,
        );
        await tester.tap(find.text('Edit dates'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exclude this cycle from estimates'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save period'));
        await tester.pumpAndSettle();
        saved = repository.loadPeriods().single;
        expect(saved.excludeFromPredictions, isFalse);
        expect(saved.predictionExclusionReason, isNull);
        expect(saved.id, 'retained');
        expect(
          saved.endDate,
          knownEnd ? now.add(const Duration(days: 2)) : isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('new periods keep an unknown end until explicitly recorded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final repository = CycleRepository(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cycleRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalette.pinkRose.seed),
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark period'));
    await tester.pumpAndSettle();
    expect(find.text('Duration unknown — end not recorded'), findsOneWidget);
    expect(find.text('Ended'), findsNothing);
    await tester.tap(find.text('Save period'));
    await tester.pumpAndSettle();
    expect(repository.loadPeriods().single.endDate, isNull);

    await tester.tap(find.text('Edit dates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End date recorded'));
    await tester.pumpAndSettle();
    expect(find.text('Ended'), findsOneWidget);
    await tester.tap(find.text('Save period'));
    await tester.pumpAndSettle();
    final recorded = repository.loadPeriods().single;
    expect(recorded.endDate, recorded.startDate);

    await tester.tap(find.text('Edit dates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End date recorded'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save period'));
    await tester.pumpAndSettle();
    expect(repository.loadPeriods().single.endDate, isNull);
    expect(tester.takeException(), isNull);
  });
}
