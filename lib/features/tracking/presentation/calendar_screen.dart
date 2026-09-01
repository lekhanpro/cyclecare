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

// ─────────────────────────────────────────────────────────────────────────────
// Calendar
//
// Three stacked blocks, in the order they are read: the month grid, a key that
// says in words what every marker means, then the detail for whichever day is
// selected. The detail lives *below* the grid rather than floating over it —
// the whole point of tapping a date is to compare it with its neighbours, and
// an overlay covers exactly the days you are comparing against.
//
// The screen sits on the plain theme canvas. It used to sit on a phase-tinted
// gradient with frosted-glass panels, which looked lovely and worked against
// the one job this screen has: the grid encodes meaning in hue — rose for
// period, mint for fertile, violet for ovulation — and washing the entire
// background in whichever hue the selected day happens to be lowers the
// contrast of the very cells the user is trying to tell apart. The phase tint
// now appears only where it cannot compete: as a local wash on the day-detail
// card. Glass went with it; without a saturated backdrop to sample, glass has
// nothing to blur and only added a second surface on top of the grid's own.
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

  /// Mirrors [CycleCalendar]'s grid delegate: seven columns of fixed aspect
  /// ratio, and always six week rows so content below the grid never shifts.
  static const _dayAspectRatio = 0.88;
  static const _weekRows = 6;

  /// Mirrors [CycleCalendar]'s month-label and weekday type sizes. A
  /// horizontally-paging child has to be handed a height before it can be laid
  /// out, so this is the one place the screen depends on the grid's internals.
  static const _monthLabelSize = 16.5;
  static const _weekdayLabelSize = 11.5;

  late final PageController _pageController;
  late final DateTime _originMonth;
  late DateTime _month;

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
    final delta = (month.year - _originMonth.year) * 12 +
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
    final alreadyOnToday = data != null &&
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
                    Reveal(child: _monthPager(data, weekStart, contentWidth)),
                    const SizedBox(height: AppSpacing.lg),
                    const Reveal(index: 1, child: _CalendarKey()),
                    const SizedBox(height: AppSpacing.xl),
                    Reveal(index: 2, child: _DayDetail(data: data)),
                    if (data.periods.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Reveal(
                        index: 3,
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
      height: _monthPageHeight(context, width),
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
            onSelected:
                ref.read(cycleTrackerControllerProvider.notifier).selectDate,
            onMonthChanged: _goToMonth,
          );
        },
      ),
    );
  }

  /// Exact height of one month page: card padding, month header, weekday row,
  /// and six week rows whose height follows from the width they are given.
  ///
  /// Text-scale aware, because the two label rows grow with the user's font
  /// size even though the grid cells do not.
  double _monthPageHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);

    // AppCard's padding inside CycleCalendar when it is not compact.
    const surface = AppSpacing.md * 2;

    final cell = (width - surface) / DateTime.daysPerWeek;
    final grid = (cell / _dayAspectRatio) * _weekRows;

    // The month name wraps to a second line at large text sizes; below that the
    // 48dp nav buttons set the floor.
    final monthLine = scaler.scale(_monthLabelSize) * 1.45;
    final header = math.max(AppLayout.minTouchTarget, monthLine * 2);
    final weekdays = scaler.scale(_weekdayLabelSize) * 1.5;

    return surface +
        header +
        AppSpacing.sm +
        weekdays +
        AppSpacing.xs +
        grid +
        // Small cushion so a type tweak inside the grid widget shows up as a
        // few spare pixels rather than a clipped last row.
        AppSpacing.xs;
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.mutedColor),
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
            message: 'Your saved cycles could not be read just now. Nothing '
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
/// days, a tile marks a single one.
enum _KeyShape { range, day, dot }

class _KeyEntry {
  const _KeyEntry({
    required this.label,
    required this.shape,
    required this.outlined,
    this.swatch,
  });

  final String label;
  final _KeyShape shape;

  /// Outlined means forecast. Filled means recorded. The grid uses the same
  /// rule, so the key teaches it rather than restating it.
  final bool outlined;
  final PhaseSwatch? swatch;
}

class _CalendarKey extends StatelessWidget {
  const _CalendarKey();

  /// Comfortable width for one entry before the key drops to fewer columns.
  static const _columnWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final entries = <_KeyEntry>[
      _KeyEntry(
        label: 'Period logged',
        shape: _KeyShape.range,
        outlined: false,
        swatch: phases.period,
      ),
      _KeyEntry(
        label: 'Period predicted',
        shape: _KeyShape.range,
        outlined: true,
        swatch: phases.predicted,
      ),
      _KeyEntry(
        label: 'Fertile window',
        shape: _KeyShape.range,
        outlined: false,
        swatch: phases.fertile,
      ),
      _KeyEntry(
        label: 'Ovulation day',
        shape: _KeyShape.day,
        outlined: false,
        swatch: phases.ovulation,
      ),
      _KeyEntry(
        label: 'PMS predicted',
        shape: _KeyShape.range,
        outlined: true,
        swatch: phases.luteal(),
      ),
      const _KeyEntry(
        label: 'Day has a log',
        shape: _KeyShape.dot,
        outlined: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Calendar key',
              style: textTheme.labelSmall?.copyWith(color: context.mutedColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              // Measured rather than derived from the page width: the entries
              // have to fit inside this padding, and an eight-pixel overshoot
              // is enough to drop the key to a single column.
              //
              // Fixed column widths mean a long label wraps inside its own
              // column instead of stretching the row, and the count falls to
              // one when text is large.
              final scale = MediaQuery.textScalerOf(context).scale(12.5) / 12.5;
              final available = constraints.maxWidth;
              final columns =
                  (available / (_columnWidth * scale)).floor().clamp(1, 3);
              final itemWidth =
                  (available - AppSpacing.md * (columns - 1)) / columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: itemWidth,
                      child: MergeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _KeySwatch(entry: entry),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.label,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.inkColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KeySwatch extends StatelessWidget {
  const _KeySwatch({required this.entry});

  final _KeyEntry entry;

  static const _height = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final swatch = entry.swatch;
    final tone = swatch?.fill ?? context.accentColor;
    final border = swatch?.border ?? context.lineColor;

    // The day tile's radius, scaled down to the key's smaller swatch.
    final radius = entry.shape == _KeyShape.range
        ? BorderRadius.circular(AppRadii.pill)
        : BorderRadius.circular(AppRadii.compact / 2);

    return ExcludeSemantics(
      child: Padding(
        // Nudged down so a swatch lines up with the first line of its label
        // rather than the top of the text box.
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Container(
          // A capsule reads as "these days run together"; a tile reads as one
          // day on its own. That difference survives without colour.
          width: entry.shape == _KeyShape.range
              ? _height + AppSpacing.md
              : _height,
          height: _height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: entry.shape == _KeyShape.dot
                ? Colors.transparent
                : entry.outlined
                    ? swatch?.surface
                    : tone,
            borderRadius: radius,
            border: entry.outlined
                ? Border.all(color: border, width: AppStrokes.hairline)
                : null,
          ),
          child: entry.shape == _KeyShape.dot
              ? Container(
                  width: AppSpacing.xs,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
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
            icon: Icons.water_drop_rounded,
            outlined: false,
            swatch: phases.period,
          ),
        DayStatus.predictedPeriod => _DayMarker(
            title: 'Period expected',
            note: 'Predicted, not recorded — outlined on the calendar.',
            icon: Icons.water_drop_outlined,
            outlined: true,
            swatch: phases.predicted,
          ),
        DayStatus.fertile => _DayMarker(
            title: 'Fertile window',
            note: 'Estimated from your average cycle length.',
            icon: Icons.eco_rounded,
            outlined: false,
            swatch: phases.fertile,
          ),
        DayStatus.ovulation => _DayMarker(
            title: 'Ovulation estimate',
            note: 'A single estimated day, marked on its own in the grid.',
            icon: Icons.adjust_rounded,
            outlined: false,
            swatch: phases.ovulation,
          ),
        DayStatus.pms => _DayMarker(
            title: 'PMS window',
            note: 'Predicted premenstrual days before your next period.',
            icon: Icons.cloud_outlined,
            outlined: true,
            swatch: phases.luteal(),
          ),
        DayStatus.normal => const _DayMarker(
            title: 'No markers',
            note: 'Nothing recorded or predicted for this day.',
            icon: Icons.remove_circle_outline_rounded,
            outlined: true,
          ),
      };
}

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
        // Announced as one unit so a screen reader hears the whole answer —
        // date, state, cycle day — the moment a new date is chosen.
        Semantics(
          container: true,
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MarkerBadge(marker: marker),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLine,
                      style: textTheme.labelLarge
                          ?.copyWith(color: context.mutedColor),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      marker.title,
                      style: textTheme.titleLarge
                          ?.copyWith(color: context.inkColor),
                    ),
                  ],
                ),
              ),
              if (cycleDay != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _CycleDayPill(day: cycleDay, swatch: marker.swatch),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          marker.note,
          style: textTheme.bodySmall?.copyWith(
            color: context.isDark
                ? context.inkColor.withOpacity(0.82)
                : context.mutedColor,
          ),
        ),
        Divider(
          height: AppSpacing.xxl,
          color: marker.swatch?.border ?? context.lineColor,
        ),
        if (log == null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: AppSpacing.lg,
                color: context.subtleColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nothing logged for this day yet.',
                  style:
                      textTheme.bodyMedium?.copyWith(color: context.mutedColor),
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
              icon: Icons.edit_note_rounded,
              // Declarative navigation, so the Log tab, the back gesture and
              // the shell's transitions all behave the way they do everywhere
              // else. The log reads the same selected date this card shows.
              onPressed: () => context.go(AppRoutes.log),
            );
            final periodButton = PrimaryButton(
              label: period == null ? 'Mark period' : 'Edit dates',
              icon: Icons.water_drop_rounded,
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

    final swatch = marker.swatch;

    // The phase wash is scoped to this card, where it labels the day without
    // tinting the grid it is describing.
    return swatch == null
        ? AppCard(child: body)
        : PhaseCard(swatch: swatch, child: body);
  }

  /// Cycle day for an arbitrary date, counted from the period that opened it.
  /// Null for dates before any recorded period, where the number would be
  /// meaningless rather than zero.
  int? _cycleDayFor(DateTime date) {
    final target = dateOnly(date);
    final starts = <DateTime>{
      for (final period in data.periods) dateOnly(period.startDate),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

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
      message: 'The recorded dates will be deleted and your predictions '
          'will be recalculated without them.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;

    await controller.deletePeriod(period.id);
    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Period removed',
      kind: ToastKind.info,
    );
  }
}

class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({required this.marker});

  final _DayMarker marker;

  @override
  Widget build(BuildContext context) {
    final swatch = marker.swatch;

    return ExcludeSemantics(
      child: Container(
        width: AppSpacing.huge,
        height: AppSpacing.huge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: marker.outlined
              ? swatch?.surface ?? Colors.transparent
              : swatch?.fill ?? context.accentColor,
          borderRadius: BorderRadius.circular(AppRadii.compact),
          border: marker.outlined
              ? Border.all(
                  color: swatch?.border ?? context.lineColor,
                  width: AppStrokes.selected,
                )
              : null,
        ),
        child: Icon(
          marker.icon,
          size: AppSpacing.xl,
          color: marker.outlined
              ? swatch?.text ?? context.mutedColor
              : swatch?.onFill ?? Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _CycleDayPill extends StatelessWidget {
  const _CycleDayPill({required this.day, required this.swatch});

  final int day;
  final PhaseSwatch? swatch;

  @override
  Widget build(BuildContext context) {
    final tone = swatch?.fill ?? context.accentColor;

    return Semantics(
      label: 'Cycle day $day',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadii.compact),
          border: Border.all(
            color: swatch?.border ?? context.lineColor,
            width: AppStrokes.hairline,
          ),
        ),
        child: Text(
          'Day $day',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: swatch?.text ?? tone,
              ),
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
        (icon: Icons.water_drop_rounded, text: 'Flow: ${log.flow!.label}'),
      if (log.mood != null && log.mood!.isNotEmpty)
        (icon: Icons.mood_rounded, text: 'Mood: ${log.mood}'),
      if (log.symptoms.isNotEmpty)
        (icon: Icons.healing_rounded, text: log.symptoms.join(', ')),
      if (log.painLevel > 0)
        (icon: Icons.monitor_heart_rounded, text: 'Pain ${log.painLevel}/10'),
      if (log.temperatureCelsius != null)
        (
          icon: Icons.thermostat_rounded,
          text: '${log.temperatureCelsius!.toStringAsFixed(2)} °C',
        ),
      if (log.weightKg != null)
        (
          icon: Icons.monitor_weight_rounded,
          text: '${log.weightKg!.toStringAsFixed(1)} kg',
        ),
      if (log.sleepHours != null)
        (icon: Icons.bedtime_rounded, text: '${log.sleepHours}h sleep'),
      if (log.waterMl > 0)
        (icon: Icons.local_drink_rounded, text: '${log.waterMl} ml water'),
      if (log.notes.isNotEmpty)
        (icon: Icons.sticky_note_2_rounded, text: log.notes),
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
  final defaultEnd = existing?.endDate ??
      data.selectedDate.add(
        Duration(days: data.preferences.averagePeriodLength - 1),
      );

  final result = await showAppSheet<_PeriodRange>(
    context: context,
    title: existing == null ? 'Mark period' : 'Edit period dates',
    child: _PeriodEditor(start: defaultStart, end: defaultEnd),
  );
  if (result == null) return;

  await controller.upsertPeriod(
    existingId: existing?.id,
    startDate: result.start,
    endDate: result.end,
    flow: result.flow,
  );

  if (!context.mounted) return;
  showAppToast(
    context,
    message: existing == null ? 'Period saved' : 'Period updated',
  );
}

class _PeriodRange {
  const _PeriodRange(this.start, this.end, this.flow);

  final DateTime start;
  final DateTime end;
  final FlowIntensity flow;
}

/// Start/end/flow editor for a period.
///
/// Replaces the previous one-tap "add period" that silently guessed an end date
/// from the average. Guessing is fine for a prediction; it is not fine for a
/// record the predictions are then computed from.
class _PeriodEditor extends StatefulWidget {
  const _PeriodEditor({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  State<_PeriodEditor> createState() => _PeriodEditorState();
}

class _PeriodEditorState extends State<_PeriodEditor> {
  late DateTime _start;
  late DateTime _end;
  FlowIntensity _flow = FlowIntensity.medium;

  @override
  void initState() {
    super.initState();
    _start = dateOnly(widget.start);
    _end = dateOnly(widget.end);
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
        const SizedBox(height: AppSpacing.md),
        Text(
          days == 1 ? '1 day' : '$days days',
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
              if (flow != FlowIntensity.none)
                SelectableChip(
                  label: flow.label,
                  selected: _flow == flow,
                  accent: AppColors.period,
                  onSelected: (_) => setState(() => _flow = flow),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'Save period',
          icon: Icons.check_rounded,
          onPressed: () =>
              Navigator.of(context).pop(_PeriodRange(_start, _end, _flow)),
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
