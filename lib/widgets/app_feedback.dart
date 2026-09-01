import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
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
    barrierColor: Colors.black.withOpacity(context.isDark ? 0.54 : 0.36),
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
          (context.isDark ? AppColors.darkSurface : AppColors.white);

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
                          color: context.subtleColor.withOpacity(0.5),
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
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: context.inkColor,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close ${title.toLowerCase()}',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(
                              AppLayout.minTouchTarget,
                            ),
                            backgroundColor:
                                context.lineColor.withOpacity(0.42),
                            foregroundColor: context.mutedColor,
                          ),
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
  final (icon, tone) = switch (kind) {
    ToastKind.success => (Icons.check_circle_rounded, AppColors.success),
    ToastKind.info => (Icons.info_rounded, AppColors.info),
    ToastKind.warning => (Icons.warning_rounded, AppColors.warning),
    ToastKind.error => (Icons.error_rounded, AppColors.error),
  };

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
          Icon(icon, size: 20, color: tone),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.35,
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
  final scheme = Theme.of(context).colorScheme;

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
              fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w900,
              color: destructive ? scheme.error : scheme.primary,
            ),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}
