import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'cycle_ring.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase hero
//
// The single saturated surface in the app, and the reason the home screen now
// has a focal point.
//
// The previous hero was a translucent glass card over a pale phase wash: card
// and page sat within a few percent of the same lightness, so the eye had
// nothing to land on and the whole screen read as one soft pink field. The fix
// is contrast of *surface*, not more decoration — one deeply saturated block
// at the top of the page, with every other surface on the screen staying a
// quiet near-white card. That figure-to-ground split is most of what separates
// this from a template, and it is what Flo, Clue and Shine all do.
//
// Three details carry it, and each one is load-bearing:
//
//  1. Full bleed. The gradient runs under the status bar and off both edges,
//     with only the bottom corners rounded. A saturated block inset on all
//     four sides reads as a banner ad; one that bleeds reads as the app's
//     chrome. This is why the widget takes the status bar inset itself rather
//     than sitting inside a SafeArea.
//  2. A tinted shadow, never black. Black under a saturated gradient turns the
//     bottom edge muddy exactly where it meets the page. The glow is the phase
//     hue itself, so the block looks lit rather than dirty.
//  3. A diagonal sheen plus a soft radial highlight. A flat two-stop gradient
//     is recognisably a CSS default; an off-centre highlight gives the surface
//     a light source and is the cheapest way to make a colour block look
//     deliberate.
// ─────────────────────────────────────────────────────────────────────────────

/// Full-bleed saturated phase surface, used as the hero at the top of a screen.
class PhaseHero extends StatelessWidget {
  const PhaseHero({
    super.key,
    required this.swatch,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  });

  final PhaseSwatch swatch;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Only the bottom corners round, so the surface reads as attached to the top
  /// of the window rather than floating in it.
  static const BorderRadius shape = BorderRadius.only(
    bottomLeft: Radius.circular(AppRadii.hero),
    bottomRight: Radius.circular(AppRadii.hero),
  );

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final top = MediaQuery.paddingOf(context).top;

    // The hero-specific stops, not the pale backdrop ones: this surface sits
    // *under* white text, so it is the one place the deep set is required.
    // Dark mode deepens them further toward the page, where a bright block
    // over a near-black canvas glares rather than leads.
    final gradient = dark
        ? <Color>[
            Color.lerp(swatch.hero.first, AppColors.darkBg, 0.34)!,
            Color.lerp(swatch.hero.last, AppColors.darkBg, 0.52)!,
          ]
        : swatch.hero;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: AppElevation.glow(swatch.fill, dark),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Stack(
            children: [
              // Off-centre highlight. Gives the block a light source so it
              // reads as a lit surface rather than a filled rectangle.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.45, -0.85),
                        radius: 1.25,
                        colors: [
                          // Capped at 0.10: the contrast figures quoted on
                          // AppColors.menstrualHero are computed against the
                          // lightest stop *with this highlight applied*, so a
                          // brighter wash here silently breaks AA.
                          Colors.white.withOpacity(dark ? 0.07 : 0.10),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: top) + padding.resolve(null),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ink colours that read correctly on top of [PhaseHero].
///
/// A saturated surface inverts the usual text rules: `context.inkColor` is a
/// near-black tuned for cream and is close to unreadable on a mid-rose block,
/// while plain white at full opacity for *every* level flattens the hierarchy
/// that the type sizes are trying to establish. So hero text has its own three
/// tiers, all white at different opacities — which keeps them in the same
/// family as the surface instead of introducing a second hue.
class HeroInk {
  const HeroInk._(this.primary, this.secondary, this.faint);

  factory HeroInk.of(BuildContext context) {
    // Both modes use white: the dark-mode hero is a deepened version of the
    // same hue, not a light surface, so it takes the same ink.
    return const HeroInk._(
      Colors.white,
      Color(0xE6FFFFFF),
      Color(0x99FFFFFF),
    );
  }

  /// Headlines and the one number the hero exists to show.
  final Color primary;

  /// Supporting sentences and labels.
  final Color secondary;

  /// Tracks, dividers, and the dimmed half of a progress indicator.
  final Color faint;
}

/// The cycle ring as it appears on a saturated hero: white strokes, a bright
/// head marker, and the phase bands held back so the active arc leads.
///
/// Kept separate from [CycleRing] rather than adding a `onColor` flag to it:
/// the two draw different things. The card version shows every phase band at
/// equal weight for reading the whole cycle at a glance, while the hero version
/// is about *position* — so the bands become a quiet reference track and all the
/// contrast goes to the arc travelled so far and the dot at its head.
class HeroCycleRing extends StatelessWidget {
  const HeroCycleRing({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.segments,
    required this.size,
    this.strokeWidth = 14,
    this.animate = true,
    this.child,
  });

  final int cycleDay;
  final int cycleLength;
  final List<RingSegment> segments;
  final double size;
  final double strokeWidth;
  final bool animate;

  /// Centre content. Laid out by the caller so the hero can own its own type.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final ink = HeroInk.of(context);
    final safeLength = cycleLength <= 0 ? 28 : cycleLength;
    final safeDay = cycleDay.clamp(1, safeLength);

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: safeDay / safeLength),
        duration: motion(animate ? AppDurations.reveal : Duration.zero),
        curve: AppCurves.out,
        builder: (context, sweep, _) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: _HeroRingPainter(
                progress: sweep,
                cycleLength: safeLength,
                segments: segments,
                strokeWidth: strokeWidth,
                ink: ink,
              ),
              child: child == null
                  ? null
                  // Clears the main ring *and* the inset phase-band track, so
                  // the centre type never collides with the bands.
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(strokeWidth * 2.2),
                        child: child,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroRingPainter extends CustomPainter {
  _HeroRingPainter({
    required this.progress,
    required this.cycleLength,
    required this.segments,
    required this.strokeWidth,
    required this.ink,
  });

  final double progress;
  final int cycleLength;
  final List<RingSegment> segments;
  final double strokeWidth;
  final HeroInk ink;

  static const _startAngle = -math.pi / 2;
  static const _fullTurn = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Reference track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Phase bands, as an inset track just inside the main ring.
    //
    // First attempt drew them as thin translucent arcs *on* the ring, where
    // the progress arc then painted straight over them and the remainder was
    // too faint to read at all — the render showed an empty ring. Moving them
    // to their own concentric track means they are always visible regardless
    // of how far the progress arc has travelled, which is what makes the ring
    // show the shape of the whole cycle rather than just a percentage.
    final bandRadius = radius - strokeWidth * 1.25;
    final bandRect = Rect.fromCircle(center: center, radius: bandRadius);
    final bandWidth = strokeWidth * 0.42;

    for (final segment in segments) {
      final start = (segment.startDay - 1).clamp(0, cycleLength) / cycleLength;
      final end = segment.endDay.clamp(0, cycleLength) / cycleLength;
      if (end <= start) continue;

      canvas.drawArc(
        bandRect,
        _startAngle + start * _fullTurn,
        (end - start) * _fullTurn,
        false,
        Paint()
          // The phase's own hue, lightened toward the surface so it reads as
          // a band of that colour rather than a foreign sticker. Full white
          // would make all four phases identical and destroy the signal.
          ..color = Color.lerp(segment.color, Colors.white, 0.45)!
              .withOpacity(0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Progress arc: solid white, round-capped, the brightest thing on the
    // surface after the number in the middle.
    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        progress * _fullTurn,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      // Head marker, with a soft halo so it reads as the live position rather
      // than a dot that happens to sit there.
      final angle = _startAngle + progress * _fullTurn;
      final head = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawCircle(
        head,
        strokeWidth * 1.15,
        Paint()..color = Colors.white.withOpacity(0.30),
      );
      canvas.drawCircle(head, strokeWidth * 0.62, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_HeroRingPainter old) {
    return old.progress != progress ||
        old.cycleLength != cycleLength ||
        old.segments != segments ||
        old.strokeWidth != strokeWidth;
  }
}
