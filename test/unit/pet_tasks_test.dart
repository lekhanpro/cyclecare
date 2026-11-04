import 'dart:convert';

import 'package:cyclecare/features/pet/pet_care.dart';
import 'package:cyclecare/features/pet/pet_models.dart';
import 'package:cyclecare/features/pet/pet_provider.dart';
import 'package:cyclecare/features/pet/pet_tasks.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store(super.data) : super.withData();
  bool failPetWrite = false;
  int petWrites = 0;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.cc.pet.v1') {
      if (failPetWrite) {
        failPetWrite = false;
        return false;
      }
      petWrites++;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  final day = DateTime(2026, 11, 3);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> ready({
    DailyLog? log,
    PetState? pet,
    _Store? store,
  }) async {
    if (store != null) SharedPreferencesStorePlatform.instance = store;
    final prefs = await SharedPreferences.getInstance();
    if (log != null)
      await prefs.setString(
        'cyclecare.daily_logs.v1',
        jsonEncode([log.toJson()]),
      );
    if (pet != null)
      await prefs.setString('cc.pet.v1', jsonEncode(pet.toJson()));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(petProvider.future);
    await container.read(cycleTrackerControllerProvider.future);
    return container;
  }

  test(
    'old companion data retains every field and new claim history defaults empty',
    () {
      final old = const PetState(
        type: PetType.fox,
        name: 'Pip',
        xp: 32,
        level: 3,
        achievements: ['first_log'],
      ).toJson()..remove('careClaims');
      final restored = PetState.fromJson(old);
      expect(restored.careClaims, isEmpty);
      expect(restored.name, 'Pip');
      expect(restored.achievements, ['first_log']);
      expect(
        PetState.fromJson(
          restored.copyWith(careClaims: ['2026-11-3:water']).toJson(),
        ).careClaims,
        ['2026-11-3:water'],
      );
    },
  );

  test(
    'missing observations never complete tasks; explicit zero stays recorded',
    () {
      expect(recordedCareGoals(null).any((g) => g.done), isFalse);
      final zero = recordedCareGoals(
        DailyLog(date: day, waterMl: 0, sleepHours: 0),
      );
      expect(zero.every((g) => g.done), isTrue);
      expect(zero.map((g) => g.title).join(), isNot(contains('2000')));
    },
  );

  test('claim cannot invent a log or reward an unrecorded task', () async {
    final container = await ready();
    final notifier = container.read(petProvider.notifier);
    expect(
      await notifier.claimCareGoal('water', now: day),
      PetClaimResult.notRecorded,
    );
    expect(container.read(petProvider).requireValue.xp, 0);
    expect(
      container.read(cycleTrackerControllerProvider).requireValue.logs,
      isEmpty,
    );
    await expectLater(
      notifier.claimCareGoal('invented', now: day),
      throwsArgumentError,
    );
    await notifier.setPetName('Still works');
    expect(container.read(petProvider).requireValue.name, 'Still works');
  });

  test(
    'rapid claims award once and store claim plus XP in one durable write',
    () async {
      final store = _Store({});
      final container = await ready(
        log: DailyLog(date: day, waterMl: 0),
        store: store,
      );
      final notifier = container.read(petProvider.notifier);
      final results = await Future.wait(
        List.generate(20, (_) => notifier.claimCareGoal('water', now: day)),
      );
      expect(results.where((r) => r == PetClaimResult.awarded), hasLength(1));
      expect(store.petWrites, 1);
      expect(container.read(petProvider).requireValue.xp, 15);
      expect(container.read(petProvider).requireValue.careClaims, [
        goalClaimKey('water', day),
      ]);
      container.invalidate(petProvider);
      expect((await container.read(petProvider.future)).careClaims, [
        goalClaimKey('water', day),
      ]);
      expect(
        await container
            .read(petProvider.notifier)
            .claimCareGoal('water', now: day),
        PetClaimResult.alreadyClaimed,
      );
    },
  );

  test(
    'claim, rename and treat preserve each other and existing growth records',
    () async {
      final container = await ready(
        log: DailyLog(date: day, mood: 'Calm'),
        pet: const PetState(
          type: PetType.fox,
          name: 'Pip',
          level: 7,
          xp: 690,
          achievements: ['first_log'],
        ),
      );
      final notifier = container.read(petProvider.notifier);
      await Future.wait([
        notifier.claimCareGoal('reflection', now: day),
        notifier.setPetName('Pipkin'),
        notifier.feed(),
      ]);
      final pet = container.read(petProvider).requireValue;
      expect(pet.type, PetType.fox);
      expect(pet.name, 'Pipkin');
      expect(pet.level, 8);
      expect(pet.xp, 15);
      expect(pet.lastFed, isNotNull);
      expect(pet.achievements, contains('first_log'));
      expect(pet.careClaims, [goalClaimKey('reflection', day)]);
    },
  );

  test(
    'failed durable claim stays unclaimed on reload and can be retried once',
    () async {
      final store = _Store({});
      final container = await ready(
        log: DailyLog(date: day, waterMl: 250),
        store: store,
      );
      store.failPetWrite = true;
      await expectLater(
        container.read(petProvider.notifier).claimCareGoal('water', now: day),
        throwsStateError,
      );
      expect(container.read(petProvider).requireValue.careClaims, isEmpty);
      expect(container.read(petProvider).requireValue.xp, 0);
      container.invalidate(petProvider);
      expect((await container.read(petProvider.future)).xp, 0);
      expect(
        await container
            .read(petProvider.notifier)
            .claimCareGoal('water', now: day),
        PetClaimResult.awarded,
      );
      expect(store.petWrites, 1);
    },
  );

  test(
    'editing or reloading a claimed day never awards it again; a new day needs its own record',
    () async {
      final container = await ready(
        log: DailyLog(date: day, mood: 'Calm'),
      );
      final notifier = container.read(petProvider.notifier);
      await notifier.claimCareGoal('reflection', now: day);
      final tracker = container.read(cycleTrackerControllerProvider.notifier);
      await tracker.saveLog(DailyLog(date: day, mood: 'Happy'));
      expect(
        await notifier.claimCareGoal('reflection', now: day),
        PetClaimResult.alreadyClaimed,
      );
      final next = day.add(const Duration(days: 1));
      expect(
        await notifier.claimCareGoal('reflection', now: next),
        PetClaimResult.notRecorded,
      );
      await tracker.saveLog(DailyLog(date: next, sleepHours: 6));
      expect(
        await notifier.claimCareGoal('reflection', now: next),
        PetClaimResult.awarded,
      );
      expect(container.read(petProvider).requireValue.xp, 30);
    },
  );

  test(
    'confirmed water additions preserve all existing daily fields and add concurrently',
    () async {
      final original = DailyLog(
        date: day,
        mood: 'Calm',
        waterMl: 500,
        symptoms: ['Cramps'],
        painLevel: 0,
        sleepHours: 6.5,
        temperatureCelsius: 36.6,
        temperatureContext: ['Illness or fever'],
        ovulationTest: 'Negative',
        notes: 'Keep this note',
      );
      final container = await ready(log: original);
      final actions = container.read(petTaskActionsProvider);
      await Future.wait([
        actions.recordWater(125, now: day),
        actions.recordWater(250, now: day),
      ]);
      final log = container
          .read(cycleTrackerControllerProvider)
          .requireValue
          .logFor(day)!;
      expect(log.toJson(), original.copyWith(waterMl: 875).toJson());
      expect(container.read(petProvider).requireValue.xp, 0);
      await expectLater(actions.recordWater(10000, now: day), throwsStateError);
      expect(
        container
            .read(cycleTrackerControllerProvider)
            .requireValue
            .logFor(day)!
            .waterMl,
        875,
      );
      await expectLater(actions.recordWater(-1, now: day), throwsArgumentError);
    },
  );
}
