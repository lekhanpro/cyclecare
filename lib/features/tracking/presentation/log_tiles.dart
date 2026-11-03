import 'package:flutter/material.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Log tiles
//
// Icon-over-label tiles for the one-tap answers on the log. A grid of tiles is
// faster to scan than a wrap of text chips, because the eye finds the picture
// before it reads the word.
//
// Selected is shown three ways at once: an accent fill, an accent border, and
// a check badge in the corner. The fill alone would fail anyone who cannot
// tell the accent from the card, and the badge is what a glance shows.
// An unselected tile always means "not logged", never "no".
// ─────────────────────────────────────────────────────────────────────────────

/// Foreground and soft background for a catalogue group's `tone`.
class LogTone {
  const LogTone({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

/// Resolves the catalogue's tone names ('sage', 'peach', 'violet', or null for
/// the palette accent) to contrast-checked colours.
LogTone logToneFor(BuildContext context, String? tone) {
  final phases = PhaseColors.of(context);
  switch (tone) {
    case 'sage':
      return LogTone(
        foreground: phases.follicular.text,
        background: phases.follicular.surface,
      );
    case 'violet':
      return LogTone(
        foreground: phases.ovulation.text,
        background: phases.ovulation.surface,
      );
    case 'peach':
      final dark = context.isDark;
      final background = dark ? AppColors.darkPeach : AppColors.peach;
      return LogTone(
        foreground: AppContrast.readable(
          AppPalette.peach.seed,
          surface: background,
          isDark: dark,
        ),
        background: background,
      );
    default:
      final accent = context.accent;
      return LogTone(foreground: accent.text, background: accent.surface);
  }
}

/// A grid of equal tiles. [columns] is the design's count at phone width; it
/// drops as the text grows or the width shrinks so labels never clip.
class LogTileGrid extends StatelessWidget {
  const LogTileGrid({
    super.key,
    required this.children,
    required this.columns,
    this.minTileWidth = 56,
  });

  final List<Widget> children;
  final int columns;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(builder: (context, constraints) {
      const gap = AppSpacing.sm;
      var count = columns;
      if (scale > 1.3) count -= 1;
      if (scale > 1.7) count -= 1;
      final minWidth = minTileWidth * scale.clamp(1.0, 1.6);
      final fit = ((constraints.maxWidth + gap) / (minWidth + gap)).floor();
      if (fit < count) count = fit;
      if (count < 2) count = 2;
      final width = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    });
  }
}

class LogTile extends StatelessWidget {
  const LogTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onLongPress,
    this.semanticHint,
  });

  /// Null for a scale step, which shows only its number.
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accent;
    final radius = BorderRadius.circular(AppRadii.calendarDay);
    final compact = icon == null;

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      semanticLabel: label,
      semanticHint: semanticHint ??
          (selected
              ? 'Selected. Tap again to leave it unlogged'
              : 'Not logged. Tap to record'),
      excludeChildSemantics: true,
      scale: 0.95,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        constraints: BoxConstraints(
          minHeight: compact ? AppLayout.minTouchTarget : 70,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: compact ? AppSpacing.sm : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? accent.surface : context.canvasColor,
          borderRadius: radius,
          border: Border.all(
            color: selected ? accent.fill : context.lineColor,
            width: selected ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: accent.text),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      fontSize: compact ? 14 : 11,
                      height: 1.2,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ).copyWith(
                      color: selected ? accent.onSurface : context.inkColor,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: compact ? -AppSpacing.xs : -AppSpacing.xxs,
                end: compact ? -AppSpacing.xxs : 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppIcons.check, size: 10, color: accent.onFill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
