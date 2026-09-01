import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';

/// Frosted-glass surface in the iOS style — a real backdrop blur behind a
/// translucent fill, with the hairline top highlight that gives iOS materials
/// their sense of depth.
///
/// Unlike `SoftCard` (an opaque elevated card), this samples and blurs whatever
/// is painted behind it, so it needs a colourful or gradient backdrop to read
/// correctly. Over a flat white background it will look almost invisible.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 18,
    this.opacity,
    this.tint,
    this.onTap,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  /// Sigma passed to the backdrop blur. iOS system materials sit around 18–30.
  final double blur;

  /// Fill opacity. Defaults to a value tuned per brightness.
  final double? opacity;

  /// Optional colour wash over the glass — usually a phase colour.
  final Color? tint;

  final VoidCallback? onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(24);

    // Dark glass needs a lighter veil to separate from the background;
    // light glass needs a heavier one to stay legible over saturated colour.
    final fillOpacity = opacity ?? (isDark ? 0.22 : 0.58);
    final base = tint ?? (isDark ? AppColors.darkCard : AppColors.white);

    // Note: the base fill and the sheen must live on separate layers.
    // BoxDecoration's gradient shader replaces its color, so setting both on
    // one decoration silently drops the fill and the glass renders empty.
    final surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: base.withOpacity(fillOpacity),
            border: showBorder
                ? Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.14 : 0.55),
                    width: 0.8,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Vertical sheen — brighter at the top edge, like frosted glass
              // catching light from above.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.10 : 0.30),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(18),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Soft ambient shadow, kept low-contrast so the glass still feels weightless.
    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.34 : 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: surface,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: shadowed);
    }
    return shadowed;
  }
}

/// Full-bleed phase-tinted gradient, used as the backdrop that [GlassCard]
/// blurs against. Without something like this behind it, glass has nothing
/// to sample.
class PhaseBackdrop extends StatelessWidget {
  const PhaseBackdrop({
    super.key,
    required this.colors,
    required this.child,
  });

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(colors.first, AppColors.darkBg, 0.72)!,
                  Color.lerp(colors.last, AppColors.darkBg, 0.86)!,
                ]
              : [
                  Color.lerp(colors.first, AppColors.white, 0.62)!,
                  Color.lerp(colors.last, AppColors.cream, 0.78)!,
                ],
        ),
      ),
      child: child,
    );
  }
}
