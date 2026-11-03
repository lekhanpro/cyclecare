import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Typography
//
// Two families, bundled rather than fetched:
//
//   Fraunces  expressive page headings and the big numeric moments
//   DM Sans   controls, body copy, values and navigation
//
// Both ship in `assets/fonts` and are declared in pubspec. They are not loaded
// through `google_fonts` any more, because that package downloads a family on
// first use: a brand-new install with no network would render the whole app in
// Roboto, and "core tracking remains useful offline" is a product invariant,
// not a nice-to-have.
//
// Only the cuts the design uses are bundled — DM Sans 400/500/600/700 and
// Fraunces 400/500. Flutter resolves a request for an undeclared weight to the
// nearest declared one, so the ~160 call sites that still ask for w800/w900
// land on DM Sans Bold rather than silently falling back to another family.
// Those sites are being lightened screen by screen as each one is migrated;
// the redesign's headings are Fraunces at 400, and weight is not how this type
// system creates emphasis.
//
// Sizes follow `redesign/assets/design-tokens.json`: body 14, page title 32,
// section title 17, control 14. The review board's 8–10px labels are a 390pt
// artboard convention, and the same token file sets
// `productionCaptionMinimum: 11`, so nothing here goes below 11.
// ─────────────────────────────────────────────────────────────────────────────

class AppFonts {
  AppFonts._();

  /// Expressive headings and major numerals.
  static const String heading = 'Fraunces';

  /// Everything else: body, controls, values, navigation.
  static const String body = 'DM Sans';
}

class AppTextStyles {
  AppTextStyles._();

  /// A Fraunces heading. Tight line height and negative tracking are part of
  /// the face's character at display sizes; both relax as the size drops.
  static TextStyle heading({
    required double fontSize,
    double height = 1.12,
    double letterSpacing = -0.9,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
      );

  /// A DM Sans style. Default 400 for copy; 500/600 for values and controls.
  static TextStyle body({
    required double fontSize,
    double height = 1.5,
    double letterSpacing = 0,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
      );

  /// Small uppercase eyebrow above a page title or section.
  ///
  /// 11px rather than the board's 10, per the token file's production floor,
  /// and the wide tracking is what keeps it legible at that size.
  static TextStyle get overline => body(
        fontSize: 11,
        height: 1.4,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
      );

  static TextTheme get textTheme => TextTheme(
        // ── Display: Fraunces, for welcome and celebration moments ──────────
        displayLarge: heading(fontSize: 54, height: 1.08, letterSpacing: -2),
        displayMedium: heading(fontSize: 38, height: 1.1, letterSpacing: -1.2),
        displaySmall: heading(fontSize: 32, height: 1.12),

        // ── Headline: Fraunces, page titles and the big number ──────────────
        headlineLarge: heading(fontSize: 32, height: 1.12),
        headlineMedium: heading(fontSize: 28, height: 1.15, letterSpacing: -0.7),
        headlineSmall: heading(fontSize: 24, height: 1.2, letterSpacing: -0.5),

        // ── Title: DM Sans, section headers and card titles ─────────────────
        //
        // The jump from Fraunces to DM Sans happens here on purpose. A section
        // label is a signpost, not a statement, and setting it in the serif
        // would make every card compete with the page title.
        titleLarge: heading(fontSize: 20, height: 1.25, letterSpacing: -0.4),
        titleMedium: body(
          fontSize: 17,
          height: 1.3,
          letterSpacing: -0.2,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: body(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),

        // ── Body: DM Sans ───────────────────────────────────────────────────
        bodyLarge: body(fontSize: 16, height: 1.5),
        bodyMedium: body(fontSize: 14, height: 1.5),
        bodySmall: body(fontSize: 12.5, height: 1.45),

        // ── Label: DM Sans, controls and values ─────────────────────────────
        labelLarge: body(
          fontSize: 14,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: body(
          fontSize: 12,
          height: 1.3,
          letterSpacing: 0.1,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: body(
          fontSize: 11,
          height: 1.3,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
        ),
      );
}
