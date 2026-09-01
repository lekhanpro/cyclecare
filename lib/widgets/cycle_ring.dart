import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';

@immutable
class RingSegment {
  const RingSegment({
    required this.startDay,
    required this.endDay,
    required this.color,
  });

  /// Inclusive, 1-based cycle day.
  final int startDay;

  /// Inclusive, 1-based cycle day.
  final int endDay;

  final Color color;
}

/// A concise cycle-position summary backed by a phase-segmented visual ring.
class CycleRing extends StatelessWidget {
  const CycleRing({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.segments,
    required this.centerLabel,
    required this.centerValue,
    this.centerCaption,
    this.size = 240,
    this.strokeWidth = 18,
    this.markerColor,
    this.animate = true,
    this.semanticLabel,
  });

  final int cycleDay;
  final int cycleLength;
  final List<RingSegment> segments;
  final String centerLabel;
  final String centerValue;
  final String? centerCaption;
  final double size;
  final double strokeWidth;
  final Color? markerColor;
  final bool animate;

  /// Optional override when a screen can provide a more contextual summary.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final safeLength = cycleLength <= 0 ? 28 : cycleLength;
    final safeDay = cycleDay.clamp(1, safeLength);
    final progress = safeDay / safeLength;
    final summary = semanticLabel ??
        [
          '$centerLabel $centerValue',
          if (centerCaption != null && centerCaption!.trim().isNotEmpty)
            centerCaption!.trim(),
          'cycle day $safeDay of $safeLength',
        ].join('. ');

    return Semantics(
      container: true,
      image: true,
      label: summary,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: motion(animate ? AppDurations.reveal : Duration.zero),
            curve: AppCurves.out,
            builder: (context, sweep, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _CycleRingPainter(
                    progress: sweep,
                    cycleLength: safeLength,
                    segments: segments,
                    strokeWidth: strokeWidth,
                    trackColor: context.lineColor,
                    markerColor: markerColor ?? context.accentColor,
                    markerCollar: context.cardColor,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        strokeWidth + AppRadii.control,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            centerLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: context.mutedColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                centerValue,
                                style: TextStyle(
                                  fontSize: size * 0.30,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  color: context.inkColor,
                                ),
                              ),
                            ),
                          ),
                          if (centerCaption != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              centerCaption!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.mutedColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  _CycleRingPainter({
    required this.progress,
    required this.cycleLength,
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
    required this.markerColor,
    required this.markerCollar,
  });

  final double progress;
  final int cycleLength;
  final List<RingSegment> segments;
  final double strokeWidth;
  final Color trackColor;
  final Color markerColor;
  final Color markerCollar;

  static const _startAngle = -math.pi / 2;
  static const _fullTurn = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    for (final segment in segments) {
      final start = (segment.startDay - 1).clamp(0, cycleLength) / cycleLength;
      final end = segment.endDay.clamp(0, cycleLength) / cycleLength;
      if (end <= start) continue;

      canvas.drawArc(
        rect,
        _startAngle + start * _fullTurn,
        (end - start) * _fullTurn,
        false,
        Paint()
          ..color = segment.color.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }

    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        progress * _fullTurn,
        false,
        Paint()
          ..color = Colors.black.withOpacity(0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }

    final angle = _startAngle + progress * _fullTurn;
    final markerCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final markerRadius = strokeWidth * 0.52;

    canvas.drawCircle(
      markerCenter,
      markerRadius + 3,
      Paint()..color = markerCollar,
    );
    canvas.drawCircle(
      markerCenter,
      markerRadius,
      Paint()..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) {
    return old.progress != progress ||
        old.cycleLength != cycleLength ||
        old.segments != segments ||
        old.strokeWidth != strokeWidth ||
        old.trackColor != trackColor ||
        old.markerColor != markerColor ||
        old.markerCollar != markerCollar;
  }
}

/// Builds display segments from already-computed cycle boundaries.
List<RingSegment> buildCycleSegments({
  required int cycleLength,
  required int periodLength,
  required int ovulationDay,
  required PhaseColors colors,
  bool showFertile = true,
  bool showOvulation = true,
}) {
  final phases = colors;
  final segments = <RingSegment>[
    RingSegment(
      startDay: 1,
      endDay: periodLength.clamp(1, cycleLength),
      color: phases.period.fill,
    ),
  ];

  if (showFertile) {
    final fertileStart = (ovulationDay - 5).clamp(1, cycleLength);
    final fertileEnd = (ovulationDay + 1).clamp(1, cycleLength);
    if (fertileEnd > fertileStart) {
      segments.add(RingSegment(
        startDay: fertileStart,
        endDay: fertileEnd,
        color: phases.fertile.fill,
      ));
    }
  }

  if (showOvulation) {
    final day = ovulationDay.clamp(1, cycleLength);
    segments.add(RingSegment(
      startDay: day,
      endDay: day,
      color: phases.ovulation.fill,
    ));
  }

  return segments;
}
