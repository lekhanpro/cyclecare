import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CycleCare Design System — Colour Tokens
//
// These are the approved redesign's tokens, read from
// `redesign/assets/design-tokens.json` and the `:root` / `.dark` blocks of
// `redesign/design.css`: a warm paper canvas, a plum primary, and rose / sage /
// violet phase semantics, each resolved for both appearances.
//
// Two rules shape this file.
//
// First, every legacy name is kept and re-pointed rather than deleted. Thirty
// five files reference these constants; renaming them would turn a visual
// migration into a mechanical sweep across the whole app for no visual gain,
// and the plan asks for a migration of the existing app, not a rewrite.
//
// Second, the phase hues do not follow the user's palette. Rose means period,
// sage means fertile, violet means ovulation. That mapping is learned within a
// day of use and is how the calendar is read at a glance, so the palette
// setting moves the primary accent and leaves the health semantics alone.
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

  // The preference persists by index, so the enum names stay. Labels and
  // colours follow the redesign's eight accents (redesign/settings-pages.js,
  // the appearance picker), each mapped from the nearest previous choice so a
  // saved preference keeps its family: sky blue becomes Ocean, sunset orange
  // becomes Rose, forest green becomes Teal and midnight becomes Berry.
  String get label => switch (this) {
        AppPalette.pinkRose => 'Plum',
        AppPalette.lavender => 'Lavender',
        AppPalette.mint => 'Mint',
        AppPalette.peach => 'Peach',
        AppPalette.skyBlue => 'Ocean',
        AppPalette.sunsetOrange => 'Rose',
        AppPalette.forestGreen => 'Teal',
        AppPalette.midnight => 'Berry',
      };

  /// The accent exactly as the design's swatch shows it.
  ///
  /// Several of these are mid-tones (Peach, Rose, Lavender, Ocean, Teal) that
  /// cannot carry white label text at 4.5:1 as they are, so filled controls
  /// must resolve a contrast-checked variant in the theme rather than paint
  /// white text straight onto this colour.
  Color get seed => switch (this) {
        AppPalette.pinkRose => AppColors.plum,
        AppPalette.lavender => const Color(0xFF8975AC),
        AppPalette.mint => const Color(0xFF547C68),
        AppPalette.peach => const Color(0xFFB98263),
        AppPalette.skyBlue => const Color(0xFF537CA1),
        AppPalette.sunsetOrange => const Color(0xFFBC667D),
        AppPalette.forestGreen => const Color(0xFF4C837C),
        AppPalette.midnight => const Color(0xFF9B4D6C),
      };

  /// A soft wash of the accent, for selected and tinted surfaces.
  Color get swatch => switch (this) {
        AppPalette.pinkRose => AppColors.plumSoft,
        AppPalette.lavender => AppColors.violetSoft,
        AppPalette.mint => AppColors.sageSoft,
        AppPalette.peach => AppColors.peach,
        AppPalette.skyBlue => const Color(0xFFE2EBF3),
        AppPalette.sunsetOrange => AppColors.roseSoft,
        AppPalette.forestGreen => const Color(0xFFE0EDEB),
        AppPalette.midnight => const Color(0xFFF3E3EA),
      };

  /// The order the design's appearance picker shows the accents in.
  static const List<AppPalette> displayOrder = [
    AppPalette.pinkRose,
    AppPalette.sunsetOrange,
    AppPalette.lavender,
    AppPalette.skyBlue,
    AppPalette.mint,
    AppPalette.peach,
    AppPalette.midnight,
    AppPalette.forestGreen,
  ];
}

class AppColors {
  AppColors._();

  // ── Redesign tokens, light ───────────────────────────────────────────────
  static const Color canvas = Color(0xFFFAF8F5);
  static const Color paper = Color(0xFFFFFDFA);
  static const Color plum = Color(0xFF793F58);
  static const Color plumSoft = Color(0xFFF0E4E9);
  static const Color roseToken = Color(0xFFCC758D);
  static const Color roseSoft = Color(0xFFF8E2E7);
  static const Color sage = Color(0xFF4B7868);
  static const Color sageSoft = Color(0xFFE3ECE5);
  static const Color violet = Color(0xFF8371B0);
  static const Color violetSoft = Color(0xFFECE7F5);
  static const Color peach = Color(0xFFF5E6D5);

  // ── Redesign tokens, dark ────────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF231F25);
  static const Color darkPaper = Color(0xFF2D2830);
  static const Color darkPlum = Color(0xFFE2A7BF);
  static const Color darkPlumSoft = Color(0xFF47323F);
  static const Color darkRose = Color(0xFFD88DA6);
  static const Color darkRoseSoft = Color(0xFF422B38);
  static const Color darkSage = Color(0xFFACD1B9);
  static const Color darkSageSoft = Color(0xFF2E4037);
  static const Color darkViolet = Color(0xFFBAACDF);
  static const Color darkVioletSoft = Color(0xFF373044);
  static const Color darkPeach = Color(0xFF47382F);

  /// Foreground for a filled accent control in dark mode.
  ///
  /// The design flips the primary button between appearances: white on the
  /// deep plum in light mode, this near-black on the pale plum in dark mode
  /// (`.dark .primary{background:var(--plum);color:#32212a}`). It measures
  /// 7.58:1 on the dark plum token.
  static const Color darkOnAccent = Color(0xFF32212A);

  // ── Phase hues deepened for text on top ──────────────────────────────────
  //
  // Rose and violet are mid-tones: white on the delivered token measures
  // 3.23:1 and 4.24:1, under the 4.5:1 body-text floor. These are the same
  // hues nudged toward ink by the smallest step that clears it (26% and 6%),
  // so a saturated chip or badge in a phase colour can carry white text.
  // Sage (5.02) and plum (7.88) already clear it and need no variant.
  static const Color roseStrong = Color(0xFFA46275);
  static const Color violetStrong = Color(0xFF7E6DA8);

  // ── Phase band fills ─────────────────────────────────────────────────────
  //
  // The segmented cycle bar and its two overlay lanes, only. These are
  // deliberately pale: they are an 11px band on paper, not a text background.
  // The bar is always paired with the labelled, iconed phase tabs beneath it,
  // so colour is never the only signal for a phase.
  static const Color bandFollicular = Color(0xFFBACAB0);
  static const Color bandFertile = Color(0xFF87AD98);
  static const Color bandLuteal = Color(0xFFD6B6C4);
  static const Color bandPms = Color(0xFFB38A9D);
  static const Color darkBandFollicular = Color(0xFF7D987A);
  static const Color darkBandFertile = Color(0xFF7BAA93);
  static const Color darkBandLuteal = Color(0xFFA4748B);
  static const Color darkBandPms = Color(0xFFBB91A5);

  // ── Semantic ──────────────────────────────────────────────────────────────
  //
  // `predicted` is the same hue as `period` on purpose. A forecast is told
  // apart from a record by its *treatment* — a dashed outline rather than a
  // fill, per the design tokens' `recorded: filled, forecast: dashed outline`
  // — not by a second, paler pink that reads as a weaker period.
  static const Color period = roseToken;
  static const Color periodLight = roseSoft;
  static const Color fertile = sage;
  static const Color fertileLight = sageSoft;
  static const Color ovulation = violet;
  static const Color ovulationLight = violetSoft;
  static const Color predicted = roseToken;
  static const Color predictedLight = Color(0xFFFDF2F5);
  static const Color luteal = plum;
  static const Color lutealLight = plumSoft;

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF332D31);
  static const Color inkLight = Color(0xFF53494E);

  /// Secondary text.
  ///
  /// The design's own value is `#766c70`, which clears 4.5:1 on the canvas and
  /// on paper (4.77 and 4.98) but lands at 4.09–4.19 on the tinted cards it is
  /// actually used on — the peach care note, the rose hero, the sage check-in,
  /// every plum-soft panel. The plan requires verified contrast, so the token
  /// is nudged 11% toward ink: imperceptible against the design (5.29 on the
  /// canvas where it was 4.77) and over the floor on every surface in the set.
  /// `test/unit/design_tokens_test.dart` holds that.
  static const Color muted = Color(0xFF6F6569);
  static const Color subtle = Color(0xFFA79DA1);
  static const Color line = Color(0xFFE9E1DF);
  static const Color cream = canvas;
  static const Color white = Color(0xFFFFFFFF);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color darkBg = darkCanvas;
  static const Color darkSurface = darkPaper;
  static const Color darkCard = darkPaper;

  /// One step above [darkCard]. Dark mode cannot lift a surface with shadow
  /// alone — a black shadow on a near-black canvas is arithmetically present
  /// and visually absent — so an elevated dark surface gets a lighter fill too.
  static const Color darkCardElevated = Color(0xFF383140);
  static const Color darkLine = Color(0xFF433842);
  static const Color darkMuted = Color(0xFFB6A7B0);
  static const Color darkText = Color(0xFFF3E9EC);

  // ── Legacy aliases (keep old names working) ──────────────────────────────
  static const Color rose = period;
  static const Color roseDark = Color(0xFFA9536E);
  static const Color peachColor = luteal;
  static const Color lavender = ovulation;
  static const Color lavenderLight = ovulationLight;
  static const Color mintColor = fertile;
  static const Color mintLight = fertileLight;
  static const Color predictedColor = predicted;
  static const Color predictedLight2 = predictedLight;

  // ── Status ────────────────────────────────────────────────────────────────
  //
  // Kept in the warm family. A stock Material red beside plum and sage reads
  // as a browser default rather than as part of the app. Error stays clearly
  // red-biased so it is not mistaken for the period rose.
  static const Color success = sage;
  static const Color warning = Color(0xFF8A5F2A);
  static const Color error = Color(0xFF9E3A35);
  static const Color info = violet;

  // ── Phase gradients ───────────────────────────────────────────────────────
  //
  // Pale pairs, for backdrops that sit behind ink. The redesign's surfaces are
  // quiet, so each is a soft token and its slightly deeper neighbour rather
  // than the saturated two-hue ramp it replaces.
  static const List<Color> menstrualGradient = [roseSoft, Color(0xFFF3D4DD)];
  static const List<Color> follicularGradient = [sageSoft, Color(0xFFD6E4DA)];
  static const List<Color> ovulationGradient = [violetSoft, Color(0xFFDFD7EE)];
  static const List<Color> lutealGradient = [plumSoft, Color(0xFFE6D3DB)];

  // ── Hero gradients ────────────────────────────────────────────────────────
  //
  // The deep set, for a saturated surface carrying white text.
  //
  // The redesign's own Home hero is a pale rose card with plum text, so this
  // set is no longer what Home uses. It is kept, and re-tuned into the new
  // palette, because any surface that does put white on a phase colour still
  // needs stops that clear 4.5:1 — and the pale tokens above emphatically do
  // not. Measured against white at the lightest stop: menstrual 7.2,
  // follicular 6.1, ovulation 7.1, luteal 7.9. `test/unit/design_tokens_test`
  // holds that floor so a later tweak cannot quietly break it.
  static const List<Color> menstrualHero = [
    Color(0xFF8F3B57),
    Color(0xFF6E2B43),
  ];
  static const List<Color> follicularHero = [
    Color(0xFF3D6B5B),
    Color(0xFF2C5244),
  ];
  static const List<Color> ovulationHero = [
    Color(0xFF5F4F8A),
    Color(0xFF46386B),
  ];
  static const List<Color> lutealHero = [
    Color(0xFF793F58),
    Color(0xFF5C2E42),
  ];
}
