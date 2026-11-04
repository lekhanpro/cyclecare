import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_accents.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'motion.dart';

/// A primary action with a minimum target height that grows for enlarged text.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
    this.destructive = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final bool destructive;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accent;
    final brightness = Theme.of(context).brightness;
    final danger = AccentRoles.destructive(brightness);
    final dangerText = AccentRoles.dangerText(brightness);
    final hasAction = onPressed != null;
    final enabled = hasAction && !loading;
    // Filled: `.primary` (accent fill + measured onFill). Outlined: the
    // design's `.secondary` hairline variant, accent text on paper.
    final fillTone = destructive ? danger.$1 : accent.fill;
    final textTone = destructive ? dangerText : accent.text;
    final activeForeground = outlined
        ? textTone
        : (destructive ? danger.$2 : accent.onFill);
    final foreground = hasAction || loading
        ? activeForeground
        : context.inkColor.withOpacity(0.38);

    final labelContent = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ).copyWith(color: foreground),
          ),
        ),
      ],
    );

    // The label remains laid out to preserve button width. The indeterminate
    // indicator only exists while loading, so idle buttons own no ticker.
    final content = Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: loading ? 0 : 1,
          duration: motion(AppDurations.fast),
          curve: AppCurves.fade,
          child: labelContent,
        ),
        if (loading)
          SizedBox(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(activeForeground),
            ),
          ),
      ],
    );

    final radius = BorderRadius.circular(AppRadii.control);
    final background = outlined
        ? context.cardColor
        : hasAction
            ? fillTone
            : context.inkColor.withOpacity(0.10);
    final borderColor = !hasAction
        ? context.inkColor.withOpacity(0.14)
        : destructive
            ? dangerText
            : context.lineColor;

    final surface = AnimatedContainer(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      constraints: const BoxConstraints(minHeight: AppLayout.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: outlined
            ? Border.all(
                color: borderColor,
                width: AppStrokes.hairline,
              )
            : null,
        // The design's `.primary` is flat; depth comes from the fill alone.
        boxShadow: null,
      ),
      child: Center(heightFactor: 1, child: content),
    );

    final button = Pressable(
      onTap: enabled
          ? () {
              if (destructive) Haptics.warn();
              onPressed!();
            }
          : null,
      enabled: enabled,
      selected: null,
      semanticLabel: label,
      semanticValue: loading ? 'Loading' : null,
      semanticHint: loading ? 'Please wait' : null,
      liveRegion: loading,
      excludeChildSemantics: true,
      haptic: !destructive,
      scale: 0.975,
      borderRadius: radius,
      child: surface,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
