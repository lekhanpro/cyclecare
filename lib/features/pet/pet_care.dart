import '../../core/utils/date_helpers.dart';
import '../tracking/domain/cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pet care
//
// What makes the pet useful rather than decorative: its needs are your real
// logging for today, so looking after it and looking after yourself are the
// same action. Borrowed, in concept only:
//
//  • Finch: the pet grows when you finish small self-care goals you can
//    actually do today, and it never punishes a missed day.
//  • Tamagotchi: needs are visible meters that fill and empty, so there is
//    always one obvious next thing to do.
//  • Pokémon Sleep: rewards come from real behaviour (logging sleep, water),
//    not from tapping the pet.
//
// Everything here is pure, so it is tested without a widget in sight.
// ─────────────────────────────────────────────────────────────────────────────

const waterGoalMl = 2000;
const sleepGoalHours = 8.0;

enum PetNeedKind { checkIn, hydration, rest, streak }

class PetNeed {
  const PetNeed({
    required this.kind,
    required this.label,
    required this.level,
    required this.nextStep,
  });

  final PetNeedKind kind;
  final String label;

  /// 0 to 1.
  final double level;

  /// What to do to fill it, or a short note when it is already full.
  final String nextStep;

  bool get isMet => level >= 1;
}

/// The four needs, from today's log and the logging streak.
List<PetNeed> petNeeds({
  required DailyLog? today,
  required int streak,
  required String petName,
}) {
  final logged = today != null;
  final water = today?.waterMl ?? 0;
  final sleep = today?.sleepHours;

  return [
    PetNeed(
      kind: PetNeedKind.checkIn,
      label: 'Check-in',
      level: logged ? 1 : 0,
      nextStep: logged
          ? 'You checked in today'
          : 'Log how you feel to cheer $petName up',
    ),
    PetNeed(
      kind: PetNeedKind.hydration,
      label: 'Hydration',
      level: (water / waterGoalMl).clamp(0.0, 1.0),
      nextStep: water >= waterGoalMl
          ? 'Goal reached'
          : water == 0
          ? 'Log the water you have had today'
          : '${((waterGoalMl - water) / 250).ceil()} more glasses to go',
    ),
    PetNeed(
      kind: PetNeedKind.rest,
      label: 'Rest',
      level: sleep == null ? 0 : (sleep / sleepGoalHours).clamp(0.0, 1.0),
      nextStep: sleep == null
          ? 'Log last night’s sleep'
          : '${sleep.toStringAsFixed(sleep % 1 == 0 ? 0 : 1)} hours logged',
    ),
    PetNeed(
      kind: PetNeedKind.streak,
      label: 'Streak',
      // A week fills the meter; the pet never sulks about a reset.
      level: (streak / 7).clamp(0.0, 1.0),
      nextStep: streak == 0
          ? 'Log today to start a streak'
          : '$streak ${streak == 1 ? 'day' : 'days'} in a row',
    ),
  ];
}

class PetGoal {
  const PetGoal({
    required this.id,
    required this.title,
    required this.done,
    required this.xp,
  });

  /// Stable per day, so a goal is rewarded once per day at most.
  final String id;
  final String title;
  final bool done;
  final int xp;
}

/// Three small goals, met automatically by logging.
///
/// The third goal changes with the cycle phase so it stays relevant: a gentle
/// symptom check on period days, mood the rest of the time.
List<PetGoal> dailyGoals({
  required DailyLog? today,
  required CyclePhase? phase,
}) {
  final menstrual = phase == CyclePhase.menstrual;
  return [
    PetGoal(id: 'log', title: 'Check in today', done: today != null, xp: 20),
    PetGoal(
      id: 'water',
      title: 'Log your water',
      done: (today?.waterMl ?? 0) > 0,
      xp: 15,
    ),
    menstrual
        ? PetGoal(
            id: 'flow',
            title: 'Note your flow or symptoms',
            done:
                today != null &&
                ((today.flow != null && today.flow != FlowIntensity.none) ||
                    today.symptoms.isNotEmpty),
            xp: 15,
          )
        : PetGoal(
            id: 'mood',
            title: 'Log your mood',
            done: today?.mood?.isNotEmpty ?? false,
            xp: 15,
          ),
  ];
}

/// Key for remembering a goal was rewarded today.
String goalClaimKey(String goalId, DateTime day) {
  final d = dateOnly(day);
  return '${d.year}-${d.month}-${d.day}:$goalId';
}

/// Optional recording tasks, with no intake or sleep-duration target. Explicit
/// zero remains an observation; missing information never completes a task.
List<PetGoal> recordedCareGoals(DailyLog? today) => [
  dailyGoals(today: today, phase: null).first,
  PetGoal(
    id: 'water',
    title: 'Record your water',
    done: today?.waterMl != null,
    xp: 15,
  ),
  PetGoal(
    id: 'reflection',
    title: 'Record mood or sleep',
    done:
        (today?.mood?.trim().isNotEmpty ?? false) || today?.sleepHours != null,
    xp: 15,
  ),
];

enum PetStage { baby, young, grown }

PetStage stageForLevel(int level) => level >= 6
    ? PetStage.grown
    : level >= 3
    ? PetStage.young
    : PetStage.baby;

extension PetStageLabel on PetStage {
  String get label => switch (this) {
    PetStage.baby => 'Baby',
    PetStage.young => 'Young',
    PetStage.grown => 'Grown',
  };

  /// Level the next stage starts at, or null when fully grown.
  int? get nextAt => switch (this) {
    PetStage.baby => 3,
    PetStage.young => 6,
    PetStage.grown => null,
  };
}

/// A phase-aware line for the pet, gentle on period days and never shaming.
String petMoodLine(
  String name,
  CyclePhase? phase, {
  required bool loggedToday,
}) {
  final base = switch (phase) {
    CyclePhase.menstrual => '$name is keeping things cosy today. Rest counts.',
    CyclePhase.follicular => '$name is feeling bright and curious.',
    CyclePhase.ovulation => '$name is full of energy today.',
    CyclePhase.luteal => '$name is slowing down a little. Go easy.',
    null => '$name is happy to see you.',
  };
  return loggedToday ? base : '$base A quick check-in would make their day.';
}

/// A small care tip for the phase, for you rather than the pet.
String petCareTip(CyclePhase? phase) => switch (phase) {
  CyclePhase.menstrual =>
    'Warmth and an easier schedule tend to help more than pushing through.',
  CyclePhase.follicular =>
    'Energy often climbs now, which suits plans and new things.',
  CyclePhase.ovulation => 'Many people feel most social around now.',
  CyclePhase.luteal =>
    'Regular meals and an earlier night can soften the last few days.',
  null => 'Logging a little every day makes your patterns clearer.',
};
