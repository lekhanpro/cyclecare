import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';
import '../core/utils/date_helpers.dart';
import '../features/tracking/domain/cycle_models.dart';
import 'soft_card.dart';

class CycleCalendar extends StatelessWidget {
  const CycleCalendar({
    required this.month,
    required this.selectedDate,
    required this.statusFor,
    required this.onSelected,
    required this.onMonthChanged,
    this.hasLogFor,
    this.compact = false,
    super.key,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DayStatus Function(DateTime day) statusFor;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final bool Function(DateTime day)? hasLogFor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays(month);
    return SoftCard(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
                icon: const Icon(CupertinoIcons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CycleCareColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
                icon: const Icon(CupertinoIcons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const _WeekHeader(),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayCell(
                day: day,
                inMonth: day.month == month.month,
                selected: isSameDate(day, selectedDate),
                today: isSameDate(day, DateTime.now()),
                status: statusFor(day),
                hasLog: hasLogFor?.call(day) ?? false,
                onTap: () => onSelected(day),
              );
            },
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            const _Legend(),
          ],
        ],
      ),
    );
  }

  List<DateTime> _visibleDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CycleCareColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
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
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool today;
  final DayStatus status;
  final bool hasLog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      DayStatus.period => CycleCareColors.rose,
      DayStatus.predictedPeriod => CycleCareColors.predicted,
      DayStatus.fertile => CycleCareColors.fertile,
      DayStatus.ovulation => CycleCareColors.ovulation,
      DayStatus.normal => Colors.transparent,
    };
    final foreground = selected
        ? Colors.white
        : inMonth
            ? CycleCareColors.ink
            : CycleCareColors.muted.withOpacity(0.42);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? CycleCareColors.rose
                : status == DayStatus.period
                    ? CycleCareColors.rose.withOpacity(0.18)
                    : statusColor,
            borderRadius: BorderRadius.circular(16),
            border: today && !selected
                ? Border.all(color: CycleCareColors.rose, width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: selected || today ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: hasLog ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: status == DayStatus.normal
                      ? hasLog
                          ? CycleCareColors.lavender
                          : Colors.transparent
                      : selected
                          ? Colors.white
                          : CycleCareColors.rose,
                  borderRadius: BorderRadius.circular(999),
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
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(color: CycleCareColors.rose, label: 'Period'),
        _LegendItem(color: CycleCareColors.predicted, label: 'Predicted'),
        _LegendItem(color: CycleCareColors.fertile, label: 'Fertile'),
        _LegendItem(color: CycleCareColors.ovulation, label: 'Ovulation'),
        _LegendItem(color: CycleCareColors.lavender, label: 'Logged'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: CycleCareColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
