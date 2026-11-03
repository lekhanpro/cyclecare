import 'package:flutter/material.dart';

import '../core/theme/app_accents.dart';
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

  /// Lifted. For the one or two surfaces on a screen that must read as
  /// sitting above the page — a primary stat, a sheet, the focused card.
  ///
  /// Deliberately not the default: if every card is elevated, none is.
  floating,
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

    // A caller-supplied tint is usually translucent (`swatch.surface`, an
    // accent at 8%). Painted as-is, the card's own shadow shows through it and
    // every tinted card turns a muddy grey. Compositing onto the card colour
    // keeps the tint and makes the surface opaque.
    final custom = color;
    final fill = custom != null
        ? (custom.opacity < 1
            ? Color.alphaBlend(custom, context.cardColor)
            : custom)
        : switch (emphasis) {
          CardEmphasis.raised => context.cardColor,
          // `.card` is solid paper in both appearances; outlined differs from
          // raised only by dropping the shade.
          CardEmphasis.outlined => context.cardColor,
          CardEmphasis.tinted => context.accent.surface,
          // Dark mode cannot lift a surface with shadow alone, so a floating
          // card is also a lighter fill than the cards around it.
          CardEmphasis.floating =>
            dark ? context.elevatedCardColor : context.cardColor,
        };

    final border = switch (emphasis) {
      CardEmphasis.outlined => Border.all(
          color: borderColor ?? context.lineColor,
          width: AppStrokes.hairline,
        ),
      CardEmphasis.raised => Border.all(
          color: borderColor ?? context.lineColor,
          width: AppStrokes.hairline,
        ),
      CardEmphasis.tinted => borderColor == null
          ? null
          : Border.all(
              color: borderColor!,
              width: AppStrokes.hairline,
            ),
      // A floating card is separated by its shadow. Adding a border on top of
      // that reads as two competing edges and flattens the lift it is for.
      CardEmphasis.floating => borderColor == null
          ? (dark
              ? Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: AppStrokes.hairline,
                )
              : null)
          : Border.all(color: borderColor!, width: AppStrokes.hairline),
    };

    final shadows = switch (emphasis) {
      CardEmphasis.raised => AppElevation.low(dark),
      CardEmphasis.floating => AppElevation.medium(dark),
      CardEmphasis.outlined || CardEmphasis.tinted => AppElevation.none,
    };

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
