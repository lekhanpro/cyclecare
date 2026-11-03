import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/haptics.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/widgets.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';
import '../domain/month_summary.dart';
import 'calendar_year_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Calendar
//
// Three stacked blocks, in the order they are read: the month grid, the detail
// for whichever day is selected, then a key that says in words what every
// marker means. The detail lives *below* the grid rather than floating over it
// — the whole point of tapping a date is to compare it with its neighbours,
// and an overlay covers exactly the days you are comparing against. It sits
// directly under the grid because it is the thing that answers the tap; the
// key is reference material and goes last, where it is available without being
// in the way of the two surfaces that change.
//
// The screen sits on the plain theme canvas. It used to sit on a phase-tinted
// gradient with frosted-glass panels, which looked lovely and worked against
// the one job this screen has: the grid encodes meaning in hue — rose for
// period, mint for fertile, violet for ovulation — and washing the entire
// background in whichever hue the selected day happens to be lowers the
// contrast of the very cells the user is trying to tell apart.
//
// So depth runs in one direction only. The grid floats, because it is the
// content; the key sits flat on the page, because it is reference; the detail
// card rests between them. Colour follows the same rule — the one saturated
// surface on the screen is the band at the top of the detail card, which is
// also the only place with enough colour behind it for glass to have anything
// to sample.
//
// Months page horizontally. A tracker is scrubbed through far more often than
// it is tapped, and arrows alone make that a chore.
// ─────────────────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Page 1200 is "today", giving 100 years of travel in either direction
  /// without ever needing to rebuild the controller.
  static const _originPage = 1200;

  late final PageController _pageController;
  late final DateTime _originMonth;
  late DateTime _month;

  /// Month grid or twelve-month overview.
  bool _yearMode = false;
  late int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _originMonth = DateTime(now.year, now.month);
    _month = _originMonth;
    _pageController = PageController(initialPage: _originPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_originMonth.year, _originMonth.month + (page - _originPage));

  void _goToMonth(DateTime month) {
    final motion = Motion.of(context);
    final delta =
        (month.year - _originMonth.year) * 12 +
        (month.month - _originMonth.month);
    final page = _originPage + delta;

    // Changing month is navigation, not decoration: fast, and instant when the
    // user has asked for reduced motion.
    if (motion.reduced) {
      _pageController.jumpToPage(page);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: motion(AppDurations.fast),
      curve: AppCurves.inOut,
    );
  }

  int _pageFor(DateTime month) =>
      _originPage +
      (month.year - _originMonth.year) * 12 +
      (month.month - _originMonth.month);

  /// From the year view into one month. The month pager is not in the tree
  /// while the year view shows, so it is moved once it has been rebuilt;
  /// jumping before that would be ignored and land on today instead.
  void _openMonth(DateTime month) {
    Haptics.selection();
    setState(() {
      _yearMode = false;
      _month = DateTime(month.year, month.month);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_pageFor(month));
      }
    });
  }

  void _setYearMode(bool year) {
    if (year == _yearMode) return;
    Haptics.selection();
    setState(() {
      _yearMode = year;
      if (year) _year = _month.year;
    });
    if (!year) _openMonth(_month);
  }

  void _jumpToToday() {
    final today = DateTime.now();
    Haptics.selection();
    ref.read(cycleTrackerControllerProvider.notifier).selectDate(today);
    _goToMonth(DateTime(today.year, today.month));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    final settings = ref.watch(appSettingsSyncProvider);
    final data = state.valueOrNull;

    // "Today" is only an action when it would actually move something.
    final today = DateTime.now();
    final alreadyOnToday =
        data != null &&
        isSameDate(data.selectedDate, today) &&
        _month.year == today.year &&
        _month.month == today.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            // The label changes with the state so the dimmed button explains
            // itself instead of looking broken.
            tooltip: alreadyOnToday ? 'Already on today' : 'Jump to today',
            onPressed: data == null || alreadyOnToday ? null : _jumpToToday,
            icon: const Icon(Icons.today_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: state.when(
        loading: () => const _CalendarLoading(),
        error: (_, __) => _CalendarError(
          onRetry: () => ref.invalidate(cycleTrackerControllerProvider),
        ),
        data: (value) => _content(value, settings.weekStart),
      ),
    );
  }

  Widget _content(CycleTrackerState data, WeekStart weekStart) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Everything is measured from the width the content actually gets,
          // never from the viewport. A tablet used to hand the grid its full
          // width, and a square-ish cell multiplied by six rows made the card
          // taller than the screen.
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
          final contentWidth = math.min(
            constraints.maxWidth - gutter * 2,
            AppLayout.maxContentWidth,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.sm,
              gutter,
              AppSpacing.xxl,
            ),
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ViewToggle(year: _yearMode, onChanged: _setYearMode),
                    const SizedBox(height: AppSpacing.md),
                    if (_yearMode)
                      Reveal(
                        child: CalendarYearView(
                          year: _year,
                          statusFor: data.statusFor,
                          weekStart: weekStart,
                          onOpenMonth: _openMonth,
                          onYearChanged: (y) => setState(() => _year = y),
                        ),
                      )
                    else ...[
                      Reveal(
                        child: _MonthSummaryStrip(
                          summary: MonthSummary.of(
                            _month,
                            statusFor: data.statusFor,
                            hasLogFor: data.hasLogFor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Reveal(child: _monthPager(data, weekStart, contentWidth)),
                      const SizedBox(height: AppSpacing.lg),
                      Reveal(index: 1, child: _DayDetail(data: data)),
                    ],
                    if (data.periods.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Reveal(
                        index: 2,
                        child: InfoBanner(
                          icon: Icons.water_drop_outlined,
                          title: 'No periods recorded yet',
                          message:
                              'Mark the period you are on, or your most recent '
                              'one, and the calendar starts filling in '
                              'predictions from there.',
                          actionLabel: 'Mark a period',
                          onAction: () =>
                              _openPeriodEditor(context, ref, data, null),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const Reveal(index: 3, child: _CalendarKey()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The month grid. [CycleCalendar] brings its own card surface, so this adds
  /// none of its own — one semantic unit, one surface.
  Widget _monthPager(
    CycleTrackerState data,
    WeekStart weekStart,
    double width,
  ) {
    return SizedBox(
      height: CycleCalendar.pageHeight(context, width),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _month = _monthForPage(page)),
        itemBuilder: (context, page) {
          return CycleCalendar(
            month: _monthForPage(page),
            selectedDate: data.selectedDate,
            statusFor: data.statusFor,
            hasLogFor: data.hasLogFor,
            weekStart: weekStart,
            // The key lives below the grid instead, where it can explain each
            // state in words without crowding the dates.
            showLegend: false,
            onSelected: ref
                .read(cycleTrackerControllerProvider.notifier)
                .selectDate,
            onMonthChanged: _goToMonth,
          );
        },
      ),
    );
  }
}

// ─── Loading and error ───────────────────────────────────────────────────────

class _CalendarLoading extends StatelessWidget {
  const _CalendarLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: AppSpacing.xxl,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Text(
              'Opening your calendar',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Scrollable so the message and its retry stay reachable at large text
    // sizes on a short screen.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Could not open your calendar',
            message:
                'Your saved cycles could not be read just now. Nothing '
                'has been lost — try loading them again.',
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ),
      ),
    );
  }
}

// ─── Calendar key ────────────────────────────────────────────────────────────

/// The shape a marker takes in the grid. Shape carries the same information as
/// colour, so the key stays readable without it: a capsule spans consecutive
/// days, a tile marks a single one, a ring marks a day that has a log.
enum _KeyShape { range, day, dot }

class _KeyEntry {
  const _KeyEntry({
    required this.label,
    required this.shape,
    required this.outlined,
    this.swatch,
  });

  /// One or two words. The grid's states are explained in full sentences on the
  /// detail card; repeating those sentences here is what made the key the
  /// tallest block on the screen.
  final String label;
  final _KeyShape shape;

  /// Outlined means forecast. Filled means recorded. The grid uses the same
  /// rule, so the key teaches it rather than restating it.
  final bool outlined;
  final PhaseSwatch? swatch;
}

/// The grid's marker vocabulary, compressed to one flowing row.
///
/// This was six swatch-and-sentence pairs in a two-column grid, which gave a
/// reference table more vertical space than the calendar's own detail card. A
/// key is consulted once and then never again, so it gets the quietest
/// treatment on the page: no card, no shadow, short labels, and a single
/// wrapping line of chips that collapses from one row to two or three as the
/// width or the text size demands.
class _CalendarKey extends StatelessWidget {
  const _CalendarKey();

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final entries = <_KeyEntry>[
      _KeyEntry(
        label: 'Period',
        shape: _KeyShape.range,
        outlined: false,
        swatch: phases.period,
      ),
      _KeyEntry(
        label: 'Expected',
        shape: _KeyShape.range,
        outlined: true,
        swatch: phases.predicted,
      ),
      _KeyEntry(
        label: 'Fertile',
        shape: _KeyShape.range,
        outlined: false,
        swatch: phases.fertile,
      ),
      _KeyEntry(
        label: 'Ovulation',
        shape: _KeyShape.day,
        outlined: false,
        swatch: phases.ovulation,
      ),
      _KeyEntry(
        label: 'PMS',
        shape: _KeyShape.range,
        outlined: true,
        swatch: phases.luteal(),
      ),
      const _KeyEntry(label: 'Logged', shape: _KeyShape.dot, outlined: true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(
                  AppIcons.help,
                  size: AppSpacing.lg,
                  color: context.subtleColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                // Wraps rather than running past the page on a narrow phone
                // at large text.
                Expanded(
                  child: Text(
                    'What the markers mean',
                    style: textTheme.labelSmall?.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              for (final entry in entries)
                MergeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _KeySwatch(entry: entry),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        entry.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeySwatch extends StatelessWidget {
  const _KeySwatch({required this.entry});

  final _KeyEntry entry;

  /// Shorter than the old swatch. At label size a 16dp block is the loudest
  /// thing in the row it is annotating.
  static const _height = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final swatch = entry.swatch;
    final tone = swatch?.fill ?? context.accentColor;
    final border = swatch?.border ?? context.lineColor;

    return ExcludeSemantics(
      child: Container(
        // A capsule reads as "these days run together"; a tile reads as one
        // day on its own. That difference survives without colour.
        width: entry.shape == _KeyShape.range
            ? _height + AppSpacing.sm
            : _height,
        height: _height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: entry.shape == _KeyShape.dot
              ? Colors.transparent
              : entry.outlined
              ? swatch?.surface
              : tone,
          borderRadius: BorderRadius.circular(
            entry.shape == _KeyShape.range ? AppRadii.pill : AppRadii.connected,
          ),
          border: entry.outlined && entry.shape != _KeyShape.dot
              ? Border.all(color: border, width: AppStrokes.hairline)
              : null,
        ),
        // The log marker is the dot the grid paints under a day number, at the
        // same size, so the key and the grid are recognisably the same mark.
        child: entry.shape == _KeyShape.dot
            ? Container(
                width: AppSpacing.xs,
                height: AppSpacing.xs,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}
// ─── Shared layout rule ──────────────────────────────────────────────────────

/// Narrowest a labelled action stays readable, and the same for a date field.
const _minActionWidth = 152.0;
const _minFieldWidth = 132.0;

/// Two controls side by side stop being readable on a 320dp screen or at large
/// text sizes, so they stack rather than ellipse. Measured against the width the
/// row actually has, not the screen's, so it holds inside cards and sheets too.
bool _stacksAt(BuildContext context, double width, double minimumItemWidth) {
  final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
  return width < (minimumItemWidth * 2 + AppSpacing.md) * scale;
}

// ─── Selected day detail ─────────────────────────────────────────────────────

/// Everything the detail card needs to describe a day without leaning on
/// colour: a word for the state, a sentence explaining it, an icon, and the
/// same filled-versus-outlined treatment the grid uses.
class _DayMarker {
  const _DayMarker({
    required this.title,
    required this.note,
    required this.icon,
    required this.outlined,
    this.swatch,
  });

  final String title;
  final String note;
  final IconData icon;
  final bool outlined;
  final PhaseSwatch? swatch;

  static _DayMarker of(DayStatus status, PhaseColors phases) =>
      switch (status) {
        DayStatus.period => _DayMarker(
          title: 'Period day',
          note: 'Recorded by you, and shown filled on the calendar.',
          icon: AppIcons.period,
          outlined: false,
          swatch: phases.period,
        ),
        // Same glyph as a recorded period on purpose: the forecast is the same
        // event, and what separates it is the outlined treatment the grid and
        // this badge both use. A second glyph would imply a second thing.
        DayStatus.predictedPeriod => _DayMarker(
          title: 'Period expected',
          note: 'Predicted, not recorded — outlined on the calendar.',
          icon: AppIcons.period,
          outlined: true,
          swatch: phases.predicted,
        ),
        DayStatus.fertile => _DayMarker(
          title: 'Fertile window',
          note: 'Estimated from your average cycle length.',
          icon: AppIcons.fertile,
          outlined: false,
          swatch: phases.fertile,
        ),
        DayStatus.ovulation => _DayMarker(
          title: 'Ovulation estimate',
          note: 'A single estimated day, marked on its own in the grid.',
          icon: AppIcons.ovulation,
          outlined: false,
          swatch: phases.ovulation,
        ),
        DayStatus.pms => _DayMarker(
          title: 'PMS window',
          note: 'Predicted premenstrual days before your next period.',
          icon: AppIcons.pms,
          outlined: true,
          swatch: phases.luteal(),
        ),
        DayStatus.normal => const _DayMarker(
          title: 'No markers',
          note: 'Nothing recorded or predicted for this day.',
          icon: AppIcons.methodNone,
          outlined: true,
        ),
      };
}

/// The selected day, answered in full.
///
/// Built as a banded card: a saturated phase strip carrying the date, the state
/// and the cycle day, then a quiet half holding the note, the log and the
/// actions. The previous version washed the whole card in the phase's pale
/// surface tint, which put card and page within a few percent of the same
/// lightness and so read as one soft field — the same mistake the home
/// screen's first hero made. Concentrating the colour into a band and leaving
/// the rest near-white is what gives the card an edge and a reading order.
///
/// That band is also the only place on this screen with enough colour behind
/// it for a blur to sample, which is why the marker badge is the screen's one
/// glass surface.
class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);
    final selected = data.selectedDate;
    final log = data.logFor(selected);
    final period = data.periodFor(selected);
    final marker = _DayMarker.of(data.statusFor(selected), phases);
    final cycleDay = _cycleDayFor(selected);
    final isToday = isSameDate(selected, DateTime.now());

    final dateLine = isToday
        ? '${DateFormat('EEEE, MMM d').format(selected)} · Today'
        : DateFormat('EEEE, MMM d').format(selected);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          marker.note,
          style: textTheme.bodySmall?.copyWith(color: context.mutedColor),
        ),
        if (period == null && data.prediction != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${data.prediction!.estimateBasis} '
            '${data.prediction!.variationSummary}',
            style: textTheme.bodySmall?.copyWith(color: context.mutedColor),
          ),
        ],
        if (period?.excludeFromPredictions == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cycle excluded from estimates. Record retained.'
            '${period!.predictionExclusionReason == null ? '' : ' ${period.predictionExclusionReason}'}',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (log == null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                AppIcons.notes,
                size: AppSpacing.lg,
                color: context.subtleColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nothing logged for this day yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.mutedColor,
                  ),
                ),
              ),
            ],
          )
        else
          _LogSummary(log: log),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final logButton = PrimaryButton(
              label: log == null ? 'Add log' : 'Edit log',
              icon: AppIcons.notes,
              // Declarative navigation, so the Log tab, the back gesture and
              // the shell's transitions all behave the way they do everywhere
              // else. The log reads the same selected date this card shows.
              onPressed: () => context.go(AppRoutes.log),
            );
            final periodButton = PrimaryButton(
              label: period == null ? 'Mark period' : 'Edit dates',
              icon: AppIcons.period,
              outlined: true,
              onPressed: () => _openPeriodEditor(context, ref, data, period),
            );

            if (_stacksAt(context, constraints.maxWidth, _minActionWidth)) {
              return Column(
                children: [
                  logButton,
                  const SizedBox(height: AppSpacing.sm),
                  periodButton,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: logButton),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: periodButton),
              ],
            );
          },
        ),
        if (period != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _removePeriod(context, ref, period),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remove period'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );

    final radius = BorderRadius.circular(AppRadii.card);

    return AppCard(
      // Raised, not floating: the grid above is the screen's lead surface, and
      // two lifted cards on one page is the same as neither being lifted.
      emphasis: CardEmphasis.raised,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayBand(marker: marker, dateLine: dateLine, cycleDay: cycleDay),
            Padding(padding: AppInsets.card, child: body),
          ],
        ),
      ),
    );
  }

  /// Cycle day for an arbitrary date, counted from the period that opened it.
  /// Null for dates before any recorded period, where the number would be
  /// meaningless rather than zero.
  int? _cycleDayFor(DateTime date) {
    final target = dateOnly(date);
    final starts = <DateTime>{
      for (final period in data.periods) dateOnly(period.startDate),
    }.toList()..sort((a, b) => b.compareTo(a));

    for (final start in starts) {
      if (!start.isAfter(target)) {
        return target.difference(start).inDays + 1;
      }
    }
    return null;
  }

  Future<void> _removePeriod(
    BuildContext context,
    WidgetRef ref,
    CycleEvent period,
  ) async {
    final controller = ref.read(cycleTrackerControllerProvider.notifier);
    final confirmed = await confirmAction(
      context,
      title: 'Remove this period?',
      message:
          'The recorded dates will be deleted and your predictions '
          'will be recalculated without them.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;

    await controller.deletePeriod(period.id);
    if (!context.mounted) return;
    showAppToast(context, message: 'Period removed', kind: ToastKind.info);
  }
}

/// The detail card's coloured strip: date, state, cycle day.
///
/// A marked day takes the phase's *hero* stops rather than its pale gradient.
/// Those are the two-stop sets picked so white ink clears 4.5:1 — the contrast
/// table on `AppColors.menstrualHero` lists the figures — and they are the only
/// phase colours in the system allowed under white text.
///
/// An unmarked day has no phase, so it gets no colour either: a quiet neutral
/// strip in page ink. Inventing a hue for "nothing here" would make the one
/// state meaning *absence* the loudest in the set, and the palette accent is
/// not safe under white text across all eight themes.
class _DayBand extends StatelessWidget {
  const _DayBand({
    required this.marker,
    required this.dateLine,
    required this.cycleDay,
  });

  final _DayMarker marker;
  final String dateLine;
  final int? cycleDay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dark = context.isDark;
    final swatch = marker.swatch;
    final ink = HeroInk.of(context);

    final onColor = swatch != null;
    final primary = onColor ? ink.primary : context.inkColor;
    final secondary = onColor ? ink.secondary : context.mutedColor;

    // Announced as one unit so a screen reader hears the whole answer — date,
    // state, cycle day — the moment a new date is chosen.
    final content = Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarkerBadge(marker: marker, onColor: onColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLine,
                  style: text.labelMedium?.copyWith(color: secondary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  marker.title,
                  style: text.titleLarge?.copyWith(
                    color: primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (cycleDay != null) ...[
            const SizedBox(width: AppSpacing.md),
            // Plain type rather than a chip. A translucent plate here would
            // lighten the gradient under its own label, and the hero stops'
            // contrast margin has nothing spare to pay for that.
            Semantics(
              label: 'Cycle day $cycleDay',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Cycle day',
                    style: text.labelSmall?.copyWith(color: secondary),
                  ),
                  Text(
                    '$cycleDay',
                    style: text.headlineSmall?.copyWith(
                      color: primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (!onColor) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: dark
              ? context.elevatedCardColor
              : context.lineColor.withOpacity(0.38),
          border: Border(
            bottom: BorderSide(
              color: context.lineColor,
              width: AppStrokes.hairline,
            ),
          ),
        ),
        child: Padding(padding: AppInsets.card, child: content),
      );
    }

    // Deepened toward the page in dark mode, for the reason [PhaseHero] gives:
    // the hero stops are tuned to lead a cream page, and a block that bright
    // over a near-black canvas glares rather than leads.
    final stops = dark
        ? <Color>[
            Color.lerp(swatch.hero.first, AppColors.darkBg, 0.34)!,
            Color.lerp(swatch.hero.last, AppColors.darkBg, 0.52)!,
          ]
        : swatch.hero;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: stops,
        ),
      ),
      child: Stack(
        children: [
          // Off-centre highlight, held at the hero's own 0.10 ceiling. The
          // contrast figures those stops were chosen for assume this wash, so
          // a brighter one silently breaks them.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, -0.9),
                    radius: 1.3,
                    colors: [
                      Colors.white.withOpacity(dark ? 0.07 : 0.10),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: AppInsets.card, child: content),
        ],
      ),
    );
  }
}

/// The state's glyph, as a 48dp plate.
///
/// On the coloured band this is the screen's one glass surface: there is a
/// saturated gradient behind it to blur and resaturate, which is the condition
/// [GlassSurface] exists for. It carries an icon and never text — the glass
/// fill lightens the gradient under it, which still clears the 3:1 floor a
/// graphical object needs but not the 4.5:1 a label needs, so the words stay
/// on the bare gradient beside it.
///
/// Off the band there is nothing to sample, so it falls back to a flat
/// hairline-bordered plate rather than rendering as the grey box glass becomes
/// on a near-white surface.
class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({required this.marker, required this.onColor});

  final _DayMarker marker;

  /// True when this badge sits on the band's phase gradient.
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.control);
    final swatch = marker.swatch;

    if (onColor) {
      return ExcludeSemantics(
        child: GlassSurface(
          borderRadius: radius,
          padding: EdgeInsets.zero,
          child: SizedBox.square(
            dimension: AppLayout.minTouchTarget,
            child: Center(
              child: Icon(
                marker.icon,
                size: AppSpacing.xl,
                color: HeroInk.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: swatch?.border ?? context.lineColor,
            width: AppStrokes.hairline,
          ),
        ),
        child: Icon(
          marker.icon,
          size: AppSpacing.xl,
          color: swatch?.text ?? context.mutedColor,
        ),
      ),
    );
  }
}

class _LogSummary extends StatelessWidget {
  const _LogSummary({required this.log});

  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final entries = <({IconData icon, String text})>[
      if (log.flow != null && log.flow != FlowIntensity.none)
        (icon: AppIcons.flow, text: 'Flow: ${log.flow!.label}'),
      if (log.mood != null && log.mood!.isNotEmpty)
        (icon: AppIcons.moodEnergetic, text: 'Mood: ${log.mood}'),
      if (log.symptoms.isNotEmpty)
        (icon: AppIcons.pain, text: log.symptoms.join(', ')),
      if ((log.painLevel ?? 0) > 0)
        (icon: AppIcons.symptoms, text: 'Pain ${log.painLevel}/10'),
      if (log.temperatureCelsius != null)
        (
          icon: AppIcons.temperature,
          text: '${log.temperatureCelsius!.toStringAsFixed(2)} °C',
        ),
      if (log.weightKg != null)
        (icon: AppIcons.weight, text: '${log.weightKg!.toStringAsFixed(1)} kg'),
      if (log.sleepHours != null)
        (icon: AppIcons.sleep, text: '${log.sleepHours}h sleep'),
      if ((log.waterMl ?? 0) > 0)
        (icon: AppIcons.water, text: '${log.waterMl} ml water'),
      if (log.notes.isNotEmpty) (icon: AppIcons.notes, text: log.notes),
    ];

    if (entries.isEmpty) {
      return Text(
        'Logged, but no details recorded.',
        style: textTheme.bodyMedium?.copyWith(color: context.mutedColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Logged this day',
            style: textTheme.labelSmall?.copyWith(color: context.mutedColor),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  entry.icon,
                  size: AppSpacing.lg,
                  color: context.accentColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.isDark
                          ? context.inkColor.withOpacity(0.86)
                          : context.mutedColor,
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

// ─── Period date editor ──────────────────────────────────────────────────────

Future<void> _openPeriodEditor(
  BuildContext context,
  WidgetRef ref,
  CycleTrackerState data,
  CycleEvent? existing,
) async {
  final controller = ref.read(cycleTrackerControllerProvider.notifier);
  final defaultStart = existing?.startDate ?? data.selectedDate;
  final defaultEnd = existing?.endDate;

  final result = await showAppSheet<_PeriodRange>(
    context: context,
    title: existing == null ? 'Mark period' : 'Edit period dates',
    child: _PeriodEditor(
      start: defaultStart,
      end: defaultEnd,
      existing: existing,
    ),
  );
  if (result == null) return;

  await controller.upsertPeriod(
    existingId: existing?.id,
    startDate: result.start,
    endDate: result.end,
    flow: result.flow,
    symptoms: existing?.symptoms ?? const [],
    notes: existing?.notes ?? '',
    excludeFromPredictions: result.excluded,
    predictionExclusionReason: result.reason,
  );

  if (!context.mounted) return;
  showAppToast(
    context,
    message: existing == null ? 'Period saved' : 'Period updated',
  );
}

class _PeriodRange {
  const _PeriodRange(
    this.start,
    this.end,
    this.flow,
    this.excluded,
    this.reason,
  );

  final DateTime start;
  final DateTime? end;
  final FlowIntensity flow;
  final bool excluded;
  final String? reason;
}

/// Start/end/flow editor for a period.
///
/// Replaces the previous one-tap "add period" that silently guessed an end date
/// from the average. Guessing is fine for a prediction; it is not fine for a
/// record the predictions are then computed from.
class _PeriodEditor extends StatefulWidget {
  const _PeriodEditor({required this.start, required this.end, this.existing});

  final DateTime start;
  final DateTime? end;
  final CycleEvent? existing;

  @override
  State<_PeriodEditor> createState() => _PeriodEditorState();
}

class _PeriodEditorState extends State<_PeriodEditor> {
  late DateTime _start;
  late DateTime _end;
  late bool _endRecorded;
  FlowIntensity _flow = FlowIntensity.medium;
  bool _excluded = false;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _start = dateOnly(widget.start);
    _end = dateOnly(widget.end ?? widget.start);
    _endRecorded = widget.end != null;
    _flow = widget.existing?.flow ?? FlowIntensity.medium;
    _excluded = widget.existing?.excludeFromPredictions ?? false;
    _reason = TextEditingController(
      text: widget.existing?.predictionExclusionReason ?? '',
    );
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = dateOnly(picked);
        // Keeping end >= start here avoids an invalid range ever reaching the
        // controller, where it would be silently clamped instead of corrected.
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = dateOnly(picked);
        if (_end.isBefore(_start)) _start = _end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _end.difference(_start).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final started = _DateField(
              label: 'Started',
              value: _start,
              onTap: () => _pick(isStart: true),
            );
            if (!_endRecorded) return started;
            final ended = _DateField(
              label: 'Ended',
              value: _end,
              onTap: () => _pick(isStart: false),
            );

            if (_stacksAt(context, constraints.maxWidth, _minFieldWidth)) {
              return Column(
                children: [
                  started,
                  const SizedBox(height: AppSpacing.sm),
                  ended,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: started),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: ended),
              ],
            );
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('End date recorded'),
          subtitle: const Text(
            'Switch on only when you know when bleeding ended.',
          ),
          value: _endRecorded,
          onChanged: (value) => setState(() => _endRecorded = value),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          !_endRecorded
              ? 'Duration unknown — end not recorded'
              : days == 1
              ? '1 day'
              : '$days days',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.mutedColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            'Typical flow',
            style: textTheme.titleSmall?.copyWith(color: context.inkColor),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final flow in FlowIntensity.values)
              // Very heavy is stored and shown, but has no control until the
              // redesigned flow picker ships.
              if (flow != FlowIntensity.none && flow != FlowIntensity.veryHeavy)
                SelectableChip(
                  label: flow.label,
                  selected: _flow == flow,
                  accent: AppColors.period,
                  onSelected: (_) => setState(() => _flow = flow),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Exclude this cycle from estimates'),
          subtitle: const Text(
            'From this period start to the next. Your record '
            'stays visible; neighbouring cycles are never joined.',
          ),
          value: _excluded,
          onChanged: (value) => setState(() => _excluded = value),
        ),
        if (_excluded)
          TextField(
            controller: _reason,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
          ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'Save period',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.of(context).pop(
            _PeriodRange(
              _start,
              _endRecorded ? _end : null,
              _flow,
              _excluded,
              _excluded && _reason.text.trim().isNotEmpty
                  ? _reason.text.trim()
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formatted = DateFormat('MMM d, yyyy').format(value);
    final radius = BorderRadius.circular(AppRadii.control);

    return Pressable(
      onTap: onTap,
      scale: 0.97,
      borderRadius: radius,
      semanticLabel: '$label $formatted',
      semanticHint: 'Change date',
      excludeChildSemantics: true,
      child: Container(
        padding: AppInsets.control,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius,
          border: Border.all(color: context.lineColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              formatted,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month summary ───────────────────────────────────────────────────────────

/// Three counts for the month on screen. Recorded and forecast period days are
/// separate numbers, so an estimate is never presented as a record.
class _MonthSummaryStrip extends StatelessWidget {
  const _MonthSummaryStrip({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final period = summary.periodDays > 0
        ? '${summary.periodDays}'
        : summary.predictedPeriodDays > 0
        ? '~${summary.predictedPeriodDays}'
        : '0';
    final periodLabel =
        summary.periodDays > 0 || summary.predictedPeriodDays == 0
        ? 'Period days'
        : 'Expected period';

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            icon: AppIcons.period,
            swatch: phases.period,
            value: period,
            label: periodLabel,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            icon: AppIcons.fertile,
            swatch: phases.fertile,
            value: '${summary.fertileDays}',
            label: 'Fertile days',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            icon: AppIcons.notes,
            swatch: phases.ovulation,
            value: '${summary.loggedDays}',
            label: 'Days logged',
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.swatch,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final PhaseSwatch swatch;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: AppCard(
          emphasis: CardEmphasis.raised,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: swatch.text),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      value,
                      style: text.titleLarge?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Month / Year toggle ─────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.year, required this.onChanged});

  final bool year;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: false,
          label: Text('Month'),
          icon: Icon(Icons.calendar_view_month_rounded),
        ),
        ButtonSegment(
          value: true,
          label: Text('Year'),
          icon: Icon(Icons.calendar_view_week_rounded),
        ),
      ],
      selected: {year},
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }
}
