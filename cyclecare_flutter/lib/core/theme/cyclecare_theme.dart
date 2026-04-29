import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CycleCareColors {
  static const rose = Color(0xFFE86F91);
  static const roseDark = Color(0xFFD9577D);
  static const peach = Color(0xFFFFB199);
  static const lavender = Color(0xFFC7B8FF);
  static const mint = Color(0xFF8EDBC5);
  static const cream = Color(0xFFFFF8F6);
  static const ink = Color(0xFF2D2530);
  static const muted = Color(0xFF81747F);
  static const line = Color(0xFFF0DEE5);
  static const predicted = Color(0xFFFFD6DE);
  static const fertile = Color(0xFFDDF4EC);
  static const ovulation = Color(0xFFD9E3FF);

  // Dark mode
  static const darkBg = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF252540);
  static const darkCard = Color(0xFF2D2D4A);
  static const darkLine = Color(0xFF3D3D5C);
  static const darkMuted = Color(0xFF9E95A5);
  static const darkText = Color(0xFFF0EDF4);
}

class CycleCareTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: CycleCareColors.rose,
      secondary: CycleCareColors.lavender,
      tertiary: CycleCareColors.mint,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: CycleCareColors.ink,
      outline: CycleCareColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: CycleCareColors.cream,
      fontFamily: CupertinoThemeData().textTheme.textStyle.fontFamily,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: CycleCareColors.cream,
        foregroundColor: CycleCareColors.ink,
        titleTextStyle: TextStyle(
          color: CycleCareColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: CycleCareColors.predicted,
        labelStyle: const TextStyle(color: CycleCareColors.ink),
        side: const BorderSide(color: CycleCareColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.rose, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        selectedItemColor: CycleCareColors.rose,
        unselectedItemColor: CycleCareColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: CycleCareColors.rose,
      secondary: CycleCareColors.lavender,
      tertiary: CycleCareColors.mint,
      surface: CycleCareColors.darkSurface,
      onPrimary: Colors.white,
      onSurface: CycleCareColors.darkText,
      outline: CycleCareColors.darkLine,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: CycleCareColors.darkBg,
      fontFamily: CupertinoThemeData().textTheme.textStyle.fontFamily,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: CycleCareColors.darkBg,
        foregroundColor: CycleCareColors.darkText,
        titleTextStyle: TextStyle(
          color: CycleCareColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: CycleCareColors.darkCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CycleCareColors.darkCard,
        selectedColor: CycleCareColors.roseDark.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: CycleCareColors.darkText),
        side: const BorderSide(color: CycleCareColors.darkLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CycleCareColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CycleCareColors.rose, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: CycleCareColors.darkSurface,
        selectedItemColor: CycleCareColors.rose,
        unselectedItemColor: CycleCareColors.darkMuted,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
