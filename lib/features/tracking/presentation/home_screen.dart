import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/phase_bar.dart';
import '../../../widgets/widgets.dart';
import '../../pet/pet_models.dart';
import '../../pet/pet_companion.dart';
import '../../pet/pet_provider.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/amenorrhea_result.dart';
import '../domain/cycle_models.dart';
import '../domain/cycle_phase_model.dart';
import '../domain/phase_guidance.dart';
import 'home_cycle_dial.dart';
import 'home_hormone_chart.dart';

part 'home_sections.dart';
part 'home_week.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home
//
// The redesign's front door, in the order of the approved handoff:
//   greeting -> cycle dial card (SLOT A) -> reference strip + confidence note
//   -> hormone chart card (SLOT B) -> cycle map card (SLOT C) -> check-in ->
//   every phase and window -> week -> care note -> upcoming -> your space ->
//   companion -> privacy line.
//
// One [CyclePhaseModel] is built at the top of the body and passed down, so
// every range on this page agrees with Calendar and Insights.
//
// Forecasts are always framed as estimates, and recorded vs estimated is said
// in words, never by colour alone.
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

/// Re-reads the tracker for pull-to-refresh and the retry action. The failure
/// is swallowed: the provider already carries it into the error branch.
Future<void> _reloadTracker(WidgetRef ref) async {
  ref.invalidate(cycleTrackerControllerProvider);
  try {
    await ref.read(cycleTrackerControllerProvider.future);
  } catch (_) {
    // Reported by the error branch of the screen.
  }
}

/// Safe area, pull to refresh, the width-aware gutter and a content column
/// capped at [AppLayout.maxContentWidth].
class _PageShell extends StatelessWidget {
  const _PageShell({required this.child, required this.onRefresh});

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
          final safe = MediaQuery.paddingOf(context);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              gutter + safe.left,
              safe.top + AppSpacing.md,
              gutter + safe.right,
              AppSpacing.xxxl + safe.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loading: the page's own silhouette, announced once.
class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your cycle',
      liveRegion: true,
      child: ExcludeSemantics(
        child: _PageShell(
          onRefresh: () async {},
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: 120, height: 12),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(width: 240, height: 28),
              SizedBox(height: AppSpacing.xl),
              LoadingSkeleton(height: 420, radius: AppRadii.card),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(height: 48, radius: AppRadii.compact),
              SizedBox(height: AppSpacing.lg),
              LoadingSkeleton(height: 220, radius: AppRadii.card),
            ],
          ),
        ),
      ),
    );
  }
}

/// Load failure: says nothing was lost and offers the retry.
class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PageShell(
      onRefresh: () => _reloadTracker(ref),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.huge),
        child: ErrorRetryView(
          noteTitle: 'We could not load your cycle',
          noteMessage: 'Nothing was lost. Your entries stay on this phone. '
              'Pull down to refresh, or try again.',
          retryLabel: 'Try again',
          onRetry: () => _reloadTracker(ref),
          caption: 'Reference: ${error.runtimeType}',
        ),
      ),
    );
  }
}

// ─── Shared text helpers ─────────────────────────────────────────────────────

/// Caption text. The board uses 9-10 px; production floors it at 11.
TextStyle _caption(BuildContext context) =>
    AppTextStyles.body(fontSize: 11, height: 1.4)
        .copyWith(color: context.mutedColor);

/// Secondary copy inside cards.
TextStyle _small(BuildContext context) =>
    AppTextStyles.body(fontSize: 12, height: 1.45)
        .copyWith(color: context.mutedColor);

/// Row and card titles.
TextStyle _strong(BuildContext context, {double size = 13}) =>
    AppTextStyles.body(fontSize: size, height: 1.3, fontWeight: FontWeight.w600)
        .copyWith(color: context.inkColor);

/// "November 5–9" / "October 23–November 4".
String _longRange(DateTime start, DateTime end) {
  final f = DateFormat('MMMM d');
  if (isSameDate(start, end)) return f.format(start);
  if (start.month == end.month) return '${f.format(start)}–${end.day}';
  return '${f.format(start)}–${f.format(end)}';
}

/// "Nov 5–9" / "Dec 31–Jan 4".
String _shortRange(DateTime start, DateTime end) {
  if (isSameDate(start, end)) return shortDate(start);
  if (start.month == end.month) return '${shortDate(start)}–${end.day}';
  return '${shortDate(start)}–${shortDate(end)}';
}

IconData _phaseIcon(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => AppIcons.period,
      CyclePhase.follicular => AppIcons.basics,
      CyclePhase.ovulation => AppIcons.ovulation,
      CyclePhase.luteal => AppIcons.luteal,
    };

/// How much history the estimate rests on, in plain words.
String _confidenceCopy(CyclePrediction p) {
  return p.estimateExplanation;
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsSyncProvider);
    final prediction = data.prediction;
    final today = dateOnly(DateTime.now());
    final model = CyclePhaseModel.maybeFromPrediction(
      prediction,
      today: today,
      showFertileWindow: settings.showFertileWindow,
      showOvulation: settings.showOvulation,
    );

    var index = 0;
    Widget reveal(Widget child) => Reveal(
          index: (index++).clamp(0, 8),
          offsetY: AppSpacing.md,
          child: child,
        );

    final gap = _longGap(data.periods, today);
    final phase = model?.currentPhase ?? CyclePhase.follicular;

    return _PageShell(
      onRefresh: () => _reloadTracker(ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          reveal(_Greeting(data: data)),
          const SizedBox(height: AppSpacing.lg + AppSpacing.xxs),

          // Alerts lead when they apply: long gap outranks late, late
          // outranks irregular.
          if (gap != null) ...[
            reveal(_GapAlert(result: gap, today: today)),
            const SizedBox(height: AppSpacing.lg),
          ] else if (prediction != null && prediction.isLate) ...[
            reveal(_LateAlert(prediction: prediction, today: today)),
            const SizedBox(height: AppSpacing.lg),
          ] else if (prediction != null &&
              prediction.isIrregular &&
              prediction.cyclesTracked >= 3) ...[
            reveal(_ConfidenceNote(
              key: const ValueKey('home-irregular-alert'),
              title: 'Your cycles vary quite a bit',
              text: 'Lengths have ranged from ${prediction.shortestCycle} to '
                  '${prediction.longestCycle} days, so every estimate here is '
                  'wider than usual. Logging each period narrows it.',
            )),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (prediction != null && model != null) ...[
            reveal(_ExplorerBlock(
              data: data,
              prediction: prediction,
              model: model,
            )),
            const SizedBox(height: AppSpacing.lg),
            reveal(_CycleMapCard(
              model: model,
              phaseBar: (selected, onSelected) =>
                  _phaseBarSlot(model, selected, onSelected),
            )),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            reveal(_NoHistoryCard(today: today)),
            const SizedBox(height: AppSpacing.lg),
          ],

          reveal(_CheckInCard(data: data, today: today)),

          if (prediction != null && model != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            reveal(_AllWindowsCard(
              data: data,
              prediction: prediction,
              model: model,
            )),
          ],

          ListSectionLabel(
            label: 'Your week',
            action: TextButton(
              onPressed: () => context.go(AppRoutes.calendar),
              child: const Text('View calendar'),
            ),
          ),
          _HomeWeek(data: data, today: today),
          const SizedBox(height: AppSpacing.xl + 2),
          if (model != null)
            _CareNote(phase: phase, cycleDay: model.cycleDay),

          if (prediction != null && prediction.upcomingCycles.isNotEmpty) ...[
            ListSectionLabel(
              label: 'Looking a little ahead',
              action: TextButton(
                onPressed: () => context.go(AppRoutes.insights),
                child: const Text('Your patterns'),
              ),
            ),
            _UpcomingCard(forecasts: prediction.upcomingCycles, today: today),
          ],

          const ListSectionLabel(label: 'Your space'),
          const _FeatureGrid(),
          const SizedBox(height: AppSpacing.xl),
          const _CompanionSection(),
          const SizedBox(height: AppSpacing.xl),
          const _PrivacyLine(),
        ],
      ),
    );
  }

  // The design's four-phase bar with its overlay lane, and the phase tabs.
  // Both are driven entirely by the model.
  Widget _phaseBarSlot(
    CyclePhaseModel model,
    CyclePhase selected,
    ValueChanged<CyclePhase> onSelected,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhaseBar(model: model),
          const SizedBox(height: AppSpacing.md),
          PhaseTabs(
            model: model,
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      );
}

// ─── Greeting ────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final name = data.preferences.profileName.trim();

    final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: _small(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(
                  'Your day, at a glance.',
                  style: AppTextStyles.heading(fontSize: 27, letterSpacing: -0.9)
                      .copyWith(color: context.inkColor),
                ),
              ),
            ],
          );
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
        HeaderIconButton(
          icon: AppIcons.ai,
          semanticLabel: 'Ask the CycleCare assistant',
          onTap: () => context.push(AppRoutes.aiChat),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (name.isEmpty)
          HeaderIconButton(
            icon: AppIcons.person,
            semanticLabel: 'Your space and settings',
            onTap: () => context.push(AppRoutes.settings),
          )
        else
          HeaderAvatar(
            initial: name,
            diameter: 42,
            semanticLabel: 'Your space and settings',
            onTap: () => context.push(AppRoutes.settings),
          ),
    ]);
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(alignment: Alignment.centerRight, child: actions),
        const SizedBox(height: AppSpacing.sm),
        heading,
      ]);
    }
    return Row(children: [Expanded(child: heading),
      const SizedBox(width: AppSpacing.md), actions]);
  }
}

// ─── Shared surfaces ─────────────────────────────────────────────────────────

/// The page's paper card: hairline, soft warm depth, 22 radius.
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 17, 16, 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border:
            Border.all(color: context.lineColor, width: AppStrokes.hairline),
        boxShadow: AppElevation.low(context.isDark),
      ),
      child: child,
    );
  }
}

/// A card's DM Sans title with an optional trailing element.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.body(
                fontSize: 16,
                height: 1.3,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w600,
              ).copyWith(color: context.inkColor),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// A condition, not an action: icon plus text at touch-target height so it
/// can stand in for a button without shifting the layout.
class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: AppSpacing.lg, color: context.accent.text),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _small(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dial card ───────────────────────────────────────────────────────────────

/// The cycle dial, the reference strip and the hormone illustration.
///
/// The dial and the chart explore ONE day, held here, so dragging either moves
/// both. That day is presentation state only: the next-period estimate inside
/// the dial stays anchored to today.
class _ExplorerBlock extends StatefulWidget {
  const _ExplorerBlock({
    required this.data,
    required this.prediction,
    required this.model,
  });

  final CycleTrackerState data;
  final CyclePrediction prediction;
  final CyclePhaseModel model;

  @override
  State<_ExplorerBlock> createState() => _ExplorerBlockState();
}

class _ExplorerBlockState extends State<_ExplorerBlock> {
  int? _day;

  /// Today until the person explores, and never outside the cycle: a reload
  /// that shortens the cycle must not leave a selected day that cannot exist.
  int get _selectedDay =>
      (_day ?? widget.model.cycleDay).clamp(1, widget.model.cycleLength);

  void _select(int day) => setState(() => _day = day);

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final day = _selectedDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DialCard(
          data: widget.data,
          prediction: widget.prediction,
          model: model,
          selectedDay: day,
          onDayChanged: _select,
        ),
        const SizedBox(height: AppSpacing.md),
        _ReferenceStrip(prediction: widget.prediction, model: model),
        const SizedBox(height: AppSpacing.lg),
        _HomeDetails(
          title: 'Explore hormone patterns',
          subtitle: 'Illustrative · not your hormone levels',
          child: HormoneChart(
            model: model,
            selectedDay: day,
            onDayChanged: _select,
          ),
        ),
      ],
    );
  }
}

/// The precise cycle dial with the two logging actions beneath it.
class _DialCard extends ConsumerWidget {
  const _DialCard({
    required this.data,
    required this.prediction,
    required this.model,
    required this.selectedDay,
    required this.onDayChanged,
  });

  final CycleTrackerState data;
  final CyclePrediction prediction;
  final CyclePhaseModel model;
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedToday = data.periodFor(model.today) != null;
    final controller = ref.read(cycleTrackerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The dial brings its own card frame, eyebrow, "Your cycle" heading,
        // day status and next-period estimate row.
        CycleDial(
          model: model,
          selectedDay: selectedDay,
          onDayChanged: onDayChanged,
          onExplainEstimate: () => showAppSheet<void>(
            context: context,
            title: 'About this estimate',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Text(
                _confidenceCopy(prediction),
                style: AppTextStyles.body(fontSize: 14)
                    .copyWith(color: context.inkColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Flex(
          direction: MediaQuery.textScalerOf(context).scale(14) > 18
              ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: MediaQuery.textScalerOf(context).scale(14) > 18
              ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            Flexible(
              child: FilledButton.icon(
                onPressed: () {
                  controller.selectDate(model.today);
                  context.go(AppRoutes.log);
                },
                icon: const Icon(AppIcons.plus, size: 18),
                label: const Text(
                  'Log today',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm, height: AppSpacing.sm),
            Flexible(
              child: loggedToday
                  ? const _QuietNote(
                      icon: AppIcons.check,
                      label: 'Period logged',
                    )
                  : OutlinedButton.icon(
                      onPressed: () async {
                        await controller.logPeriodStart(model.today);
                        if (!context.mounted) return;
                        showAppToast(
                          context,
                          message: 'Period logged for today',
                        );
                      },
                      icon: const Icon(AppIcons.period, size: 18),
                      label: const Text(
                        'Log period',
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Reference strip ─────────────────────────────────────────────────────────

/// Average cycle, average period, and how many cycles the estimate rests on.
/// The third figure is a button that opens the confidence explanation; with
/// thin history that explanation is always shown, and the first two figures
/// say they come from the user's settings rather than from measurement.
class _ReferenceStrip extends StatefulWidget {
  const _ReferenceStrip({required this.prediction, required this.model});

  final CyclePrediction prediction;
  final CyclePhaseModel model;

  @override
  State<_ReferenceStrip> createState() => _ReferenceStripState();
}

class _ReferenceStripState extends State<_ReferenceStrip> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final learning = !widget.model.history.isSufficient;
    final cycles = p.cyclesTracked;
    final motion = Motion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flex(
          direction: MediaQuery.textScalerOf(context).scale(14) > 18
              ? Axis.vertical
              : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: MediaQuery.textScalerOf(context).scale(14) > 18
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _RefStat(
                value: '${p.averageCycleLength}',
                unit: 'days',
                label: cycles == 0 ? 'Cycle, from settings' : 'Average cycle',
              ),
            ),
            Flexible(
              child: _RefStat(
                value: '${p.averagePeriodLength}',
                unit: 'days',
                label: 'Average period',
              ),
            ),
            Flexible(
              flex: 1,
              child: Pressable(
                onTap: () => setState(() => _open = !_open),
                semanticLabel:
                    '$cycles ${cycles == 1 ? 'cycle' : 'cycles'} '
                    'behind this estimate',
                semanticHint: _open
                    ? 'Hide the explanation'
                    : 'Show how this estimate was calculated',
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(AppRadii.compact),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: context.lineColor)),
                  ),
                  child: _RefStat(
                    value: '$cycles',
                    unit: cycles == 1 ? 'cycle' : 'cycles',
                    label: 'Behind this estimate',
                    trailingIcon: AppIcons.help,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          p.variationSummary,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
        ),
        if (learning) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Still learning · tap the cycle count for details',
            style: _caption(context),
          ),
        ],
        AnimatedSize(
          duration: motion(AppDurations.normal),
          curve: AppCurves.out,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _ConfidenceNote(
                    title: learning ? 'Still learning your cycle' : null,
                    text: _confidenceCopy(p),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Secondary context stays one tap away without competing with today's actions.
class _HomeDetails extends StatelessWidget {
  const _HomeDetails({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      key: PageStorageKey(title),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
      title: Text(title, style: _strong(context)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: _caption(context)),
      children: [child],
    ),
  );
}

class _RefStat extends StatelessWidget {
  const _RefStat({
    required this.value,
    required this.unit,
    required this.label,
    this.trailingIcon,
  });

  final String value;
  final String unit;
  final String label;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: AppTextStyles.body(
                fontSize: 19,
                height: 1.3,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w600,
              ).copyWith(color: context.inkColor),
              children: [
                TextSpan(text: ' $unit', style: _caption(context)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _caption(context),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 3),
                Icon(trailingIcon, size: 12, color: context.mutedColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceNote extends StatelessWidget {
  const _ConfidenceNote({super.key, required this.text, this.title});

  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.compact + 4),
        border: Border.all(color: context.lineColor, width: AppStrokes.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(AppIcons.info, size: 16, color: context.mutedColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: _strong(context, size: 12)),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(text, style: _small(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No history ──────────────────────────────────────────────────────────────

/// Nothing logged: no dates are invented. One action starts the model.
class _NoHistoryCard extends ConsumerWidget {
  const _NoHistoryCard({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _HomeCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: EmptyStateView(
        icon: AppIcons.cycle,
        title: 'Let’s find your rhythm.',
        message: 'Add the first day of your last period and CycleCare can '
            'start estimating. Until then there are no dates to show, and '
            'nothing here is a guess.',
        actionLabel: 'Log my period',
        actionIcon: AppIcons.period,
        onAction: () async {
          await ref
              .read(cycleTrackerControllerProvider.notifier)
              .logPeriodStart(today);
          if (!context.mounted) return;
          showAppToast(context, message: 'Period logged for today');
        },
      ),
    );
  }
}
