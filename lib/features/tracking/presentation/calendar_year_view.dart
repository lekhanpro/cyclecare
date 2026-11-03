import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/widgets.dart';
import '../domain/cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Year view
//
// Twelve mini-months, for seeing the rhythm of a whole year at once and for
// jumping a long way without swiping month by month.
//
// Each mini-month is painted, not built from widgets. Twelve months of up to 42
// day cells is ~500 widgets with their own semantics, which is slow to build
// and far too much for a screen reader. Instead each month is one tappable
// unit with a one-line summary as its label, and the dots are a picture.
// ─────────────────────────────────────────────────────────────────────────────

class CalendarYearView extends StatelessWidget {
  const CalendarYearView({
    super.key,
    required this.year,
    required this.statusFor,
    required this.weekStart,
    required this.onOpenMonth,
    required this.onYearChanged,
  });

  final int year;
  final DayStatus Function(DateTime day) statusFor;
  final WeekStart weekStart;
  final ValueChanged<DateTime> onOpenMonth;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return AppCard(
      emphasis: CardEmphasis.floating,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous year',
                onPressed: () => onYearChanged(year - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(
                    color: context.inkColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next year',
                onPressed: () => onYearChanged(year + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(builder: (context, constraints) {
            // Three across on a phone, four once there is room.
            final columns = constraints.maxWidth >= 520 ? 4 : 3;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.82,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MiniMonth(
                    month: DateTime(year, m),
                    statusFor: statusFor,
                    weekStart: weekStart,
                    isCurrent: now.year == year && now.month == m,
                    onTap: () => onOpenMonth(DateTime(year, m)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.month,
    required this.statusFor,
    required this.weekStart,
    required this.isCurrent,
    required this.onTap,
  });

  final DateTime month;
  final DayStatus Function(DateTime day) statusFor;
  final WeekStart weekStart;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = DateTime(month.year, month.month + 1, 0).day;
    var period = 0;
    var fertile = 0;
    final statuses = <DayStatus>[
      for (var d = 1; d <= days; d++) statusFor(DateTime(month.year, month.month, d)),
    ];
    for (final s in statuses) {
      if (s == DayStatus.period || s == DayStatus.predictedPeriod) period++;
      if (s == DayStatus.fertile || s == DayStatus.ovulation) fertile++;
    }
    final name = DateFormat('MMMM').format(month);

    return Pressable(
      onTap: onTap,
      semanticLabel: '$name ${month.year}',
      semanticHint: '$period period days, $fertile fertile days. Opens the month.',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(AppRadii.compact),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.compact),
          border: Border.all(
            color: isCurrent ? context.accentColor : context.lineColor,
            width: isCurrent ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM').format(month),
              style: text.labelLarge?.copyWith(
                color: isCurrent ? context.accentColor : context.inkColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MiniMonthPainter(
                  month: month,
                  statuses: statuses,
                  weekStart: weekStart,
                  phases: PhaseColors.of(context),
                  empty: context.lineColor,
                  today: dateOnly(DateTime.now()),
                  todayColor: context.inkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMonthPainter extends CustomPainter {
  _MiniMonthPainter({
    required this.month,
    required this.statuses,
    required this.weekStart,
    required this.phases,
    required this.empty,
    required this.today,
    required this.todayColor,
  });

  final DateTime month;
  final List<DayStatus> statuses;
  final WeekStart weekStart;
  final PhaseColors phases;
  final Color empty;
  final DateTime today;
  final Color todayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final first = DateTime(month.year, month.month);
    final lead = (first.weekday - weekStart.weekday + 7) % 7;
    final cell = size.width / 7;
    final r = (cell * 0.32).clamp(1.5, 5.0);

    for (var i = 0; i < statuses.length; i++) {
      final slot = lead + i;
      final c = Offset(
        (slot % 7) * cell + cell / 2,
        (slot ~/ 7) * cell + cell / 2,
      );
      if (c.dy > size.height) break;
      final s = statuses[i];
      // Recorded period is solid; a forecast is a ring, the same rule the
      // month grid uses, so the two views read the same way.
      final paint = Paint();
      switch (s) {
        case DayStatus.period:
          paint.color = phases.period.fill;
        case DayStatus.predictedPeriod:
          paint
            ..color = phases.period.fill
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
        case DayStatus.fertile:
          paint.color = phases.fertile.fill;
        case DayStatus.ovulation:
          paint.color = phases.ovulation.fill;
        case DayStatus.pms:
        case DayStatus.normal:
          paint.color = empty;
      }
      canvas.drawCircle(c, r, paint);
      if (DateTime(month.year, month.month, i + 1) == today) {
        canvas.drawCircle(
          c,
          r + 2,
          Paint()
            ..color = todayColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniMonthPainter old) =>
      old.month != month ||
      old.weekStart != weekStart ||
      old.phases.brightness != phases.brightness ||
      !_sameList(old.statuses, statuses);

  static bool _sameList(List<DayStatus> a, List<DayStatus> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
