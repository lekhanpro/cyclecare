import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'motion.dart';

enum CardEmphasis {
  /// Default surface with restrained depth.
  raised,

  /// Flat fill, hairline border, no shadow.
  outlined,

  /// Low-emphasis palette tint for grouping.
  tinted,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.emphasis = CardEmphasis.raised,
    this.color,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final CardEmphasis emphasis;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.card);
    final dark = context.isDark;

    final fill = color ??
        switch (emphasis) {
          CardEmphasis.raised => context.cardColor,
          CardEmphasis.outlined => dark
              ? context.cardColor.withOpacity(0.62)
              : Colors.white.withOpacity(0.84),
          CardEmphasis.tinted => dark
              ? context.cardColor.withOpacity(0.76)
              : context.accentColor.withOpacity(0.055),
        };

    final border = switch (emphasis) {
      CardEmphasis.outlined => Border.all(
          color: borderColor ?? context.lineColor,
          width: AppStrokes.hairline,
        ),
      CardEmphasis.raised => Border.all(
          color: borderColor ?? context.lineColor.withOpacity(dark ? 0.70 : 0.58),
          width: AppStrokes.hairline,
        ),
      CardEmphasis.tinted => borderColor == null
          ? null
          : Border.all(
              color: borderColor!,
              width: AppStrokes.hairline,
            ),
    };

    final shadows = emphasis == CardEmphasis.raised
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.20 : 0.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[];

    Widget surface = AnimatedContainer(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      padding: padding ?? AppInsets.card,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      surface = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: 0.985,
        borderRadius: radius,
        child: surface,
      );
    }

    return margin == null ? surface : Padding(padding: margin!, child: surface);
  }
}

/// A phase-tinted card with a non-colour leading marker.
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.child,
    required this.swatch,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final PhaseSwatch swatch;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return AppCard(
      margin: margin,
      onTap: onTap,
      padding: EdgeInsets.zero,
      color: swatch.surface,
      borderColor: swatch.border,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 5),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
                child: child,
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: swatch.fill),
            ),
          ],
        ),
      ),
    );
  }
}
