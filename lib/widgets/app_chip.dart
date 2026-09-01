import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import 'motion.dart';

/// Palette-aware selectable chip with fixed geometry and explicit semantics.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.accent,
    this.emoji,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final Color? accent;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final tone = accent ?? context.accentColor;
    final foreground = selected
        ? (context.isDark
            ? Colors.white
            : Color.lerp(tone, Colors.black, 0.40)!)
        : context.inkColor;
    final radius = BorderRadius.circular(AppRadii.pill);

    return Pressable(
      onTap: () {
        Haptics.selection();
        onSelected(!selected);
      },
      haptic: false,
      selected: selected,
      semanticLabel: label,
      semanticHint: selected ? 'Tap to deselect' : 'Tap to select',
      excludeChildSemantics: true,
      inMutuallyExclusiveGroup: false,
      scale: 0.96,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        constraints: const BoxConstraints(
          minHeight: AppLayout.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tone.withOpacity(context.isDark ? 0.30 : 0.14)
              : context.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: selected ? tone : context.lineColor,
            width: selected ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.sm),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? tone : context.mutedColor,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility wrapper for existing call sites.
class SymptomChip extends StatelessWidget {
  const SymptomChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => SelectableChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
      );
}

/// Material 3 segmented selector with a single quiet moving indicator.
class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.accent,
  }) : assert(segments.length > 0, 'segments cannot be empty');

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final tone = accent ?? context.accentColor;
    final keys = segments.keys.toList();
    final selectedIndex = keys.indexOf(value);
    final index = selectedIndex < 0 ? 0 : selectedIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        const trackPadding = AppSpacing.xs;
        final slotWidth =
            (constraints.maxWidth - trackPadding * 2) / keys.length;
        final radius = BorderRadius.circular(AppRadii.control);

        return Container(
          height: AppLayout.minTouchTarget,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.black.withOpacity(0.24)
                : tone.withOpacity(0.07),
            borderRadius: radius,
            border: Border.all(
              color: context.lineColor.withOpacity(context.isDark ? 0.72 : 0.62),
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: motion(AppDurations.fast),
                curve: AppCurves.inOut,
                start: slotWidth * index,
                top: 0,
                bottom: 0,
                width: slotWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppRadii.compact),
                    border: Border.all(
                      color: context.lineColor.withOpacity(0.66),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          context.isDark ? 0.20 : 0.045,
                        ),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var itemIndex = 0;
                      itemIndex < keys.length;
                      itemIndex++)
                    Expanded(
                      child: Pressable(
                        onTap: () {
                          final key = keys[itemIndex];
                          if (key == value) return;
                          Haptics.selection();
                          onChanged(key);
                        },
                        haptic: false,
                        selected: keys[itemIndex] == value,
                        semanticLabel: segments[keys[itemIndex]]!,
                        semanticValue: '${itemIndex + 1} of ${keys.length}',
                        excludeChildSemantics: true,
                        inMutuallyExclusiveGroup: true,
                        scale: 0.97,
                        borderRadius:
                            BorderRadius.circular(AppRadii.compact),
                        minimumSize: Size.zero,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: motion(AppDurations.fast),
                            curve: AppCurves.out,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: keys[itemIndex] == value
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: keys[itemIndex] == value
                                  ? tone
                                  : context.mutedColor,
                            ),
                            child: Text(
                              segments[keys[itemIndex]]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
