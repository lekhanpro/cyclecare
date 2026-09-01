import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/widgets.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/amenorrhea_result.dart';
import '../domain/cycle_models.dart';
import '../domain/phase_guidance.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home
//
// One question dominates this screen: where am I in my cycle, and when is the
// next period *estimated*? A single hero answers it — phase, ring, one plain
// sentence, one filled button — and nothing else on the page is allowed to
// compete with that block.
//
// Surface hierarchy is deliberately shallow. Exactly one surface is elevated
// (the glass hero); everything below it is a flat, hairline-bordered card or a
// tinted phase card. Six elevated tiles stacked down a page reads as six equal
// priorities, which is the same as none.
//
// Reading order below the hero, in priority order:
//   1. A footnote on the status itself (the PMS window).
//   2. Anything abnormal — a long gap, a late estimate, a wide spread.
//   3. Week context, for moving to another day.
//   4. Today's entry, one tap from empty to recorded.
//   5. Phase guidance.
//   6. Everything else, grouped into one quiet list behind a section label.
//
// Language rules applied throughout: a forecast is always framed as an
// estimate and hedged with "about", never stated as a fact, and status is never
// carried by colour alone — the phase pill, the alerts, and the logged-state
// row each carry an icon and name themselves in text.
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);

    return Scaffold(
      body: state.when(
        loading: () => const _LoadingHome(),
        error: (error, _) => _LoadFailure(error: error),
        data: (data) => _HomeBody(data: data),
      ),
    );
  }
}

/// Re-reads the tracker for pull-to-refresh and the retry action.
///
/// The failure is swallowed here on purpose: the provider already carries it
/// into [HomeScreen], which renders the error surface. Letting the future throw
/// would additionally surface an unhandled error from a refresh gesture the
/// user has already been answered about.
Future<void> _reloadTracker(WidgetRef ref) async {
  ref.invalidate(cycleTrackerControllerProvider);
  try {
    await ref.read(cycleTrackerControllerProvider.future);
  } catch (_) {
    // Reported by the error branch of the screen.
  }
}

/// Page scaffolding shared by the loaded and failed states: safe area, pull to
/// refresh, a width-aware gutter, and a content column that stops growing at
/// [AppLayout.maxContentWidth] and centres itself on tablets.
class _PageShell extends StatelessWidget {
  const _PageShell({
    required this.child,
    required this.onRefresh,
    this.fillViewport = false,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// Stretches the content to at least one viewport height, so a short
  /// placeholder sits centred rather than pinned under the status bar.
  final bool fillViewport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

            Widget content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: child,
              ),
            );

            if (fillViewport) {
              content = ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: fillViewport
                  ? EdgeInsets.symmetric(horizontal: gutter)
                  : EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.md,
                      gutter,
                      AppSpacing.xxxl,
                    ),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

/// Loading, kept calm rather than blank.
///
/// A bare spinner on an empty page reads as a stall. Naming what is happening
/// costs one line and removes the ambiguity, and it gives assistive technology
/// something to announce.
class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: AppSpacing.xxl,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  semanticsLabel: 'Loading your cycle',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Getting your cycle ready',
                textAlign: TextAlign.center,
                style: text.labelLarge?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Load failure, kept actionable.
///
/// The raw exception is never the headline — it is unreadable to the person
/// holding the phone and it buries the one thing they can do about it. The
/// message says what happened and that nothing was lost; the type name and the
/// exception text stay as quiet footnotes for a bug report.
class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final detail = error.toString().trim();

    return _PageShell(
      fillViewport: true,
      onRefresh: () => _reloadTracker(ref),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'We could not load your cycle',
            message: 'Nothing was lost — your entries stay on this device. '
                'Pull down to refresh, or try again.',
            actionLabel: 'Try again',
            onAction: () => _reloadTracker(ref),
          ),
          Text(
            'Reference: ${error.runtimeType}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: context.subtleColor),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: context.subtleColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = PhaseColors.of(context);
    final prediction = data.prediction;
    final phase = prediction?.currentPhase ?? CyclePhase.follicular;
    final swatch = phases.phase(phase);

    return PhaseBackdrop(
      colors: swatch.gradient,
      child: _PageShell(
        onRefresh: () => _reloadTracker(ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Greeting(data: data),
            const SizedBox(height: AppSpacing.xl),

            // 1 — the answer. The only elevated surface on the page.
            Reveal(
              offsetY: AppSpacing.md,
              child: _StatusHero(data: data),
            ),

            // 1b — a footnote on the same fact, deliberately not a card.
            if (prediction != null && !prediction.isLate)
              _PmsNote(prediction: prediction),

            // 2 — anomalies, only when they apply.
            ..._alerts(ref, prediction),

            // 3 — move to another day.
            const SizedBox(height: AppSpacing.lg),
            Reveal(
              index: 3,
              offsetY: AppSpacing.md,
              child: _WeekSection(data: data),
            ),

            // 4 — today's entry.
            const SizedBox(height: AppSpacing.lg),
            Reveal(
              index: 4,
              offsetY: AppSpacing.md,
              child: _TodaySection(data: data),
            ),

            // 5 — phase guidance.
            const SizedBox(height: AppSpacing.lg),
            Reveal(
              index: 5,
              offsetY: AppSpacing.md,
              child: _GuidanceCard(
                phase: phase,
                swatch: swatch,
                cycleDay: prediction?.cycleDay ?? 1,
              ),
            ),

            // 6 — everything else, one grouped list instead of six cards.
            const SizedBox(height: AppSpacing.xxl),
            const Reveal(
              index: 6,
              offsetY: AppSpacing.md,
              child: SectionHeader(
                title: 'Explore',
                subtitle: 'Tools and guidance for the rest of your health',
              ),
            ),
            const Reveal(
              index: 7,
              offsetY: AppSpacing.md,
              child: _ExploreList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Alert cards, ordered most-urgent first. Returns an empty list in the
  /// normal case so the home screen stays quiet unless there is something to
  /// say — a dashboard that always shows a warning trains people to ignore it.
  List<Widget> _alerts(WidgetRef ref, CyclePrediction? prediction) {
    final widgets = <Widget>[];
    final gap = _AmenorrheaCheck.evaluate(data.periods);

    if (gap != null) {
      widgets
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(Reveal(
          index: 2,
          offsetY: AppSpacing.md,
          child: _AmenorrheaCard(result: gap),
        ));
    } else if (prediction != null && prediction.isLate) {
      widgets
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(Reveal(
          index: 2,
          offsetY: AppSpacing.md,
          child: InfoBanner(
            icon: Icons.schedule_rounded,
            tone: AppColors.warning,
            title: prediction.daysLate == 1
                ? 'Your period is 1 day past the estimate'
                : 'Your period is ${prediction.daysLate} days past the '
                    'estimate',
            message:
                'Timing shifts with stress, travel, illness, and sleep, and '
                'the estimate is only as good as the cycles behind it. If it '
                'stays off or something feels wrong, a clinician is the right '
                'next step.',
            actionLabel: 'Log it now',
            onAction: () => ref
                .read(cycleTrackerControllerProvider.notifier)
                .logPeriodStart(DateTime.now()),
          ),
        ));
    } else if (prediction != null &&
        prediction.isIrregular &&
        prediction.cyclesTracked >= 3) {
      widgets
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(Reveal(
          index: 2,
          offsetY: AppSpacing.md,
          child: InfoBanner(
            icon: Icons.show_chart_rounded,
            tone: AppColors.info,
            title: 'Your cycles vary quite a bit',
            message: 'Lengths have ranged from ${prediction.shortestCycle} to '
                '${prediction.longestCycle} days, so every estimate here is '
                'wider than usual. Logging each period narrows it.',
          ),
        ));
    }

    return widgets;
  }
}

/// Non-colour phase cue. Paired with the phase name so the pill never relies on
/// its tint to say which phase it is.
IconData _phaseIcon(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => Icons.water_drop_rounded,
      CyclePhase.follicular => Icons.eco_rounded,
      CyclePhase.ovulation => Icons.wb_sunny_rounded,
      CyclePhase.luteal => Icons.nights_stay_rounded,
    };

// ─── Greeting ────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = data.preferences.profileName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(color: context.mutedColor),
              ),
              Text(
                name.isNotEmpty ? name : 'Welcome back',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  letterSpacing: -0.3,
                  color: context.inkColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderAction(
          icon: Icons.auto_awesome_rounded,
          label: 'Ask the CycleCare assistant',
          onTap: () => context.push(AppRoutes.aiChat),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderAction(
          icon: Icons.settings_rounded,
          label: 'Settings',
          initial: name.isNotEmpty ? name[0].toUpperCase() : null,
          tinted: true,
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

/// Icon-only header control. Icon-only means the label has to live in
/// semantics, and the box is a full touch target rather than a 42dp square
/// that happens to sit inside one.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.initial,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown instead of [icon] when the profile has a name.
  final String? initial;

  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.control);

    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: radius,
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tinted
              ? context.accentColor.withOpacity(context.isDark ? 0.22 : 0.14)
              : context.cardColor.withOpacity(context.isDark ? 0.60 : 0.66),
          borderRadius: radius,
          border: tinted
              ? null
              : Border.all(
                  color: context.lineColor,
                  width: AppStrokes.hairline,
                ),
        ),
        child: initial == null
            ? Icon(icon, size: AppSpacing.xl, color: context.accentColor)
            : Text(
                initial!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.accentColor,
                    ),
              ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

/// The plain-language status the hero exists to say, split into the sentence
/// the eye reads and the sentence a screen reader hears.
///
/// Every phrasing here is hedged. The app is projecting from a handful of past
/// cycles, so "about" and "estimated" are load-bearing words, not padding.
@immutable
class _CycleStatus {
  const _CycleStatus({
    required this.headline,
    required this.detail,
    required this.spoken,
  });

  factory _CycleStatus.from(CyclePrediction prediction) {
    final date = DateFormat('EEE d MMM').format(prediction.nextPeriodStart);

    if (prediction.isLate) {
      final days = prediction.daysLate;
      final headline = days == 1
          ? 'Your period is a day past the estimate'
          : 'Your period is $days days past the estimate';
      return _CycleStatus(
        headline: headline,
        detail: 'The estimate was $date. Timing shifts for plenty of '
            'everyday reasons.',
        spoken: headline,
      );
    }

    if (prediction.daysUntilPeriod <= 0) {
      const headline = 'Your period is expected today';
      return _CycleStatus(
        headline: headline,
        detail: _basis(prediction, 'Estimated to start today'),
        spoken: headline,
      );
    }

    final days = prediction.daysUntilPeriod;
    final headline = days == 1
        ? 'Period expected in about a day'
        : 'Period expected in about $days days';
    return _CycleStatus(
      headline: headline,
      detail: _basis(prediction, 'Estimated around $date'),
      spoken: headline,
    );
  }

  /// Large, centred, and the loudest text on the screen.
  final String headline;

  /// The hedge: what the estimate is built on, and how much it might move.
  final String detail;

  /// Read instead of [headline] when the hero is announced as one node.
  final String spoken;

  static String _basis(CyclePrediction prediction, String lead) {
    if (prediction.cyclesTracked < 2) {
      return '$lead. CycleCare is still learning your pattern, so expect '
          'this to move.';
    }

    final shortest = prediction.shortestCycle;
    final longest = prediction.longestCycle;
    if (prediction.isIrregular && shortest != null && longest != null) {
      return '$lead. Your recent cycles ran $shortest to $longest days, so '
          'this may shift.';
    }

    return '$lead, based on your recent cycles.';
  }
}

/// One surface, one job: where am I, when is the next period estimated, and
/// what is the single thing to do about it.
class _StatusHero extends ConsumerWidget {
  const _StatusHero({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = data.prediction;
    if (prediction == null) return const _HeroSetup();

    final text = Theme.of(context).textTheme;
    final settings = ref.watch(appSettingsSyncProvider);
    final phases = PhaseColors.of(context);
    final phase = prediction.currentPhase;
    final swatch = phases.phase(phase);
    final status = _CycleStatus.from(prediction);
    final loggedToday = data.periodFor(DateTime.now()) != null;
    final ovulationDay =
        prediction.averageCycleLength - data.preferences.lutealPhaseLength;

    // One merged summary for assistive technology. The pill, the ring, the
    // sentence, and the fact row are all facets of the same fact, and reading
    // them as six separate nodes is worse than reading one sentence.
    final dayClause = 'cycle day ${prediction.cycleDay} of about '
        '${prediction.averageCycleLength}';
    final confidenceClause =
        'estimate confidence ${prediction.confidenceLabel.toLowerCase()}';
    final summary = <String>[
      '${phase.label} phase',
      status.spoken,
      dayClause,
      confidenceClause,
    ].join('. ');

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Semantics(
            container: true,
            label: summary,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  _PhasePill(phase: phase, swatch: swatch),
                  const SizedBox(height: AppSpacing.xl),

                  // The ring carries cycle position; the sentence below carries
                  // the estimate. Splitting them stops the hero from saying the
                  // same number twice in two type sizes.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Large text needs a larger ring, not a clipped one, and
                      // a 320dp screen needs a smaller one.
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final ceiling = scale > 1.3 ? 288.0 : 252.0;
                      final size =
                          constraints.maxWidth.clamp(168.0, ceiling).toDouble();

                      return CycleRing(
                        size: size,
                        strokeWidth:
                            (size * 0.075).clamp(13.0, 19.0).toDouble(),
                        cycleDay: prediction.cycleDay,
                        cycleLength: prediction.averageCycleLength,
                        centerLabel: 'Cycle day',
                        centerValue: '${prediction.cycleDay}',
                        centerCaption:
                            'of about ${prediction.averageCycleLength}',
                        markerColor: swatch.fill,
                        segments: buildCycleSegments(
                          cycleLength: prediction.averageCycleLength,
                          periodLength: prediction.averagePeriodLength,
                          ovulationDay: ovulationDay,
                          colors: phases,
                          showFertile: settings.showFertileWindow,
                          showOvulation: settings.showOvulation,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    status.headline,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                      letterSpacing: -0.3,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    status.detail,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: context.mutedColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _HeroFacts(prediction: prediction),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Exactly one filled action. Once today is already recorded as a
          // period day the filled slot moves to the full log rather than
          // offering a duplicate entry, and the confirmation drops to a quiet
          // row underneath.
          BlurSwap(
            child: KeyedSubtree(
              key: ValueKey(loggedToday),
              child: loggedToday
                  ? _HeroActions(
                      primary: PrimaryButton(
                        label: 'Log today',
                        icon: Icons.edit_note_rounded,
                        onPressed: () => context.go(AppRoutes.log),
                      ),
                      secondary: const _QuietNote(
                        icon: Icons.check_circle_rounded,
                        label: 'Period logged for today',
                        tone: AppColors.success,
                      ),
                    )
                  : _HeroActions(
                      primary: PrimaryButton(
                        label: 'Log period today',
                        icon: Icons.water_drop_rounded,
                        onPressed: () async {
                          await ref
                              .read(cycleTrackerControllerProvider.notifier)
                              .logPeriodStart(DateTime.now());
                          if (!context.mounted) return;
                          showAppToast(
                            context,
                            message: 'Period logged for today',
                          );
                        },
                      ),
                      secondary: TextButton(
                        onPressed: () => context.go(AppRoutes.log),
                        child: const Text('Log symptoms instead'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacks the single primary action above its secondary, so the hierarchy is
/// vertical rather than two equal buttons fighting across a row.
class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        primary,
        const SizedBox(height: AppSpacing.xs),
        secondary,
      ],
    );
  }
}

/// First run: no cycles yet, so no ring and no estimate to dress up.
class _HeroSetup extends ConsumerWidget {
  const _HeroSetup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            'Let\'s set up your cycle',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(color: context.inkColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add the first day of your last period and CycleCare can start '
            'estimating from there.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Log my period',
            icon: Icons.water_drop_rounded,
            onPressed: () => ref
                .read(cycleTrackerControllerProvider.notifier)
                .logPeriodStart(DateTime.now()),
          ),
        ],
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.phase, required this.swatch});

  final CyclePhase phase;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: swatch.fill.withOpacity(context.isDark ? 0.26 : 0.15),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: swatch.border, width: AppStrokes.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_phaseIcon(phase), size: AppSpacing.lg, color: swatch.text),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '${phase.label} phase',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: swatch.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Supporting numbers, set as running text rather than columns of numerals.
///
/// The hero already has one large number in the ring and one large sentence
/// under it; a row of three more bold figures competes with both. Wrapped text
/// keeps them available without promoting them, and survives 200% scale on a
/// 320dp screen where a three-across row does not.
class _HeroFacts extends StatelessWidget {
  const _HeroFacts({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        _HeroFact(
          label: 'Typical cycle',
          value: '${prediction.averageCycleLength} days',
        ),
        _HeroFact(
          label: 'Estimate confidence',
          value: prediction.confidenceLabel,
        ),
      ],
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: context.inkColor,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: text.labelMedium?.copyWith(color: context.mutedColor),
    );
  }
}

/// Quiet centred icon-plus-text row. Used for confirmations and footnotes —
/// anything that states a condition rather than offering an action.
///
/// Not a disabled button: a greyed-out control invites taps that do nothing,
/// while a row that names its state does not. Sized to the minimum touch target
/// so swapping it in for a button does not shift the layout underneath.
class _QuietNote extends StatelessWidget {
  const _QuietNote({
    required this.icon,
    required this.label,
    this.tone,
  });

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: AppSpacing.lg,
              color: tone ?? context.mutedColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.mutedColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The premenstrual window, as a footnote to the hero rather than a card of its
/// own. It qualifies the status directly above it, so giving it a surface would
/// imply it is a separate topic.
class _PmsNote extends StatelessWidget {
  const _PmsNote({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = prediction.daysUntilPms(now);
    if (days == null) return const SizedBox.shrink();

    final label = prediction.isPmsOn(now)
        ? 'You\'re in your PMS window — symptoms often peak now'
        : days <= 0
            ? 'PMS window has started'
            : days == 1
                ? 'PMS window starts tomorrow'
                : 'PMS window starts in about $days days';

    return Reveal(
      index: 1,
      offsetY: AppSpacing.md,
      child: _QuietNote(
        icon: Icons.nights_stay_rounded,
        label: label,
        tone: AppColors.luteal,
      ),
    );
  }
}

// ─── Week ────────────────────────────────────────────────────────────────────

class _WeekSection extends ConsumerWidget {
  const _WeekSection({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cycleTrackerControllerProvider.notifier);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: AppInsets.compactCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(data.selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.inkColor,
                      ),
                ),
              ),
              // Loose-flex plus an end-aligned box: the link keeps half the row
              // as its ceiling so a long label ellipsises instead of pushing
              // the month off-screen at large text, but it still sits flush
              // with the trailing edge instead of floating mid-row.
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _QuietLink(
                    label: 'Full calendar',
                    semanticLabel: 'Open the full calendar',
                    onTap: () => context.go(AppRoutes.calendar),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          WeekStrip(
            selectedDate: data.selectedDate,
            statusFor: data.statusFor,
            hasLogFor: data.hasLogFor,
            onSelected: controller.selectDate,
          ),
        ],
      ),
    );
  }
}

/// Text-plus-chevron secondary action. Visually quiet, but still a full-height
/// touch target and still labelled for assistive technology.
class _QuietLink extends StatelessWidget {
  const _QuietLink({
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.compact);

    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: semanticLabel ?? label,
      excludeChildSemantics: true,
      borderRadius: radius,
      minimumSize: const Size(0, AppLayout.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.accentColor,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppSpacing.lg,
              color: context.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today ───────────────────────────────────────────────────────────────────

class _TodaySection extends ConsumerWidget {
  const _TodaySection({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final today = dateOnly(DateTime.now());
    final log = data.logFor(today);
    final controller = ref.read(cycleTrackerControllerProvider.notifier);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log == null ? 'How are you today?' : 'Today\'s log',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.inkColor,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE d MMMM').format(today),
                      style:
                          text.labelSmall?.copyWith(color: context.mutedColor),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _QuietLink(
                    label: log == null ? 'Add' : 'Edit',
                    semanticLabel: log == null
                        ? 'Add a full log for today'
                        : 'Edit today\'s log',
                    onTap: () {
                      controller.selectDate(today);
                      context.go(AppRoutes.log);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (log == null)
            _QuickMoodRow(
              onPick: (mood) async {
                await controller.saveLog(DailyLog(date: today, mood: mood));
                if (!context.mounted) return;
                showAppToast(context, message: 'Logged $mood for today');
              },
            )
          else
            _LoggedChips(log: log),
        ],
      ),
    );
  }
}

/// One-tap mood entry.
///
/// The fastest possible path from opening the app to having logged something.
/// Most days a user has thirty seconds, not three minutes, and a tracker that
/// demands the full form gets abandoned.
///
/// Laid out as a [Wrap] rather than a six-across row: six fixed columns fit a
/// 360dp screen at default text and nothing else.
class _QuickMoodRow extends StatelessWidget {
  const _QuickMoodRow({required this.onPick});

  final ValueChanged<String> onPick;

  static const _moods = <({String emoji, String label})>[
    (emoji: '😀', label: 'Happy'),
    (emoji: '😌', label: 'Calm'),
    (emoji: '😐', label: 'Focused'),
    (emoji: '😣', label: 'Irritable'),
    (emoji: '😢', label: 'Sad'),
    (emoji: '😰', label: 'Anxious'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final mood in _moods)
          _MoodButton(
            emoji: mood.emoji,
            label: mood.label,
            onTap: () => onPick(mood.label),
          ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      semanticLabel: label,
      semanticHint: 'Log this mood for today',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(AppRadii.control),
      minimumSize: Size.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(
                context.isDark ? 0.18 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(emoji, style: text.titleLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}

class _LoggedChips extends StatelessWidget {
  const _LoggedChips({required this.log});

  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = <String>[
      if (log.flow != null && log.flow != FlowIntensity.none)
        '${log.flow!.label} flow',
      if (log.mood != null && log.mood!.isNotEmpty) log.mood!,
      ...log.symptoms,
      if (log.painLevel > 0) 'Pain ${log.painLevel}/10',
      if (log.waterMl > 0) '${log.waterMl} ml',
      if (log.sleepHours != null) '${log.sleepHours}h sleep',
    ];

    if (items.isEmpty) {
      return Text(
        'Logged, but nothing recorded yet.',
        style: text.bodySmall?.copyWith(color: context.mutedColor),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(
                context.isDark ? 0.20 : 0.10,
              ),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              item,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.isDark ? context.inkColor : context.accentColor,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Phase guidance ──────────────────────────────────────────────────────────

/// Phase guidance on a phase-tinted surface.
///
/// A [PhaseCard] rather than a second white card: the tint plus the leading
/// marker tie the tip to the phase named in the hero, and it keeps the page
/// from becoming a stack of identical rectangles. The emoji sits directly on the
/// tint — wrapping it in its own tinted tile would be a tint inside a tint for
/// one semantic unit.
class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.phase,
    required this.swatch,
    required this.cycleDay,
  });

  final CyclePhase phase;
  final PhaseSwatch swatch;
  final int cycleDay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Keyed off the cycle day so the tip rotates daily but stays stable within
    // a day — a card that changes on every rebuild is unreadable.
    final tip = PhaseGuidance.tipFor(phase, day: cycleDay);

    return PhaseCard(
      swatch: swatch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(tip.emoji, style: text.titleLarge),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.inkColor,
                      ),
                    ),
                    Text(
                      '${phase.label} phase',
                      style: text.labelSmall?.copyWith(color: swatch.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            tip.body,
            style: text.bodySmall?.copyWith(
              color: context.isDark
                  ? context.inkColor.withOpacity(0.84)
                  : context.mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Explore ─────────────────────────────────────────────────────────────────

/// The remaining destinations, as one grouped list on a single quiet surface.
///
/// Six individually elevated tiles read as six competing priorities and stack
/// six shadows down the page. One outlined card with hairline-separated rows
/// says the same thing at a fraction of the visual cost, and it is the shape
/// people already know from platform settings lists.
///
/// One column at every width by choice: the rows carry two lines of text, and a
/// 2- or 3-across grid of them is the first thing to collapse at 200% text
/// scale. The page is width-capped for tablets instead.
class _ExploreList extends StatelessWidget {
  const _ExploreList();

  static const double _iconSize = AppSpacing.huge;
  static const double _textInset = AppSpacing.lg + _iconSize + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    const items =
        <({String emoji, String title, String subtitle, String route})>[
      (
        emoji: '💊',
        title: 'Birth control',
        subtitle: 'Daily check-ins and streaks',
        route: AppRoutes.birthControl,
      ),
      (
        emoji: '🤰',
        title: 'Pregnancy',
        subtitle: 'Week by week and kick counter',
        route: AppRoutes.pregnancy,
      ),
      (
        emoji: '💜',
        title: 'Health conditions',
        subtitle: 'PCOS, endometriosis, PMDD',
        route: AppRoutes.health,
      ),
      (
        emoji: '📚',
        title: 'Learn',
        subtitle: 'Evidence-based articles',
        route: AppRoutes.education,
      ),
      (
        emoji: '🔔',
        title: 'Reminders',
        subtitle: 'Periods, pills, check-ins',
        route: AppRoutes.reminders,
      ),
      (
        emoji: '💑',
        title: 'Share with partner',
        subtitle: 'Read-only cycle summary',
        route: AppRoutes.partner,
      ),
    ];

    final radius = BorderRadius.circular(AppRadii.card);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Divider(
                  height: AppStrokes.hairline,
                  thickness: AppStrokes.hairline,
                  indent: _textInset,
                  endIndent: AppSpacing.lg,
                  color: context.lineColor,
                ),
              _ExploreRow(
                emoji: items[index].emoji,
                title: items[index].title,
                subtitle: items[index].subtitle,
                iconSize: _iconSize,
                onTap: () => context.push(items[index].route),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  const _ExploreRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.iconSize,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      semanticLabel: title,
      semanticHint: subtitle,
      excludeChildSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(
                  context.isDark ? 0.20 : 0.10,
                ),
                borderRadius: BorderRadius.circular(AppRadii.compact),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(emoji, style: text.titleMedium),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.inkColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: text.labelSmall?.copyWith(color: context.mutedColor),
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
    );
  }
}

// ─── Long-gap detection ──────────────────────────────────────────────────────

/// Flags an unusually long gap since the last recorded period.
///
/// Deliberately conservative: nothing is shown before 46 days, because a single
/// long cycle is common and a tracker that cries wolf about it is worse than
/// useless. The copy never names a condition — that is a clinician's call, and
/// the app's job is to prompt the visit, not pre-empt it.
class _AmenorrheaCheck {
  static AmenorrheaResult? evaluate(List<CycleEvent> periods) {
    if (periods.isEmpty) return null;

    final sorted = List<CycleEvent>.from(periods)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final daysSince = dateOnly(DateTime.now())
        .difference(dateOnly(sorted.first.startDate))
        .inDays;

    if (daysSince <= 45) return null;

    final severity = daysSince >= 180
        ? AmenorrheaSeverity.severe
        : daysSince >= 90
            ? AmenorrheaSeverity.moderate
            : AmenorrheaSeverity.mild;

    return AmenorrheaResult(
      severity: severity,
      daysSinceLastPeriod: daysSince,
      lastPeriodDate: sorted.first.startDate,
      description:
          '$daysSince days since your last logged period. ${severity.description}.',
      recommendations: const [
        'Check whether any periods are missing from your log',
        'Note recent changes in stress, weight, travel, or medication',
        'Consider talking to a healthcare provider',
      ],
    );
  }
}

class _AmenorrheaCard extends StatelessWidget {
  const _AmenorrheaCard({required this.result});

  final AmenorrheaResult result;

  @override
  Widget build(BuildContext context) {
    final tone = switch (result.severity) {
      AmenorrheaSeverity.none => AppColors.success,
      AmenorrheaSeverity.mild => AppColors.warning,
      AmenorrheaSeverity.moderate => const Color(0xFFF4732A),
      AmenorrheaSeverity.severe => AppColors.error,
    };

    return InfoBanner(
      icon: Icons.event_busy_rounded,
      tone: tone,
      title: result.severity.displayName,
      message: '${result.description}\n\n'
          'This is an observation from your logs, not a diagnosis.',
    );
  }
}
