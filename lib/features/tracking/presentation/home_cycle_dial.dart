import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/phase_colors.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/phase_bar.dart';
import '../domain/cycle_models.dart';
import '../domain/cycle_phase_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The precise cycle dial (design: section.home-orbit-card.precision-cycle).
//
// The selected day is owned by the parent so the dial and the hormone chart
// stay in step. The next-period estimate is always computed from today, never
// from the explored day. The companion lives outside this card on purpose.
// ─────────────────────────────────────────────────────────────────────────────

const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// "November 5–9", "Oct 30–Nov 3" across months.
String _rangeLabel(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return start.day == end.day
        ? '${_monthsLong[start.month - 1]} ${start.day}'
        : '${_monthsLong[start.month - 1]} ${start.day}–${end.day}';
  }
  return '${shortDateLabel(start)}–${shortDateLabel(end)}';
}

/// The date of cycle day [day] in [model].
DateTime cycleDayDate(CyclePhaseModel model, int day) =>
    _addDays(model.cycleStart, day - 1);

/// "Day N, Oct 30, luteal phase" — shared by the dial and the chart.
String cycleDayValueText(CyclePhaseModel model, int day) {
  final phase = model.segmentOnDay(day).phase.label.toLowerCase();
  return 'Day $day, ${shortDateLabel(cycleDayDate(model, day))}, $phase phase';
}

class CycleDial extends StatefulWidget {
  const CycleDial({
    super.key,
    required this.model,
    required this.selectedDay,
    required this.onDayChanged,
    this.onExplainEstimate,
  });

  final CyclePhaseModel model;

  /// 1-based explored cycle day. Pass `model.cycleDay` for today.
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  /// Opens the "About this estimate" explanation. Null hides the help button.
  final VoidCallback? onExplainEstimate;

  @override
  State<CycleDial> createState() => _CycleDialState();
}

class _CycleDialState extends State<CycleDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursor;
  late Animation<double> _angle;
  final FocusNode _focus = FocusNode(debugLabel: 'cycle-dial');
  bool _dragging = false;

  int get _length => widget.model.cycleLength;
  int get _day => widget.selectedDay.clamp(1, _length);

  double _targetAngle(int day) => (day - 0.5) / _length * 2 * math.pi;

  @override
  void initState() {
    super.initState();
    _cursor = AnimationController(
      vsync: this,
      duration: AppDurations.navigation,
    );
    final a = _targetAngle(_day);
    _angle = AlwaysStoppedAnimation(a);
  }

  @override
  void didUpdateWidget(CycleDial old) {
    super.didUpdateWidget(old);
    final target = _targetAngle(_day);
    final from = _angle.value;
    if ((target - from).abs() < 1e-6) return;
    final reduced = Motion.of(context).reduced;
    if (reduced || _dragging) {
      _cursor.stop();
      _angle = AlwaysStoppedAnimation(target);
      return;
    }
    // Rotate the short way round.
    var delta = (target - from) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    _angle = Tween<double>(
      begin: from,
      end: from + delta,
    ).chain(CurveTween(curve: AppCurves.out)).animate(_cursor);
    _cursor
      ..duration = Motion.of(context)(AppDurations.navigation)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _cursor.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(int day) {
    final clamped = day.clamp(1, _length);
    if (clamped != widget.selectedDay) widget.onDayChanged(clamped);
  }

  void _fromPointer(Offset local, Size size) {
    final c = size.center(Offset.zero);
    final v = local - c;
    if (v.distance < 4) return;
    // 0 at 12 o'clock, clockwise.
    final a =
        (math.atan2(v.dy, v.dx) + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    _select((a / (2 * math.pi) * _length).floor() + 1);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _select(_day + 1);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _select(_day - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _select(1);
    } else if (key == LogicalKeyboardKey.end) {
      _select(_length);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final muted = context.mutedColor;
    final day = _day;
    final isToday = day == model.cycleDay;

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.lineColor,
          width: AppStrokes.hairline,
        ),
        boxShadow: AppElevation.low(context.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading(model: model, day: day),
          const SizedBox(height: 6),
          Center(child: _dial(context, day, isToday)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Drag the ring to explore',
                  style: AppTextStyles.body(
                    fontSize: 11,
                    height: 1.3,
                  ).copyWith(color: muted),
                ),
              ),
              _TodayButton(
                enabled: !isToday,
                onTap: () => _select(model.cycleDay),
                semanticLabel: 'Back to today, cycle day ${model.cycleDay}',
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Semantics(
              label: 'Explore cycle day',
              value: cycleDayValueText(model, day),
              child: ExcludeSemantics(
                child: Slider(
                  key: const ValueKey('cycle-dial-slider'),
                  min: 1,
                  max: _length.toDouble(),
                  divisions: math.max(1, _length - 1),
                  value: day.toDouble(),
                  onChanged: (v) => _select(v.round()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _Forecast(model: model, onExplain: widget.onExplainEstimate),
        ],
      ),
    );
  }

  Widget _dial(BuildContext context, int day, bool isToday) {
    final model = widget.model;
    final colors = PhaseColors.of(context);
    final accent = context.accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(245.0, constraints.maxWidth);
        return Semantics(
          slider: true,
          focusable: true,
          label: 'Explore cycle day',
          value: cycleDayValueText(model, day),
          increasedValue: day < _length
              ? cycleDayValueText(model, day + 1)
              : null,
          decreasedValue: day > 1 ? cycleDayValueText(model, day - 1) : null,
          onIncrease: day < _length ? () => _select(day + 1) : null,
          onDecrease: day > 1 ? () => _select(day - 1) : null,
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _onKey,
            child: GestureDetector(
              key: const ValueKey('cycle-dial-ring'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                _focus.requestFocus();
                _fromPointer(d.localPosition, Size.square(size));
              },
              onPanStart: (d) {
                _dragging = true;
                _focus.requestFocus();
                _fromPointer(d.localPosition, Size.square(size));
              },
              onPanUpdate: (d) =>
                  _fromPointer(d.localPosition, Size.square(size)),
              onPanEnd: (_) => _dragging = false,
              onPanCancel: () => _dragging = false,
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _cursor,
                        builder: (context, _) => CustomPaint(
                          key: const ValueKey('cycle-dial-paint'),
                          painter: CycleDialPainter(
                            segments: [
                              for (final s in model.segments)
                                (
                                  s.startDay,
                                  s.endDay,
                                  phaseArcColor(colors, s.phase),
                                ),
                            ],
                            cycleLength: _length,
                            todayDay: model.cycleDay,
                            cursorAngle: _angle.value,
                            base: context.lineColor,
                            tick: context.mutedColor,
                            paper: context.cardColor,
                            cursor: accent.fill,
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size * 34 / 245,
                          vertical: size * 34 / 245,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _Centre(
                            model: model,
                            day: day,
                            isToday: isToday,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Arc colour of [phase] on the dial: the full token, with luteal's softer
/// band so the long luteal arc does not dominate.
Color phaseArcColor(PhaseColors colors, CyclePhase phase) => switch (phase) {
  CyclePhase.menstrual => colors.period.fill,
  CyclePhase.follicular => colors.follicular.fill,
  CyclePhase.ovulation => colors.ovulation.fill,
  CyclePhase.luteal => colors.luteal().band,
};

/// Paints the ring in a 320 unit viewBox scaled to the widget.
class CycleDialPainter extends CustomPainter {
  CycleDialPainter({
    required this.segments,
    required this.cycleLength,
    required this.todayDay,
    required this.cursorAngle,
    required this.base,
    required this.tick,
    required this.paper,
    required this.cursor,
  });

  /// (startDay, endDay, colour) per phase.
  final List<(int, int, Color)> segments;
  final int cycleLength;
  final int todayDay;

  /// Radians clockwise from 12 o'clock.
  final double cursorAngle;
  final Color base;
  final Color tick;
  final Color paper;
  final Color cursor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 320;
    canvas.save();
    canvas.scale(s);
    const c = Offset(160, 160);
    const r = 126.0;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = base,
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    for (final (from, to, color) in segments) {
      final a = (from - 1) / cycleLength * 2 * math.pi - math.pi / 2 + 0.025;
      final b = to / cycleLength * 2 * math.pi - math.pi / 2 - 0.025;
      canvas.drawArc(
        rect,
        a,
        math.max(0.001, b - a),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
    final tickPaint = Paint()
      ..strokeWidth = 1
      ..color = tick.withValues(alpha: 0.36);
    for (var i = 0; i < cycleLength; i++) {
      final a = (i + 0.5) / cycleLength * 2 * math.pi - math.pi / 2;
      final major = i % 7 == 0;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * 143, c + dir * (major ? 150 : 146), tickPaint);
    }
    // Today tick, darker so today stays findable while exploring.
    final ta = (todayDay - 0.5) / cycleLength * 2 * math.pi - math.pi / 2;
    final td = Offset(math.cos(ta), math.sin(ta));
    canvas.drawLine(
      c + td * 142,
      c + td * 152,
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = cursor,
    );
    // Dotted inner ring.
    final inner = Paint()
      ..style = PaintingStyle.fill
      ..color = base;
    const dots = 136;
    for (var i = 0; i < dots; i++) {
      final a = i / dots * 2 * math.pi;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 109, 0.5, inner);
    }
    // Cursor dot on the ring.
    final ca = cursorAngle - math.pi / 2;
    final p = c + Offset(math.cos(ca), math.sin(ca)) * r;
    canvas.drawCircle(p, 9, Paint()..color = paper);
    canvas.drawCircle(
      p,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = cursor,
    );
    canvas.drawCircle(p, 3.5, Paint()..color = cursor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CycleDialPainter old) =>
      old.cursorAngle != cursorAngle ||
      old.cycleLength != cycleLength ||
      old.todayDay != todayDay ||
      old.base != base ||
      old.cursor != cursor ||
      old.paper != paper ||
      old.segments.length != segments.length ||
      !_sameSegments(old.segments);

  bool _sameSegments(List<(int, int, Color)> other) {
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != other[i]) return false;
    }
    return true;
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.model, required this.day});

  final CyclePhaseModel model;
  final int day;

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedColor;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${shortDateLabel(model.cycleStart)} — ${shortDateLabel(model.cycleEnd)}'
              .toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Semantics(
          header: true,
          child: Text(
            'Your cycle',
            style: AppTextStyles.heading(
              fontSize: 26,
              letterSpacing: -0.8,
            ).copyWith(color: context.inkColor),
          ),
        ),
      ],
    );
    final status = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: context.canvasColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: context.lineColor),
      ),
      child: Text(
        'Day $day of ${model.cycleLength}',
        key: const ValueKey('cycle-dial-status'),
        style: AppTextStyles.body(
          fontSize: 11,
          height: 1.2,
        ).copyWith(color: muted),
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          status,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: AppSpacing.sm),
        status,
      ],
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre({
    required this.model,
    required this.day,
    required this.isToday,
  });

  final CyclePhaseModel model;
  final int day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedColor;
    final ink = context.inkColor;
    final phase = model.segmentOnDay(day).phase;
    final swatch = PhaseColors.of(context).phase(phase);
    final small = AppTextStyles.body(
      fontSize: 11,
      height: 1.3,
    ).copyWith(color: muted);
    final numeralStyle = AppTextStyles.heading(
      fontSize: 62,
      height: 1.02,
      letterSpacing: -3,
    ).copyWith(color: ink);
    final unitStyle = AppTextStyles.body(
      fontSize: 16,
      height: 1.2,
    ).copyWith(color: muted);

    final String label;
    final String numeral;
    final String unit;
    final String dateLine;
    if (isToday) {
      final daysUntil = dateOnly(
        model.nextPeriodStart,
      ).difference(dateOnly(model.today)).inDays;
      if (daysUntil > 0) {
        label = 'Period in about';
        numeral = '$daysUntil';
        unit = daysUntil == 1 ? 'day' : 'days';
      } else if (daysUntil == 0) {
        label = 'Period estimated';
        numeral = 'Today';
        unit = '';
      } else {
        label = 'Period estimate was';
        numeral = '${-daysUntil}';
        unit = -daysUntil == 1 ? 'day ago' : 'days ago';
      }
      dateLine = 'Estimated · ${shortDateLabel(model.nextPeriodStart)}';
    } else {
      label = 'Exploring cycle day';
      numeral = '$day';
      unit = 'of ${model.cycleLength}';
      dateLine = shortDateLabel(cycleDayDate(model, day));
    }

    return Column(
      key: const ValueKey('cycle-dial-centre'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: small, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(numeral, style: numeralStyle),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 7),
              Text(unit, style: unitStyle),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(dateLine, style: small, textAlign: TextAlign.center),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: swatch.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(phaseIcon(phase), size: 12, color: swatch.text),
              const SizedBox(width: 4),
              Text(
                '${phase.label} phase',
                style: AppTextStyles.body(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ).copyWith(color: swatch.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cycle day $day${isToday ? ' · Today' : ''}',
          style: small,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({
    required this.enabled,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? context.accent.text : context.mutedColor;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('cycle-dial-today'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.compact),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTouchTarget,
            minWidth: AppLayout.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Today',
                  style: AppTextStyles.body(
                    fontSize: 11,
                    height: 1.2,
                  ).copyWith(color: color),
                ),
                const SizedBox(width: 5),
                Icon(AppIcons.undo, size: 12, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.model, required this.onExplain});

  final CyclePhaseModel model;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    // The estimate spans the expected period length, from today's model.
    final periodDays = model.segmentOf(CyclePhase.menstrual).lengthInDays;
    final start = model.nextPeriodStart;
    final end = _addDays(start, math.max(0, periodDays - 1));
    return Container(
      padding: const EdgeInsets.only(top: 9, bottom: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.lineColor)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.calendar, size: 21, color: accent.text),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next period estimate',
                  style: AppTextStyles.body(
                    fontSize: 11,
                    height: 1.3,
                  ).copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: 4),
                Text(
                  _rangeLabel(start, end),
                  key: const ValueKey('cycle-dial-forecast'),
                  style: AppTextStyles.body(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: context.inkColor),
                ),
              ],
            ),
          ),
          if (onExplain != null)
            IconButton(
              key: const ValueKey('cycle-dial-explain'),
              onPressed: onExplain,
              tooltip: 'About this estimate',
              icon: Icon(AppIcons.help, size: 17, color: accent.text),
            ),
        ],
      ),
    );
  }
}
