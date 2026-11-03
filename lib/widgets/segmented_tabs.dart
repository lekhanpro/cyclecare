import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/cyclecare_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Segmented tabs
//
// The calendar's Month / Year overview control, from its spec:
//
//   div.segmented  342x40, accent-soft fill, radius 14, padding 4
//     button.active 167x32, paper fill, accent text, 11/600, radius 10,
//                   shadow rgba(57,32,45,.02) 0 2px 8px
//     button        muted text, 11/400, no fill
//
// The selected segment slides rather than cutting, because the track makes the
// travel legible — and under reduced motion the slide collapses to an instant
// swap, which is why the position is animated through [Motion] rather than by
// a bare AnimatedAlign.
//
// Selection is carried by fill, weight *and* contrast, not by colour alone,
// and each segment is announced as a tab in a mutually exclusive group so a
// screen reader says "selected" instead of leaving the user to infer it.
// ─────────────────────────────────────────────────────────────────────────────

/// One option in a [SegmentedTabs].
@immutable
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  final T value;
  final String label;

  /// Optional leading glyph. The design's own control is text-only; a few
  /// screens (log categories) pair an icon with the word.
  final IconData? icon;

  /// Where the visible label is abbreviated and the spoken one should not be.
  final String? semanticLabel;
}

class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.height = 40,
  });

  /// `.segmented{height:40px;padding:4px;border-radius:14px}`.
  static const double trackPadding = 4;

  final List<SegmentOption<T>> segments;
  final T value;

  /// Null disables the whole control, which still renders its current value.
  final ValueChanged<T>? onChanged;

  final String? semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final motion = Motion.of(context);
    final enabled = onChanged != null;
    final selectedIndex = segments.indexWhere((s) => s.value == value);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        constraints: BoxConstraints(minHeight: height < 48 ? 48 : height),
        padding: const EdgeInsets.all(trackPadding),
        decoration: BoxDecoration(
          color: accent.surface,
          borderRadius: BorderRadius.circular(AppRadii.calendarDay),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = segments.length;
            final segmentWidth = count == 0
                ? 0.0
                : constraints.maxWidth / count;

            return Stack(
              children: [
                // The moving selection sits under the labels so the text does
                // not cross-fade with it.
                if (selectedIndex >= 0)
                  AnimatedPositioned(
                    duration: motion(AppDurations.fast),
                    curve: AppCurves.out,
                    left: segmentWidth * selectedIndex,
                    width: segmentWidth,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(AppRadii.compact),
                        boxShadow: AppElevation.low(context.isDark),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        child: _Segment<T>(
                          segment: segment,
                          selected: segment.value == value,
                          enabled: enabled,
                          onTap: () {
                            if (segment.value == value) return;
                            Haptics.selection();
                            onChanged!(segment.value);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SegmentOption<T> segment;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final color = !enabled
        ? context.subtleColor
        : selected
        ? accent.onSurface
        : context.mutedColor;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      enabled: enabled,
      label: segment.semanticLabel ?? segment.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Center(
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (segment.icon != null) ...[
                  Icon(segment.icon, size: 15, color: color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    segment.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ).copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
