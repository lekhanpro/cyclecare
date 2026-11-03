import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page header
//
// The redesign opens almost every pushed screen the same way, and the specs
// agree on the measurements down to the margin:
//
//   div.page-back      342x36, gap 12, margin-bottom 16–18
//     svg.back         20x24, ink
//     span.muted       DM Sans 12, muted — the section you came from
//   header.page-heading
//     h1               Fraunces 30–31 / 400 / ls -1
//     p                DM Sans 12/18, muted, margin-top 4–8
//
// Two things this does not do. It is not an AppBar: the design's heading
// scrolls away with the content rather than docking, so it is an ordinary
// sliver of the page body. And it never *invents* a back affordance — the
// back row only appears when a caller supplies a section name or a handler,
// because a root tab has nothing to go back to.
//
// The whole back row is the tap target, not just the 20pt glyph. The design's
// own button is 32x36, which fails the project's 48pt touch-target rule, and
// extending it sideways would push the section label off its measured x. The
// row plus its bottom margin is 52pt tall and the full content width, so the
// target is generous and nothing moves.
// ─────────────────────────────────────────────────────────────────────────────

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.sectionLabel,
    this.eyebrow,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.titleFontSize = 30,
    this.backRowSpacing = 18,
    this.bottomSpacing = 20,
  });

  /// `h1` — the Fraunces page title. Sentence case with a full stop is the
  /// design's voice ("Make yourself at home."), set by the caller.
  final String title;

  /// The muted word beside the back arrow: where this screen sits, not where
  /// the user came from, so it reads the same however the screen was reached.
  /// The back row is hidden when this and [onBack] are both null.
  final String? sectionLabel;

  /// Optional uppercase eyebrow above the title, in [AppTextStyles.overline].
  final String? eyebrow;

  /// Muted supporting line under the title.
  final String? subtitle;

  /// Defaults to popping the route. Pass an explicit handler where leaving
  /// needs a confirmation (see `showUnsavedChangesDialog`).
  final VoidCallback? onBack;

  /// Trailing icon button or avatar, laid out opposite the title the way
  /// `header.page-heading{justify-content:space-between}` does.
  final Widget? trailing;

  /// 30 in most specs, 31 where the title is a single short line.
  final double titleFontSize;

  /// `.page-back{margin-bottom}` — 16 on settings, 18 on the form screens.
  final double backRowSpacing;

  /// `.page-heading{margin-bottom}`.
  final double bottomSpacing;

  bool get _hasBackRow => sectionLabel != null || onBack != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasBackRow) _BackRow(
          label: sectionLabel,
          spacing: backRowSpacing,
          onBack: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: bottomSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          eyebrow!.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      // A page title is the screen's name: it is announced as
                      // a heading so a screen reader can jump to it.
                      semanticsLabel: title,
                      style: AppTextStyles.heading(
                        fontSize: titleFontSize,
                        height: 1.12,
                        letterSpacing: -1,
                      ).copyWith(color: context.inkColor),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          subtitle!,
                          style: AppTextStyles.body(fontSize: 12, height: 1.5)
                              .copyWith(color: context.mutedColor),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({
    required this.label,
    required this.spacing,
    required this.onBack,
  });

  final String? label;
  final double spacing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label == null ? 'Back' : 'Back to $label',
      excludeSemantics: true,
      child: Pressable(
        onTap: onBack,
        haptic: false,
        scale: 0.98,
        excludeChildSemantics: true,
        // The target is the row *and* its bottom margin, which is dead space
        // in the design and the cheapest 52pt the layout has to give.
        child: Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                Icon(AppIcons.back, size: 20, color: context.inkColor),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(fontSize: 12)
                          .copyWith(color: context.mutedColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's `.icon-button`: a 44pt circle with a hairline border and no
/// fill, used as a page header's trailing control.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
  });

  static const double diameter = 44;

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      enabled: onTap != null,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.lineColor,
            width: AppStrokes.hairline,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: onTap == null ? context.subtleColor : context.inkColor,
          ),
        ),
      ),
    );
  }
}

/// The design's circular monogram avatar (`.icon-button.avatar`): 49pt, the
/// accent's soft wash behind an accent initial.
class HeaderAvatar extends StatelessWidget {
  const HeaderAvatar({
    super.key,
    required this.initial,
    this.onTap,
    this.semanticLabel,
    this.diameter = 49,
  });

  final String initial;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final avatar = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: accent.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.isEmpty ? '?' : initial.characters.first.toUpperCase(),
          style: AppTextStyles.body(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ).copyWith(color: accent.onSurface),
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        image: semanticLabel != null,
        excludeSemantics: semanticLabel != null,
        child: avatar,
      );
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: avatar,
    );
  }
}
