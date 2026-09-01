import 'cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase guidance
//
// Short, practical notes surfaced on the home screen for the user's current
// phase. Rotated by day so the dashboard isn't identical every morning.
//
// Editorial rules, applied to every line below:
//  • Suggest, never prescribe. No dosages, no diagnoses, no "you should".
//  • Describe tendencies, not certainties — bodies vary, and a tracker that
//    tells someone how they feel is worse than one that says nothing.
//  • No shame framing around rest, appetite, or mood.
// ─────────────────────────────────────────────────────────────────────────────

class PhaseTip {
  const PhaseTip({
    required this.title,
    required this.body,
    required this.emoji,
  });

  final String title;
  final String body;
  final String emoji;
}

class PhaseGuidance {
  const PhaseGuidance._();

  static const _menstrual = <PhaseTip>[
    PhaseTip(
      emoji: '🛏️',
      title: 'Rest is doing something',
      body:
          'Energy is often lowest in the first couple of days. Lighter movement '
          'like walking or stretching tends to feel better than pushing hard.',
    ),
    PhaseTip(
      emoji: '🍫',
      title: 'Iron and warmth',
      body:
          'Bleeding uses iron. Leafy greens, beans, and red meat are common '
          'sources, and warm food or a heat pack can ease cramping.',
    ),
    PhaseTip(
      emoji: '💧',
      title: 'Hydration helps bloating',
      body:
          'It sounds backwards, but drinking more water usually reduces the '
          'puffy, heavy feeling rather than adding to it.',
    ),
    PhaseTip(
      emoji: '📝',
      title: 'Log your flow',
      body:
          'Recording heaviness and cramping now is what makes next cycle\'s '
          'prediction and symptom patterns accurate.',
    ),
  ];

  static const _follicular = <PhaseTip>[
    PhaseTip(
      emoji: '🌱',
      title: 'Energy on the way up',
      body:
          'Oestrogen climbs after your period ends. Many people find this the '
          'easiest stretch for harder workouts and new projects.',
    ),
    PhaseTip(
      emoji: '🧠',
      title: 'Good window for hard things',
      body:
          'Focus and mood often improve here. If you have been putting off '
          'something demanding, this is a reasonable time to start it.',
    ),
    PhaseTip(
      emoji: '🥗',
      title: 'Build on protein',
      body:
          'Appetite is usually steadier now. Protein and fibre help keep it '
          'that way through the second half of your cycle.',
    ),
    PhaseTip(
      emoji: '😴',
      title: 'Bank the sleep',
      body:
          'Sleep tends to be less disrupted in this phase. Getting ahead now '
          'makes the luteal stretch easier.',
    ),
  ];

  static const _ovulation = <PhaseTip>[
    PhaseTip(
      emoji: '🌸',
      title: 'Peak fertility',
      body:
          'These are your most fertile days. Worth knowing whether you are '
          'trying to conceive or specifically trying not to.',
    ),
    PhaseTip(
      emoji: '🔍',
      title: 'Signs to notice',
      body:
          'Clear, stretchy discharge, a slight temperature rise afterwards, and '
          'mild one-sided twinges are all common around ovulation.',
    ),
    PhaseTip(
      emoji: '⚡',
      title: 'Often the best you feel',
      body:
          'Energy, mood, and confidence commonly peak here. A good moment for '
          'anything social or demanding.',
    ),
    PhaseTip(
      emoji: '🌡️',
      title: 'Temperature confirms it',
      body:
          'A sustained rise of about 0.3°C after ovulation is the clearest sign '
          'it has already happened. Logging daily makes the shift visible.',
    ),
  ];

  static const _luteal = <PhaseTip>[
    PhaseTip(
      emoji: '🌙',
      title: 'Winding down',
      body:
          'Progesterone rises and then falls before your period. Lower energy '
          'and a shorter fuse in the last few days are both very common.',
    ),
    PhaseTip(
      emoji: '🧘',
      title: 'PMS is usually late luteal',
      body:
          'Symptoms tend to cluster in the five days before bleeding starts. '
          'Knowing that is coming makes it easier to plan around.',
    ),
    PhaseTip(
      emoji: '🍠',
      title: 'Cravings have a reason',
      body:
          'Appetite genuinely increases in this phase. Complex carbohydrates '
          'and magnesium-rich foods often steady it better than resisting.',
    ),
    PhaseTip(
      emoji: '💤',
      title: 'Protect your sleep',
      body:
          'Sleep is more easily disrupted now. Cutting caffeine earlier in the '
          'day is the change most people notice fastest.',
    ),
  ];

  /// A tip for [phase], varied by [day] so the home screen changes daily
  /// without needing stored state.
  static PhaseTip tipFor(CyclePhase phase, {int day = 0}) {
    final tips = switch (phase) {
      CyclePhase.menstrual => _menstrual,
      CyclePhase.follicular => _follicular,
      CyclePhase.ovulation => _ovulation,
      CyclePhase.luteal => _luteal,
    };
    return tips[day.abs() % tips.length];
  }

  /// All tips for a phase, for the education and phase-detail views.
  static List<PhaseTip> allFor(CyclePhase phase) => switch (phase) {
        CyclePhase.menstrual => _menstrual,
        CyclePhase.follicular => _follicular,
        CyclePhase.ovulation => _ovulation,
        CyclePhase.luteal => _luteal,
      };
}
