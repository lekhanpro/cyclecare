import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_accents.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_contrast.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'app_card.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Display components
//
// Small, repeated pieces of chrome. Individually unremarkable; collectively
// they are most of what the user actually looks at. Restyled to the redesign:
// DM Sans 600/700 rather than 800/900, accent roles rather than raw seed
// tints, and the redesign's glyph font rather than Material icons.
// ─────────────────────────────────────────────────────────────────────────────

/// The accent tone for a caller-supplied colour, measured against [surface].
/// Falls back to the palette's accent text when the caller passes nothing.
Color _toneOn(BuildContext context, Color? custom, Color surface) =>
    custom == null
        ? context.accent.text
        : AppContrast.readable(custom, surface: surface, isDark: context.isDark);

/// A soft tint of [custom] (or the palette surface), composited to be opaque.
Color _tintFor(BuildContext context, Color? custom) => custom == null
    ? context.accent.surface
    : Color.alphaBlend(
        custom.withOpacity(context.isDark ? 0.20 : 0.11),
        context.cardColor,
      );

/// Section title with an optional trailing action.
///
/// The design's `.section-head`: a 16 px DM Sans 600 title with a muted
/// subtitle, and an accent text action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent.text;
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTextStyles.body(
                      fontSize: 16,
                      height: 1.3,
                      letterSpacing: -0.1,
                      fontWeight: FontWeight.w600,
                    ).copyWith(color: context.inkColor),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body(fontSize: 12, height: 1.4)
                        .copyWith(color: context.mutedColor),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            Pressable(
              onTap: onAction,
              scale: 0.94,
              semanticLabel: actionLabel,
              excludeChildSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppLayout.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTextStyles.body(
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ).copyWith(color: accent),
                      ),
                      const SizedBox(width: 3),
                      Icon(AppIcons.forward, size: 12, color: accent),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact icon + value + label, for reading several numbers side by side.
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = _tintFor(context, accent);
    final tone = _toneOn(context, accent, fill);

    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.body(
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: context.inkColor),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ).copyWith(color: context.mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width stat card for the insights grid.
///
/// The value is a Fraunces numeral, as in the design's `.stat strong`.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final tone = _toneOn(context, accent, context.cardColor);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: AppInsets.compactCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: tone),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: context.mutedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 3,
            children: [
              Text(
                value,
                style: AppTextStyles.heading(
                  fontSize: 26,
                  height: 1.1,
                  letterSpacing: -0.8,
                ).copyWith(color: context.inkColor),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: AppTextStyles.body(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ).copyWith(color: context.mutedColor),
                  ),
                ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: AppTextStyles.body(fontSize: 11, height: 1.35)
                  .copyWith(color: context.mutedColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable row with a leading icon tile — the shape used for settings,
/// quick links, and any "go somewhere" affordance.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accent,
    this.trailing,
    this.emoji,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? accent;
  final Widget? trailing;

  /// Accepted but **not rendered**. Pass an `AppIcons` value to [icon].
  ///
  /// Kept as an inert parameter so the call sites still being migrated keep
  /// compiling. Not marked `@Deprecated` on purpose: that would raise an
  /// analyzer note at every remaining call site and bury real warnings.
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final tile = _tintFor(context, accent);
    final tone = _toneOn(context, accent, tile);

    return AppCard(
      onTap: onTap,
      padding: AppInsets.compactCard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(AppRadii.compact),
            ),
            child: Icon(icon, size: 20, color: tone),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: context.inkColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body(fontSize: 12, height: 1.35)
                        .copyWith(color: context.mutedColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing ??
              Icon(
                AppIcons.forward,
                size: 16,
                color: context.subtleColor,
              ),
        ],
      ),
    );
  }
}

/// Inline notice. Used for late periods, irregular-cycle notes, and medical
/// disclaimers.
///
/// Deliberately not a snackbar: these messages are conditions rather than
/// events, so they persist while the condition holds and are dismissible only
/// when the user has actually resolved it.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = AppIcons.info,
    this.tone,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData icon;

  /// Defaults to the palette accent. Pass `AppColors.warning` or `.error` for
  /// escalating severity.
  final Color? tone;

  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Informational banners take the palette accent; warning and error keep
    // their own hues because there the colour carries the severity (and the
    // icon and title carry it too, so colour is never the only signal).
    final custom = (tone == null || tone == AppColors.info) ? null : tone;
    final fill = _tintFor(context, custom);
    final color = _toneOn(context, custom, fill);
    final border = custom == null
        ? context.accent.border.withOpacity(0.32)
        : custom.withOpacity(0.32);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      color: fill,
      borderColor: border,
      padding: AppInsets.compactCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTextStyles.body(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ).copyWith(color: context.inkColor),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: AppTextStyles.body(fontSize: 12, height: 1.45)
                      .copyWith(color: context.mutedColor),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: onAction,
                    scale: 0.95,
                    semanticLabel: actionLabel,
                    excludeChildSemantics: true,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: Text(
                          actionLabel!,
                          style: AppTextStyles.body(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: color),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            Pressable(
              onTap: onDismiss,
              scale: 0.9,
              semanticLabel: 'Dismiss',
              excludeChildSemantics: true,
              child: SizedBox.square(
                dimension: 36,
                child: Center(
                  child: Icon(
                    AppIcons.close,
                    size: 16,
                    color: context.mutedColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder for a screen with nothing in it yet.
///
/// New screens should prefer [EmptyStateView] from content_states.dart, which
/// is the design's empty-state layout; this keeps the older call sites on the
/// same visual language.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.emoji,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;

  /// Accepted but **not rendered** — pass an `AppIcons` value to [icon].
  final String? emoji;

  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Reveal(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? AppIcons.sparkle,
                  size: 30,
                  color: accent.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Reveal(
              index: 1,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(
                  fontSize: 22,
                  height: 1.2,
                  letterSpacing: -0.5,
                ).copyWith(color: context.inkColor),
              ),
            ),
            const SizedBox(height: 7),
            Reveal(
              index: 2,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(fontSize: 13, height: 1.5)
                    .copyWith(color: context.mutedColor),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              Reveal(
                index: 3,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Labelled 0–10 severity picker used for pain and symptom intensity.
///
/// Rendered as discrete taps rather than a slider: a slider implies continuous
/// precision the user does not have about their own pain, and it is fiddly to
/// hit an exact value one-handed. Ten targets are unambiguous.
class SeveritySelector extends StatelessWidget {
  const SeveritySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 10,
    this.accent,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final base = accent ?? context.accent.fill;

    return Semantics(
      container: true,
      label: 'Severity',
      value: value == 0 ? 'Not set' : '$value of $max',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dividedWidth = constraints.maxWidth / max;
          final itemWidth = dividedWidth < kMinInteractiveDimension
              ? kMinInteractiveDimension
              : dividedWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 1; i <= max; i++)
                  Builder(
                    builder: (context) {
                      final filled = i <= value;
                      // The ramp deepens with severity; the numeral takes
                      // whichever of ink or white measures better on it.
                      final fill = filled
                          ? Color.alphaBlend(
                              base.withOpacity(0.22 + (i / max) * 0.70),
                              context.cardColor,
                            )
                          : context.cardColor;
                      final numeral = filled
                          ? AppContrast.onColor(fill)
                          : context.mutedColor;
                      return SizedBox(
                        width: itemWidth,
                        child: Pressable(
                          onTap: () {
                            Haptics.selection();
                            onChanged(i == value ? 0 : i);
                          },
                          haptic: false,
                          selected: i == value,
                          semanticLabel: 'Severity $i of $max',
                          excludeChildSemantics: true,
                          inMutuallyExclusiveGroup: true,
                          scale: 0.92,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedContainer(
                              duration: motion(AppDurations.fast),
                              curve: AppCurves.out,
                              height: kMinInteractiveDimension,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.compact),
                                border: Border.all(
                                  color: filled
                                      ? Colors.transparent
                                      : context.lineColor,
                                ),
                              ),
                              child: Text(
                                '$i',
                                style: AppTextStyles.body(
                                  fontSize: 12,
                                  height: 1.2,
                                  fontWeight: filled
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ).copyWith(color: numeral),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
