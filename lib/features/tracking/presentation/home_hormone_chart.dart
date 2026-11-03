import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/phase_colors.dart';
import '../../../widgets/widgets.dart';
import '../domain/cycle_models.dart';
import '../domain/cycle_phase_model.dart';
import '../domain/hormone_illustration.dart';
import 'home_cycle_dial.dart' show cycleDayDate, cycleDayValueText;

// ─────────────────────────────────────────────────────────────────────────────
// Educational hormone-pattern chart (design: section.hormone-card.
// precision-hormones). Relative, independently normalised illustration
// curves — never a measurement, a unit or a personal level.
//
// The explored day is owned by the parent and shared with the cycle dial.
// The crosshair, dots and tooltip follow the pointer with no animation, so
// direct scrubbing never lags behind the finger.
// ─────────────────────────────────────────────────────────────────────────────

enum HormoneChartRange { cycle, phase }

/// Curve colour for [kind]. The redesign's `--h-*` hormone hues have no
/// production token, so each curve borrows the phase hue it is most
/// associated with; the label, not the colour, identifies it.
Color hormoneColor(PhaseColors colors, HormoneKind kind) => switch (kind) {
  HormoneKind.estrogen => colors.period.fill,
  HormoneKind.progesterone => colors.luteal().fill,
  HormoneKind.lh => colors.ovulation.fill,
  HormoneKind.fsh => colors.follicular.fill,
};

/// Text-safe variant of [hormoneColor].
Color hormoneTextColor(PhaseColors colors, HormoneKind kind) => switch (kind) {
  HormoneKind.estrogen => colors.period.text,
  HormoneKind.progesterone => colors.luteal().text,
  HormoneKind.lh => colors.ovulation.text,
  HormoneKind.fsh => colors.follicular.text,
};

class HormoneChart extends StatefulWidget {
  const HormoneChart({
    super.key,
    required this.model,
    required this.selectedDay,
    required this.onDayChanged,
  });

  final CyclePhaseModel model;

  /// 1-based explored cycle day, shared with the cycle dial.
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  @override
  State<HormoneChart> createState() => _HormoneChartState();
}

class _HormoneChartState extends State<HormoneChart> {
  HormoneKind? _focus;
  HormoneChartRange _range = HormoneChartRange.cycle;
  bool _expanded = false;
  bool _stageFocused = false;

  final FocusNode _stageNode = FocusNode(debugLabel: 'hormone-chart-stage');

  /// One stable node per readout, so keyboard focus survives the rebuild a
  /// focus change triggers.
  final Map<HormoneKind, FocusNode> _readoutNodes = {
    for (final k in HormoneKind.values)
      k: FocusNode(debugLabel: 'hormone-readout-${k.name}'),
  };

  int get _length => widget.model.cycleLength;
  int get _day => widget.selectedDay.clamp(1, _length);

  @override
  void dispose() {
    _stageNode.dispose();
    for (final n in _readoutNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  (int, int) _bounds(int day) {
    if (_range == HormoneChartRange.cycle) return (1, _length);
    final seg = widget.model.segmentOnDay(day);
    var from = math.max(1, seg.startDay - 1);
    var to = math.min(_length, seg.endDay + 1);
    if (to <= from) {
      from = math.max(1, from - 1);
      to = math.min(_length, to + 1);
    }
    return (from, to);
  }

  void _select(int day) {
    final clamped = day.clamp(1, _length);
    if (clamped != widget.selectedDay) widget.onDayChanged(clamped);
  }

  void _fromLocal(double dx, double width) {
    final (from, to) = _bounds(_day);
    final s = width / HormoneChartPainter.viewWidth;
    final t =
        (dx / s - HormoneChartPainter.left) / HormoneChartPainter.plotWidth;
    _select((from + t * (to - from)).round().clamp(from, to));
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
    final day = _day;
    final muted = context.mutedColor;
    final ink = context.inkColor;
    final accent = context.accent;
    final colors = PhaseColors.of(context);
    final phase = model.segmentOnDay(day).phase;
    final ill = HormoneIllustration(
      cycleLength: _length,
      ovulationDay: model.segmentOf(CyclePhase.ovulation).startDay,
    );
    final small = AppTextStyles.body(
      fontSize: 11,
      height: 1.45,
    ).copyWith(color: muted);

    return Semantics(
      container: true,
      label: 'Interactive educational hormone chart',
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 19, 15, 14),
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
            // Header.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNDERSTAND YOUR CYCLE',
                        style: AppTextStyles.overline.copyWith(
                          color: muted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Semantics(
                        header: true,
                        child: Text(
                          'Hormone patterns',
                          style: AppTextStyles.heading(
                            fontSize: 25,
                            letterSpacing: -0.7,
                          ).copyWith(color: ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                HeaderIconButton(
                  key: const ValueKey('hormone-expand'),
                  icon: AppIcons.external,
                  semanticLabel: _expanded
                      ? 'Compact hormone chart'
                      : 'Expand hormone chart',
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('An illustrative cycle. Explore what changes.', style: small),
            const SizedBox(height: 15),
            // Large type needs the complete chart width for both range labels.
            if (MediaQuery.textScalerOf(context).scale(14) > 18) ...[
              _rangeControl(),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: _AllButton(
                  selected: _focus == null,
                  onTap: () => setState(() => _focus = null),
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: _rangeControl()),
                  const SizedBox(width: AppSpacing.sm),
                  _AllButton(
                    selected: _focus == null,
                    onTap: () => setState(() => _focus = null),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('Relative pattern · each curve normalized', style: small),
                Text('Cycle day', style: small),
              ],
            ),
            const SizedBox(height: 11),
            _stage(context, ill, day),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Day $day · ${phase.label}',
                    key: const ValueKey('hormone-selected-day'),
                    style: AppTextStyles.body(
                      fontSize: 12,
                      height: 1.3,
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: ink),
                  ),
                ),
                _ChartTodayButton(
                  enabled: day != model.cycleDay,
                  onTap: () => _select(model.cycleDay),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Semantics(
                label: 'Explore hormone pattern by cycle day',
                value: cycleDayValueText(model, day),
                child: ExcludeSemantics(
                  child: Slider(
                    key: const ValueKey('hormone-slider'),
                    min: 1,
                    max: _length.toDouble(),
                    divisions: math.max(1, _length - 1),
                    value: day.toDouble(),
                    onChanged: (v) => _select(v.round()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _readouts(context, ill, day, colors),
            // Pattern note.
            Padding(
              padding: const EdgeInsets.only(top: 13, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _focus != null
                          ? hormoneColor(colors, _focus!)
                          : colors.phase(phase).fill,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _focus != null
                              ? '${_focus!.label} pattern'
                              : '${phase.label} phase',
                          key: const ValueKey('hormone-pattern-title'),
                          style: AppTextStyles.body(
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _focus != null
                              ? _focus!.patternCopy
                              : hormonePhaseCopy(phase),
                          style: AppTextStyles.body(
                            fontSize: 11,
                            height: 1.55,
                          ).copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.lineColor)),
              ),
              child: Text(
                'Drag the chart to explore. Tap a hormone to focus.',
                style: small,
              ),
            ),
            const SizedBox(height: 8),
            // Always-visible educational disclosure.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(AppIcons.info, size: 13, color: muted),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Educational illustration, not your measured hormone levels.',
                        key: const ValueKey('hormone-footnote'),
                        style: small,
                      ),
                      _SourceLink(color: accent.text),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, HormoneIllustration ill, int day) {
    final model = widget.model;
    final (from, to) = _bounds(day);
    final colors = PhaseColors.of(context);
    final textScale =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(11) /
        11;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final s = width / HormoneChartPainter.viewWidth;
        final bottom = _expanded ? 270.0 : 185.0;
        final height = (bottom + 45) * s + (textScale - 1) * 22;
        final cursorX =
            s *
            (HormoneChartPainter.left +
                (day - from) / math.max(1, to - from) * 280);
        final tipX = cursorX.clamp(width * 0.18, width * 0.82);

        return Semantics(
          slider: true,
          focusable: true,
          label: 'Scrub hormone patterns by cycle day',
          value: cycleDayValueText(model, day),
          increasedValue: day < _length
              ? cycleDayValueText(model, day + 1)
              : null,
          decreasedValue: day > 1 ? cycleDayValueText(model, day - 1) : null,
          onIncrease: day < _length ? () => _select(day + 1) : null,
          onDecrease: day > 1 ? () => _select(day - 1) : null,
          child: Focus(
            focusNode: _stageNode,
            onKeyEvent: _onKey,
            onFocusChange: (f) => setState(() => _stageFocused = f),
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              onHover: (e) => _fromLocal(e.localPosition.dx, width),
              child: GestureDetector(
                key: const ValueKey('hormone-chart-stage'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  _stageNode.requestFocus();
                  _fromLocal(d.localPosition.dx, width);
                },
                onHorizontalDragStart: (d) =>
                    _fromLocal(d.localPosition.dx, width),
                onHorizontalDragUpdate: (d) =>
                    _fromLocal(d.localPosition.dx, width),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _stageFocused
                          ? colors.ovulation.fill
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              key: const ValueKey('hormone-chart-paint'),
                              painter: HormoneChartPainter(
                                illustration: ill,
                                from: from,
                                to: to,
                                day: day,
                                bottom: bottom,
                                focus: _focus,
                                phaseBands: [
                                  for (final seg in model.segments)
                                    (
                                      seg.startDay,
                                      seg.endDay,
                                      colors.phase(seg.phase).fill,
                                    ),
                                ],
                                curveColors: {
                                  for (final k in HormoneKind.values)
                                    k: hormoneColor(colors, k),
                                },
                                dateLabels: {
                                  for (var d = from; d <= to; d++)
                                    d: _short(cycleDayDate(model, d)),
                                },
                                line: context.lineColor,
                                muted: context.mutedColor,
                                paper: context.cardColor,
                                cursor: context.accent.fill,
                                textScale: textScale,
                              ),
                            ),
                          ),
                        ),
                        // Tooltip follows the crosshair with no transition.
                        Positioned(
                          top: -2,
                          left: tipX,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: ExcludeSemantics(
                              child: _Tooltip(
                                date: _short(cycleDayDate(model, day)),
                                day: day,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rangeControl() => SegmentedTabs<HormoneChartRange>(
    key: const ValueKey('hormone-range'),
    semanticLabel: 'Chart time range',
    segments: const [
      SegmentOption(value: HormoneChartRange.cycle, label: 'Full cycle'),
      SegmentOption(value: HormoneChartRange.phase, label: 'This phase'),
    ],
    value: _range,
    onChanged: (value) => setState(() => _range = value),
  );

  Widget _readouts(
    BuildContext context,
    HormoneIllustration ill,
    int day,
    PhaseColors colors,
  ) {
    Widget cell(HormoneKind k) => _Readout(
      key: ValueKey('hormone-readout-${k.name}'),
      kind: k,
      trend: ill.trendAt(k, day),
      selected: _focus == k,
      focusNode: _readoutNodes[k]!,
      dot: hormoneColor(colors, k),
      text: hormoneTextColor(colors, k),
      onTap: () => setState(() => _focus = _focus == k ? null : k),
    );
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in HormoneKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: cell(kind),
            ),
        ],
      );
    }
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cell(HormoneKind.estrogen)),
              const SizedBox(width: 7),
              Expanded(child: cell(HormoneKind.progesterone)),
            ],
          ),
        ),
        const SizedBox(height: 7),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cell(HormoneKind.lh)),
              const SizedBox(width: 7),
              Expanded(child: cell(HormoneKind.fsh)),
            ],
          ),
        ),
      ],
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _short(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// Paints bands, grid, curves, focused area, crosshair and axis labels in a
/// 336-unit-wide viewBox. Text is drawn at logical size so it never shrinks
/// below the 11 px caption floor.
class HormoneChartPainter extends CustomPainter {
  HormoneChartPainter({
    required this.illustration,
    required this.from,
    required this.to,
    required this.day,
    required this.bottom,
    required this.focus,
    required this.phaseBands,
    required this.curveColors,
    required this.dateLabels,
    required this.line,
    required this.muted,
    required this.paper,
    required this.cursor,
    required this.textScale,
  });

  static const double viewWidth = 336;
  static const double left = 35;
  static const double plotWidth = 280;
  static const double top = 30;

  final HormoneIllustration illustration;
  final int from;
  final int to;
  final int day;
  final double bottom;
  final HormoneKind? focus;
  final List<(int, int, Color)> phaseBands;
  final Map<HormoneKind, Color> curveColors;
  final Map<int, String> dateLabels;
  final Color line;
  final Color muted;
  final Color paper;
  final Color cursor;
  final double textScale;

  /// True when [kind] is drawn faded because another hormone is focused.
  bool isMuted(HormoneKind kind) => focus != null && focus != kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / viewWidth;
    final span = math.max(1, to - from).toDouble();
    final range = bottom == 270 ? 235.0 : 150.0;
    double x(double d) => s * (left + (d - from) / span * plotWidth);
    double y(double v) => s * (bottom - v * range);
    final plotLeft = x(from.toDouble());
    final plotRight = x(to.toDouble());

    // Phase bands.
    for (final (a, b, color) in phaseBands) {
      final lo = math.max(from.toDouble(), a - 0.5);
      final hi = math.min(to.toDouble(), b + 0.5);
      if (hi <= lo) continue;
      canvas.drawRect(
        Rect.fromLTRB(x(lo), s * top, x(hi), s * bottom),
        Paint()..color = color.withValues(alpha: 0.055),
      );
    }

    // Grid with Low / Mid / High.
    final grid = Paint()
      ..color = line
      ..strokeWidth = 0.8;
    for (final (v, label) in const [
      (0.0, 'Low'),
      (0.5, 'Mid'),
      (1.0, 'High'),
    ]) {
      final gy = y(v);
      for (var gx = plotLeft; gx < plotRight; gx += 6) {
        canvas.drawLine(
          Offset(gx, gy),
          Offset(math.min(gx + 2, plotRight), gy),
          grid,
        );
      }
      _text(
        canvas,
        label,
        Offset(plotLeft - 4, gy),
        _Anchor.rightMiddle,
        fontSize: 11,
        color: muted,
      );
    }

    // Curves.
    Path curve(HormoneKind k) {
      final p = Path();
      const steps = 140;
      for (var i = 0; i <= steps; i++) {
        final d = from + span * i / steps;
        final pt = Offset(x(d), y(illustration.valueAt(k, d)));
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      return p;
    }

    if (focus != null) {
      final area = curve(focus!)
        ..lineTo(plotRight, s * bottom)
        ..lineTo(plotLeft, s * bottom)
        ..close();
      final c = curveColors[focus]!;
      canvas.drawPath(
        area,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.withValues(alpha: 0.21), c.withValues(alpha: 0.01)],
              ).createShader(
                Rect.fromLTRB(plotLeft, s * top, plotRight, s * bottom),
              ),
      );
    }
    // Muted curves first so the focused one sits on top.
    final order = [
      ...HormoneKind.values.where(isMuted),
      ...HormoneKind.values.where((k) => !isMuted(k)),
    ];
    for (final k in order) {
      final c = curveColors[k]!;
      canvas.drawPath(
        curve(k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = isMuted(k) ? c.withValues(alpha: 0.14) : c,
      );
    }

    // Curve name tags at each visible peak, so colour is never the only key.
    for (final k in HormoneKind.values) {
      if (isMuted(k)) continue;
      var peakDay = from.toDouble();
      var peak = -1.0;
      for (var d = from.toDouble(); d <= to; d += 0.1) {
        final v = illustration.valueAt(k, d);
        if (v > peak) {
          peak = v;
          peakDay = d;
        }
      }
      final anchor = switch (k) {
        HormoneKind.estrogen => _Anchor.bottomRight,
        HormoneKind.lh => _Anchor.bottomLeft,
        _ => _Anchor.bottomCenter,
      };
      final dx = switch (k) {
        HormoneKind.estrogen => -3.0,
        HormoneKind.lh => 3.0,
        _ => 0.0,
      };
      final pos = Offset(
        (x(peakDay) + dx).clamp(plotLeft + 12, plotRight - 12),
        y(peak) - 3,
      );
      _text(
        canvas,
        k.shortLabel,
        pos,
        anchor,
        fontSize: 11,
        color: curveColors[k]!,
        weight: FontWeight.w600,
      );
    }

    // Crosshair and per-curve dots.
    final cx = x(day.toDouble());
    final dash = Paint()
      ..color = cursor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var dy = s * (top - 5); dy < s * bottom; dy += 5 * s) {
      canvas.drawLine(
        Offset(cx, dy),
        Offset(cx, math.min(dy + 2 * s, s * bottom)),
        dash,
      );
    }
    for (final k in order) {
      final c = curveColors[k]!;
      final p = Offset(cx, y(illustration.valueAt(k, day.toDouble())));
      final mutedDot = isMuted(k);
      canvas.drawCircle(
        p,
        3.7 * s + 1.7 * s / 2,
        Paint()..color = mutedDot ? paper.withValues(alpha: 0.14) : paper,
      );
      canvas.drawCircle(
        p,
        3.7 * s,
        Paint()..color = mutedDot ? c.withValues(alpha: 0.14) : c,
      );
    }

    // Day and date ticks.
    final ticks = <int>{};
    if (from == 1 && to == illustration.cycleLength) {
      ticks.add(1);
      for (var d = 7; d < to - 2; d += 7) {
        ticks.add(d);
      }
      ticks.add(to);
    } else {
      ticks.addAll({from, ((from + to) / 2).round(), to});
    }
    for (final d in ticks) {
      final tx = x(d.toDouble());
      final anchorTop = s * (bottom + 6);
      final h = _text(
        canvas,
        '$d',
        Offset(tx, anchorTop),
        _Anchor.topCenter,
        fontSize: 11,
        color: muted,
        weight: FontWeight.w600,
      );
      _text(
        canvas,
        dateLabels[d] ?? '',
        Offset(tx, anchorTop + h + 1),
        _Anchor.topCenter,
        fontSize: 11,
        color: muted,
      );
    }
  }

  double _text(
    Canvas canvas,
    String text,
    Offset at,
    _Anchor anchor, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.body(
          fontSize: fontSize * textScale,
          height: 1.1,
          fontWeight: weight,
        ).copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final o = switch (anchor) {
      _Anchor.rightMiddle => at - Offset(tp.width, tp.height / 2),
      _Anchor.topCenter => at - Offset(tp.width / 2, 0),
      _Anchor.bottomCenter => at - Offset(tp.width / 2, tp.height),
      _Anchor.bottomLeft => at - Offset(0, tp.height),
      _Anchor.bottomRight => at - Offset(tp.width, tp.height),
    };
    tp.paint(canvas, o);
    return tp.height;
  }

  @override
  bool shouldRepaint(HormoneChartPainter old) =>
      old.day != day ||
      old.from != from ||
      old.to != to ||
      old.bottom != bottom ||
      old.focus != focus ||
      old.line != line ||
      old.paper != paper ||
      old.cursor != cursor ||
      old.textScale != textScale ||
      old.illustration.cycleLength != illustration.cycleLength ||
      old.illustration.ovulationDay != illustration.ovulationDay;
}

enum _Anchor { rightMiddle, topCenter, bottomCenter, bottomLeft, bottomRight }

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.date, required this.day});

  final String date;
  final int day;

  @override
  Widget build(BuildContext context) {
    final ink = context.inkColor;
    final paper = context.cardColor;
    return Container(
      key: const ValueKey('hormone-tooltip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date,
            style: AppTextStyles.body(
              fontSize: 11,
              height: 1.2,
            ).copyWith(color: paper),
          ),
          const SizedBox(width: 6),
          Text(
            'Day $day',
            style: AppTextStyles.body(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ).copyWith(color: paper),
          ),
        ],
      ),
    );
  }
}

class _AllButton extends StatelessWidget {
  const _AllButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: 'All hormones',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('hormone-all'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: Motion.of(context)(AppDurations.micro),
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTouchTarget,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? context.lineColor : Colors.transparent,
            ),
          ),
          child: Text(
            'All hormones',
            style: AppTextStyles.body(
              fontSize: 11,
              height: 1.2,
            ).copyWith(color: selected ? accent.text : context.mutedColor),
          ),
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    super.key,
    required this.kind,
    required this.trend,
    required this.selected,
    required this.focusNode,
    required this.dot,
    required this.text,
    required this.onTap,
  });

  final HormoneKind kind;
  final HormoneTrend trend;
  final bool selected;
  final FocusNode focusNode;
  final Color dot;
  final Color text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedColor;
    final turn = switch (trend.direction) {
      HormoneDirection.rising => -math.pi / 4,
      HormoneDirection.falling => math.pi / 4,
      HormoneDirection.steady => 0.0,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${kind.label}, ${trend.direction.label}, ${trend.levelText}',
      hint: selected ? 'Tap to show all hormones' : 'Tap to focus this hormone',
      excludeSemantics: true,
      child: InkWell(
        focusNode: focusNode,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Motion.of(context)(AppDurations.micro),
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? context.cardColor : context.canvasColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? dot : context.lineColor,
              width: selected ? AppStrokes.selected : AppStrokes.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      kind.label,
                      style: AppTextStyles.body(
                        fontSize: 11,
                        height: 1.2,
                      ).copyWith(color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Transform.rotate(
                    angle: turn,
                    child: Icon(AppIcons.arrowForward, size: 13, color: text),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      trend.direction.label,
                      style: AppTextStyles.body(
                        fontSize: 12,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                trend.levelText,
                style: AppTextStyles.body(
                  fontSize: 11,
                  height: 1.35,
                ).copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartTodayButton extends StatelessWidget {
  const _ChartTodayButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? context.accent.text : context.mutedColor;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Back to today',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('hormone-today'),
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

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.color});

  final Color color;

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(hormoneIllustrationSourceUrl),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && context.mounted) {
      showAppToast(
        context,
        message: 'Could not open the link. Check you are online.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'About these patterns, opens UCSF in your browser',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('hormone-source-link'),
        onTap: () => _open(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTouchTarget,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              'About these patterns',
              style: AppTextStyles.body(fontSize: 11, height: 1.3).copyWith(
                color: color,
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
