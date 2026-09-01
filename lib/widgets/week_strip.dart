import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import '../core/utils/date_helpers.dart';
import '../features/tracking/domain/cycle_models.dart';
import 'cycle_calendar.dart' show cycleDateSemanticLabel;
import 'motion.dart';

/// Horizontally scrollable compact date selector centered near today.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.statusFor,
    required this.onSelected,
    this.hasLogFor,
    this.weeksEitherSide = 26,
  }) : assert(weeksEitherSide >= 0);

  final DateTime selectedDate;
  final DayStatus Function(DateTime day) statusFor;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime day)? hasLogFor;
  final int weeksEitherSide;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  late final ScrollController _controller;
  late final DateTime _origin;

  static const _dayWidth = 52.0;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _origin = today.subtract(Duration(days: widget.weeksEitherSide * 7));
    final desiredOffset =
        widget.weeksEitherSide * 7 * _dayWidth - _dayWidth * 3;
    _controller = ScrollController(
      initialScrollOffset: desiredOffset.clamp(0.0, double.infinity).toDouble(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.weeksEitherSide * 14 + 1;
    final today = DateTime.now();

    return SizedBox(
      height: 74,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: totalDays,
        itemExtent: _dayWidth,
        itemBuilder: (context, index) {
          final day = _origin.add(Duration(days: index));
          final status = widget.statusFor(day);
          final selected = isSameDate(day, widget.selectedDate);
          final isToday = isSameDate(day, today);
          final hasLog = widget.hasLogFor?.call(day);

          return _StripDay(
            day: day,
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
            ),
            onTap: () {
              Haptics.selection();
              widget.onSelected(day);
            },
          );
        },
      ),
    );
  }
}

class _StripDay extends StatelessWidget {
  const _StripDay({
    required this.day,
    required this.selected,
    required this.today,
    required this.status,
    required this.hasLog,
    required this.semanticLabel,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final DayStatus status;
  final bool hasLog;
  final String semanticLabel;
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
    final radius = BorderRadius.circular(AppRadii.calendarDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Pressable(
        onTap: onTap,
        haptic: false,
        selected: selected,
        semanticLabel: semanticLabel,
        semanticHint: 'Select date',
        excludeChildSemantics: true,
        scale: 0.96,
        borderRadius: radius,
        child: Column(
          children: [
            Text(
              DateFormat.E().format(day).substring(0, 1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: AnimatedContainer(
                duration: motion(AppDurations.fast),
                curve: AppCurves.out,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : swatch == null
                          ? Colors.transparent
                          : isForecast
                              ? swatch.surface
                              : swatch.fill,
                  borderRadius: radius,
                  border: selected
                      ? null
                      : today
                          ? Border.all(
                              color: scheme.primary,
                              width: AppStrokes.selected,
                            )
                          : isForecast && swatch != null
                              ? Border.all(
                                  color: swatch.border,
                                  width: AppStrokes.hairline,
                                )
                              : swatch == null
                                  ? Border.all(
                                      color: context.lineColor,
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
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? scheme.onPrimary
                            : swatch != null && !isForecast
                                ? swatch.onFill
                                : context.inkColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: AppSpacing.xs,
                      height: AppSpacing.xs,
                      decoration: BoxDecoration(
                        color: !hasLog
                            ? Colors.transparent
                            : selected
                                ? scheme.onPrimary
                                : swatch != null && !isForecast
                                    ? swatch.onFill
                                    : scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
