import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shape, spacing and depth
//
// Values come from `redesign/assets/design-tokens.json` and the measured rules
// in `redesign/design.css`. Legacy token names are kept and re-pointed, because
// re-pointing a token migrates every screen that already uses it, while
// renaming it would only create a sweep.
// ─────────────────────────────────────────────────────────────────────────────

/// Four-unit base. `baseUnit: 4` in the token file, so every step is a
/// multiple of it and nothing in between is legal.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// One radius vocabulary keeps controls related without making every surface
/// the same shape. Four rungs, from the token file: small 10, button 16,
/// card 22, hero 27.
class AppRadii {
  AppRadii._();

  /// Where two surfaces meet and the seam should read as one shape.
  static const double connected = 4;

  /// Small controls: chips, value pills, the icon tile inside a list row.
  static const double compact = 10;

  /// Buttons, segmented controls, inputs, inner panels. The design's
  /// `.primary` / `.secondary` radius.
  static const double control = 16;

  /// A calendar day cell. Slightly tighter than [control] because seven of
  /// them sit in a row and the gaps read as the shape at that scale.
  static const double calendarDay = 14;

  /// The workhorse card radius.
  static const double card = 22;

  /// Sheets and the hero card. Concentric with [card] when one nests in the
  /// other, which is why they are close rather than identical.
  static const double sheet = 27;
  static const double hero = 27;

  static const double pill = 999;
}

/// Layout roles shared by themes and custom widgets.
class AppLayout {
  AppLayout._();

  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;

  /// The navigation bar's own height, before the home-gesture inset. The
  /// design's bar is 84 tall including 18 of bottom padding; on a device with
  /// a real gesture inset that padding is the inset instead, so the bar
  /// reserves its content height here and adds the inset at build time.
  static const double navigationBarHeight = 66;
  static const double compactNavigationBarHeight = 62;

  /// Fallback bottom padding where the OS reports no gesture inset, so the
  /// bar still matches the design's 84 on a square-cornered screen.
  static const double navigationBarMinInset = 18;

  static const double narrowWidth = 360;
  static const double maxContentWidth = 720;

  /// The design's page gutter is 24. It tightens on a narrow phone rather
  /// than letting the content column collapse.
  static double pageGutterFor(double width) =>
      width < narrowWidth ? AppSpacing.lg : AppSpacing.xxl;
}

/// Reusable component insets.
class AppInsets {
  AppInsets._();

  /// `.card{padding:18px}`.
  static const EdgeInsets card = EdgeInsets.all(18);
  static const EdgeInsets compactCard = EdgeInsets.all(14);
  static const EdgeInsets control = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.md,
    AppSpacing.xxl,
    AppSpacing.xxl,
  );
}

class AppStrokes {
  AppStrokes._();

  static const double hairline = 1;
  static const double selected = 1.5;
  static const double focus = 3;
}

/// Shadow scale.
///
/// The redesign is a paper interface: surfaces are separated by a hairline and
/// a wide, very soft shadow, not by lift. The design's own card shadow is
/// `0 8px 28px #46333b08` — a 3% warm shade — and that restraint is most of
/// why the boards read as calm. So depth here is deliberately shallow, and a
/// screen is expected to use one or two rungs rather than all four.
///
/// Opacities are far heavier in dark mode. A 3% black shadow over a near-black
/// canvas is arithmetically present and visually absent, so dark surfaces are
/// separated by shadow *and* a lifted fill rather than by shadow alone.
class AppElevation {
  AppElevation._();

  /// Flat. Hairline-bordered surfaces that group content without lifting it.
  /// The default for a card in this design.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Resting cards. The workhorse.
  static List<BoxShadow> low(bool isDark) => [
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.20 : 0.012),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.18 : 0.032),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  /// Surfaces that sit above the page: sheets, the hero, a pressed card's
  /// rest state.
  static List<BoxShadow> medium(bool isDark) => [
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.24 : 0.02),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.26 : 0.048),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  /// Floating: dialogs, menus, the nav bar's own lift.
  static List<BoxShadow> high(bool isDark) => [
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.30 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: _ink.withOpacity(isDark ? 0.42 : 0.10),
          blurRadius: 36,
          offset: const Offset(0, 14),
        ),
      ];

  /// A coloured glow, for saturated surfaces only.
  ///
  /// A black shadow under a saturated fill turns the colour muddy exactly
  /// where it matters — the bottom edge, against the page. Tinting the shadow
  /// with the surface's own hue is what makes a colour block look lit rather
  /// than dirty. Softer here than before, because the only saturated surface
  /// left in this design is the primary button and the nav's centre tile.
  static List<BoxShadow> glow(Color color, bool isDark) => [
        BoxShadow(
          color: color.withOpacity(isDark ? 0.18 : 0.20),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withOpacity(isDark ? 0.10 : 0.12),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ];

  /// Shadows are cast by the design's warm shade (`#46333b`), not pure black.
  /// Pure black over a warm paper canvas greys it out; this keeps the shade in
  /// the same family as the page.
  static const Color _ink = Color(0xFF46333B);
}
