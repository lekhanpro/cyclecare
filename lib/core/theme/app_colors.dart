import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CycleCare Design System — Color Tokens
// 8 palettes: Pink Rose (default), Lavender, Mint, Peach,
//             Sky Blue, Sunset Orange, Forest Green, Midnight
// ─────────────────────────────────────────────────────────────────────────────

enum AppPalette {
  pinkRose,
  lavender,
  mint,
  peach,
  skyBlue,
  sunsetOrange,
  forestGreen,
  midnight;

  String get label => switch (this) {
        AppPalette.pinkRose => 'Pink Rose',
        AppPalette.lavender => 'Lavender',
        AppPalette.mint => 'Mint',
        AppPalette.peach => 'Peach',
        AppPalette.skyBlue => 'Sky Blue',
        AppPalette.sunsetOrange => 'Sunset Orange',
        AppPalette.forestGreen => 'Forest Green',
        AppPalette.midnight => 'Midnight',
      };

  Color get seed => switch (this) {
        AppPalette.pinkRose => const Color(0xFFE86F91),
        AppPalette.lavender => const Color(0xFF9B7FE8),
        AppPalette.mint => const Color(0xFF3DBFA0),
        AppPalette.peach => const Color(0xFFFF8C69),
        AppPalette.skyBlue => const Color(0xFF4AABDB),
        AppPalette.sunsetOrange => const Color(0xFFFF6B35),
        AppPalette.forestGreen => const Color(0xFF4CAF7D),
        AppPalette.midnight => const Color(0xFF6C63FF),
      };

  Color get swatch => switch (this) {
        AppPalette.pinkRose => const Color(0xFFFCE4EC),
        AppPalette.lavender => const Color(0xFFEDE7F6),
        AppPalette.mint => const Color(0xFFE0F2F1),
        AppPalette.peach => const Color(0xFFFFF3E0),
        AppPalette.skyBlue => const Color(0xFFE1F5FE),
        AppPalette.sunsetOrange => const Color(0xFFFBE9E7),
        AppPalette.forestGreen => const Color(0xFFE8F5E9),
        AppPalette.midnight => const Color(0xFFEDE7F6),
      };
}

class AppColors {
  AppColors._();

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color period = Color(0xFFE86F91);
  static const Color periodLight = Color(0xFFFCE4EC);
  static const Color fertile = Color(0xFF3DBFA0);
  static const Color fertileLight = Color(0xFFE0F7F4);
  static const Color ovulation = Color(0xFF9B7FE8);
  static const Color ovulationLight = Color(0xFFEDE7F6);
  static const Color predicted = Color(0xFFFFB3C6);
  static const Color predictedLight = Color(0xFFFFF0F4);
  static const Color luteal = Color(0xFFFFB199);
  static const Color lutealLight = Color(0xFFFFF3EE);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF2D2530);
  static const Color inkLight = Color(0xFF4A3F4E);
  static const Color muted = Color(0xFF81747F);
  static const Color subtle = Color(0xFFB0A4AE);
  static const Color line = Color(0xFFF0DEE5);
  static const Color cream = Color(0xFFFFF8F6);
  static const Color white = Color(0xFFFFFFFF);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF1A1520);
  static const Color darkSurface = Color(0xFF241E2A);
  static const Color darkCard = Color(0xFF2E2736);
  static const Color darkLine = Color(0xFF3D3547);
  static const Color darkMuted = Color(0xFF9E95A5);
  static const Color darkText = Color(0xFFF5F0F8);

  // ── Legacy aliases (keep old names working) ──────────────────────────────
  static const Color rose = period;
  static const Color roseDark = Color(0xFFD9577D);
  static const Color peachColor = luteal;
  static const Color lavender = ovulation;
  static const Color lavenderLight = ovulationLight;
  static const Color mintColor = fertile;
  static const Color mintLight = fertileLight;
  static const Color predictedColor = predicted;
  static const Color predictedLight2 = predictedLight;

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF4AABDB);

  // ── Phase gradients ───────────────────────────────────────────────────────
  static const List<Color> menstrualGradient = [
    Color(0xFFE86F91),
    Color(0xFFFF8FAB),
  ];
  static const List<Color> follicularGradient = [
    Color(0xFF4AABDB),
    Color(0xFF81D4FA),
  ];
  static const List<Color> ovulationGradient = [
    Color(0xFF9B7FE8),
    Color(0xFFCE93D8),
  ];
  static const List<Color> lutealGradient = [
    Color(0xFFFFB199),
    Color(0xFFFFCCBC),
  ];
}
