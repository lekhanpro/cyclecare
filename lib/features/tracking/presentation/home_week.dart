part of 'home_screen.dart';

// ─── Your week ───────────────────────────────────────────────────────────────

/// Seven fixed cells for the current week (from the user's week start).
/// Today is filled with the accent; logged days carry a dot; tapping a day
/// opens the log for that date.
class _HomeWeek extends ConsumerWidget {
  const _HomeWeek({required this.data, required this.today});

  final CycleTrackerState data;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(appSettingsSyncProvider).weekStart.weekday;
    final offset = (today.weekday - weekStart) % 7;
    final first = DateTime(today.year, today.month, today.day - offset);
    final days = [
      for (var i = 0; i < 7; i++) DateTime(first.year, first.month, first.day + i),
    ];
    final controller = ref.read(cycleTrackerControllerProvider.notifier);

    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _WeekCell(
              key: ValueKey('home-week-${days[i].day}'),
              day: days[i],
              isToday: isSameDate(days[i], today),
              logged: data.hasLogFor(days[i]),
              status: data.statusFor(days[i]),
              onTap: () {
                controller.selectDate(days[i]);
                context.go(AppRoutes.log);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.logged,
    required this.status,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool logged;
  final DayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final phases = PhaseColors.of(context);
    final fg = isToday ? accent.onFill : context.inkColor;
    final muted = isToday ? accent.onFill : context.mutedColor;
    final isPeriod = status == DayStatus.period;
    final isPredicted = status == DayStatus.predictedPeriod;
    final parts = <String>[
      DateFormat('EEEE, MMMM d').format(day),
      if (isToday) 'today',
      if (isPeriod) 'period recorded',
      if (isPredicted) 'period estimated',
      logged ? 'logged' : 'not logged',
    ];

    return Pressable(
      onTap: onTap,
      selected: isToday,
      semanticLabel: parts.join(', '),
      semanticHint: 'Open the log for this day',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(15),
      minimumSize: const Size(0, AppLayout.minTouchTarget),
      child: Container(
        constraints: const BoxConstraints(minHeight: 67),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          color: isToday ? accent.fill : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.E().format(day).substring(0, 1),
              style: AppTextStyles.body(fontSize: 11, height: 1.3)
                  .copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              '${day.day}',
              style: AppTextStyles.body(
                fontSize: 14,
                height: 1.2,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ).copyWith(color: fg),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Logged: filled dot. Period recorded: rose dot. Estimated
            // period: hollow rose ring. Shape, not only hue, tells them apart.
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPeriod
                    ? (isToday ? accent.onFill : phases.period.fill)
                    : logged
                        ? (isToday ? accent.onFill : accent.text)
                        : null,
                border: isPredicted && !isPeriod
                    ? Border.all(
                        color: isToday ? accent.onFill : phases.predicted.fill,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
