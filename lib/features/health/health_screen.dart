import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../widgets/widgets.dart';
import 'application/health_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Health
//
// This screen used to be five paragraphs of text. The information was good and
// it is preserved here, but reading about endometriosis is not the same as
// doing anything about it, and a leaflet is closed once and never reopened.
//
// So the content stays and three things are added around it:
//
//  • Marking a condition as yours. It floats to the top and the screen becomes
//    about your situation rather than a list of possibilities.
//  • A pain diary. The gap between "it hurts a lot sometimes" and a dated
//    record of levels and locations is most of the gap between being believed
//    and not. Average time to an endometriosis diagnosis is measured in years,
//    and a diary is the cheapest thing that shortens it.
//  • Two self-assessments. These are the delicate part. They exist because
//    people already run these questions past a search engine and get a
//    confident, wrong answer. Here they are framed as a conversation starter
//    with a clinician and nothing else: no scores presented as verdicts, no
//    condition ever asserted, and a disclaimer that does not scroll away.
//
// Everything here is educational. No dosages, no treatments, no diagnoses.
// ─────────────────────────────────────────────────────────────────────────────

enum _HealthTab { conditions, diary, screening }

/// Which phase hue carries each condition.
///
/// Reusing the cycle palette rather than inventing five new colours keeps the
/// screen inside the app's visual language, and a couple of the mappings are
/// genuinely meaningful — PMDD gets the luteal wash because the luteal phase is
/// when it happens, and amenorrhea gets the period rose it is defined by.
enum _Tone { period, predicted, fertile, ovulation, luteal }

PhaseSwatch _swatch(BuildContext context, _Tone tone) {
  final phases = PhaseColors.of(context);
  return switch (tone) {
    _Tone.period => phases.period,
    _Tone.predicted => phases.predicted,
    _Tone.fertile => phases.fertile,
    _Tone.ovulation => phases.ovulation,
    _Tone.luteal => phases.luteal(),
  };
}

/// Body copy sitting on a tinted surface. Muted grey is right in light mode but
/// too dim against a dark card, so the dark variant lifts toward the ink.
Color _bodyColor(BuildContext context) =>
    context.isDark ? context.inkColor.withOpacity(0.86) : context.mutedColor;

/// Leading for the long-form copy on this screen.
///
/// Looser than the theme's 1.45 on purpose: several of these blocks run to a
/// full paragraph about a condition someone may be living with, and the extra
/// air between lines is the difference between reading it and skimming it.
const double _readingLeading = 1.6;

/// The paragraph style used everywhere this screen sets prose rather than a
/// label. One definition so a summary, an escalation note and a diary note all
/// read at the same size and rhythm.
TextStyle? _readingStyle(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: _readingLeading,
          color: color ?? _bodyColor(context),
        );

// ─────────────────────────────────────────────────────────────────────────────
// Content
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class _Condition {
  const _Condition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.tone,
    required this.summary,
    required this.signs,
    required this.escalate,
    required this.tracking,
  });

  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final _Tone tone;

  /// Always visible. The original leaflet copy, tightened.
  final String summary;

  /// Commonly reported signs. Deliberately phrased as "often", "may" — these
  /// are patterns people recognise, not criteria they can score themselves on.
  final List<String> signs;

  /// When waiting stops being reasonable.
  final String escalate;

  /// What logging in this app actually contributes for this condition.
  final String tracking;
}

const _conditions = <_Condition>[
  _Condition(
    id: 'pcos',
    name: 'PCOS',
    subtitle: 'Polycystic ovary syndrome',
    emoji: '🔵',
    tone: _Tone.fertile,
    summary:
        'A common hormonal condition among people of reproductive age. It tends '
        'to show up as some combination of irregular or infrequent ovulation, '
        'higher androgen levels, and the ovarian appearance it is named after — '
        'though nobody needs all three, and the name is a poor description of '
        'what it actually is.',
    signs: [
      'Cycles that often run long, skip, or stay unpredictable for a year or more',
      'Acne or persistently oily skin that carried on past the teenage years',
      'Coarser hair growth on the face, chest, or abdomen',
      'Thinning hair at the scalp or temples',
      'Ovulation that is hard to pin down — flat temperature charts, ambiguous mucus',
      'Weight that shifts without a clear change in habits',
      'Darker, velvety patches of skin at the neck, underarms, or groin',
    ],
    escalate:
        'Cycles regularly longer than 35 days, fewer than eight periods in a '
        'year, or a year of trying to conceive without success are all reasons '
        'to book an appointment rather than keep watching.',
    tracking:
        'Your logged cycle lengths are the single most useful thing to bring. '
        'A clinician asking "how irregular?" gets a real answer instead of a '
        'guess.',
  ),
  _Condition(
    id: 'endometriosis',
    name: 'Endometriosis',
    subtitle: 'Tissue growth outside the uterus',
    emoji: '🟣',
    tone: _Tone.ovulation,
    summary:
        'Tissue similar to the uterine lining grows outside the uterus, where '
        'it responds to the same hormonal signals and has nowhere to shed. The '
        'result is inflammation and pain that often has its own schedule, and '
        'severity of pain does not track how much tissue is involved.',
    signs: [
      'Period pain that stops you doing ordinary things, or that no longer responds to what used to help',
      'Pain that starts days before bleeding rather than with it',
      'Deep pelvic pain during or after sex',
      'Pain with bowel movements or urination, often worse around your period',
      'Heavy bleeding, or passing clots',
      'Bloating that arrives in a wave and lasts days',
      'Fatigue that outlasts the bleeding',
      'Pain radiating into the lower back, hips, or thighs',
    ],
    escalate:
        'Pain that keeps you off work or school, needs more relief than it used '
        'to, or comes with bowel or bladder symptoms deserves an appointment. '
        'So does pain that has quietly become normal to you.',
    tracking:
        'Diagnosis takes years on average, and the most common reason is that '
        'pain gets described from memory. The pain diary in the next tab is '
        'built for this: dated entries, levels, and locations you can hand over.',
  ),
  _Condition(
    id: 'pmdd',
    name: 'PMDD',
    subtitle: 'Premenstrual dysphoric disorder',
    emoji: '🟡',
    tone: _Tone.luteal,
    summary:
        'A severe premenstrual condition affecting mood as much as the body. '
        'The distinguishing feature is timing, not intensity alone: symptoms '
        'arrive in the luteal phase, in the week or two before bleeding, and '
        'lift within a few days of the period starting.',
    signs: [
      'Marked irritability or anger, often surfacing as conflict with the people closest to you',
      'Hopelessness, harsh self-criticism, or feeling out of control',
      'Anxiety, tension, or being permanently on edge',
      'Losing interest in things you normally enjoy',
      'Sleeping much more or much less than usual',
      'Strong food cravings, or appetite falling away',
      'A clear lift within a few days of bleeding starting',
    ],
    escalate:
        'If the mood shift is severe, repeats across cycles, or brings thoughts '
        'of harming yourself, reach out now rather than collecting more data. '
        'For thoughts of self-harm, contact local emergency services or a '
        'crisis line straight away.',
    tracking:
        'Assessment usually asks for daily ratings across two full cycles, '
        'because the timing is the whole point. Two cycles of mood logs is '
        'exactly the evidence that gets taken seriously.',
  ),
  _Condition(
    id: 'perimenopause',
    name: 'Perimenopause',
    subtitle: 'The transition toward menopause',
    emoji: '🟠',
    tone: _Tone.predicted,
    summary:
        'The years of hormonal change leading up to menopause, often starting '
        'in the forties and sometimes earlier. Cycles usually get shorter and '
        'closer together first, then longer and more variable. It ends twelve '
        'months after a final period, and can run for several years.',
    signs: [
      'Cycles shortening, then lengthening and becoming unpredictable',
      'Periods skipped entirely, then returning',
      'Flow changing character — much heavier or much lighter than your normal',
      'Hot flushes or night sweats',
      'Sleep breaking in the early hours',
      'Mood changes, irritability, or word-finding and memory lapses',
      'Vaginal dryness or discomfort',
      'New joint aches and stiffness',
    ],
    escalate:
        'Bleeding much heavier than your usual, bleeding between periods, '
        'bleeding after sex, or any bleeding at all after twelve consecutive '
        'months without a period needs looking at rather than waiting.',
    tracking:
        'Cycle length variability is the clearest early signal, and it is only '
        'visible across many months. Your history here shows the shape of the '
        'change instead of just the latest cycle.',
  ),
  _Condition(
    id: 'amenorrhea',
    name: 'Amenorrhea',
    subtitle: 'Absent periods',
    emoji: '⚪',
    tone: _Tone.period,
    summary:
        'Menstruation that has not started, or has stopped. Pregnancy, '
        'breastfeeding, and some contraception account for many cases and are '
        'expected. Beyond those, it is a signal worth following up rather than '
        'a condition in itself, because what caused it is the useful question.',
    signs: [
      'No period for three months, or six if your cycles were already irregular',
      'No first period by around age fifteen',
      'A recent large change in training load, food intake, or weight',
      'Sustained high stress or illness',
      'Milky discharge from the breasts, new headaches, or changes in vision',
      'Hot flushes or dryness alongside the absent periods',
    ],
    escalate:
        'Three missed cycles in a row with a negative pregnancy test is worth '
        'an appointment. Go sooner if there is also breast discharge, severe '
        'headache, or any change in vision.',
    tracking:
        'CycleCare flags a significantly overdue period automatically. Treat '
        'the flag as a prompt to ask a question, never as an answer.',
  ),
];

const _painLocations = <String>[
  'Lower abdomen',
  'Lower back',
  'Pelvis',
  'Thighs',
  'Head',
  'Breasts',
  'Digestive',
];

@immutable
class _Screener {
  const _Screener({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.tone,
    required this.questions,
    required this.threshold,
    required this.overlap,
    required this.noOverlap,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final _Tone tone;
  final List<String> questions;

  /// How many "yes" answers before the result copy shifts from "not much
  /// overlap" to "worth raising". Chosen to be generous rather than precise —
  /// the cost of prompting an unnecessary conversation is far lower than the
  /// cost of talking someone out of one.
  final int threshold;

  final String overlap;
  final String noOverlap;
}

const _screeners = <_Screener>[
  _Screener(
    id: 'pcos',
    title: 'Cycle and hormone patterns',
    subtitle: 'Questions clinicians often ask when PCOS comes up',
    emoji: '🔵',
    tone: _Tone.fertile,
    threshold: 3,
    questions: [
      'Have your cycles often run longer than 35 days, or stayed unpredictable, for a year or more?',
      'Have you had fewer than eight periods in the last twelve months?',
      'Do you get acne or oily skin that has persisted well past your teens?',
      'Have you noticed coarser hair growing on your face, chest, or abdomen?',
      'Have you noticed hair thinning at your scalp or temples?',
      'Has your weight changed without a clear change in your habits?',
      'Does a parent or sibling have PCOS or type 2 diabetes?',
    ],
    overlap:
        'Several of your answers touch on the patterns clinicians look at when '
        'PCOS comes up. That is not a diagnosis and it is not a result — thyroid '
        'issues, stress, and plenty of ordinary variation produce the same '
        'answers. It is a good reason to book a conversation, and your logged '
        'cycle lengths are worth bringing with you.',
    noOverlap:
        'Your answers do not line up strongly with the pattern these questions '
        'describe. This is not a test and it cannot rule anything out. If '
        'something about your cycle feels off to you, that on its own is reason '
        'enough to ask a clinician.',
  ),
  _Screener(
    id: 'pmdd',
    title: 'Premenstrual mood patterns',
    subtitle: 'How the week or two before bleeding tends to go',
    emoji: '🟡',
    tone: _Tone.luteal,
    threshold: 4,
    questions: [
      'In the week or two before your period, do you feel unusually irritable or angry?',
      'Do you feel hopeless, unusually self-critical, or overwhelmed in that window?',
      'Does anxiety or feeling on edge spike in the days before bleeding?',
      'Do you lose interest in things you normally enjoy during that stretch?',
      'Does it noticeably affect your work, studying, or closest relationships?',
      'Do the symptoms ease within a few days of bleeding starting?',
      'Has this pattern repeated across most of your recent cycles?',
    ],
    overlap:
        'Your answers describe a premenstrual pattern that overlaps with what '
        'clinicians call PMDD. This screen cannot diagnose it — assessment '
        'normally asks for daily ratings across two full cycles, which is '
        'exactly what your logs build. Worth raising, and worth bringing the '
        'logs to.',
    noOverlap:
        'Your answers do not line up strongly with the premenstrual pattern '
        'these questions describe. That does not mean what you are experiencing '
        'is minor or imagined. If it is affecting your life, it is worth '
        'discussing regardless of what any questionnaire says.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome
// ─────────────────────────────────────────────────────────────────────────────

/// Scroll padding shared by the three tabs: a width-aware gutter either side,
/// a little air at the top, and enough at the bottom that the last card clears
/// the pinned notice instead of hiding under it.
EdgeInsets _tabPadding(double width) {
  final gutter = AppLayout.pageGutterFor(width);
  return EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, AppSpacing.xxl);
}

/// Holds a scroll body to a readable measure and centres it on wide screens.
///
/// Without this a tablet gets paragraphs a thousand pixels wide, which is the
/// fastest way to make health information feel like a terms-of-service page.
class _Bounded extends StatelessWidget {
  const _Bounded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Section title, announced as a heading so assistive technology can jump
/// between the parts of a tab instead of walking every card.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, this.index = 0});

  final String title;
  final String? subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      index: index,
      child: MergeSemantics(
        child: Semantics(
          header: true,
          child: SectionHeader(
            title: title,
            subtitle: subtitle,
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small label above a block of detail. Uppercased and tracked rather than
/// large, and marked as a heading so it is navigable.
class _SubHeading extends StatelessWidget {
  const _SubHeading({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: color,
            ),
      ),
    );
  }
}

/// The leading emoji tile on a condition or screener card.
///
/// A fixed square: it is decoration, so it holds its size while the text beside
/// it grows with the user's text scale, and the glyph shrinks to fit rather
/// than pushing the row apart.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.emoji, required this.swatch, this.tinted = false});

  final String emoji;
  final PhaseSwatch swatch;

  /// Fills with the phase tint instead of the card colour. Used where the card
  /// itself is already white and needs the accent.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tinted ? swatch.surface : context.cardColor,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(
            color: swatch.border,
            width: AppStrokes.hairline,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(emoji, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

/// The expand/collapse affordance shared by condition and screener cards.
///
/// Only the header row is the control, not the whole card — both cards carry
/// their own buttons inside, and a tap target wrapped around another tap target
/// is impossible to describe to a screen reader and awkward to hit.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.emoji,
    required this.swatch,
    required this.title,
    required this.subtitle,
    required this.open,
    required this.onToggle,
    required this.expandHint,
    required this.collapseHint,
    this.subtitleColor,
    this.tintedGlyph = false,
  });

  final String emoji;
  final PhaseSwatch swatch;
  final String title;
  final String subtitle;
  final bool open;
  final VoidCallback onToggle;
  final String expandHint;
  final String collapseHint;
  final Color? subtitleColor;
  final bool tintedGlyph;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Semantics(
        // The native expanded state, so the card announces "expanded" or
        // "collapsed" rather than leaving the chevron to carry it visually.
        expanded: open,
        child: Pressable(
          onTap: onToggle,
          scale: 0.995,
          semanticLabel: '$title. $subtitle',
          semanticHint: open ? collapseHint : expandHint,
          excludeChildSemantics: true,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                _Glyph(emoji: emoji, swatch: swatch, tinted: tintedGlyph),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.inkColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: text.labelMedium?.copyWith(
                          height: 1.35,
                          color: subtitleColor ?? swatch.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: motion(AppDurations.fast),
                  curve: AppCurves.out,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: AppSpacing.xl,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  _HealthTab _tab = _HealthTab.conditions;

  final Set<String> _expandedConditions = <String>{};
  final Set<String> _expandedScreeners = <String>{};

  /// Screener id → question index → yes/no. Held here rather than inside the
  /// screening tab so switching tabs mid-questionnaire does not wipe the
  /// answers. Deliberately *not* persisted: a stale answer set restored weeks
  /// later would be read as a saved result, which is the one thing these
  /// questions must never look like.
  final Map<String, Map<int, bool>> _answers = <String, Map<int, bool>>{};

  void _toggleCondition(String id) {
    setState(() {
      if (!_expandedConditions.remove(id)) _expandedConditions.add(id);
    });
  }

  void _toggleScreener(String id) {
    setState(() {
      if (!_expandedScreeners.remove(id)) _expandedScreeners.add(id);
    });
  }

  void _answer(String screenerId, int index, bool value) {
    setState(() {
      final answers = _answers.putIfAbsent(screenerId, () => <int, bool>{});
      // Tapping the answer already selected clears it, matching how the
      // severity control lets you undo a tap.
      if (answers[index] == value) {
        answers.remove(index);
      } else {
        answers[index] = value;
      }
    });
  }

  void _resetScreener(String screenerId) {
    setState(() => _answers.remove(screenerId));
  }

  Future<void> _logPain() async {
    final entry = await showAppSheet<PainEntry>(
      context: context,
      title: 'Log pain',
      child: const _PainSheet(),
    );
    if (entry == null || !mounted) return;

    await ref.read(painEntriesProvider.notifier).add(entry);
    if (!mounted) return;
    showAppToast(context, message: 'Pain entry saved');
  }

  Future<bool> _deletePain(PainEntry entry) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this entry?',
      message:
          '${shortDate(entry.date)} at ${entry.severity}/10 will be removed '
          'from your diary. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return false;

    await ref.read(painEntriesProvider.notifier).remove(entry.id);
    if (mounted) {
      showAppToast(context, message: 'Entry deleted', kind: ToastKind.info);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_tab) {
      _HealthTab.conditions => _ConditionsTab(
          expanded: _expandedConditions,
          onToggle: _toggleCondition,
          onOpenDiary: () => setState(() => _tab = _HealthTab.diary),
        ),
      _HealthTab.diary => _PainDiaryTab(
          onLogPain: _logPain,
          onDelete: _deletePain,
        ),
      _HealthTab.screening => _ScreeningTab(
          expanded: _expandedScreeners,
          answers: _answers,
          onToggle: _toggleScreener,
          onAnswer: _answer,
          onReset: _resetScreener,
        ),
    };

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Health')),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.xs,
                  gutter,
                  AppSpacing.md,
                ),
                child: _Bounded(
                  // Announced as one labelled group with heading semantics, so
                  // the three parts of this screen are reachable by heading
                  // navigation rather than only by swiping through controls.
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    header: true,
                    label: 'Health sections',
                    child: SegmentedSelector<_HealthTab>(
                      segments: const {
                        _HealthTab.conditions: 'Conditions',
                        _HealthTab.diary: 'Pain diary',
                        _HealthTab.screening: 'Screening',
                      },
                      value: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlurSwap(
              child: KeyedSubtree(key: ValueKey(_tab), child: content),
            ),
          ),
          // Pinned rather than appended to each list. A disclaimer that can be
          // scrolled past is a disclaimer that gets scrolled past, and this one
          // is doing real work on a screen about medical conditions.
          const _PinnedDisclaimer(),
        ],
      ),
    );
  }
}

/// The medical disclaimer, held at the bottom of the screen.
///
/// The wording is fixed, but the box it lives in is not: at 200% text scale an
/// unbounded banner grows to several hundred pixels and starts eating the tab
/// content it is meant to qualify. So it is capped against the viewport and
/// scrolls inside that cap — the notice stays present and complete, and the
/// content above it keeps a usable share of the screen.
class _PinnedDisclaimer extends StatelessWidget {
  const _PinnedDisclaimer();

  @override
  Widget build(BuildContext context) {
    final cap = (MediaQuery.sizeOf(context).height * 0.3)
        .clamp(AppLayout.minTouchTarget * 2, 240.0)
        .toDouble();

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.xs,
              gutter,
              AppSpacing.sm,
            ),
            child: _Bounded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: cap),
                child: SingleChildScrollView(
                  child: const InfoBanner(
                    icon: Icons.medical_information_rounded,
                    tone: AppColors.info,
                    message:
                        'Educational information only. Nothing here is a '
                        'diagnosis or a treatment recommendation — please talk '
                        'to a qualified clinician about anything that concerns '
                        'you.',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conditions
// ─────────────────────────────────────────────────────────────────────────────

class _ConditionsTab extends ConsumerWidget {
  const _ConditionsTab({
    required this.expanded,
    required this.onToggle,
    required this.onOpenDiary,
  });

  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myConditionsProvider);

    // Marked conditions float up, original order preserved inside each group.
    // Someone living with PCOS should not have to scroll past four things they
    // do not have every time they open this screen.
    final ordered = [
      ..._conditions.where((condition) => mine.contains(condition.id)),
      ..._conditions.where((condition) => !mine.contains(condition.id)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: _tabPadding(constraints.maxWidth),
          children: [
            _Bounded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: mine.isEmpty ? 'Conditions' : 'Yours first',
                    subtitle: mine.isEmpty
                        ? 'Tap a card to read the full picture'
                        : '${mine.length} marked as applying to you',
                  ),
                  for (var i = 0; i < ordered.length; i++)
                    Reveal(
                      index: i + 1,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ConditionCard(
                          condition: ordered[i],
                          mine: mine.contains(ordered[i].id),
                          open: expanded.contains(ordered[i].id),
                          onToggle: () => onToggle(ordered[i].id),
                          onMarkChanged: () => ref
                              .read(myConditionsProvider.notifier)
                              .toggle(ordered[i].id),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Reveal(
                    index: ordered.length + 1,
                    child: ActionTile(
                      icon: Icons.edit_note_rounded,
                      title: 'Keep a pain diary',
                      subtitle:
                          'Dated levels and locations you can hand to a '
                          'clinician instead of describing pain from memory',
                      onTap: onOpenDiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.condition,
    required this.mine,
    required this.open,
    required this.onToggle,
    required this.onMarkChanged,
  });

  final _Condition condition;
  final bool mine;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onMarkChanged;

  @override
  Widget build(BuildContext context) {
    final swatch = _swatch(context, condition.tone);

    // A flat, hairline card by default. Five saturated tinted surfaces stacked
    // down a page read as five equal alarms, which is the same as none — so the
    // tint is spent on the conditions the user has told us are theirs, and the
    // rest stay quiet. The tint is never the only cue: the chip at the foot of
    // the card names the state in words.
    return AppCard(
      emphasis: CardEmphasis.outlined,
      color: mine ? swatch.surface : null,
      borderColor: mine ? swatch.border : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            emoji: condition.emoji,
            swatch: swatch,
            title: condition.name,
            subtitle: condition.subtitle,
            open: open,
            onToggle: onToggle,
            tintedGlyph: mine,
            expandHint: 'Read the full picture',
            collapseHint: 'Hide the full picture',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(condition.summary, style: _readingStyle(context)),

                // Revealed with a fade and lift rather than an animated height:
                // a card growing under its own rounded corners clips its border
                // on the way, and the detail here is several paragraphs long, so
                // the travel would be the slowest thing on the screen.
                if (open)
                  Reveal(
                    offsetY: AppSpacing.sm,
                    duration: AppDurations.fast,
                    child: _ConditionDetail(
                      condition: condition,
                      swatch: swatch,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SelectableChip(
                    label: 'This applies to me',
                    icon: mine
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    selected: mine,
                    accent: swatch.fill,
                    onSelected: (_) => onMarkChanged(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The expanded half of a condition card: signs, escalation, and what logging
/// in this app actually contributes.
class _ConditionDetail extends StatelessWidget {
  const _ConditionDetail({required this.condition, required this.swatch});

  final _Condition condition;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        _SubHeading(label: 'Common signs', color: swatch.text),
        const SizedBox(height: AppSpacing.sm),
        _Bullets(items: condition.signs, dot: swatch.text),
        const SizedBox(height: AppSpacing.xl),
        _SubHeading(label: 'When to see someone', color: swatch.text),
        const SizedBox(height: AppSpacing.sm),
        Text(condition.escalate, style: _readingStyle(context)),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: AppInsets.compactCard,
          decoration: BoxDecoration(
            color: context.cardColor.withOpacity(context.isDark ? 0.5 : 0.7),
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(
              color: context.lineColor,
              width: AppStrokes.hairline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.insights_rounded,
                  size: AppSpacing.lg,
                  color: swatch.text,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  condition.tracking,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: _readingLeading,
                        color: _bodyColor(context),
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hanging-indent bullet list.
///
/// The marker is a text glyph rather than a drawn dot so it grows with the
/// user's text scale and stays on the first line's baseline instead of drifting
/// toward the top of a tall paragraph.
class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.dot});

  final List<String> items;

  /// Marker colour. Decorative — the indent, not the colour, is what says
  /// "list".
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final style = _readingStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: AppSpacing.lg,
                    child: Text('•', style: style?.copyWith(color: dot)),
                  ),
                ),
                Expanded(child: Text(item, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pain diary
// ─────────────────────────────────────────────────────────────────────────────

class _PainDiaryTab extends ConsumerWidget {
  const _PainDiaryTab({required this.onLogPain, required this.onDelete});

  final VoidCallback onLogPain;
  final Future<bool> Function(PainEntry entry) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(painEntriesProvider);

    if (entries.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: _tabPadding(constraints.maxWidth),
            // Stretched to the viewport rather than pinned to a fixed height, so
            // the placeholder sits centred on a phone and still scrolls into
            // reach at large text instead of being clipped.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _Bounded(
                child: EmptyState(
                  emoji: '📓',
                  title: 'No entries yet',
                  message:
                      'Log a flare-up while you remember it. Dated levels and '
                      'locations turn "it hurts sometimes" into a record a '
                      'clinician can work from.',
                  actionLabel: 'Log pain',
                  onAction: onLogPain,
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Built lazily rather than as one column: the diary holds hundreds of
        // entries after a couple of years of flare-ups.
        return ListView.builder(
          padding: _tabPadding(constraints.maxWidth),
          itemCount: entries.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _Bounded(
                child: _DiarySummary(entries: entries, onLogPain: onLogPain),
              );
            }

            final position = index - 1;
            final entry = entries[position];

            return _Bounded(
              child: Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                // Confirmed before the row animates away, so a stray swipe never
                // silently removes a record the user cannot get back.
                confirmDismiss: (_) => onDelete(entry),
                background: const _DeleteBackground(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Reveal(
                    index: position.clamp(0, 8),
                    child: _PainEntryCard(
                      entry: entry,
                      onLongPress: () => onDelete(entry),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}

/// The header of the diary: what the record adds up to, and the one action that
/// grows it.
class _DiarySummary extends StatelessWidget {
  const _DiarySummary({required this.entries, required this.onLogPain});

  final List<PainEntry> entries;
  final VoidCallback onLogPain;

  @override
  Widget build(BuildContext context) {
    final average =
        entries.fold<int>(0, (sum, entry) => sum + entry.severity) /
            entries.length;
    final worst =
        entries.map((entry) => entry.severity).reduce((a, b) => a > b ? a : b);
    final topLocation = _mostCommonLocation(entries);

    // Two number cards side by side stop fitting somewhere past 130% text
    // scale — the value alone is 24pt before scaling. Stacking is the honest
    // answer; shrinking the figures is not.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final tiles = <Widget>[
      StatTile(
        label: 'Entries',
        value: '${entries.length}',
        icon: Icons.event_note_rounded,
        caption: 'since ${shortDate(entries.last.date)}',
      ),
      StatTile(
        label: 'Average level',
        value: average.toStringAsFixed(1),
        unit: '/10',
        icon: Icons.show_chart_rounded,
        accent: _severitySwatch(context, average.round()).fill,
        caption: 'worst logged $worst/10',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Section(
          title: 'Pain diary',
          subtitle: 'Newest first — long-press or swipe an entry to delete',
        ),
        Reveal(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stacked)
                for (final tile in tiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: tile,
                  )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles.first),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tiles.last),
                  ],
                ),
              if (topLocation != null) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MetricPill(
                    icon: Icons.my_location_rounded,
                    value: topLocation,
                    label: 'most logged location',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Log pain',
                icon: Icons.add_rounded,
                outlined: true,
                onPressed: onLogPain,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  String? _mostCommonLocation(List<PainEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final location in entry.locations) {
        counts[location] = (counts[location] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;

    var best = counts.keys.first;
    for (final entry in counts.entries) {
      if (entry.value > counts[best]!) best = entry.key;
    }
    return best;
  }
}

PhaseSwatch _severitySwatch(BuildContext context, int severity) {
  final phases = PhaseColors.of(context);
  if (severity >= 8) return phases.period;
  if (severity >= 5) return phases.luteal();
  return phases.fertile;
}

class _PainEntryCard extends StatelessWidget {
  const _PainEntryCard({required this.entry, required this.onLongPress});

  final PainEntry entry;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final swatch = _severitySwatch(context, entry.severity);

    // Merged so the whole entry is announced as one item — date, level, word,
    // locations, note — with the delete action attached, instead of five nodes
    // a screen-reader user has to reassemble.
    return MergeSemantics(
      child: AppCard(
        onLongPress: onLongPress,
        color: swatch.surface,
        borderColor: swatch.border,
        padding: AppInsets.compactCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The number is the level; the word beside it says what the
                // number means, so severity never rests on the tint alone.
                Container(
                  width: AppLayout.minTouchTarget,
                  height: AppLayout.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: swatch.fill,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${entry.severity}',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: swatch.onFill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(entry.date),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.inkColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${_severityLabel(entry.severity)} · '
                        '${entry.severity}/10',
                        style: text.labelMedium?.copyWith(color: swatch.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.locations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final location in entry.locations)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: swatch.border,
                          width: AppStrokes.hairline,
                        ),
                      ),
                      child: Text(
                        location,
                        style: text.labelSmall?.copyWith(
                          color: context.inkColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                entry.notes,
                style: text.bodySmall?.copyWith(
                  height: _readingLeading,
                  color: _bodyColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A word alongside the number. "7/10" means different things to different
  /// people; the label anchors it without pretending to be clinical.
  String _severityLabel(int severity) {
    if (severity >= 9) return 'Severe';
    if (severity >= 7) return 'Strong';
    if (severity >= 4) return 'Moderate';
    return 'Mild';
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(context.isDark ? 0.24 : 0.12),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: AppSpacing.xl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Delete',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The log-pain form.
///
/// Its own stateful widget rather than a builder closure so the controller gets
/// disposed properly and the sheet can hold a draft while the user thinks.
class _PainSheet extends StatefulWidget {
  const _PainSheet();

  @override
  State<_PainSheet> createState() => _PainSheetState();
}

class _PainSheetState extends State<_PainSheet> {
  int _severity = 0;
  final Set<String> _locations = <String>{};
  final TextEditingController _notes = TextEditingController();
  DateTime _date = dateOnly(DateTime.now());

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: dateOnly(DateTime.now()),
    );
    if (picked != null && mounted) {
      setState(() => _date = dateOnly(picked));
    }
  }

  void _save() {
    Navigator.of(context).pop(
      PainEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: _date,
        severity: _severity,
        // Stored in the canonical order so two entries with the same locations
        // always read the same way.
        locations: _painLocations.where(_locations.contains).toList(),
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final swatch = _severitySwatch(context, _severity);
    final isToday = isSameDate(_date, DateTime.now());
    final dateLabel =
        isToday ? 'Today' : DateFormat('EEEE, MMM d').format(_date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: AppCard(
            emphasis: CardEmphasis.outlined,
            padding: AppInsets.control,
            onTap: _pickDate,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: AppSpacing.lg,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: text.labelLarge?.copyWith(color: context.inkColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Change',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SheetSection(
          title: 'How bad was it?',
          subtitle: _severity == 0
              ? 'Pick a level from 1 to 10'
              : 'Level $_severity of 10',
        ),
        SeveritySelector(
          value: _severity,
          accent: swatch.fill,
          onChanged: (value) => setState(() => _severity = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SheetSection(
          title: 'Where',
          subtitle: 'Anything that applies',
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final location in _painLocations)
              SelectableChip(
                label: location,
                selected: _locations.contains(location),
                accent: swatch.fill,
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _locations.add(location);
                  } else {
                    _locations.remove(location);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SheetSection(
          title: 'Notes',
          subtitle: 'Optional — what it felt like, what you were doing',
        ),
        TextField(
          controller: _notes,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Sharp, low on the left, worse when standing…',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Save entry',
          icon: Icons.check_rounded,
          // A level is the one thing an entry cannot be summarised without.
          onPressed: _severity == 0 ? null : _save,
        ),
      ],
    );
  }
}

/// Section label inside the log sheet. Same shape as the page sections, with a
/// tighter foot because the control it introduces sits directly beneath it.
class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: SectionHeader(
          title: title,
          subtitle: subtitle,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screening
// ─────────────────────────────────────────────────────────────────────────────

class _ScreeningTab extends StatelessWidget {
  const _ScreeningTab({
    required this.expanded,
    required this.answers,
    required this.onToggle,
    required this.onAnswer,
    required this.onReset,
  });

  final Set<String> expanded;
  final Map<String, Map<int, bool>> answers;
  final ValueChanged<String> onToggle;
  final void Function(String screenerId, int index, bool value) onAnswer;
  final ValueChanged<String> onReset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: _tabPadding(constraints.maxWidth),
          children: [
            _Bounded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Section(
                    title: 'Self-assessment',
                    subtitle: 'A conversation starter, not a test',
                  ),
                  const Reveal(
                    index: 1,
                    child: InfoBanner(
                      icon: Icons.warning_amber_rounded,
                      tone: AppColors.warning,
                      title: 'These questions cannot diagnose anything',
                      message:
                          'They are the sort of thing a clinician asks early '
                          'on, so working through them helps you arrive with '
                          'clear answers. They cannot confirm a condition and '
                          'they cannot rule one out — only a clinician who can '
                          'examine and test you can do either.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < _screeners.length; i++)
                    Reveal(
                      index: i + 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ScreenerCard(
                          screener: _screeners[i],
                          answers:
                              answers[_screeners[i].id] ?? const <int, bool>{},
                          open: expanded.contains(_screeners[i].id),
                          onToggle: () => onToggle(_screeners[i].id),
                          onAnswer: (index, value) =>
                              onAnswer(_screeners[i].id, index, value),
                          onReset: () => onReset(_screeners[i].id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScreenerCard extends StatelessWidget {
  const _ScreenerCard({
    required this.screener,
    required this.answers,
    required this.open,
    required this.onToggle,
    required this.onAnswer,
    required this.onReset,
  });

  final _Screener screener;
  final Map<int, bool> answers;
  final bool open;
  final VoidCallback onToggle;
  final void Function(int index, bool value) onAnswer;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final swatch = _swatch(context, screener.tone);

    final total = screener.questions.length;
    final answered = answers.length;
    final yes = answers.values.where((value) => value).length;
    final complete = answered == total;
    final flagged = yes >= screener.threshold;

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: EdgeInsets.zero,
      child: AnimatedSize(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              emoji: screener.emoji,
              swatch: swatch,
              title: screener.title,
              subtitle: answered == 0
                  ? screener.subtitle
                  : '$answered of $total answered',
              subtitleColor: answered == 0 ? context.mutedColor : swatch.text,
              open: open,
              onToggle: onToggle,
              tintedGlyph: true,
              expandHint: 'Open the questions',
              collapseHint: 'Close the questions',
            ),
            if (!open && !complete)
              const SizedBox(height: AppSpacing.xs)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (open) ...[
                    for (var i = 0; i < total; i++)
                      _QuestionRow(
                        index: i,
                        total: total,
                        question: screener.questions[i],
                        answer: answers[i],
                        accent: swatch.fill,
                        onAnswer: (value) => onAnswer(i, value),
                      ),
                    if (answered > 0)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Pressable(
                          onTap: onReset,
                          scale: 0.96,
                          semanticLabel: 'Clear answers',
                          semanticHint: 'Removes all $answered answers',
                          excludeChildSemantics: true,
                          borderRadius:
                              BorderRadius.circular(AppRadii.compact),
                          minimumSize:
                              const Size(0, AppLayout.minTouchTarget),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'Clear answers',
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.mutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // The result. Never a score and never a verdict — the copy
                  // says what to do next, and both branches say in words that
                  // this is not a diagnosis.
                  if (complete)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Semantics(
                        liveRegion: true,
                        child: InfoBanner(
                          icon: flagged
                              ? Icons.flag_rounded
                              : Icons.info_rounded,
                          tone: flagged
                              ? AppColors.warning
                              : AppColors.info,
                          title: flagged
                              ? 'Worth raising with a clinician'
                              : 'Not much overlap here',
                          message: flagged
                              ? screener.overlap
                              : screener.noOverlap,
                        ),
                      ),
                    )
                  else if (open && answered > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        'Answer all $total to see what these patterns might be '
                        'worth discussing.',
                        style: _readingStyle(context),
                      ),
                    )
                  else if (!open)
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One question and its answer pair.
///
/// The question sits on its own line above the two options rather than sharing a
/// row with them: these are full sentences, and at 200% text scale a
/// sentence-plus-two-buttons row has nowhere left to go on a 320dp screen.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
    required this.accent,
    required this.onAnswer,
  });

  final int index;
  final int total;
  final String question;
  final bool? answer;
  final Color accent;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Grouped and numbered, so the two options are announced as belonging to
      // this question rather than as a loose pair of buttons in a long list.
      container: true,
      explicitChildNodes: true,
      label: 'Question ${index + 1} of $total. $question',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(
              height: AppStrokes.hairline,
              thickness: AppStrokes.hairline,
              color: context.lineColor,
            ),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(
              child: Text(
                question,
                style: _readingStyle(context, color: context.inkColor),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _AnswerButton(
                    label: 'Yes',
                    selected: answer == true,
                    accent: accent,
                    onTap: () => onAnswer(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _AnswerButton(
                    label: 'No',
                    selected: answer == false,
                    accent: context.mutedColor,
                    onTap: () => onAnswer(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A yes/no option.
///
/// Radio semantics rather than a chip: the two are mutually exclusive, and
/// announcing them as an exclusive group is the difference between "Yes,
/// selected" and a user wondering whether both are on. Selection carries an
/// icon, a heavier border and a heavier label, so it never rests on the tint.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.control);

    return Pressable(
      onTap: onTap,
      scale: 0.97,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: radius,
      minimumSize: const Size(0, AppLayout.minTouchTarget),
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        constraints: const BoxConstraints(
          minHeight: AppLayout.minTouchTarget,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(context.isDark ? 0.26 : 0.12)
              : context.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: selected ? accent : context.lineColor,
            width: selected ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: AppSpacing.lg,
              color: selected ? accent : context.subtleColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: context.inkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
