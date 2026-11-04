import 'dart:convert';

import 'package:cyclecare/features/modes/tracking_mode.dart';
import 'package:cyclecare/features/tour/feature_tour.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('legacy preferences retain period mode, every mode round-trips', () {
    expect(CyclePreferences.fromJson({}).goal, TrackingGoal.trackPeriods);
    expect(
      CyclePreferences.fromJson({'goal': 'future-mode'}).goal,
      TrackingGoal.trackPeriods,
    );
    for (final goal in TrackingGoal.values) {
      expect(
        CyclePreferences.fromJson(CyclePreferences(goal: goal).toJson()).goal,
        goal,
      );
      expect(describeTrackingMode(goal).focus, hasLength(3));
      expect(modeBoundary(goal), isNotEmpty);
    }
    expect(
      TrackingGoal.values.map((g) => describeTrackingMode(g).title).toSet(),
      hasLength(5),
    );
  });

  test('mode preferences preserve records and unknown period ends', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(cycleTrackerControllerProvider.future);
    final control = container.read(cycleTrackerControllerProvider.notifier);
    await control.logPeriodStart(DateTime(2026, 10, 8));
    await control.saveLog(
      DailyLog(
        date: DateTime(2026, 10, 9),
        mood: 'Calm',
        ovulationTest: 'Negative',
      ),
    );
    final before = container.read(cycleTrackerControllerProvider).requireValue;
    for (final goal in TrackingGoal.values) {
      await control.updatePreferences(before.preferences.copyWith(goal: goal));
      final after = container.read(cycleTrackerControllerProvider).requireValue;
      expect(after.preferences.goal, goal);
      expect(after.periods.single.toJson(), before.periods.single.toJson());
      expect(after.periods.single.endDate, isNull);
      expect(after.logs.single.toJson(), before.logs.single.toJson());
    }
    final storage = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(storage.getString('cyclecare.preferences.v1')!)
            as Map<String, dynamic>;
    expect(stored['goal'], TrackingGoal.symptomWellness.name);
  });

  test(
    'tour next, back, pause and restart resume durable progress without health records',
    () async {
      var container = ProviderContainer();
      await container.read(featureTourProvider.future);
      final controller = container.read(featureTourProvider.notifier);
      await controller.start();
      await Future.wait([controller.next(), controller.next()]);
      expect(container.read(featureTourProvider).requireValue.step, 2);
      await controller.back();
      await controller.pause();
      expect(container.read(featureTourProvider).requireValue.step, 1);
      container.dispose();
      container = ProviderContainer();
      addTearDown(container.dispose);
      final restored = await container.read(featureTourProvider.future);
      expect(restored.status, FeatureTourStatus.paused);
      expect(restored.step, 1);
      await container.read(featureTourProvider.notifier).start();
      expect(
        container.read(featureTourProvider).requireValue.current.route,
        '/calendar',
      );
      final storage = await SharedPreferences.getInstance();
      expect(storage.getKeys(), {FeatureTourController.storageKey});
    },
  );

  test(
    'completed tour stays complete on reload; explicit replay starts at zero',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(featureTourProvider.future);
      final controller = container.read(featureTourProvider.notifier);
      await controller.start();
      for (var i = 0; i < featureTourSteps.length; i++) await controller.next();
      expect(
        container.read(featureTourProvider).requireValue.status,
        FeatureTourStatus.completed,
      );
      expect(
        FeatureTourState.fromJson(
          container.read(featureTourProvider).requireValue.toJson(),
        ).status,
        FeatureTourStatus.completed,
      );
      await controller.start(replay: true);
      expect(container.read(featureTourProvider).requireValue.step, 0);
      expect(featureTourSteps.map((s) => s.route).toSet(), hasLength(10));
    },
  );

  test('old, malformed and future tour data do not invent completed steps', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'version': 2, 'status': 'completed', 'step': 9},
      {'version': 1, 'status': 'completed', 'step': -1},
      {'version': 1, 'status': 'completed', 'step': 10},
      {'version': 1, 'status': 'unknown', 'step': 0},
    ]) {
      expect(
        FeatureTourState.fromJson(json).status,
        FeatureTourStatus.notStarted,
      );
    }
    expect(
      FeatureTourState.fromJson({
        'version': 1,
        'status': 'active',
        'step': 4,
      }).status,
      FeatureTourStatus.paused,
    );
  });
}
