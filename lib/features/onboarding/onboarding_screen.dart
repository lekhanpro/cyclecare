import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../pet/pet_models.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding
//
// Five screens between "I downloaded this" and "I use this". The design is
// built around three rules:
//
//  • One question per page. A single decision per screen is answered; a form
//    with six fields is abandoned.
//  • Nothing pre-answered that the user should own. Goal and companion start
//    empty and Next stays disabled until they are chosen — a pre-ticked answer
//    gets accepted without being read, and this one shapes the whole app.
//    Cycle and period length are the exception: they *are* estimates, so
//    sensible defaults are a kindness rather than a presumption.
//  • Discrete taps, never a slider. Asking someone to drag to "29" implies a
//    precision they do not have about their own body, and it fails badly
//    one-handed. Steppers commit to a number without pretending to measure.
//
// The last page is a review, not a celebration. Everything collected is shown
// back before anything is written, and every row jumps to the page that set it.
//
// Layout contract, shared by the header, every page, and the action bar: one
// width-aware gutter from `AppLayout.pageGutterFor`, and a content column that
// stops growing at `AppLayout.maxContentWidth` and centres itself, so the three
// bands stay optically aligned from 320dp up to a tablet. Nothing here uses a
// fixed aspect ratio or a fixed square, because both break at 200% text scale.
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();

  int _page = 0;
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 7));

  // Held as ints rather than the doubles a Slider needed. Same values reach
  // `completeOnboarding`, minus a rounding step that could only lose data.
  int _cycleLength = 28;
  int _periodLength = 5;

  // Nullable on purpose: null is what gates the Next button. Both resolve to
  // the same defaults the old screen used before anything is saved.
  TrackingGoal? _goal;
  PetType? _petType;

  bool _saving = false;

  static const _totalPages = 5;

  static const _goalEmoji = <TrackingGoal, String>{
    TrackingGoal.trackPeriods: '🌸',
    TrackingGoal.tryingToConceive: '🌿',
    TrackingGoal.pregnancy: '🤰',
    TrackingGoal.perimenopause: '🌙',
    TrackingGoal.symptomWellness: '💜',
  };

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Whether the current page has been answered. Pages with genuine defaults
  /// are always satisfied; pages asking the user to choose are not.
  bool get _canAdvance => switch (_page) {
        1 => _goal != null,
        3 => _petType != null,
        _ => true,
      };

  void _next() {
    if (!_canAdvance || _saving) return;
    Haptics.selection();
    if (_page >= _totalPages - 1) {
      _finish();
      return;
    }
    // Dismiss the keyboard before the slide so the page doesn't animate while
    // the viewport is still resizing under it.
    FocusScope.of(context).unfocus();
    _goTo(_page + 1);
  }

  void _back() {
    if (_page == 0) return;
    Haptics.selection();
    FocusScope.of(context).unfocus();
    _goTo(_page - 1);
  }

  void _goTo(int page) {
    _pageCtrl.animateToPage(
      page,
      duration: Motion.of(context)(AppDurations.modal),
      curve: AppCurves.inOut,
    );
  }

  Future<void> _pickLastPeriod() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      helpText: 'When did your last period start?',
    );
    if (picked == null || !mounted) return;
    Haptics.selection();
    setState(() => _lastPeriod = picked);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(cycleTrackerControllerProvider.notifier)
          .completeOnboarding(
            lastPeriodStart: _lastPeriod,
            cycleLength: _cycleLength,
            periodLength: _periodLength,
            goal: _goal ?? TrackingGoal.trackPeriods,
            profileName: _nameCtrl.text.trim(),
          );
      if (!mounted) return;
      Haptics.celebrate();
      context.go(AppRoutes.home);
    } catch (_) {
      // Saving to local storage should not fail, but if it does the user must
      // not be left staring at a spinner with no way back.
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        message: 'Could not save your setup. Please try again.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onLastPage = _page == _totalPages - 1;

    return Scaffold(
      body: PhaseBackdrop(
        colors: AppColors.menstrualGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

              return Column(
                children: [
                  _Bounded(
                    gutter: gutter,
                    top: AppSpacing.md,
                    child: _ProgressHeader(
                      page: _page,
                      total: _totalPages,
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      // Swiping would let someone slide past a page the Next
                      // button is deliberately holding shut.
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [
                        _WelcomePage(gutter: gutter, nameCtrl: _nameCtrl),
                        _GoalPage(
                          gutter: gutter,
                          selected: _goal,
                          emoji: _goalEmoji,
                          onChanged: (goal) => setState(() => _goal = goal),
                        ),
                        _CyclePage(
                          gutter: gutter,
                          lastPeriod: _lastPeriod,
                          cycleLength: _cycleLength,
                          periodLength: _periodLength,
                          onPickDate: _pickLastPeriod,
                          onCycleLength: (value) =>
                              setState(() => _cycleLength = value),
                          onPeriodLength: (value) =>
                              setState(() => _periodLength = value),
                        ),
                        _CompanionPage(
                          gutter: gutter,
                          selected: _petType,
                          onChanged: (pet) => setState(() => _petType = pet),
                        ),
                        _ReviewPage(
                          gutter: gutter,
                          name: _nameCtrl.text.trim(),
                          goal: _goal,
                          goalEmoji: _goalEmoji,
                          lastPeriod: _lastPeriod,
                          cycleLength: _cycleLength,
                          periodLength: _periodLength,
                          petType: _petType,
                          onEdit: _goTo,
                        ),
                      ],
                    ),
                  ),
                  _Bounded(
                    gutter: gutter,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.lg,
                    child: _ActionBar(
                      showBack: _page > 0,
                      saving: _saving,
                      canAdvance: _canAdvance,
                      onLastPage: onLastPage,
                      onBack: _back,
                      onNext: _next,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Layout ──────────────────────────────────────────────────────────────────

/// The shared layout band: width-aware gutter, content capped at
/// [AppLayout.maxContentWidth], centred once the viewport is wider than that.
class _Bounded extends StatelessWidget {
  const _Bounded({
    required this.child,
    required this.gutter,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double gutter;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, top, gutter, bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Chrome ──────────────────────────────────────────────────────────────────

/// Step count above a segmented bar.
///
/// The count is the accessible version of the bar, so the bar itself is hidden
/// from assistive technology and the count is a live region — advancing a page
/// announces "Step 3 of 5" instead of leaving a screen-reader user to infer it
/// from a decoration they cannot see.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = 'Step ${page + 1} of $total';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: label,
          child: ExcludeSemantics(
            child: Text(
              label,
              style: text.labelMedium?.copyWith(color: context.mutedColor),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(child: _StepBar(page: page, total: total)),
      ],
    );
  }
}

/// Segmented progress bar. Segments rather than one continuous track, because
/// "three of five" is countable at a glance in a way that "60%" is not.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accentColor;

    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i == total - 1 ? 0 : AppSpacing.xs,
              ),
              child: AnimatedContainer(
                duration: motion(AppDurations.fast),
                curve: AppCurves.out,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: i <= page
                      ? accent
                      : accent.withOpacity(context.isDark ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Back and Continue.
///
/// Side by side normally, stacked once text is scaled up — at 200% a two-column
/// row leaves "Start CycleCare" about a third of the width it needs, and an
/// ellipsised primary action is worse than a taller action bar.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.showBack,
    required this.saving,
    required this.canAdvance,
    required this.onLastPage,
    required this.onBack,
    required this.onNext,
  });

  final bool showBack;
  final bool saving;
  final bool canAdvance;
  final bool onLastPage;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final next = PrimaryButton(
      label: onLastPage ? 'Start CycleCare' : 'Continue',
      icon: onLastPage ? Icons.favorite_rounded : Icons.arrow_forward_rounded,
      loading: saving,
      // Disabled rather than hidden: a greyed button explains that something
      // is still needed, an absent one does not.
      onPressed: canAdvance ? onNext : null,
    );
    final back = PrimaryButton(
      label: 'Back',
      outlined: true,
      onPressed: saving ? null : onBack,
    );

    if (!showBack) return next;

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          next,
          const SizedBox(height: AppSpacing.sm),
          back,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: back),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: next),
      ],
    );
  }
}

/// Shared page scaffold: emoji tile, heading, one line of support, then
/// content. Every page uses it so the eye lands in the same place each time it
/// advances, and each page scrolls independently so a keyboard or a large text
/// scale never clips the question.
class _PageShell extends StatelessWidget {
  const _PageShell({
    required this.gutter,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final double gutter;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xl,
        gutter,
        AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.accentColor
                            .withOpacity(context.isDark ? 0.20 : 0.11),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Text(
                        emoji,
                        style: text.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Reveal(
                index: 1,
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: text.headlineSmall?.copyWith(
                      letterSpacing: -0.4,
                      color: context.inkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Reveal(
                index: 2,
                child: Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(color: context.mutedColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < children.length; i++)
                Reveal(index: 3 + i, child: children[i]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet closing line. Used to promise reversibility on the pages where a
/// choice might otherwise feel permanent.
class _Reassurance extends StatelessWidget {
  const _Reassurance(this.message, {this.icon = Icons.tune_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.lg, color: context.subtleColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: text.labelSmall?.copyWith(
                height: 1.45,
                color: context.subtleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small heading used inside the reassurance cards, where a card title has to
/// sit beside an icon without overflowing at large text scales.
class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.lg, color: tone),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: text.labelLarge?.copyWith(color: context.inkColor),
          ),
        ),
      ],
    );
  }
}

// ─── Page 1: Welcome ─────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.gutter, required this.nameCtrl});

  final double gutter;
  final TextEditingController nameCtrl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);

    return _PageShell(
      gutter: gutter,
      emoji: '🌸',
      title: 'Hey, welcome in',
      subtitle: 'A few quick questions and CycleCare will be set up around '
          'you. It takes about a minute.',
      children: [
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'What should we call you?',
            hintText: 'Optional',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: phases.fertile.surface,
          borderColor: phases.fertile.border,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeading(
                icon: Icons.lock_rounded,
                label: 'This stays with you',
                tone: phases.fertile.text,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Everything you enter is saved on this device only. No '
                'account, no upload, nothing leaving your phone.',
                style: text.bodySmall?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Page 2: Goal ────────────────────────────────────────────────────────────

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.gutter,
    required this.selected,
    required this.emoji,
    required this.onChanged,
  });

  final double gutter;
  final TrackingGoal? selected;
  final Map<TrackingGoal, String> emoji;
  final ValueChanged<TrackingGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      gutter: gutter,
      emoji: '🧭',
      title: 'What brings you here?',
      subtitle: 'This shapes what CycleCare puts front and centre. Pick the '
          'one that fits best today.',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final goal in TrackingGoal.values)
              SelectableChip(
                label: goal.label,
                emoji: emoji[goal],
                selected: selected == goal,
                // Reselecting the current answer must not clear it — this page
                // cannot advance from an empty state.
                onSelected: (_) => onChanged(goal),
              ),
          ],
        ),
        const _Reassurance(
          'Switch this whenever you like in Settings — nothing you log '
          'gets lost when you do.',
        ),
      ],
    );
  }
}

// ─── Page 3: Cycle ───────────────────────────────────────────────────────────

class _CyclePage extends StatelessWidget {
  const _CyclePage({
    required this.gutter,
    required this.lastPeriod,
    required this.cycleLength,
    required this.periodLength,
    required this.onPickDate,
    required this.onCycleLength,
    required this.onPeriodLength,
  });

  final double gutter;
  final DateTime lastPeriod;
  final int cycleLength;
  final int periodLength;
  final VoidCallback onPickDate;
  final ValueChanged<int> onCycleLength;
  final ValueChanged<int> onPeriodLength;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);

    return _PageShell(
      gutter: gutter,
      emoji: '🗓️',
      title: 'Your cycle so far',
      subtitle: 'Rough numbers are perfect. CycleCare learns your real '
          'pattern from the days you log.',
      children: [
        _LastPeriodCard(lastPeriod: lastPeriod, onTap: onPickDate),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepperRow(
                label: 'Cycle length',
                caption: 'First day of one period to the next',
                value: '$cycleLength days',
                accent: phases.ovulation.fill,
                onDecrease: cycleLength <= 18
                    ? null
                    : () => onCycleLength(cycleLength - 1),
                onIncrease: cycleLength >= 60
                    ? null
                    : () => onCycleLength(cycleLength + 1),
              ),
              Divider(
                height: AppSpacing.xxl,
                thickness: AppStrokes.hairline,
                color: context.lineColor.withOpacity(0.6),
              ),
              _StepperRow(
                label: 'Period length',
                caption: 'How many days the bleeding usually lasts',
                value: '$periodLength days',
                accent: phases.period.fill,
                onDecrease: periodLength <= 1
                    ? null
                    : () => onPeriodLength(periodLength - 1),
                onIncrease: periodLength >= 10
                    ? null
                    : () => onPeriodLength(periodLength + 1),
              ),
            ],
          ),
        ),
        const _Reassurance(
          'Not sure? Leave the defaults. Estimates get sharper on their '
          'own as you log.',
          icon: Icons.auto_awesome_rounded,
        ),
      ],
    );
  }
}

/// The one date this flow asks for. A whole card rather than a field, because
/// it is the single most consequential answer on the page.
class _LastPeriodCard extends StatelessWidget {
  const _LastPeriodCard({required this.lastPeriod, required this.onTap});

  final DateTime lastPeriod;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);
    final daysAgo = DateTime.now().difference(lastPeriod).inDays;
    final relative = daysAgo <= 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  phases.period.fill.withOpacity(context.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(AppRadii.compact),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: AppSpacing.xl,
              color: phases.period.text,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last period started',
                  style: text.labelSmall?.copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('EEEE, MMMM d').format(lastPeriod),
                  style: text.labelLarge?.copyWith(color: context.inkColor),
                ),
                Text(
                  relative,
                  style: text.labelSmall?.copyWith(color: context.subtleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            size: AppSpacing.xl,
            color: context.subtleColor,
          ),
        ],
      ),
    );
  }
}

/// Label, current value, and two tap targets. The value sits between the
/// buttons so a thumb can hold position and watch the number change, and it is
/// a live region so the change is announced rather than only seen.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.caption,
    required this.value,
    required this.onIncrease,
    required this.onDecrease,
    this.accent,
  });

  final String label;
  final String caption;
  final String value;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final subject = label.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelLarge?.copyWith(color: context.inkColor),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          caption,
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              semanticLabel: 'Decrease $subject',
              accent: accent,
              onTap: onDecrease,
            ),
            Expanded(
              child: Semantics(
                container: true,
                liveRegion: true,
                label: '$label, $value',
                child: ExcludeSemantics(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                      letterSpacing: -0.3,
                      color: context.inkColor,
                    ),
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              semanticLabel: 'Increase $subject',
              accent: accent,
              onTap: onIncrease,
            ),
          ],
        ),
      ],
    );
  }
}

/// Icon-only stepper control, so the label lives in semantics and the target is
/// a full [AppLayout.minTouchTarget] square rather than a smaller circle that
/// merely sits inside one.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tone = accent ?? context.accentColor;

    return Pressable(
      // Selection rather than the default tap: the user is stepping through
      // values and each increment is a state change worth feeling.
      haptic: false,
      onTap: enabled
          ? () {
              Haptics.selection();
              onTap!();
            }
          : null,
      // Passed explicitly so a limit-reached button stays a disabled button in
      // the semantics tree instead of dropping out of it.
      enabled: enabled,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      scale: 0.88,
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? tone.withOpacity(context.isDark ? 0.22 : 0.11)
              : context.lineColor.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: AppSpacing.xl,
          color: enabled ? tone : context.subtleColor,
        ),
      ),
    );
  }
}

// ─── Page 4: Companion ───────────────────────────────────────────────────────

class _CompanionPage extends StatelessWidget {
  const _CompanionPage({
    required this.gutter,
    required this.selected,
    required this.onChanged,
  });

  final double gutter;
  final PetType? selected;
  final ValueChanged<PetType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      gutter: gutter,
      emoji: '🐾',
      title: 'Pick a companion',
      subtitle: 'They grow as you log. It is a small nudge on the days you '
          'would rather not think about any of this.',
      children: [
        // A Wrap with intrinsic-height tiles rather than a GridView with a
        // fixed aspect ratio: at 200% text scale a fixed ratio clips the name,
        // and this simply gets taller.
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.md;
            final columns = constraints.maxWidth < 260 ? 1 : 2;
            // Floored so two tiles plus the gap can never exceed the row and
            // fall to separate lines on a rounding error.
            final tileWidth =
                ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                    .floorToDouble();

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final pet in PetType.values)
                  SizedBox(
                    width: tileWidth,
                    child: _CompanionTile(
                      pet: pet,
                      selected: selected == pet,
                      onTap: () => onChanged(pet),
                    ),
                  ),
              ],
            );
          },
        ),
        const _Reassurance(
          'You can rename them, or swap for another, any time in Settings.',
        ),
      ],
    );
  }
}

class _CompanionTile extends StatelessWidget {
  const _CompanionTile({
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  final PetType pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    final accent = context.accentColor;
    final radius = BorderRadius.circular(AppRadii.card);

    return Pressable(
      haptic: false,
      onTap: () {
        Haptics.selection();
        onTap();
      },
      scale: 0.96,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      // The emoji would otherwise be read out as its unicode name alongside
      // the label, so the tile names itself once and hides its contents.
      semanticLabel: pet.name,
      excludeChildSemantics: true,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(context.isDark ? 0.26 : 0.13)
              : context.cardColor,
          borderRadius: radius,
          border: Border.all(
            // Border weight carries selection so the tile never changes size
            // and the grid stays perfectly still while choosing.
            color: selected ? accent : context.lineColor,
            width: selected ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pet.emoji, style: text.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              pet.name,
              textAlign: TextAlign.center,
              style: text.labelLarge?.copyWith(
                color: selected ? accent : context.inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 5: Review ──────────────────────────────────────────────────────────

class _ReviewPage extends StatelessWidget {
  const _ReviewPage({
    required this.gutter,
    required this.name,
    required this.goal,
    required this.goalEmoji,
    required this.lastPeriod,
    required this.cycleLength,
    required this.periodLength,
    required this.petType,
    required this.onEdit,
  });

  final double gutter;
  final String name;
  final TrackingGoal? goal;
  final Map<TrackingGoal, String> goalEmoji;
  final DateTime lastPeriod;
  final int cycleLength;
  final int periodLength;
  final PetType? petType;

  /// Jumps back to the page that owns a row.
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);

    return _PageShell(
      gutter: gutter,
      emoji: petType?.emoji ?? '✨',
      title: name.isEmpty ? 'Does this look right?' : 'All set, $name?',
      subtitle: 'A quick check before anything is saved. Tap any line to go '
          'back and change it.',
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (name.isNotEmpty)
                _ReviewRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: name,
                  onTap: () => onEdit(0),
                ),
              _ReviewRow(
                icon: Icons.explore_outlined,
                label: 'Here for',
                value: goal?.label ?? 'Not chosen',
                emoji: goalEmoji[goal],
                onTap: () => onEdit(1),
              ),
              _ReviewRow(
                icon: Icons.calendar_today_rounded,
                label: 'Last period started',
                value: DateFormat('MMMM d, yyyy').format(lastPeriod),
                onTap: () => onEdit(2),
              ),
              _ReviewRow(
                icon: Icons.repeat_rounded,
                label: 'Cycle length',
                value: '$cycleLength days',
                onTap: () => onEdit(2),
              ),
              _ReviewRow(
                icon: Icons.water_drop_outlined,
                label: 'Period length',
                value: '$periodLength days',
                onTap: () => onEdit(2),
              ),
              _ReviewRow(
                icon: Icons.pets_rounded,
                label: 'Companion',
                value: petType?.name ?? 'Not chosen',
                emoji: petType?.emoji,
                onTap: () => onEdit(3),
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoBanner(
          icon: Icons.tune_rounded,
          tone: phases.fertile.fill,
          title: 'Nothing here is final',
          message: 'Every one of these can be changed later in Settings, and '
              'your estimates update the moment you do.',
        ),
        const SizedBox(height: AppSpacing.sm),
        InfoBanner(
          icon: Icons.health_and_safety_outlined,
          tone: context.mutedColor,
          message: 'CycleCare is for personal tracking and education. It is '
              'not a medical device and does not give medical advice — please '
              'talk to a healthcare professional about any concerns.',
        ),
      ],
    );
  }
}

/// One reviewable answer.
///
/// Label above value rather than beside it: a two-column row of "Last period
/// started" and a full date has nowhere to go on a 320dp screen once text is
/// scaled up, and stacking removes the overflow instead of ellipsising the
/// answer the user is here to check.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.emoji,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? emoji;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: onTap,
          scale: 0.99,
          semanticLabel: '$label: $value',
          semanticHint: 'Go back and change this',
          excludeChildSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppSpacing.xl, color: context.mutedColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: text.labelSmall?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          if (emoji != null) ...[
                            Text(emoji!, style: text.labelLarge),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Text(
                              value,
                              style: text.labelLarge?.copyWith(
                                color: context.inkColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSpacing.xl,
                  color: context.subtleColor,
                ),
              ],
            ),
          ),
        ),
        if (!last)
          Divider(
            height: AppStrokes.hairline,
            thickness: AppStrokes.hairline,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: context.lineColor.withOpacity(0.5),
          ),
      ],
    );
  }
}
