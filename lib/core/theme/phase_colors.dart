import 'package:flutter/material.dart';

import '../../features/tracking/domain/cycle_models.dart';
import 'app_colors.dart';
import 'app_contrast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase colour resolution
//
// A deliberate exception to the palette system: the cycle phase hues stay put
// when the user changes their theme. Rose means period, sage means fertile,
// violet means ovulation — the mapping the design tokens call `semanticPhases`.
// It is learned within a day of use and becomes how the calendar is read at a
// glance, so recolouring it per palette would trade a functional signal for
// decoration.
//
// What *does* change is how each hue renders. The redesign ships a resolved
// pair for every token — rose is `#cc758d` on paper and `#d88da6` on the dark
// canvas — so each role below is a looked-up token rather than a computed
// tint. Only `text` is derived, and only where the design token itself does
// not clear 4.5:1 as body text on paper.
//
// Colour is never the only signal. Every phase also carries an icon and a
// label at its call sites, and a forecast is distinguished from a record by a
// dashed outline rather than by a paler hue.
// ─────────────────────────────────────────────────────────────────────────────

/// The colour roles a phase needs to render anywhere in the app.
@immutable
class PhaseSwatch {
  const PhaseSwatch({
    required this.fill,
    required this.onFill,
    required this.fillStrong,
    required this.onFillStrong,
    required this.surface,
    required this.border,
    required this.text,
    required this.band,
    required this.gradient,
    required this.hero,
  });

  /// Solid, high-emphasis. Calendar day markers, dots, progress arcs.
  ///
  /// For marks and short labels only. Several phase hues are mid-tone by
  /// design: measured against both polarities, rose reaches 4.16:1 and violet
  /// 4.24:1 at best, which clears the 3:1 floor for a mark or large label but
  /// not the 4.5:1 body-text floor. A paragraph on a phase colour uses
  /// [surface] with [text]; white text on a phase colour uses [fillStrong].
  final Color fill;

  /// Whichever of ink or white reads better on [fill], chosen by measurement.
  final Color onFill;

  /// [fill] adjusted so it can carry [onFillStrong] at 4.5:1.
  ///
  /// Equal to [fill] where the token already clears it (sage and plum in
  /// light; every token in dark, where they are pale enough to carry ink).
  /// This is what a saturated chip, badge or small-text button in a phase
  /// colour uses, so "text on the phase hue" is never a contrast failure.
  final Color fillStrong;

  /// Legible on [fillStrong] at body size: white in light mode, the dark
  /// canvas in dark mode, where the phase tokens are pale.
  final Color onFillStrong;

  /// Low-emphasis background tint — the design's `*-soft` token. Range
  /// highlights, card washes, icon tiles.
  final Color surface;

  /// Hairline for outlined treatments.
  final Color border;

  /// The phase hue as text or an icon on a card. Clears 4.5:1 on paper in
  /// light mode and on the dark card fill in dark mode.
  final Color text;

  /// Fill for the segmented cycle bar and its overlay lanes. Paler than
  /// [fill]: it is an 11px band on paper, read as a proportion rather than as
  /// a value, and the saturated hue at that size vibrates.
  final Color band;

  /// Two-stop gradient for pale backdrops, behind dark text.
  final List<Color> gradient;

  /// Two-stop gradient for a saturated surface that carries white text.
  ///
  /// Opposite job to [gradient]: that one sits behind ink, this one sits under
  /// white. See the contrast note on `AppColors.menstrualHero`.
  final List<Color> hero;
}

class PhaseColors {
  /// Non-widget entry point, for painters and pure functions.
  const PhaseColors.forBrightness(this.brightness);

  factory PhaseColors.of(BuildContext context) =>
      PhaseColors.forBrightness(Theme.of(context).brightness);

  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;

  PhaseSwatch phase(CyclePhase phase) => switch (phase) {
        CyclePhase.menstrual => period,
        CyclePhase.follicular => follicular,
        CyclePhase.ovulation => ovulation,
        CyclePhase.luteal => luteal(),
      };

  /// Period days that have actually been logged.
  PhaseSwatch get period => _build(
        light: AppColors.roseToken,
        dark: AppColors.darkRose,
        lightSurface: AppColors.roseSoft,
        darkSurface: AppColors.darkRoseSoft,
        lightBand: AppColors.roseToken,
        darkBand: AppColors.darkRose,
        gradient: AppColors.menstrualGradient,
        hero: AppColors.menstrualHero,
        // Rose is the lightest phase token: 3.18:1 as text on paper. 40%
        // toward ink is the smallest step that also clears 4.5:1 on roseSoft,
        // which is the surface it is most often read on.
        lightTextLerp: 0.40,
        lightStrong: AppColors.roseStrong,
      );

  /// Predicted, not-yet-confirmed period days.
  ///
  /// The same hue as [period] and deliberately so: the design distinguishes a
  /// forecast by a dashed outline over an unfilled cell, not by a second,
  /// paler pink that would read as a lighter period. The call site supplies
  /// the outline; this supplies the hue.
  PhaseSwatch get predicted => period;

  PhaseSwatch get follicular => _build(
        light: AppColors.sage,
        dark: AppColors.darkSage,
        lightSurface: AppColors.sageSoft,
        darkSurface: AppColors.darkSageSoft,
        lightBand: AppColors.bandFollicular,
        darkBand: AppColors.darkBandFollicular,
        gradient: AppColors.follicularGradient,
        hero: AppColors.follicularHero,
        // Sage clears the floor on paper and canvas as delivered, but reaches
        // only 4.16:1 on sageSoft; 9% toward ink fixes that surface.
        lightTextLerp: 0.09,
      );

  PhaseSwatch get fertile => _build(
        light: AppColors.sage,
        dark: AppColors.darkSage,
        lightSurface: AppColors.sageSoft,
        darkSurface: AppColors.darkSageSoft,
        lightBand: AppColors.bandFertile,
        darkBand: AppColors.darkBandFertile,
        gradient: AppColors.follicularGradient,
        hero: AppColors.follicularHero,
        lightTextLerp: 0.09,
      );

  PhaseSwatch get ovulation => _build(
        light: AppColors.violet,
        dark: AppColors.darkViolet,
        lightSurface: AppColors.violetSoft,
        darkSurface: AppColors.darkVioletSoft,
        lightBand: AppColors.violet,
        darkBand: AppColors.darkViolet,
        gradient: AppColors.ovulationGradient,
        hero: AppColors.ovulationHero,
        // #8371b0 is 4.17:1 as text on paper and 3.98:1 on violetSoft, both
        // under the floor, so the violet is nudged toward ink for text use.
        lightTextLerp: 0.23,
        lightStrong: AppColors.violetStrong,
      );

  /// A day that carries a saved entry.
  PhaseSwatch get logged => ovulation;

  /// The luteal / premenstrual wash. A method rather than a getter to keep it
  /// visually distinct at call sites from the confirmed-state getters above.
  PhaseSwatch luteal() => _build(
        light: AppColors.plum,
        dark: AppColors.darkPlum,
        lightSurface: AppColors.plumSoft,
        darkSurface: AppColors.darkPlumSoft,
        lightBand: AppColors.bandLuteal,
        darkBand: AppColors.darkBandLuteal,
        gradient: AppColors.lutealGradient,
        hero: AppColors.lutealHero,
      );

  /// The PMS overlay. Shares luteal's plum identity — it is a window inside
  /// the luteal phase, not a fifth phase — and differs only in its band.
  PhaseSwatch get pms => _build(
        light: AppColors.plum,
        dark: AppColors.darkPlum,
        lightSurface: AppColors.plumSoft,
        darkSurface: AppColors.darkPlumSoft,
        lightBand: AppColors.bandPms,
        darkBand: AppColors.darkBandPms,
        gradient: AppColors.lutealGradient,
        hero: AppColors.lutealHero,
      );

  PhaseSwatch _build({
    required Color light,
    required Color dark,
    required Color lightSurface,
    required Color darkSurface,
    required Color lightBand,
    required Color darkBand,
    required List<Color> gradient,
    required List<Color> hero,
    double lightTextLerp = 0,
    Color? lightStrong,
  }) {
    final base = _dark ? dark : light;
    return PhaseSwatch(
      fill: base,
      onFill: AppContrast.onColor(base),
      // Dark mode needs no deepened variant: every phase token is pale there
      // by design, so the dark canvas reads on it at 5.3:1 or better. In light
      // mode only the mid-tone hues need one, and they pass it in.
      fillStrong: _dark ? base : (lightStrong ?? base),
      onFillStrong: _dark ? AppColors.darkCanvas : Colors.white,
      surface: _dark ? darkSurface : lightSurface,
      border: base.withOpacity(_dark ? 0.46 : 0.34),
      // The dark tokens are already lifted toward white by the design, so they
      // read on the dark card as delivered. Only the light tokens sometimes
      // need a nudge toward ink to clear the body-text floor.
      text: _dark || lightTextLerp == 0
          ? base
          : Color.lerp(base, AppColors.ink, lightTextLerp)!,
      band: _dark ? darkBand : lightBand,
      gradient: gradient,
      // The hero stops are already deep enough to carry white text; lifting
      // them the way the other roles are lifted would undo exactly the
      // contrast they were chosen for.
      hero: hero,
    );
  }

}

/// Surface and text tokens that vary by brightness, so screens stop
/// hardcoding `AppColors.ink` (which is invisible in dark mode).
extension ThemeSurfaces on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary text colour.
  Color get inkColor => isDark ? AppColors.darkText : AppColors.ink;

  /// Secondary text — labels, captions, supporting copy.
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.muted;

  /// Tertiary text and disabled states.
  Color get subtleColor =>
      isDark ? AppColors.darkMuted.withOpacity(0.62) : AppColors.subtle;

  /// Hairline dividers and card borders.
  Color get lineColor => isDark ? AppColors.darkLine : AppColors.line;

  /// Default card fill — the design's `--paper`.
  Color get cardColor => isDark ? AppColors.darkPaper : AppColors.paper;

  /// Fill for a surface that must read as sitting above the cards around it.
  /// Identical to [cardColor] in light mode, where the hairline and shadow do
  /// the work; dark mode needs a lighter fill because shadow cannot separate
  /// two near-black surfaces.
  Color get elevatedCardColor =>
      isDark ? AppColors.darkCardElevated : AppColors.paper;

  /// Page background — the design's `--canvas`.
  Color get canvasColor => isDark ? AppColors.darkCanvas : AppColors.canvas;

  /// The active palette's seed, for accenting non-semantic elements.
  Color get accentColor => Theme.of(this).colorScheme.primary;
}
