import 'package:cyclecare/features/health/application/health_controller.dart';
import 'package:cyclecare/features/health/health_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HealthScreen()),
    );

/// PrimaryButton always builds a (faded out) CircularProgressIndicator, which
/// never stops ticking, so pumpAndSettle can't be used once a sheet is open.
/// First pump builds the route, second runs its entrance to completion.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// A tall surface so every card and the whole log form fit without scrolling.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('conditions tab renders every card, expands, and marks',
      (tester) async {
    useTallSurface(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    // All five conditions laid out at once, which is where a PhaseCard given an
    // unbounded height would blow up.
    for (final name in [
      'PCOS',
      'Endometriosis',
      'PMDD',
      'Perimenopause',
      'Amenorrhea',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Keep a pain diary'), findsOneWidget);

    // Expanding reveals the signs list and the escalation note.
    await tester.tap(find.text('PCOS'));
    await tester.pumpAndSettle();
    expect(find.text('COMMON SIGNS'), findsOneWidget);
    expect(find.text('WHEN TO SEE SOMEONE'), findsOneWidget);

    await tester.tap(find.text('This applies to me').first);
    await tester.pumpAndSettle();
    expect(container.read(myConditionsProvider), contains('pcos'));

    // Marked conditions sort to the top.
    expect(find.text('Yours first'), findsOneWidget);
  });

  testWidgets('pain diary shows the empty state and logs an entry',
      (tester) async {
    useTallSurface(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pain diary'));
    await tester.pumpAndSettle();
    expect(find.text('No entries yet'), findsOneWidget);

    await tester.tap(find.text('Log pain'));
    await _settle(tester);

    // Severity 7, one location, then save.
    await tester.tap(find.text('7'));
    await _settle(tester);
    await tester.tap(find.text('Lower back'));
    await _settle(tester);
    await tester.tap(find.text('Save entry'));
    await _settle(tester);
    await _settle(tester);

    final entries = container.read(painEntriesProvider);
    expect(entries, hasLength(1));
    expect(entries.first.severity, 7);
    expect(entries.first.locations, ['Lower back']);

    // And it renders in the diary with its summary stats.
    expect(find.textContaining('7/10'), findsWidgets);
    expect(find.text('Average level'), findsOneWidget);
    expect(find.text('Lower back'), findsWidgets);
  });

  testWidgets('screening completes without asserting a diagnosis',
      (tester) async {
    useTallSurface(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Screening'));
    await tester.pumpAndSettle();

    expect(
      find.text('These questions cannot diagnose anything'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cycle and hormone patterns'));
    await tester.pumpAndSettle();

    // Answering everything yes surfaces the "raise it" banner, never a verdict.
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('Yes').at(i));
      await tester.pumpAndSettle();
    }

    expect(find.text('Worth raising with a clinician'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsWidgets);
  });
}
