import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_accents.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_tokens.dart';

/// The app's Material theme, built from the redesign's measured values.
///
/// Every filled or tinted colour comes from [AccentRoles], which carries a
/// contrast-checked pair for each of the eight palettes in both appearances.
/// The [ColorScheme]'s primary roles are pointed at those same pairs, so a
/// widget that still reads `colorScheme.primary` paints the design's accent
/// rather than `ColorScheme.fromSeed`'s shifted tone.
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

  /// `.field` radius in the design. The same rung as a calendar day.
  static const double _inputRadius = AppRadii.calendarDay;

  /// `.toast` radius.
  static const double _toastRadius = AppRadii.calendarDay;

  /// Text button height: the design's `.text-button` is shorter than a
  /// filled control, but still a comfortable target.
  static const double _textButtonHeight = 44;

  /// Icon buttons are the design's 44 px hairline circle. The padded tap
  /// target size keeps the hit area at 48.
  static const double _iconButtonSize = 44;

  /// Inputs: `.field{min-height:49px;padding:15px}`.
  static const double _inputMinHeight = 49;
  static const double _inputPadding = 15;

  static ThemeData _build({
    required Color seed,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final accent = AccentRoles.resolve(seed, brightness);
    // The toast sits on ink, which is the opposite appearance's canvas, so its
    // action takes the opposite appearance's accent text.
    final inverseAccent = AccentRoles.resolve(
      seed,
      isDark ? Brightness.light : Brightness.dark,
    );
    final danger = AccentRoles.destructive(brightness);

    final canvas = isDark ? AppColors.darkCanvas : AppColors.canvas;
    final paper = isDark ? AppColors.darkPaper : AppColors.paper;
    final line = isDark ? AppColors.darkLine : AppColors.line;
    final ink = isDark ? AppColors.darkText : AppColors.ink;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final subtle =
        isDark ? AppColors.darkMuted.withOpacity(0.62) : AppColors.subtle;
    final sage = isDark ? AppColors.darkSage : AppColors.sage;

    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      primary: accent.fill,
      onPrimary: accent.onFill,
      primaryContainer: accent.surface,
      onPrimaryContainer: accent.onSurface,
      secondaryContainer: accent.surface,
      onSecondaryContainer: accent.onSurface,
      error: danger.$1,
      onError: danger.$2,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: paper,
      surfaceContainer: paper,
      surfaceContainerHigh: isDark ? AppColors.darkCardElevated : canvas,
      surfaceContainerHighest: isDark ? AppColors.darkCardElevated : canvas,
      outline: line,
      outlineVariant: line,
      inverseSurface: ink,
      onInverseSurface: canvas,
      inversePrimary: inverseAccent.text,
      surfaceTint: Colors.transparent,
      shadow: AppColors.ink,
    );

    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: line, width: AppStrokes.hairline),
    );
    final buttonLabel = AppTextStyles.body(
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600,
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    );
    final disabledFill = ink.withOpacity(0.10);
    final disabledInk = ink.withOpacity(0.38);

    Color? overlay(Set<WidgetState> states, Color tone) {
      if (states.contains(WidgetState.pressed)) {
        return tone.withOpacity(isDark ? 0.18 : 0.11);
      }
      if (states.contains(WidgetState.focused)) {
        return tone.withOpacity(isDark ? 0.16 : 0.09);
      }
      if (states.contains(WidgetState.hovered)) {
        return tone.withOpacity(isDark ? 0.11 : 0.06);
      }
      return null;
    }

    final accentOverlay =
        WidgetStateProperty.resolveWith((s) => overlay(s, accent.text));
    final onFillOverlay =
        WidgetStateProperty.resolveWith((s) => overlay(s, accent.onFill));

    OutlineInputBorder field(Color color, {double width = AppStrokes.hairline}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // The design's exact accent pairs, measured for contrast. Without this
      // the AccentRoles.of fallback derives them from colorScheme.primary.
      extensions: <ThemeExtension<dynamic>>[accent],
      textTheme: textTheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: paper,
      dividerColor: line,
      disabledColor: disabledInk,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: accent.text.withOpacity(isDark ? 0.16 : 0.09),
      hoverColor: accent.text.withOpacity(isDark ? 0.11 : 0.06),
      splashColor: accent.text.withOpacity(isDark ? 0.18 : 0.12),
      highlightColor: accent.text.withOpacity(isDark ? 0.12 : 0.07),
      iconTheme: IconThemeData(color: ink, size: 22),
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
      // Card: paper, 1 px line, radius 22. CardThemeData can only express a
      // Material elevation, not the design's soft two-layer shade, so the
      // card stays flat here; AppCard paints AppElevation.low itself.
      cardTheme: CardThemeData(
        elevation: 0,
        color: paper,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: paper,
        disabledColor: ink.withOpacity(0.06),
        selectedColor: accent.surface,
        secondarySelectedColor: accent.surface,
        surfaceTintColor: Colors.transparent,
        checkmarkColor: accent.onSurface,
        showCheckmark: false,
        labelStyle: textTheme.labelMedium?.copyWith(color: ink),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: accent.onSurface),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected) ? accent.border : line,
            width: AppStrokes.hairline,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      // Inputs: paper, 1 px line, radius 14, padding 15, min-height 49. Focus
      // is the accent border plus the design's 3 px soft ring.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        isDense: false,
        constraints: const BoxConstraints(minHeight: _inputMinHeight),
        contentPadding: const EdgeInsets.all(_inputPadding),
        border: field(line),
        enabledBorder: field(line),
        disabledBorder: field(line.withOpacity(0.55)),
        focusedBorder: _RingedInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: accent.border),
          ringColor: accent.border.withOpacity(isDark ? 0.28 : 0.16),
        ),
        errorBorder: field(AccentRoles.dangerText(brightness)),
        focusedErrorBorder: _RingedInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: AccentRoles.dangerText(brightness)),
          ringColor: AccentRoles.dangerText(brightness)
              .withOpacity(isDark ? 0.28 : 0.16),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: accent.text),
        hintStyle: textTheme.bodyMedium?.copyWith(color: subtle),
        helperStyle: textTheme.bodySmall?.copyWith(color: muted),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AccentRoles.dangerText(brightness),
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      // Primary: `.primary` — light plum with white, dark the pale plum with
      // dark ink. AccentRoles keeps every palette's pair above 4.5:1.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.minTouchTarget,
          ),
          backgroundColor: accent.fill,
          foregroundColor: accent.onFill,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledInk,
          elevation: 0,
          shape: controlShape,
          textStyle: buttonLabel,
          padding: buttonPadding,
        ).copyWith(overlayColor: onFillOverlay),
      ),
      // Secondary / tonal: `.secondary` — accent surface with accent text.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.minTouchTarget,
          ),
          backgroundColor: accent.surface,
          foregroundColor: accent.onSurface,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledInk,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: controlShape,
          textStyle: buttonLabel,
          padding: buttonPadding,
        ).copyWith(overlayColor: accentOverlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minTouchTarget,
            AppLayout.minTouchTarget,
          ),
          backgroundColor: paper,
          foregroundColor: accent.text,
          disabledForegroundColor: disabledInk,
          shape: controlShape,
          textStyle: buttonLabel,
          padding: buttonPadding,
        ).copyWith(
          overlayColor: accentOverlay,
          side: WidgetStateProperty.resolveWith((states) {
            final disabled = states.contains(WidgetState.disabled);
            return BorderSide(
              color: disabled ? ink.withOpacity(0.14) : line,
              width: AppStrokes.hairline,
            );
          }),
        ),
      ),
      // `.text-button`: accent text, 13 px, 600, 44 tall.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            _textButtonHeight,
            _textButtonHeight,
          ),
          foregroundColor: accent.text,
          disabledForegroundColor: disabledInk,
          textStyle: AppTextStyles.body(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
          shape: controlShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ).copyWith(overlayColor: accentOverlay),
      ),
      // `.icon-button`: 44 px circle with a 1 px line border.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(_iconButtonSize),
          fixedSize: const Size.square(_iconButtonSize),
          padding: EdgeInsets.zero,
          iconSize: 20,
          backgroundColor: paper,
          foregroundColor: ink,
          disabledForegroundColor: disabledInk,
          shape: const CircleBorder(),
          side: BorderSide(color: line, width: AppStrokes.hairline),
        ).copyWith(overlayColor: accentOverlay),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppLayout.navigationBarHeight,
        elevation: 0,
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.body(
            fontSize: 11,
            height: 1.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ).copyWith(color: selected ? accent.text : muted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accent.text : muted,
            size: 23,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: paper,
        modalBackgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.ink.withOpacity(isDark ? 0.56 : 0.32),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: line,
        dragHandleSize: const Size(38, 4),
      ),
      // Dialog radius 27. The design's `0 15px 60px` shade is approximated by
      // a high Material elevation with a faint warm shadow colour, because
      // DialogThemeData takes an elevation rather than a BoxShadow.
      dialogTheme: DialogThemeData(
        elevation: 24,
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.ink.withOpacity(isDark ? 0.40 : 0.14),
        barrierColor: AppColors.ink.withOpacity(isDark ? 0.56 : 0.32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          side: BorderSide(color: line, width: AppStrokes.hairline),
        ),
        titleTextStyle: AppTextStyles.heading(
          fontSize: 22,
          height: 1.2,
          letterSpacing: -0.5,
        ).copyWith(color: ink),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      // `.toast`: ink background, canvas text, radius 14, floating 24 in.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: ink,
        contentTextStyle: AppTextStyles.body(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ).copyWith(color: canvas),
        actionTextColor: inverseAccent.text,
        disabledActionTextColor: canvas.withOpacity(0.38),
        closeIconColor: canvas,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_toastRadius),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: line,
        dividerHeight: AppStrokes.hairline,
        indicatorColor: accent.fill,
        labelColor: accent.text,
        unselectedLabelColor: muted,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        overlayColor: accentOverlay,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent.fill,
        linearTrackColor: line,
        circularTrackColor: line,
        refreshBackgroundColor: paper,
        linearMinHeight: AppSpacing.xs,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent.fill,
        inactiveTrackColor: line,
        thumbColor: accent.fill,
        overlayColor: accent.fill.withOpacity(0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent.fill : null,
        ),
        checkColor: WidgetStatePropertyAll(accent.onFill),
        side: BorderSide(color: subtle, width: AppStrokes.selected),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.connected),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent.fill : subtle,
        ),
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
        tileColor: Colors.transparent,
        selectedColor: accent.text,
        selectedTileColor: accent.surface,
        titleTextStyle: AppTextStyles.body(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ).copyWith(color: ink),
        subtitleTextStyle: AppTextStyles.body(
          fontSize: 12,
          height: 1.4,
        ).copyWith(color: muted),
        shape: controlShape,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.ink.withOpacity(isDark ? 0.40 : 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: line, width: AppStrokes.hairline),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: ink),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(AppRadii.compact),
        ),
        textStyle: AppTextStyles.body(fontSize: 12, height: 1.35)
            .copyWith(color: canvas),
      ),
      // Matches AppToggle: sage when on, line when off, a white knob (dark
      // mode's knob is the dark ink, because white on pale sage fails 3:1).
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return paper.withOpacity(0.7);
          }
          return states.contains(WidgetState.selected) && isDark
              ? AppColors.darkOnAccent
              : AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return ink.withOpacity(0.10);
          }
          return states.contains(WidgetState.selected) ? sage : line;
        }),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll<Icon?>(null),
      ),
    );
  }
}

/// An outline border that adds the design's 3 px soft focus ring outside the
/// accent stroke (`box-shadow: 0 0 0 3px <accent-soft>`).
///
/// OutlineInputBorder paints one stroke; the ring is drawn first, just outside
/// it, so the field's own geometry and label gap are unchanged.
class _RingedInputBorder extends OutlineInputBorder {
  const _RingedInputBorder({
    super.borderSide,
    super.borderRadius,
    required this.ringColor,
  });

  final Color ringColor;

  @override
  _RingedInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) =>
      _RingedInputBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
        ringColor: ringColor,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OutlineInputBorder) {
      final from = a is _RingedInputBorder ? a.ringColor : ringColor.withOpacity(0);
      return _RingedInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        ringColor: Color.lerp(from, ringColor, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final outer = borderRadius
        .resolve(textDirection)
        .toRRect(rect)
        .inflate(AppStrokes.focus / 2);
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStrokes.focus
        ..color = ringColor,
    );
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _RingedInputBorder &&
      other.ringColor == ringColor &&
      super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, ringColor);
}
