import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/phase_colors.dart';
import 'app_card.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Display components
//
// Small, repeated pieces of chrome. Individually unremarkable; collectively
// they are most of what the user actually looks at, and the reason a screen
// either feels composed or assembled.
// ─────────────────────────────────────────────────────────────────────────────

/// Section title with an optional trailing action.
///
/// Titles are set small, heavy and slightly tracked rather than large — the
/// content should be the loudest thing on the screen, not the labels
/// organising it.
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
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 4, right: 4, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                    color: context.inkColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            Pressable(
              onTap: onAction,
              scale: 0.94,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.accentColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: context.accentColor,
                    ),
                  ],
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
    final tone = accent ?? context.accentColor;

    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tone.withOpacity(context.isDark ? 0.18 : 0.09),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: context.inkColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width stat card for the insights grid.
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
    final tone = accent ?? context.accentColor;

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: const EdgeInsets.all(14),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.mutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: context.inkColor,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.subtleColor,
              ),
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
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? context.accentColor;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withOpacity(context.isDark ? 0.20 : 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 19))
                : Icon(icon, size: 20, color: tone),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: context.inkColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
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
/// events, so they need to persist while the condition holds and be dismissible
/// only when the user has actually resolved it.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_rounded,
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
    final color = tone ?? context.accentColor;

    return AppCard(
      color: color.withOpacity(context.isDark ? 0.16 : 0.09),
      borderColor: color.withOpacity(0.28),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: context.isDark
                        ? context.inkColor.withOpacity(0.86)
                        : context.mutedColor,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 9),
                  Pressable(
                    onTap: onAction,
                    scale: 0.95,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: color,
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
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: context.mutedColor,
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
/// Empty states are the first thing every new user sees, so they get real
/// design attention rather than a centred "No data" string. Each one names
/// what will appear here and offers the action that fills it.
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
  final String? emoji;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Reveal(
              child: Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.accentColor
                      .withOpacity(context.isDark ? 0.18 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 34))
                    : Icon(
                        icon ?? Icons.spa_rounded,
                        size: 32,
                        color: context.accentColor,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Reveal(
              index: 1,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: context.inkColor,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Reveal(
              index: 2,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: context.mutedColor,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              Reveal(
                index: 3,
                child: Pressable(
                  onTap: onAction,
                  scale: 0.96,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.accentColor.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
    final tone = accent ?? context.accentColor;

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
                  SizedBox(
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
                            color: i <= value
                                ? tone.withOpacity(0.18 + (i / max) * 0.55)
                                : context.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: i <= value
                                  ? Colors.transparent
                                  : context.lineColor,
                            ),
                          ),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i <= value
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: i <= value
                                  ? (i > max * 0.6
                                      ? Colors.white
                                      : context.inkColor)
                                  : context.mutedColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
