import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_accents.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import '../core/utils/date_helpers.dart';
import '../features/tracking/domain/cycle_models.dart';
import '../features/tracking/domain/cycle_phase_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The four-phase bar and its phase tabs (design: section.card.home-cycle-map).
//
// Everything is placed from [CyclePhaseModel] fractions, never from the
// design's Oct 8 example. The bar is one picture for assistive technology:
// a single Semantics label carries [CyclePhaseModel.spokenSummary].
// ─────────────────────────────────────────────────────────────────────────────

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Oct 8" for [date].
String shortDateLabel(DateTime date) => '${_monthsShort[date.month - 1]} ${date.day}';

/// True when today is after the last day the model describes, so the period
/// is late. The pin then stops at the end of the bar instead of running off.
bool phaseModelIsPastCycleEnd(CyclePhaseModel model) =>
    dateOnly(model.today).isAfter(model.cycleEnd);

/// Icon used for each phase across the bar tabs, the dial and the chart.
IconData phaseIcon(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => AppIcons.period,
      CyclePhase.follicular => AppIcons.basics,
      CyclePhase.ovulation => AppIcons.ovulation,
      CyclePhase.luteal => AppIcons.luteal,
    };

/// Band colour of [phase] on the bar.
Color phaseBandColor(PhaseColors colors, CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => colors.period.fill,
      CyclePhase.follicular => colors.follicular.band,
      CyclePhase.ovulation => colors.ovulation.fill,
      CyclePhase.luteal => colors.luteal().band,
    };

/// The 11 px four-phase track, overlay lane, today pin and date scale.
class PhaseBar extends StatelessWidget {
  const PhaseBar({super.key, required this.model});

  final CyclePhaseModel model;

  static const double trackHeight = 11;
  static const double trackRadius = 9;
  static const double segmentGap = 2;
  static const double ovulationFloor = 7;
  static const double laneHeight = 6;
  static const double laneBarHeight = 3;
  static const double pinZone = 31;

  /// Pixel widths of the four segments for [width], honouring the 2 px gaps
  /// and the ovulation floor. Exposed so tests can compare against the model.
  static List<double> segmentWidths(CyclePhaseModel model, double width) {
    final segments = model.segments;
    final available = math.max(0.0, width - segmentGap * (segments.length - 1));
    final raw = [for (final s in segments) s.fractionWidth * available];
    final ovIndex = segments.indexWhere((s) => s.phase == CyclePhase.ovulation);
    if (ovIndex >= 0 && raw[ovIndex] < ovulationFloor && available > ovulationFloor * 2) {
      final deficit = ovulationFloor - raw[ovIndex];
      raw[ovIndex] = ovulationFloor;
      // Take the deficit from the widest segment so the total still fits.
      var widest = 0;
      for (var i = 1; i < raw.length; i++) {
        if (i != ovIndex && raw[i] > raw[widest]) widest = i;
      }
      raw[widest] = math.max(0.0, raw[widest] - deficit);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final colors = PhaseColors.of(context);
    final accent = context.accent;
    final pastEnd = phaseModelIsPastCycleEnd(model);
    final labelStyle = AppTextStyles.body(
      fontSize: 11,
      height: 1.1,
      fontWeight: FontWeight.w600,
    ).copyWith(color: accent.text);
    final scaleStyle = AppTextStyles.body(fontSize: 11, height: 1.1)
        .copyWith(color: context.mutedColor);
    final pinLabel = pastEnd
        ? 'Today · after day ${model.cycleLength}'
        : 'Today · day ${model.cycleDay}';

    return Semantics(
      container: true,
      label: model.spokenSummary,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final widths = segmentWidths(model, width);
        final pinFraction = pastEnd ? 1.0 : model.todayFraction.clamp(0.0, 1.0);
        final pinX = (pinFraction * width).clamp(1.0, width - 1.0);
        final textScale = MediaQuery.textScalerOf(context).scale(11) / 11;
        final labelZone = pinZone + (textScale - 1) * 13;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: labelZone + trackHeight + 4 + laneHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Today label, centred on the pin but kept inside the card.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _PinLabel(
                      x: pinX,
                      width: width,
                      text: pinLabel,
                      style: labelStyle,
                    ),
                  ),
                  Positioned(
                    key: const ValueKey('phase-bar-track'),
                    top: labelZone,
                    left: 0,
                    right: 0,
                    height: trackHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(trackRadius),
                      child: Row(
                        children: [
                          for (var i = 0; i < model.segments.length; i++) ...[
                            if (i > 0) const SizedBox(width: segmentGap),
                            Container(
                              key: ValueKey('phase-bar-${model.segments[i].phase.name}'),
                              width: widths[i],
                              color: phaseBandColor(colors, model.segments[i].phase),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Overlay lane.
                  for (final overlay in model.overlays)
                    Positioned(
                      key: ValueKey('phase-lane-${overlay.kind.name}'),
                      top: labelZone + trackHeight + 4,
                      left: overlay.fractionStart * width,
                      width: overlay.fractionWidth * width,
                      height: laneBarHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: overlay.kind == CycleOverlayKind.fertile
                              ? colors.fertile.band
                              : colors.pms.band,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  // Today pin: 2 px accent line with a paper-ringed dot.
                  AnimatedPositioned(
                    key: const ValueKey('phase-bar-pin'),
                    duration: Motion.of(context)(AppDurations.normal),
                    curve: AppCurves.out,
                    top: labelZone - 6,
                    left: pinX - 4,
                    width: 8,
                    height: trackHeight + 10,
                    child: CustomPaint(
                      painter: _PinPainter(
                        color: accent.fill,
                        ring: context.cardColor,
                        late: pastEnd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(shortDateLabel(model.cycleStart), style: scaleStyle)),
                if (model.showsOvulation)
                  Flexible(
                    child: Text(
                      'Ovulation est. ${shortDateLabel(model.segmentOf(CyclePhase.ovulation).start)}',
                      key: const ValueKey('phase-bar-ovulation-callout'),
                      style: scaleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                Flexible(
                  child: Text(
                    shortDateLabel(model.cycleEnd),
                    style: scaleStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _PinLabel extends StatelessWidget {
  const _PinLabel({
    required this.x,
    required this.width,
    required this.text,
    required this.style,
  });

  final double x;
  final double width;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Align the label's centre to the pin, clamped at both card edges.
    final alignX = width <= 0 ? 0.0 : (x / width) * 2 - 1;
    return Align(
      alignment: Alignment(alignX.clamp(-1.0, 1.0), -1),
      child: Text(text, style: style, maxLines: 1),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.color, required this.ring, required this.late});

  final Color color;
  final Color ring;
  final bool late;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), line);
    final dotCenter = Offset(cx, 3);
    canvas.drawCircle(dotCenter, 4, Paint()..color = ring);
    canvas.drawCircle(dotCenter, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.color != color || old.ring != ring || old.late != late;
}

/// Four phase tabs beneath the bar. Selection is owned by the parent.
class PhaseTabs extends StatelessWidget {
  const PhaseTabs({
    super.key,
    required this.model,
    required this.selected,
    required this.onSelected,
  });

  final CyclePhaseModel model;
  final CyclePhase? selected;
  final ValueChanged<CyclePhase> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Explore each phase',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < model.segments.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _PhaseTab(
                segment: model.segments[i],
                selected: model.segments[i].phase == selected,
                onTap: () => onSelected(model.segments[i].phase),
                ovulationHidden: model.segments[i].phase == CyclePhase.ovulation &&
                    !model.showsOvulation,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseTab extends StatelessWidget {
  const _PhaseTab({
    required this.segment,
    required this.selected,
    required this.onTap,
    required this.ovulationHidden,
  });

  final CyclePhaseSegment segment;
  final bool selected;
  final VoidCallback onTap;
  final bool ovulationHidden;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final swatch = PhaseColors.of(context).phase(segment.phase);
    final motion = Motion.of(context);
    final label = segment.phase.label;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label phase, ${segment.dateRangeLabel}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          key: ValueKey('phase-tab-${segment.phase.name}'),
          duration: motion(AppDurations.micro),
          curve: AppCurves.out,
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? accent.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent.border : Colors.transparent,
              width: AppStrokes.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? context.canvasColor : swatch.surface,
                ),
                child: Icon(phaseIcon(segment.phase), size: 17, color: swatch.text),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTextStyles.body(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ).copyWith(color: selected ? accent.text : context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
