import 'package:flutter/material.dart';

import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Accent resolution
//
// The redesign's appearance picker offers eight accents and five of them are
// mid-tones: Peach #b98263, Rose #bc667d, Lavender #8975ac, Ocean #537ca1 and
// Teal #4c837c. White label text on any of those measures below 4.5:1, so a
// filled control cannot assume `onPrimary == white` the way the plum default
// allows. Every role below is therefore measured rather than assumed, and
// `test/unit/accent_contrast_test.dart` holds the floor.
//
// The derivation is not invented. The design ships one light/dark pair it
// resolved by hand — plum #793f58 on paper, #e2a7bf on the dark canvas — and
// that pair turns out to be a rule: keep the hue, lift saturation to at least
// 0.50 and lightness to at least 0.77. Applied to #793f58 that yields
// #e2a7c0, the delivered token to within one unit of blue. The rule therefore
// reproduces the designer's own decision, and the other seven accents get the
// same treatment instead of a second, unrelated set of guesses.
//
// Where the design actually delivered a token, the token wins: the default
// plum palette returns the handoff's values verbatim rather than the rule's
// approximation of them, so the shipped default is exact to the boards and the
// rule only covers the accents the design left open.
//
// These roles are carried on the ThemeData as a [ThemeExtension], so a widget
// reads the resolved values instead of re-deriving them from
// `colorScheme.primary`. That matters: `primary` is a single colour, and the
// safe accent for *text on the canvas* is not always the safe accent for a
// *fill under a label*. Keeping six named roles means a call site asks for the
// one it needs rather than guessing.
// ─────────────────────────────────────────────────────────────────────────────

/// The foreground the design places on a dark-mode accent fill.
///
/// From `.dark .primary{background:var(--plum);color:#32212a}` — the design
/// deliberately flips the primary button's foreground in dark mode, because
/// the dark accent tokens are light tints and white on them is unreadable.
const Color kDarkOnAccent = Color(0xFF32212A);

/// The design's destructive fill (`.primary` in a delete flow), which carries
/// white at 5.61:1.
const Color kDestructiveFill = Color(0xFFA14D60);

/// The design's danger text colour, light appearance (`.sp-danger-text`).
const Color kDangerTextLight = Color(0xFFA14D60);

/// The design's danger text colour, dark appearance
/// (`.dark .sp-danger-text`).
const Color kDangerTextDark = Color(0xFFEFA9B9);

/// WCAG floors: 4.5:1 for text, 3:1 for a meaningful edge.
const double kTextContrastFloor = 4.5;
const double kEdgeContrastFloor = 3.0;

/// The colour roles a palette accent needs to render a control in one
/// appearance, each contrast-checked against the surface it lands on.
///
/// Read these from a widget with `context.accent`. Use [fill] with [onFill]
/// for a filled control, [surface] with [onSurface] for a tinted one, [text]
/// for an accent word or icon on the page, and [border] for a hairline.
@immutable
class AccentRoles extends ThemeExtension<AccentRoles> {
  const AccentRoles({
    required this.fill,
    required this.onFill,
    required this.text,
    required this.surface,
    required this.onSurface,
    required this.border,
  });

  /// Background for a filled control — the design's `.primary`. Deepened from
  /// the raw swatch only as far as [onFill] requires, so the accent the user
  /// picked stays recognisable.
  final Color fill;

  /// Label and icon colour on [fill]: whichever of white or the design's dark
  /// ink measures better, never assumed. At least 4.5:1 against [fill].
  final Color onFill;

  /// The accent as text or an icon directly on the page. At least 4.5:1
  /// against the canvas.
  final Color text;

  /// Soft tinted surface — the design's `*-soft` token. Secondary buttons,
  /// selected chips, icon tiles, the segmented track.
  final Color surface;

  /// Text and icons on [surface]. At least 4.5:1 against it.
  final Color onSurface;

  /// Hairline and outline use. At least 3:1 against the canvas, so an
  /// outlined control's edge is a boundary rather than a suggestion.
  final Color border;

  /// Roles for [seed] in [brightness], with the design's delivered tokens
  /// taking precedence over the derivation for the default palette.
  ///
  /// Cached, because the search loops below would otherwise run on every
  /// theme rebuild.
  static AccentRoles resolve(Color seed, Brightness brightness) =>
      _cache[(seed, brightness)] ??= _resolve(seed, brightness);

  /// The active palette's roles for the current appearance.
  ///
  /// Reads the values the theme resolved. Falls back to deriving them from
  /// `colorScheme.primary` for a bare [ThemeData] that never registered the
  /// extension, so a widget still renders correctly in an isolated test.
  static AccentRoles of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AccentRoles>() ??
        resolve(theme.colorScheme.primary, theme.brightness);
  }

  static final Map<(Color, Brightness), AccentRoles> _cache = {};

  static AccentRoles _resolve(Color seed, Brightness brightness) {
    final dark = brightness == Brightness.dark;

    // The design's delivered plum pair, verbatim, so the default appearance
    // matches the handoff exactly.
    if (seed == AppColors.plum || (dark && seed == AppColors.darkPlum)) {
      return dark
          ? const AccentRoles(
              fill: AppColors.darkPlum,
              onFill: kDarkOnAccent,
              text: AppColors.darkPlum,
              surface: AppColors.darkPlumSoft,
              onSurface: AppColors.darkPlum,
              border: AppColors.darkPlum,
            )
          : const AccentRoles(
              fill: AppColors.plum,
              onFill: Colors.white,
              text: AppColors.plum,
              surface: AppColors.plumSoft,
              onSurface: AppColors.plum,
              border: AppColors.plum,
            );
    }

    final canvas = dark ? AppColors.darkCanvas : AppColors.canvas;

    // Dark mode lifts the accent into a tint, by the same rule that maps the
    // design's own #793f58 to #e2a7bf.
    final base = dark ? liftForDark(seed) : seed;

    // Measure both candidates instead of guessing from the hue: for a
    // mid-tone the better foreground is often not the one a glance suggests.
    final onFill = betterForegroundOn(base);

    final surface = dark ? _darkSurface(seed) : _lightSurface(seed);

    return AccentRoles(
      fill: _nudgeUntil(base, onFill, kTextContrastFloor),
      onFill: onFill,
      text: _nudgeUntil(base, canvas, kTextContrastFloor),
      surface: surface,
      onSurface: _nudgeUntil(base, surface, kTextContrastFloor),
      border: _nudgeUntil(base, canvas, kEdgeContrastFloor),
    );
  }

  /// The design's light-to-dark accent rule: keep the hue, lift saturation to
  /// at least 0.50 and lightness to at least 0.77.
  static Color liftForDark(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    return hsl
        .withSaturation(hsl.saturation < 0.50 ? 0.50 : hsl.saturation)
        .withLightness(hsl.lightness < 0.77 ? 0.77 : hsl.lightness)
        .toColor();
  }

  /// A soft wash of the accent. The design's four light `*-soft` tokens all
  /// sit near 92% lightness with their saturation pulled back.
  static Color _lightSurface(Color seed) => HSLColor.fromColor(seed)
      .withSaturation(0.38)
      .withLightness(0.92)
      .toColor();

  /// The dark softs are the same hue held far down: about 24% lightness at low
  /// saturation.
  static Color _darkSurface(Color seed) => HSLColor.fromColor(seed)
      .withSaturation(0.18)
      .withLightness(0.24)
      .toColor();

  /// [preferred], deepened or lifted only as far as needed to clear [floor]
  /// against [surface].
  ///
  /// For a hue painted on a tinted surface: a phase colour on its own soft
  /// tile, or an accent icon on a wash. Several of the design's soft tokens
  /// are close in lightness to the hue they carry, so the pairing has to be
  /// measured rather than assumed to work.
  static Color readableOn(
    Color surface,
    Color preferred, {
    double floor = kTextContrastFloor,
  }) =>
      _nudgeUntil(preferred, surface, floor);

  /// Whichever of white or the design's dark ink reads better on [fill].
  ///
  /// Public because any surface painting a saturated fill under a label needs
  /// the same measurement, not a guess.
  static Color betterForegroundOn(Color fill) =>
      contrast(fill, Colors.white) >= contrast(fill, kDarkOnAccent)
          ? Colors.white
          : kDarkOnAccent;

  /// Walks [colour]'s lightness away from [against] until the pair clears
  /// [floor], so an accent is deepened or lifted only as far as legibility
  /// requires.
  static Color _nudgeUntil(Color colour, Color against, double floor) {
    if (contrast(colour, against) >= floor) return colour;

    // Move away from what we are measuring against: darker under a light
    // surface, lighter under a dark one.
    final step =
        against.computeLuminance() > colour.computeLuminance() ? -0.01 : 0.01;

    var hsl = HSLColor.fromColor(colour);
    for (var i = 0; i < 100; i++) {
      final next = (hsl.lightness + step).clamp(0.0, 1.0);
      if (next == hsl.lightness) break;
      hsl = hsl.withLightness(next);
      final candidate = hsl.toColor();
      if (contrast(candidate, against) >= floor) return candidate;
    }
    // Exhausted the ramp. Return the strongest available tone rather than
    // something that silently fails the floor.
    return step < 0 ? Colors.black : Colors.white;
  }

  /// WCAG 2.1 contrast ratio, 1.0 (identical) to 21.0 (black on white).
  ///
  /// Built on [Color.computeLuminance], which is already the WCAG relative
  /// luminance, so the channel maths is not re-derived here.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// The destructive fill and its measured foreground.
  ///
  /// Dark mode follows the same flip the design applies to `.primary`: the
  /// fill lifts into a tint and the label becomes the dark ink.
  static (Color fill, Color onFill) destructive(Brightness brightness) {
    if (brightness == Brightness.light) {
      return (kDestructiveFill, Colors.white);
    }
    final fill = liftForDark(kDestructiveFill);
    return (fill, betterForegroundOn(fill));
  }

  /// The design's danger text colour for [brightness] (`.sp-danger-text`).
  static Color dangerText(Brightness brightness) =>
      brightness == Brightness.dark ? kDangerTextDark : kDangerTextLight;

  @override
  AccentRoles copyWith({
    Color? fill,
    Color? onFill,
    Color? text,
    Color? surface,
    Color? onSurface,
    Color? border,
  }) =>
      AccentRoles(
        fill: fill ?? this.fill,
        onFill: onFill ?? this.onFill,
        text: text ?? this.text,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
        border: border ?? this.border,
      );

  @override
  AccentRoles lerp(covariant AccentRoles? other, double t) {
    if (other == null) return this;
    return AccentRoles(
      fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      text: Color.lerp(text, other.text, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Resolves the active palette's accent roles from a widget's context.
extension AccentRolesContext on BuildContext {
  /// Contrast-checked roles for the active palette in the current appearance.
  ///
  /// Prefer this over `colorScheme.primary` whenever the accent is painted as
  /// a fill that must carry a label: [AccentRoles.onFill] is measured, while
  /// white is only correct for some palettes.
  AccentRoles get accent => AccentRoles.of(this);
}
