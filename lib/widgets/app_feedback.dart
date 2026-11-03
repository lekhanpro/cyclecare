import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_accents.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';

/// Opens CycleCare's standard keyboard-safe Material bottom sheet.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  bool showHandle = true,
}) {
  final motion = Motion.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withOpacity(context.isDark ? 0.56 : 0.32),
    sheetAnimationStyle: AnimationStyle(
      duration: motion(AppDurations.modal),
      reverseDuration: motion(AppDurations.exit),
    ),
    builder: (context) {
      final media = MediaQuery.of(context);
      final sheetMotion = Motion.of(context);
      final bottomInset = media.viewInsets.bottom;
      final maxHeight = media.size.height * 0.88;
      final surface = Theme.of(context).bottomSheetTheme.backgroundColor ??
          context.cardColor;

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: sheetMotion(AppDurations.fast),
        curve: AppCurves.out,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: surface,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.sheet),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xs,
                    ),
                    child: ExcludeSemantics(
                      child: Container(
                        width: 38,
                        height: AppSpacing.xs,
                        decoration: BoxDecoration(
                          color: context.lineColor,
                          borderRadius:
                              BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                  ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AppTextStyles.heading(
                                fontSize: 22,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ).copyWith(color: context.inkColor),
                            ),
                          ),
                        ),
                        // The theme's 44 px hairline circle.
                        IconButton(
                          tooltip: 'Close ${title.toLowerCase()}',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(AppIcons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      title == null ? AppSpacing.lg : AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.xxl + media.padding.bottom,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

enum ToastKind { success, info, warning, error }

void showAppToast(
  BuildContext context, {
  required String message,
  ToastKind kind = ToastKind.success,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  // `.toast` is ink with canvas text. The kind is carried by the glyph shape
  // (and the screen-reader prefix below), so the icon takes the text colour:
  // a phase or status hue on the ink background would fail contrast in one
  // appearance or the other.
  final (icon, spoken) = switch (kind) {
    ToastKind.success => (AppIcons.success, null),
    ToastKind.info => (AppIcons.info, null),
    ToastKind.warning => (AppIcons.warning, 'Warning'),
    ToastKind.error => (AppIcons.warning, 'Error'),
  };
  final foreground = context.canvasColor;

  switch (kind) {
    case ToastKind.success:
      Haptics.commit();
    case ToastKind.error:
    case ToastKind.warning:
      Haptics.warn();
    case ToastKind.info:
      break;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      action: action,
      content: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 18, color: foreground)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              label: spoken == null ? null : '$spoken: $message',
              excludeSemantics: spoken != null,
              child: Text(
                message,
                style: AppTextStyles.body(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ).copyWith(color: foreground),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Returns true only after an explicit confirmation.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final brightness = Theme.of(context).brightness;
  final confirmColor = destructive
      ? AccentRoles.dangerText(brightness)
      : context.accent.text;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (destructive) Haptics.warn();
            Navigator.of(context).pop(true);
          },
          child: Text(
            confirmLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: confirmColor,
            ),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}
