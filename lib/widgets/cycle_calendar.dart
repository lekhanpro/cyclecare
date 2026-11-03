import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/providers/app_settings_provider.dart';
import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import '../core/utils/date_helpers.dart';
import '../features/tracking/domain/cycle_models.dart';
import 'app_card.dart';
import 'motion.dart';

/// Shared date announcement used by both month and compact cycle selectors.
String cycleDateSemanticLabel({
  required DateTime day,
  required DayStatus status,
  required bool selected,
  required bool today,
  bool? hasLog,
  bool outsideDisplayedMonth = false,
}) {
  final details = <String>[DateFormat.yMMMMEEEEd().format(day)];
  if (selected) details.add('selected');
  if (today) details.add('today');

  details.add(switch (status) {
    DayStatus.period => 'logged period day',
    DayStatus.predictedPeriod => 'predicted period day',
    DayStatus.fertile => 'fertile window',
    DayStatus.ovulation => 'estimated ovulation day',
    DayStatus.pms => 'predicted premenstrual window',
    DayStatus.normal => 'no cycle marker',
  });

  if (hasLog != null) details.add(hasLog ? 'has a log' : 'no log');
  if (outsideDisplayedMonth) details.add('outside displayed month');
  return details.join(', ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Month grid
//
// The grid is the calendar's content rather than a widget sitting on it, so it
// is the one surface on that screen allowed to lift off the page; everything
// below it stays flat or merely raised.
//
// Four states can land on the same cell, and each is told apart by something
// other than its hue — a cycle calendar that encodes "recorded" and "guessed"
// in rose versus pink alone is unreadable to anyone who cannot separate the
// two:
//
//   recorded   solid phase fill, no outline
//   forecast   pale wash behind a hairline outline
//   today      a quiet ring at hairline-plus weight, never lifted
//   selected   a heavy neutral ring, and the only cell that casts a shadow
//
// Selection stays neutral on purpose. Repainting the chosen day in the
// palette's accent — which is what this grid used to do — discards the phase
// colour that was the reason the day was worth tapping, and leaves the user
// comparing a day whose own marker has disappeared.
//
// Consecutive days of one state read as a single bar: shared edges drop their
// radius and their padding. A forecast cell's outline is drawn as a
// one-pixel underlay rather than a Border, because Flutter requires a Border
// to be uniform once a radius is involved, and a uniform border lays a
// hairline down every internal seam of the run.
// ─────────────────────────────────────────────────────────────────────────────

class CycleCalendar extends StatelessWidget {
  const CycleCalendar({
    required this.month,
    required this.selectedDate,
    required this.statusFor,
    required this.onSelected,
    required this.onMonthChanged,
    this.hasLogFor,
    this.compact = false,
    this.weekStart = WeekStart.monday,
    this.showLegend = true,
    super.key,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DayStatus Function(DateTime day) statusFor;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final bool Function(DateTime day)? hasLogFor;
  final bool compact;
  final WeekStart weekStart;
  final bool showLegend;

  /// Cell proportion. Taller than square so a day has room for its number and
  /// the log dot beneath it.
  static const double dayAspectRatio = 0.88;

  /// Always six rows, so content below the grid never shifts when a month
  /// happens to span five weeks instead of six.
  static const int weekRows = 6;

  /// Month-title and weekday type sizes, used by [pageHeight].
  static const double monthLabelSize = 22;
  static const double weekdayLabelSize = 11.5;

  /// Height of the month header at the current text scale.
  ///
  /// Two lines of allowance: the month and year wrap at large text sizes, and
  /// below that the 48dp controls set the floor. The slack left at default
  /// sizes is wanted — a header squeezed to the height of its own type is most
  /// of why the old one read as an afterthought rather than the screen's
  /// primary navigation.
  static double monthHeaderHeight(BuildContext context) {
    final line = MediaQuery.textScalerOf(context).scale(monthLabelSize) * 1.45;
    return math.max(AppLayout.minTouchTarget, line * 2);
  }

  /// Exact height of one non-compact month: card padding, the month header,
  /// the weekday row, and six week rows whose height follows from [width].
  ///
  /// Exposed because a horizontally-paging parent has to be handed a page
  /// height before it can lay the page out. Keeping the arithmetic here is
  /// what stops that parent from mirroring these numbers by hand.
  static double pageHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    const surface = AppSpacing.md * 2;

    final cell = (width - surface) / DateTime.daysPerWeek;
    final grid = (cell / dayAspectRatio) * weekRows;
    final weekdays = scaler.scale(weekdayLabelSize) * 1.5;

    return surface +
        monthHeaderHeight(context) +
        AppSpacing.sm +
        weekdays +
        AppSpacing.xs +
        grid +
        // Cushion, so a type tweak inside the grid shows up as a few spare
        // pixels rather than a clipped last row.
        AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    final days = visibleDays(month, weekStart);
    final today = DateTime.now();

    return AppCard(
      // The screen's leading surface. Floating rather than raised because a
      // month grid that sits at the same depth as its own legend reads as a
      // panel of reference material instead of the thing the screen is for.
      emphasis: compact ? CardEmphasis.raised : CardEmphasis.floating,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        children: [
          SizedBox(
            height: monthHeaderHeight(context),
            child: _MonthHeader(
              month: month,
              onPrevious: () =>
                  onMonthChanged(DateTime(month.year, month.month - 1)),
              onNext: () =>
                  onMonthChanged(DateTime(month.year, month.month + 1)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _WeekHeader(weekStart: weekStart),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: DateTime.daysPerWeek,
              childAspectRatio: dayAspectRatio,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final status = statusFor(day);
              final inMonth = day.month == month.month;
              final selected = isSameDate(day, selectedDate);
              final isToday = isSameDate(day, today);
              final hasLog = hasLogFor?.call(day);
              final atRowStart = index % DateTime.daysPerWeek == 0;
              final atRowEnd =
                  index % DateTime.daysPerWeek == DateTime.daysPerWeek - 1;

              return _DayCell(
                day: day,
                inMonth: inMonth,
                selected: selected,
                today: isToday,
                status: status,
                hasLog: hasLog ?? false,
                semanticLabel: cycleDateSemanticLabel(
                  day: day,
                  status: status,
                  selected: selected,
                  today: isToday,
                  hasLog: hasLog,
                  outsideDisplayedMonth: !inMonth,
                ),
                connectsLeft:
                    !atRowStart &&
                    index > 0 &&
                    _connects(status, statusFor(days[index - 1])),
                connectsRight:
                    !atRowEnd &&
                    index < days.length - 1 &&
                    _connects(status, statusFor(days[index + 1])),
                onTap: () {
                  Haptics.selection();
                  onSelected(day);
                },
              );
            },
          ),
          if (showLegend && !compact) ...[
            const SizedBox(height: AppSpacing.md),
            const _Legend(),
          ],
        ],
      ),
    );
  }

  static bool _connects(DayStatus a, DayStatus b) =>
      a == b && a != DayStatus.normal && a != DayStatus.ovulation;

  /// Always returns six complete weeks so content below the calendar is stable.
  static List<DateTime> visibleDays(DateTime month, WeekStart weekStart) {
    final first = DateTime(month.year, month.month);
    final offset = (first.weekday - weekStart.weekday + 7) % 7;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }
}

/// Month title and the two controls that move it.
///
/// Left-aligned, with the controls grouped at the trailing edge: the month name
/// is the heading of everything below it, and a heading centred between two
/// small buttons reads as a toolbar label rather than a title.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final previous = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            label: monthLabel(month),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: Text.rich(
                TextSpan(
                  text: DateFormat.MMMM().format(month),
                  children: [
                    // The year is context, not the title. Holding it at label
                    // weight keeps the month the one word the eye lands on
                    // while paging.
                    TextSpan(
                      text: '  ${DateFormat.y().format(month)}',
                      style: text.titleMedium?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                style: text.titleLarge?.copyWith(
                  color: context.inkColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_left_rounded,
          label: 'Previous month, ${monthLabel(previous)}',
          onTap: onPrevious,
        ),
        const SizedBox(width: AppSpacing.xs),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          label: 'Next month, ${monthLabel(next)}',
          onTap: onNext,
        ),
      ],
    );
  }
}

/// A full-size month step.
///
/// Built from [Pressable] rather than an [IconButton] so it carries the app's
/// press scale and focus ring, and so the tinted plate is a real 48dp target
/// instead of a small circle floating inside one.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.control);

    return Tooltip(
      message: label,
      child: Pressable(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        haptic: false,
        scale: 0.94,
        semanticLabel: label,
        excludeChildSemantics: true,
        borderRadius: radius,
        child: Container(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(
              context.isDark ? 0.22 : 0.10,
            ),
            borderRadius: radius,
          ),
          child: Icon(icon, size: AppSpacing.xl, color: context.accentColor),
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.weekStart});

  final WeekStart weekStart;

  static const _initials = {
    DateTime.monday: 'M',
    DateTime.tuesday: 'T',
    DateTime.wednesday: 'W',
    DateTime.thursday: 'T',
    DateTime.friday: 'F',
    DateTime.saturday: 'S',
    DateTime.sunday: 'S',
  };

  static const _names = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    final ordered = [
      for (var i = 0; i < 7; i++) ((weekStart.weekday - 1 + i) % 7) + 1,
    ];

    return Row(
      children: [
        for (final weekday in ordered)
          Expanded(
            child: Semantics(
              label: _names[weekday],
              excludeSemantics: true,
              child: Text(
                _initials[weekday]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.subtleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: CycleCalendar.weekdayLabelSize,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.today,
    required this.status,
    required this.hasLog,
    required this.semanticLabel,
    required this.connectsLeft,
    required this.connectsRight,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool today;
  final DayStatus status;
  final bool hasLog;
  final String semanticLabel;
  final bool connectsLeft;
  final bool connectsRight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final phases = PhaseColors.of(context);
    final text = Theme.of(context).textTheme;
    final dark = context.isDark;

    final swatch = switch (status) {
      DayStatus.period => phases.period,
      DayStatus.predictedPeriod => phases.predicted,
      DayStatus.fertile => phases.fertile,
      DayStatus.ovulation => phases.ovulation,
      DayStatus.pms => phases.luteal(),
      DayStatus.normal => null,
    };

    /// Forecast states are the ones the app is guessing at, and they are drawn
    /// outlined everywhere in the app for exactly that reason.
    final isForecast =
        status == DayStatus.predictedPeriod || status == DayStatus.pms;
    final filled = swatch != null && !isForecast;

    const radius = Radius.circular(AppRadii.calendarDay);
    const connectedRadius = Radius.circular(AppRadii.connected);
    final pillRadius = BorderRadius.only(
      topLeft: connectsLeft ? connectedRadius : radius,
      bottomLeft: connectsLeft ? connectedRadius : radius,
      topRight: connectsRight ? connectedRadius : radius,
      bottomRight: connectsRight ? connectedRadius : radius,
    );

    final fill = swatch == null
        // An unmarked day has no fill of its own, so selection needs one — a
        // ring around nothing has no centre and reads as an empty box.
        ? selected
              ? context.accentColor.withOpacity(dark ? 0.26 : 0.12)
              : Colors.transparent
        : isForecast
        ? swatch.surface
        : swatch.fill.withOpacity(inMonth ? 1 : 0.35);

    // Ink for the day number. A number on a solid phase fill takes that
    // swatch's own onFill; page ink on a saturated cell is the contrast
    // failure this grid is most prone to.
    final Color foreground;
    if (filled && inMonth) {
      foreground = swatch.onFill;
    } else if (!inMonth && !selected) {
      foreground = context.subtleColor.withOpacity(0.55);
    } else if (isForecast && swatch != null) {
      foreground = swatch.text;
    } else {
      foreground = context.inkColor;
    }

    // Today's ring has to hold up on a solid phase fill as well as on the bare
    // card, so on a filled cell it borrows that swatch's own onFill. The
    // palette accent can land in the same family as the fill and vanish.
    final Border? ring = selected
        ? Border.all(
            color: context.inkColor.withOpacity(dark ? 0.94 : 0.86),
            width: AppStrokes.focus,
          )
        : today
        ? Border.all(
            color: filled ? swatch.onFill : context.accentColor,
            width: AppStrokes.selected,
          )
        : null;

    Widget surface = AnimatedContainer(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: pillRadius,
        // The only cell that lifts. Shadow is the one selection cue that
        // survives being laid over any fill, which is what separates it from
        // today's ring at a glance.
        boxShadow: selected ? AppElevation.low(dark) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A date is always one line. At large text scales a two-digit
          // number can be wider than its own cell, and wrapping it onto a
          // second line pushes the log dot past the bottom of the cell.
          // Scaling it down instead keeps the whole number readable.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${day.day}',
                maxLines: 1,
                softWrap: false,
                style: text.labelLarge?.copyWith(
                  color: foreground,
                  height: 1.1,
                  fontWeight: selected || today
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedOpacity(
            opacity: hasLog ? 1 : 0,
            duration: motion(AppDurations.fast),
            child: Container(
              width: AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                // A log is not a cycle marker, so on a filled cell it is drawn
                // in that cell's own ink rather than the accent, where it
                // would read as a second, competing status.
                color: filled ? swatch.onFill : context.accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );

    if (isForecast && swatch != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          color: swatch.border,
          borderRadius: pillRadius,
        ),
        child: Padding(
          // The outline is suppressed on edges shared with a neighbour of the
          // same state, so a run of forecast days reads as one bar instead of
          // a row of boxes.
          padding: EdgeInsets.only(
            left: connectsLeft ? 0 : AppStrokes.hairline,
            right: connectsRight ? 0 : AppStrokes.hairline,
            top: AppStrokes.hairline,
            bottom: AppStrokes.hairline,
          ),
          child: surface,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        // Connected days give up their side gap so the fills meet.
        left: connectsLeft ? 0 : AppSpacing.xxs,
        right: connectsRight ? 0 : AppSpacing.xxs,
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Pressable(
        onTap: onTap,
        haptic: false,
        selected: selected,
        semanticLabel: semanticLabel,
        semanticHint: inMonth ? 'Select date' : 'Select adjacent-month date',
        excludeChildSemantics: true,
        scale: 0.97,
        borderRadius: pillRadius,
        child: AnimatedContainer(
          duration: motion(AppDurations.fast),
          curve: AppCurves.out,
          foregroundDecoration: ring == null
              ? null
              : BoxDecoration(borderRadius: pillRadius, border: ring),
          child: surface,
        ),
      ),
    );
  }
}

/// In-card key, kept for the grid's standalone use.
///
/// Shape carries what colour carries: a capsule spans consecutive days, a tile
/// marks a single one, and an outline means the app is forecasting rather than
/// reporting.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(swatch: phases.period, label: 'Period'),
        _LegendItem(
          swatch: phases.predicted,
          label: 'Expected',
          outlined: true,
        ),
        _LegendItem(swatch: phases.fertile, label: 'Fertile'),
        _LegendItem(swatch: phases.ovulation, label: 'Ovulation', single: true),
        _LegendItem(swatch: phases.luteal(), label: 'PMS', outlined: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.swatch,
    required this.label,
    this.outlined = false,
    this.single = false,
  });

  final PhaseSwatch swatch;
  final String label;
  final bool outlined;

  /// A one-day marker, drawn as a tile rather than a capsule.
  final bool single;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: single ? AppSpacing.md : AppSpacing.xl,
              height: AppSpacing.md,
              decoration: BoxDecoration(
                color: outlined ? swatch.surface : swatch.fill,
                borderRadius: BorderRadius.circular(
                  single ? AppRadii.connected : AppRadii.pill,
                ),
                border: outlined
                    ? Border.all(
                        color: swatch.border,
                        width: AppStrokes.hairline,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
