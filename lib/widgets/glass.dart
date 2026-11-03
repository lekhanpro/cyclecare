import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Liquid Glass
//
// Glass is a *conditional* material, not a skin. A backdrop blur samples what
// is painted behind it, so glass over a flat near-white page has nothing to
// sample and renders as a flat grey box with a border — which is exactly how
// the old GlassCard looked on the previous pale wash, and why it read as
// invisible rather than premium.
//
// So the rule in this app is: glass only where there is colour beneath it.
//   - over a PhaseHero or any saturated surface   → glass
//   - floating chrome with content scrolling under → glass
//   - sheets and overlays above a dimmed page      → glass
//   - a content card on the page background        → opaque AppCard
//
// What makes it read as glass rather than translucency is four layers, and
// dropping any of them flattens it:
//
//   1. A real backdrop blur, with saturation pushed up. iOS materials boost
//      the colour they sample; a plain blur greys everything behind it and is
//      the single biggest tell of fake glass.
//   2. A translucent fill, heavier in light mode than dark.
//   3. A specular top edge — a bright hairline on the top border only, fading
//      toward the bottom. This is the "lit rim" that sells thickness.
//   4. A vertical sheen falling from the top edge.
// ─────────────────────────────────────────────────────────────────────────────

/// How much colour a glass surface is sitting on, which decides how hard it
/// has to work to stay legible.
enum GlassTone {
  /// Over a saturated surface: a hero, a phase block, a photo. Light fill,
  /// bright rim, white ink.
  onColor,

  /// Floating chrome over scrolling page content — a nav bar or app bar.
  /// Heavier fill so text stays readable whatever scrolls underneath.
  chrome,

  /// A sheet or dialog above a dimmed page.
  sheet,
}

/// A Liquid Glass surface.
///
/// Prefer `AppCard` for ordinary content. Reach for this only in the three
/// situations named in [GlassTone] — the file header explains why.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.tone = GlassTone.onColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.blur,
    this.tint,
  });

  final Widget child;
  final GlassTone tone;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// Blur sigma. iOS system materials sit around 18–32.
  final double? blur;

  /// Optional colour wash, usually a phase hue.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.card);

    // Fill opacity per tone. Chrome carries arbitrary scrolling content behind
    // it, so it needs the heaviest veil to keep labels legible; onColor sits on
    // a known surface and can stay light.
    final fill = switch (tone) {
      GlassTone.onColor => dark ? 0.16 : 0.20,
      GlassTone.chrome => dark ? 0.72 : 0.78,
      GlassTone.sheet => dark ? 0.80 : 0.86,
    };

    final base = tint ??
        switch (tone) {
          GlassTone.onColor => Colors.white,
          GlassTone.chrome || GlassTone.sheet =>
            dark ? AppColors.darkSurface : Colors.white,
        };

    final sigma = blur ??
        switch (tone) {
          GlassTone.onColor => 14.0,
          GlassTone.chrome => 24.0,
          GlassTone.sheet => 30.0,
        };

    // The rim: bright along the top, fading to nothing at the bottom. A
    // uniform border reads as a stroke around a shape; a gradient rim reads as
    // a lit edge on a solid piece of material.
    final rimTop = Colors.white.withOpacity(
      tone == GlassTone.onColor ? (dark ? 0.34 : 0.62) : (dark ? 0.16 : 0.90),
    );
    final rimBottom = Colors.white.withOpacity(dark ? 0.04 : 0.14);

    Widget surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        // Saturation first, then blur. iOS materials amplify the colour they
        // sample — without this the glass greys out whatever is behind it and
        // immediately looks like a translucent grey rectangle instead of glass.
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          inner: ColorFilter.matrix(_saturate(dark ? 1.35 : 1.5)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: base.withOpacity(fill),
          ),
          child: Stack(
            children: [
              // Sheen, falling from the top edge.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(dark ? 0.08 : 0.22),
                          Colors.white.withOpacity(0),
                        ],
                        stops: const [0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
              // Specular rim.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: GradientBoxBorder(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [rimTop, rimBottom],
                        ),
                        width: 0.9,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding ?? AppInsets.card, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      surface = Pressable(
        onTap: onTap,
        scale: 0.985,
        borderRadius: radius,
        child: surface,
      );
    }

    if (tone != GlassTone.onColor) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: tone == GlassTone.sheet
              ? AppElevation.high(dark)
              : AppElevation.medium(dark),
        ),
        child: surface,
      );
    }

    return margin == null ? surface : Padding(padding: margin!, child: surface);
  }

  /// Saturation matrix. 1.0 is identity; above that pushes colour.
  static List<double> _saturate(double amount) {
    // Luminance-preserving saturation, so brightness is unchanged and only
    // chroma moves.
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final s = amount;
    return <double>[
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// A [Border] whose colour is a gradient, so an edge can be lit at the top and
/// dark at the bottom.
///
/// Flutter's own Border takes a flat colour per side, which cannot express a
/// specular rim — the detail that makes glass look like a solid pane rather
/// than a translucent fill.
@immutable
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  BorderSide get top => BorderSide(width: width);

  @override
  bool get isUniform => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;

    // Inset by half the stroke so the line sits inside the clip rather than
    // being shaved in half by it.
    final inner = rect.deflate(width / 2);

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(inner), paint);
    } else if (shape == BoxShape.circle) {
      canvas.drawCircle(inner.center, inner.shortestSide / 2, paint);
    } else {
      canvas.drawRect(inner, paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}
