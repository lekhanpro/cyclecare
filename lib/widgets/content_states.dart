import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';
import 'motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Content states
//
// Loading, empty and error, from `D:/tmp/design-ref/{loading,empty,saveError}`,
// plus the unsaved-changes dialog from `unsaved`.
//
// The shared idea in all four boards is that a non-ideal state is still the
// product: it keeps the page's heading, it says what is true in plain words,
// and it offers the next action. None of them is a spinner over a grey page.
//
// Honesty rules these screens. A skeleton announces that records are being
// read rather than implying content exists; the error state says the entry is
// still here, because it is, and never claims a save that did not happen.
// ─────────────────────────────────────────────────────────────────────────────

/// A placeholder block for content being read from the phone.
///
/// The design's `.sp-skeleton-*` elements are flat accent-soft shapes — no
/// shimmer sweep. A slow opacity pulse stands in for "working", and it stops
/// entirely under reduced motion.
///
/// In a widget test, prefer `pump()` over `pumpAndSettle()` while a skeleton
/// is on screen, or pass `animate: false`: a repeating pulse never settles.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 7,
    this.shape = BoxShape.rectangle,
    this.animate = true,
  });

  /// `.sp-skeleton-line` — a full-width 14pt bar with a 7pt radius.
  const LoadingSkeleton.line({
    Key? key,
    double? width,
    bool animate = true,
  }) : this(key: key, width: width, height: 14, radius: 7, animate: animate);

  /// A larger filled block: a card, a chart, an image.
  const LoadingSkeleton.block({
    Key? key,
    double? width,
    double height = 83,
    double radius = AppRadii.calendarDay,
    bool animate = true,
  }) : this(
          key: key,
          width: width,
          height: height,
          radius: radius,
          animate: animate,
        );

  /// A round placeholder: an avatar, a pet portrait, the cycle ring's hub.
  const LoadingSkeleton.circle({
    Key? key,
    double size = 40,
    bool animate = true,
  }) : this(
          key: key,
          width: size,
          height: size,
          shape: BoxShape.circle,
          animate: animate,
        );

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;
  final bool animate;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LoadingSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldAnimate => widget.animate && !Motion.of(context).reduced;

  /// Starting a repeating ticker belongs here rather than in `build`: the
  /// reduced-motion flag is an inherited dependency, so this runs exactly when
  /// that flag changes.
  void _sync() {
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final shouldAnimate = _shouldAnimate;

    final block = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: accent.surface,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.rectangle
            ? BorderRadius.circular(widget.radius)
            : null,
      ),
    );

    if (!shouldAnimate) return block;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.55).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: block,
    );
  }
}

/// The design's `.sp-skeleton-list`: placeholder rows matching [ListRow]'s
/// metrics, so content arriving does not shift the page.
class SkeletonListRows extends StatelessWidget {
  const SkeletonListRows({
    super.key,
    this.count = 3,
    this.animate = true,
    this.semanticLabel = 'Loading your records',
  });

  final int count;
  final bool animate;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.lineColor,
                    width: AppStrokes.hairline,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 21),
              child: Row(
                children: [
                  LoadingSkeleton.circle(size: 40, animate: animate),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeleton.line(width: 187, animate: animate),
                        const SizedBox(height: AppSpacing.sm),
                        LoadingSkeleton.line(width: 120, animate: animate),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// An empty state for a page that has no records yet.
///
/// The design's board (`empty`) pairs a large soft orb holding the companion
/// with a Fraunces line in the app's voice, a muted explanation and one
/// primary action. It says "there is no rush" rather than treating the absence
/// of data as the user's failure.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.artwork,
    this.orbColor,
    this.orbSize = 185,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.footer,
  });

  /// `h2.quote` — Fraunces 25, centred.
  final String title;

  /// Muted centred explanation beneath it.
  final String? message;

  /// Drawn inside the orb when [artwork] is null.
  final IconData? icon;

  /// Replaces the glyph: the companion portrait on the design's own board.
  final Widget? artwork;

  /// Defaults to the fertile sage wash the board uses.
  final Color? orbColor;
  final double orbSize;

  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Optional card beneath the action — the board's "What will show up here?"
  /// explainer.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          child: Center(
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                color: orbColor ?? phases.fertile.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: artwork ??
                    (icon == null
                        ? null
                        : Icon(
                            icon,
                            size: orbSize * 0.3,
                            color: phases.fertile.text,
                          )),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Reveal(
          index: 1,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(
              fontSize: 25,
              height: 1.3,
              letterSpacing: -0.5,
            ).copyWith(color: context.inkColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Reveal(
            index: 2,
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: 12, height: 1.5)
                  .copyWith(color: context.mutedColor),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 28),
          Reveal(
            index: 3,
            child: FilledButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionIcon != null) ...[
                    Icon(actionIcon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(actionLabel!),
                ],
              ),
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 27),
          Reveal(index: 4, child: footer!),
        ],
      ],
    );
  }
}

/// The error state from the `saveError` board: a warm circular mark with a
/// small badge, a note saying what did *not* happen, and up to three actions.
///
/// Sits under a [PageHeader], which carries the title, exactly as the board
/// does. The note never says the record was saved, and the retry stays the
/// primary action so the user's entry is not stranded.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.noteTitle,
    this.noteMessage,
    this.icon = AppIcons.notes,
    this.badgeIcon = AppIcons.warning,
    this.retryLabel,
    this.retryIcon = AppIcons.undo,
    this.onRetry,
    this.caption,
    this.secondaryLabel,
    this.onSecondary,
    this.dangerLabel,
    this.onDanger,
    this.details,
  });

  /// `strong` inside `.sp-note.sp-warning` — what is true right now.
  final String noteTitle;

  /// The muted follow-on: what to do, and that nothing was lost.
  final String? noteMessage;

  final IconData icon;
  final IconData badgeIcon;

  final String? retryLabel;
  final IconData? retryIcon;
  final VoidCallback? onRetry;

  /// Muted line under the primary action.
  final String? caption;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A destructive text action ("Leave without saving"), in the design's
  /// danger colour. The caller still confirms if the loss is unrecoverable.
  final String? dangerLabel;
  final VoidCallback? onDanger;

  /// Optional summary of what is being held — the board lists the entry's
  /// facts so the user can see their work is intact.
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final phases = PhaseColors.of(context);
    final peach = isDark ? AppColors.darkPeach : AppColors.peach;
    final onPeach = AppContrast.readable(
      AppColors.warning,
      surface: peach,
      isDark: isDark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 115,
            height: 115,
            child: Stack(
              children: [
                Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(color: peach, shape: BoxShape.circle),
                  child: Center(child: Icon(icon, size: 48, color: onPeach)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: phases.fertile.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.canvasColor, width: 4),
                    ),
                    child: Center(
                      child: Icon(
                        badgeIcon,
                        size: 20,
                        color: phases.fertile.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: peach,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                noteTitle,
                style: AppTextStyles.body(
                  fontSize: 12,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ).copyWith(color: context.inkColor),
              ),
              if (noteMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    noteMessage!,
                    style: AppTextStyles.body(fontSize: 11, height: 1.6)
                        .copyWith(color: context.mutedColor),
                  ),
                ),
            ],
          ),
        ),
        if (details != null) ...[
          const SizedBox(height: AppSpacing.lg),
          details!,
        ],
        if (retryLabel != null && onRetry != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: onRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (retryIcon != null) ...[
                  Icon(retryIcon, size: 19),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(retryLabel!),
              ],
            ),
          ),
        ],
        if (caption != null) ...[
          const SizedBox(height: 9),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(fontSize: 11, height: 1.4)
                .copyWith(color: context.mutedColor),
          ),
        ],
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
        if (dangerLabel != null && onDanger != null)
          TextButton(
            onPressed: onDanger,
            style: TextButton.styleFrom(
              foregroundColor: isDark ? kDangerTextDark : kDangerTextLight,
            ),
            child: Text(dangerLabel!),
          ),
      ],
    );
  }
}

/// What the user chose when leaving a screen with unsaved changes.
enum UnsavedChangesChoice {
  /// Commit the changes, then leave.
  save,

  /// Stay on the screen. The safe default, and what a dismissed dialog means.
  keepEditing,

  /// Leave and lose the changes.
  discard,
}

/// The `unsaved` board's dialog: a 27pt card with a peach icon tile, a
/// Fraunces question, and three actions in descending safety.
///
/// Never dismissible by tapping outside. This dialog is the confirmation that
/// stands between a tap and lost data, so an accidental barrier tap must not
/// resolve it; a system back gesture returns [UnsavedChangesChoice.keepEditing]
/// for the same reason.
Future<UnsavedChangesChoice> showUnsavedChangesDialog(
  BuildContext context, {
  String title = 'Keep your little notes?',
  String message =
      'You’ve made changes to this check-in. Save them before leaving, or stay and take your time.',
  String saveLabel = 'Save and leave',
  String keepEditingLabel = 'Keep editing',
  String discardLabel = 'Discard my changes',
  IconData icon = AppIcons.notes,
}) async {
  final choice = await showDialog<UnsavedChangesChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UnsavedChangesDialog(
      title: title,
      message: message,
      saveLabel: saveLabel,
      keepEditingLabel: keepEditingLabel,
      discardLabel: discardLabel,
      icon: icon,
    ),
  );
  return choice ?? UnsavedChangesChoice.keepEditing;
}

class _UnsavedChangesDialog extends StatelessWidget {
  const _UnsavedChangesDialog({
    required this.title,
    required this.message,
    required this.saveLabel,
    required this.keepEditingLabel,
    required this.discardLabel,
    required this.icon,
  });

  final String title;
  final String message;
  final String saveLabel;
  final String keepEditingLabel;
  final String discardLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final peach = isDark ? AppColors.darkPeach : AppColors.peach;
    final onPeach = AppContrast.readable(
      AppColors.warning,
      surface: peach,
      isDark: isDark,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(23, 25, 23, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: peach,
                  borderRadius: BorderRadius.circular(AppRadii.calendarDay),
                ),
                child: Center(child: Icon(icon, size: 24, color: onPeach)),
              ),
            ),
            const SizedBox(height: 17),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(
                  fontSize: 27,
                  height: 1.2,
                  letterSpacing: -0.5,
                ).copyWith(color: context.inkColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: 12, height: 1.7)
                  .copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: 23),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(UnsavedChangesChoice.save),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.check, size: 19),
                  const SizedBox(width: AppSpacing.sm),
                  Text(saveLabel),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SecondaryButton(
              label: keepEditingLabel,
              onPressed: () =>
                  Navigator.of(context).pop(UnsavedChangesChoice.keepEditing),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(UnsavedChangesChoice.discard),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? kDangerTextDark : kDangerTextLight,
              ),
              child: Text(discardLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's `.secondary`: the accent's soft wash carrying accent text, at
/// the same metrics as `.primary`.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent.surface,
        foregroundColor: accent.onSurface,
      ),
      child: Text(label),
    );
  }
}
