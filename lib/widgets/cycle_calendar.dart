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

  @override
  Widget build(BuildContext context) {
    final days = visibleDays(month, weekStart);
    final today = DateTime.now();

    return AppCard(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        children: [
          _MonthHeader(
            month: month,
            onPrevious: () =>
                onMonthChanged(DateTime(month.year, month.month - 1)),
            onNext: () => onMonthChanged(DateTime(month.year, month.month + 1)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _WeekHeader(weekStart: weekStart),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final status = statusFor(day);
              final inMonth = day.month == month.month;
              final selected = isSameDate(day, selectedDate);
              final isToday = isSameDate(day, today);
              final hasLog = hasLogFor?.call(day);
              final atRowStart = index % 7 == 0;
              final atRowEnd = index % 7 == 6;

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
                connectsLeft: !atRowStart &&
                    index > 0 &&
                    _connects(status, statusFor(days[index - 1])),
                connectsRight: !atRowEnd &&
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
    final previous = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);

    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          label: 'Previous month, ${monthLabel(previous)}',
          onTap: onPrevious,
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              monthLabel(month),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.inkColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          label: 'Next month, ${monthLabel(next)}',
          onTap: onNext,
        ),
      ],
    );
  }
}

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
    return IconButton(
      tooltip: label,
      onPressed: () {
        Haptics.selection();
        onTap();
      },
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppLayout.minTouchTarget),
        backgroundColor: context.lineColor.withOpacity(0.42),
        foregroundColor: context.inkColor,
        shape: const CircleBorder(),
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
                  color: context.mutedColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
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
    final scheme = Theme.of(context).colorScheme;

    final swatch = switch (status) {
      DayStatus.period => phases.period,
      DayStatus.predictedPeriod => phases.predicted,
      DayStatus.fertile => phases.fertile,
      DayStatus.ovulation => phases.ovulation,
      DayStatus.pms => phases.luteal(),
      DayStatus.normal => null,
    };
    final isForecast =
        status == DayStatus.predictedPeriod || status == DayStatus.pms;

    const radius = Radius.circular(AppRadii.calendarDay);
    const connectedRadius = Radius.circular(AppRadii.connected);
    final pillRadius = BorderRadius.only(
      topLeft: connectsLeft ? connectedRadius : radius,
      bottomLeft: connectsLeft ? connectedRadius : radius,
      topRight: connectsRight ? connectedRadius : radius,
      bottomRight: connectsRight ? connectedRadius : radius,
    );

    final foreground = selected
        ? scheme.onPrimary
        : !inMonth
            ? context.subtleColor.withOpacity(0.55)
            : swatch != null && !isForecast
                ? swatch.onFill
                : context.inkColor;

    return Padding(
      padding: EdgeInsets.only(
        left: connectsLeft ? 0 : 2.5,
        right: connectsRight ? 0 : 2.5,
        top: 2.5,
        bottom: 2.5,
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
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : swatch == null
                    ? Colors.transparent
                    : isForecast
                        ? swatch.surface
                        : swatch.fill.withOpacity(inMonth ? 1 : 0.35),
            borderRadius: pillRadius,
            border: today && !selected
                ? Border.all(
                    color: scheme.primary,
                    width: AppStrokes.selected,
                  )
                : isForecast && swatch != null
                    ? Border.all(
                        color: swatch.border,
                        width: AppStrokes.hairline,
                      )
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 14.5,
                  height: 1.1,
                  fontWeight:
                      selected || today ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedOpacity(
                opacity: hasLog ? 1 : 0,
                duration: motion(AppDurations.fast),
                child: Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: selected || (swatch != null && !isForecast)
                        ? foreground
                        : scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        _LegendItem(color: phases.period.fill, label: 'Period'),
        _LegendItem(
          color: phases.predicted.fill,
          label: 'Predicted',
          outlined: true,
        ),
        _LegendItem(color: phases.fertile.fill, label: 'Fertile'),
        _LegendItem(color: phases.ovulation.fill, label: 'Ovulation'),
        _LegendItem(
          color: phases.luteal().fill,
          label: 'PMS',
          outlined: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: outlined ? color.withOpacity(0.18) : color,
              shape: BoxShape.circle,
              border: outlined
                  ? Border.all(color: color, width: AppStrokes.selected)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            color: context.mutedColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
