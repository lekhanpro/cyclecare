import 'package:cyclecare/features/pet/pet_care.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 10, 30);

  group('petNeeds', () {
    test('nothing logged: every need empty, with a next step', () {
      final needs = petNeeds(today: null, streak: 0, petName: 'Luna');
      expect(needs.map((n) => n.level), [0, 0, 0, 0]);
      expect(needs.every((n) => n.nextStep.isNotEmpty), isTrue);
      expect(needs.first.nextStep, contains('Luna'));
    });

    test('a full day fills check-in, hydration and rest', () {
      final needs = petNeeds(
        today: DailyLog(date: day, mood: 'Calm', waterMl: 2000, sleepHours: 8),
        streak: 7,
        petName: 'Luna',
      );
      expect(needs.every((n) => n.isMet), isTrue);
    });

    test('partial water says how many glasses are left', () {
      final water = petNeeds(
        today: DailyLog(date: day, waterMl: 1000),
        streak: 0,
        petName: 'Luna',
      ).firstWhere((n) => n.kind == PetNeedKind.hydration);
      expect(water.level, 0.5);
      expect(water.nextStep, '4 more glasses to go');
    });

    test('streak fills over a week and is capped', () {
      double level(int s) => petNeeds(today: null, streak: s, petName: 'L')
          .firstWhere((n) => n.kind == PetNeedKind.streak)
          .level;
      expect(level(0), 0);
      expect(level(3), closeTo(3 / 7, 1e-9));
      expect(level(30), 1);
    });
  });

  group('dailyGoals', () {
    test('three goals, done automatically from the log', () {
      final none = dailyGoals(today: null, phase: CyclePhase.luteal);
      expect(none, hasLength(3));
      expect(none.any((g) => g.done), isFalse);

      final all = dailyGoals(
        today: DailyLog(date: day, mood: 'Calm', waterMl: 250),
        phase: CyclePhase.luteal,
      );
      expect(all.every((g) => g.done), isTrue);
    });

    test('the third goal follows the phase', () {
      expect(dailyGoals(today: null, phase: CyclePhase.menstrual).last.id,
          'flow');
      expect(dailyGoals(today: null, phase: CyclePhase.follicular).last.id,
          'mood');

      final period = dailyGoals(
        today: DailyLog(date: day, flow: FlowIntensity.light),
        phase: CyclePhase.menstrual,
      );
      expect(period.last.done, isTrue);
    });

    test('claim keys are per day', () {
      expect(goalClaimKey('water', day), goalClaimKey('water', day));
      expect(goalClaimKey('water', day),
          isNot(goalClaimKey('water', day.add(const Duration(days: 1)))));
    });
  });

  test('growth stages by level', () {
    expect(stageForLevel(1), PetStage.baby);
    expect(stageForLevel(2), PetStage.baby);
    expect(stageForLevel(3), PetStage.young);
    expect(stageForLevel(5), PetStage.young);
    expect(stageForLevel(6), PetStage.grown);
    expect(PetStage.baby.nextAt, 3);
    expect(PetStage.grown.nextAt, isNull);
  });

  test('mood line is gentle and nudges only when nothing is logged', () {
    final logged =
        petMoodLine('Luna', CyclePhase.menstrual, loggedToday: true);
    final notLogged =
        petMoodLine('Luna', CyclePhase.menstrual, loggedToday: false);
    expect(logged, contains('Luna'));
    expect(notLogged, contains('check-in'));
    expect(logged, isNot(contains('check-in')));
  });
}
