import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'motion.dart';

/// CycleCare's stable-height primary action.
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
    final scheme = Theme.of(context).colorScheme;
    final tone = destructive ? scheme.error : scheme.primary;
    final hasAction = onPressed != null;
    final enabled = hasAction && !loading;
    final activeForeground = outlined
        ? tone
        : (destructive ? scheme.onError : scheme.onPrimary);
    final foreground = hasAction || loading
        ? activeForeground
        : scheme.onSurface.withOpacity(0.38);

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: foreground,
            ),
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
        ? Colors.transparent
        : hasAction
            ? tone
            : scheme.onSurface.withOpacity(0.12);
    final borderColor = hasAction
        ? tone
        : scheme.onSurface.withOpacity(0.18);

    final surface = AnimatedContainer(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      height: AppLayout.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: outlined
            ? Border.all(
                color: borderColor,
                width: AppStrokes.selected,
              )
            : null,
        boxShadow: outlined || !enabled
            ? null
            : [
                BoxShadow(
                  color: tone.withOpacity(context.isDark ? 0.22 : 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Center(child: content),
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
