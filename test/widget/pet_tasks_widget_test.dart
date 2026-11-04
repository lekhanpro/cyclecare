import 'dart:convert';

import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/pet/pet_companion.dart';
import 'package:cyclecare/features/pet/pet_provider.dart';
import 'package:cyclecare/features/pet/pet_tasks.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> prepare() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(petProvider.future);
    await container.read(cycleTrackerControllerProvider.future);
    return container;
  }

  Widget tasks(ProviderContainer container, List<PetAction> rewards) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(const Color(0xff79516a)),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, child) => PetCareTasks(
                  pet: ref.watch(petProvider).requireValue,
                  onReward: rewards.add,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets(
    'water requires explicit amount confirmation and never claims XP automatically',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await prepare();
      final rewards = <PetAction>[];
      await tester.pumpWidget(tasks(container, rewards));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Add water'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add water'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pet-water-amount')),
        '250',
      );
      expect(
        container.read(cycleTrackerControllerProvider).requireValue.logs,
        isEmpty,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        container.read(cycleTrackerControllerProvider).requireValue.logs,
        isEmpty,
      );
      await tester.tap(find.text('Add water'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pet-water-amount')),
        '250',
      );
      await tester.tap(find.text('Confirm amount'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .logs
            .single
            .waterMl,
        250,
      );
      expect(container.read(petProvider).requireValue.xp, 0);
      expect(rewards, [PetAction.water]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit claim updates reward state without changing health records',
    (tester) async {
      final day = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'cyclecare.daily_logs.v1': jsonEncode([
          DailyLog(
            date: DateTime(day.year, day.month, day.day),
            mood: 'Calm',
          ).toJson(),
        ]),
      });
      final container = await prepare();
      final rewards = <PetAction>[];
      final before = container
          .read(cycleTrackerControllerProvider)
          .requireValue
          .logs
          .single
          .toJson();
      await tester.pumpWidget(tasks(container, rewards));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claim 20 XP'));
      await tester.pumpAndSettle();
      expect(container.read(petProvider).requireValue.xp, 20);
      expect(find.text('Reward claimed today'), findsOneWidget);
      expect(find.text('Claim 20 XP'), findsNothing);
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .logs
            .single
            .toJson(),
        before,
      );
      expect(rewards, [PetAction.celebrate]);
    },
  );

  testWidgets(
    'Record in log selects today instead of an earlier calendar date',
    (tester) async {
      final container = await prepare();
      final tracker = container.read(cycleTrackerControllerProvider.notifier);
      await tracker.selectDate(DateTime(2020, 1, 1));
      final router = GoRouter(
        initialLocation: '/tasks',
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                child: Consumer(
                  builder: (context, ref, child) => PetCareTasks(
                    pet: ref.watch(petProvider).requireValue,
                    onReward: (_) {},
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/log',
            builder: (context, state) =>
                const Scaffold(body: Text('Daily log')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record in log').first);
      await tester.pumpAndSettle();
      final today = DateTime.now();
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .selectedDate,
        DateTime(today.year, today.month, today.day),
      );
      expect(
        container.read(cycleTrackerControllerProvider).requireValue.logs,
        isEmpty,
      );
      expect(find.text('Daily log'), findsOneWidget);
    },
  );
}
