import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color seed) => _build(
        seed: seed,
        brightness: Brightness.light,
      );

  static ThemeData dark(Color seed) => _build(
        seed: seed,
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required Color seed,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? AppColors.darkBg : AppColors.cream;
    final surface = isDark ? AppColors.darkSurface : AppColors.white;
    final card = isDark ? AppColors.darkCard : AppColors.white;
    final line = isDark ? AppColors.darkLine : AppColors.line;
    final ink = isDark ? AppColors.darkText : AppColors.ink;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;

    // Let Material derive contrast-safe primary/on-primary tones from every
    // selectable seed. In particular, dark mode receives a lifted primary
    // instead of reusing a dark light-mode seed.
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: card,
      surfaceContainerHigh: isDark ? AppColors.darkLine : AppColors.cream,
      outline: line,
      outlineVariant: line,
      shadow: Colors.black,
    );

    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(
        color: line.withOpacity(isDark ? 0.82 : 0.72),
        width: AppStrokes.hairline,
      ),
    );
    final stateOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return scheme.primary.withOpacity(isDark ? 0.18 : 0.11);
      }
      if (states.contains(WidgetState.focused)) {
        return scheme.primary.withOpacity(isDark ? 0.16 : 0.09);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.primary.withOpacity(isDark ? 0.11 : 0.06);
      }
      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: scheme.primary.withOpacity(isDark ? 0.16 : 0.09),
      hoverColor: scheme.primary.withOpacity(isDark ? 0.11 : 0.06),
      splashColor: scheme.primary.withOpacity(isDark ? 0.18 : 0.12),
      highlightColor: scheme.primary.withOpacity(isDark ? 0.12 : 0.07),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.xl,
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: ink),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(isDark ? 0.24 : 0.06),
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: card,
        disabledColor: scheme.onSurface.withOpacity(0.08),
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        checkmarkColor: scheme.onPrimaryContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelMedium?.copyWith(color: ink),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: line),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: line.withOpacity(0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppStrokes.selected,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(
            color: scheme.error,
            width: AppStrokes.selected,
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: muted.withOpacity(0.82),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.buttonHeight,
          ),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          elevation: 0,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
        ).copyWith(overlayColor: stateOverlay),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.buttonHeight,
          ),
          backgroundColor: card,
          foregroundColor: scheme.primary,
          disabledBackgroundColor: scheme.onSurface.withOpacity(0.08),
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(isDark ? 0.26 : 0.10),
          surfaceTintColor: Colors.transparent,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
        ).copyWith(overlayColor: stateOverlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.buttonHeight,
          ),
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
        ).copyWith(
          overlayColor: stateOverlay,
          side: WidgetStateProperty.resolveWith((states) {
            final disabled = states.contains(WidgetState.disabled);
            return BorderSide(
              color: disabled
                  ? scheme.onSurface.withOpacity(0.18)
                  : scheme.primary,
              width: AppStrokes.hairline,
            );
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.minTouchTarget,
          ),
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ).copyWith(overlayColor: stateOverlay),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppLayout.minTouchTarget),
          foregroundColor: scheme.onSurfaceVariant,
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          focusColor: scheme.primary.withOpacity(isDark ? 0.16 : 0.09),
          hoverColor: scheme.primary.withOpacity(isDark ? 0.11 : 0.06),
          highlightColor: scheme.primary.withOpacity(isDark ? 0.16 : 0.09),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppLayout.navigationBarHeight,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? scheme.primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : muted,
            size: selected ? 25 : 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: muted.withOpacity(0.48),
        dragHandleSize: const Size(38, 4),
      ),
      dialogTheme: DialogTheme(
        elevation: 1,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: line),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: ink),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 1,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor: isDark ? scheme.primary : scheme.primaryContainer,
        disabledActionTextColor: AppColors.white.withOpacity(0.38),
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
      tabBarTheme: TabBarTheme(
        dividerColor: line,
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: muted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        overlayColor: stateOverlay,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: line,
        circularTrackColor: line,
        refreshBackgroundColor: card,
        linearMinHeight: AppSpacing.xs,
      ),
      dividerTheme: DividerThemeData(
        color: line,
        thickness: AppStrokes.hairline,
        space: AppStrokes.hairline,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        iconColor: muted,
        textColor: ink,
        shape: controlShape,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : (isDark ? AppColors.darkMuted : AppColors.subtle);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.12);
          }
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : line;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : line;
        }),
      ),
    );
  }
}
