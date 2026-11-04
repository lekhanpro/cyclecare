import 'dart:convert';

import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/modes/mode_screens.dart';
import 'package:cyclecare/features/modes/tracking_mode.dart';
import 'package:cyclecare/features/tour/feature_tour.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(TrackingGoal goal) async {
  SharedPreferences.setMockInitialValues({
    'cyclecare.preferences.v1': jsonEncode(
      CyclePreferences(goal: goal, onboardingCompleted: true).toJson(),
    ),
    'cyclecare.periods.v1': jsonEncode([
      CycleEvent(id: 'kept', startDate: DateTime(2026, 10, 8)).toJson(),
    ]),
  });
  final container = ProviderContainer();
  await container.read(cycleTrackerControllerProvider.future);
  return container;
}

Widget _app(ProviderContainer container, Widget screen, {double scale = 1}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(const Color(0xff79516a)),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: screen,
      ),
    );

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final goal in TrackingGoal.values) {
    testWidgets(
      '${goal.name} has an honest compact large-text dashboard and introduction',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = await _container(goal);
        addTearDown(container.dispose);
        await tester.pumpWidget(
          _app(container, const ModeDashboardScreen(), scale: 2),
        );
        await tester.pumpAndSettle();
        expect(find.text(describeTrackingMode(goal).title), findsOneWidget);
        if (goal == TrackingGoal.pregnancy) {
          expect(
            find.text('No pregnancy dates have been set.'),
            findsOneWidget,
          );
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('cc.preg.active'), isNull);
        }
        await tester.scrollUntilVisible(
          find.text('All cycle tools'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('All cycle tools'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _app(container, const ModeIntroductionScreen(), scale: 2),
        );
        await tester.pumpAndSettle();
        for (final focus in describeTrackingMode(goal).focus)
          expect(find.text(focus), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mode cancel leaves goal and records; confirm changes only the goal',
    (tester) async {
      final container = await _container(TrackingGoal.trackPeriods);
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/source',
        routes: [
          GoRoute(
            path: '/source',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, child) => TextButton(
                  onPressed: () =>
                      showModeChange(context, ref, TrackingGoal.pregnancy),
                  child: const Text('Choose pregnancy'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/mode-introduction',
            builder: (context, state) =>
                const Scaffold(body: Text('Mode introduction')),
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
      await tester.tap(find.text('Choose pregnancy'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .preferences
            .goal,
        TrackingGoal.trackPeriods,
      );
      await tester.tap(find.text('Keep current mode'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .preferences
            .goal,
        TrackingGoal.trackPeriods,
      );
      await tester.tap(find.text('Choose pregnancy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm switch'));
      await tester.pumpAndSettle();
      final data = container.read(cycleTrackerControllerProvider).requireValue;
      expect(data.preferences.goal, TrackingGoal.pregnancy);
      expect(data.periods.single.id, 'kept');
      expect(data.periods.single.endDate, isNull);
      expect(find.text('Mode introduction'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('cc.preg.active'),
        isNull,
      );
    },
  );

  testWidgets(
    'tour visits actual routes with overview, next/back and durable pause',
    (tester) async {
      final container = await _container(TrackingGoal.trackPeriods);
      addTearDown(container.dispose);
      final controller = container.read(featureTourProvider.notifier);
      await container.read(featureTourProvider.future);
      await controller.start();
      final router = GoRouter(
        initialLocation: '/home?cycle=1',
        routes: [
          for (final path in ['/home', '/calendar', '/mode'])
            GoRoute(
              path: path,
              builder: (context, state) =>
                  Scaffold(body: Text('Actual ${state.uri.path}')),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                FeatureTourHost(router: router, child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/10 · Your cycle at a glance'), findsOneWidget);
      expect(find.text('Actual /home'), findsOneWidget);
      await tester.tap(find.text('Explore this page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Actual /calendar'), findsOneWidget);
      expect(find.text('2/10 · Your calendar'), findsOneWidget);
      await tester.tap(find.text('Explore this page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Actual /home'), findsOneWidget);
      await tester.tap(find.text('Explore this page'));
      await tester.pumpAndSettle();
    await tester.tap(find.text('Pause tour'));
      await tester.pumpAndSettle();
      expect(
        container.read(featureTourProvider).requireValue.status,
        FeatureTourStatus.paused,
      );
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
