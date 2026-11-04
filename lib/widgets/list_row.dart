import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// List row
//
// The backbone of settings, reminders, health, learn and birth control. From
// the settings spec, which twenty other rows across the pack match exactly:
//
//   button.list-row   342x69, padding 12 0, gap 12, bottom hairline
//     span.icon-tile  44x44, radius 14, accent-soft fill, accent 24pt glyph
//     span            strong 14/600  +  small 11/15.4 muted, 4 above
//     svg.forward     16x24, muted
//
// 12 + 44 + 12 + 1 is the 69 the boards show, so the height is a *result* of
// the padding and the tile rather than a number set on the box. That matters
// for the 200% text-scale case: nothing here is a fixed height, so a wrapped
// two-line title makes the row taller instead of overflowing it. The title
// and subtitle wrap; only a trailing value clips, at two lines.
//
// The row is one tap target and one semantics node. Reading a title, then a
// subtitle, then "button" as three separate nodes is how a settings list turns
// into forty swipes for a screen-reader user.
// ─────────────────────────────────────────────────────────────────────────────

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.leading,
    this.trailing,
    this.value,
    this.showChevron,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.enabled = true,
    this.danger = false,
    this.semanticLabel,
    this.semanticValue,
    this.iconTileSize = 44,
    this.verticalPadding = 12,
  });

  /// `strong` — DM Sans 14/600.
  final String title;

  /// `small` — DM Sans 11, muted. The design's rows use it for the current
  /// setting in words ("Understand my cycle"), not for help text.
  final String? subtitle;

  /// The glyph inside the soft tile. Null and with no [leading] the row has
  /// no tile and the copy starts at the gutter, which is how the design's
  /// plainer rows (language, about) are drawn.
  final IconData? icon;

  /// Defaults to the active accent on its own soft wash. Pass a
  /// [PhaseSwatch]'s `text` and `surface` for a phase-coloured row.
  final Color? iconColor;
  final Color? iconBackground;

  /// Replaces the icon tile entirely — an avatar, a pet portrait, a swatch.
  final Widget? leading;

  /// Trailing control: an [AppToggle], a badge, a checkmark. Takes precedence
  /// over [value] and [showChevron].
  final Widget? trailing;

  /// Trailing value text, muted, for a row that opens a picker.
  final String? value;

  /// Defaults to true when the row has an [onTap] and no [trailing].
  final bool? showChevron;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final bool enabled;

  /// Paints the title and glyph in the design's danger colour. The row still
  /// confirms before acting — this marks it, it does not arm it.
  final bool danger;

  final String? semanticLabel;
  final String? semanticValue;

  /// 44 in the specs. Exposed because the error-summary rows use 36.
  final double iconTileSize;

  final double verticalPadding;

  bool get _interactive => enabled && (onTap != null || onLongPress != null);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accent = context.accent;
    final muted = context.mutedColor;
    final dangerColor = isDark ? kDangerTextDark : kDangerTextLight;

    final titleColor = !enabled
        ? context.subtleColor
        : danger
        ? dangerColor
        : context.inkColor;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && icon != null) {
      leadingWidget = Container(
        width: iconTileSize,
        height: iconTileSize,
        decoration: BoxDecoration(
          color:
              iconBackground ??
              (danger ? dangerColor.withOpacity(0.12) : accent.surface),
          borderRadius: BorderRadius.circular(AppRadii.calendarDay),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconTileSize <= 36 ? 19 : 24,
            color: iconColor ?? (danger ? dangerColor : accent.onSurface),
          ),
        ),
      );
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && value != null) {
      trailingWidget = Text(
        value!,
        textAlign: TextAlign.end,
        style: AppTextStyles.body(
          fontSize: 12,
          height: 1.35,
        ).copyWith(color: muted),
      );
    }

    final chevron = showChevron ?? (onTap != null && trailing == null);

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stackTrailing =
              trailingWidget != null &&
              (constraints.maxWidth < 280 ||
                  (scale > 1.3 && constraints.maxWidth < 420));
          return Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: titleColor),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          subtitle!,
                          style: AppTextStyles.body(
                            fontSize: 11,
                            height: 1.4,
                          ).copyWith(color: muted),
                        ),
                      ),
                    if (stackTrailing) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                      child: trailingWidget,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null && !stackTrailing) ...[
                const SizedBox(width: AppSpacing.md),
                if (trailing == null && value != null)
                Flexible(child: trailingWidget)
                else
                trailingWidget,
              ],
              if (chevron) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  AppIcons.forward,
                  size: 16,
                  color: enabled ? muted : context.subtleColor,
                ),
              ],
            ],
          );
        },
      ),
    );

    final bordered = DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: context.lineColor,
                  width: AppStrokes.hairline,
                ),
              )
            : null,
      ),
      child: row,
    );

    if (!_interactive) {
      // A row that does nothing is still content, so its text stays readable
      // to assistive technology — it simply is not announced as a button.
      return Semantics(
        container: true,
        label: semanticLabel,
        value: semanticValue,
        enabled: enabled,
        child: bordered,
      );
    }

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.99,
      haptic: false,
      enabled: enabled,
      semanticLabel:
          semanticLabel ?? [title, if (subtitle != null) subtitle!].join(', '),
      semanticValue: semanticValue ?? value,
      excludeChildSemantics: true,
      child: bordered,
    );
  }
}

/// A small count or status badge for a [ListRow]'s trailing slot.
///
/// Carries a word or a number, never colour alone: a red dot that means
/// "three unread" is not readable to a colour-blind user or a screen reader.
class ListRowBadge extends StatelessWidget {
  const ListRowBadge({
    super.key,
    required this.label,
    this.color,
    this.background,
  });

  final String label;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background ?? accent.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ).copyWith(color: color ?? accent.onSurface),
      ),
    );
  }
}

/// The design's `.section-label`: a 17/600 heading above a group of rows,
/// with an optional trailing action.
///
/// Distinct from [SectionHeader] in `app_display.dart`, which is the older
/// card-level header still used by 21 screens.
class ListSectionLabel extends StatelessWidget {
  const ListSectionLabel({
    super.key,
    required this.label,
    this.action,
    this.topSpacing = 22,
    this.bottomSpacing = 12,
  });

  final String label;
  final Widget? action;
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(
                fontSize: 17,
                height: 1.3,
                letterSpacing: -0.5,
                fontWeight: FontWeight.w600,
              ).copyWith(color: context.inkColor),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
