import 'package:flutter/material.dart';

import '../../features/tracking/domain/cycle_models.dart';
import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase colour resolution
//
// A deliberate exception to the palette system: the cycle phase hues stay put
// when the user changes their theme. Rose means period, teal means fertile,
// violet means ovulation — that mapping is learned within a day of use and
// becomes how the calendar is read at a glance. Recolouring it per theme would
// trade a functional signal for decoration.
//
// What *does* change is how each hue is rendered. A saturated fill that reads
// beautifully on cream becomes a glare on a near-black surface, and a pale
// tint that separates nicely in light mode disappears entirely in dark. So
// every phase resolves to a small set of roles — fill, surface, border, text —
// tuned per brightness rather than a single flat colour.
// ─────────────────────────────────────────────────────────────────────────────

/// The four colour roles a phase needs to render anywhere in the app.
@immutable
class PhaseSwatch {
  const PhaseSwatch({
    required this.fill,
    required this.onFill,
    required this.surface,
    required this.border,
    required this.text,
    required this.gradient,
  });

  /// Solid, high-emphasis. Selected calendar days, progress arcs, dots.
  final Color fill;

  /// Legible on top of [fill].
  final Color onFill;

  /// Low-emphasis background tint. Range highlights, card washes.
  final Color surface;

  /// Hairline for outlined treatments.
  final Color border;

  /// [fill] adjusted for contrast when used as text or an icon on a normal
  /// card. The raw fill is often too light to read at body size.
  final Color text;

  /// Two-stop gradient for hero surfaces and backdrops.
  final List<Color> gradient;
}

class PhaseColors {
  /// Non-widget entry point, for painters and pure functions.
  const PhaseColors.forBrightness(this.brightness);

  factory PhaseColors.of(BuildContext context) =>
      PhaseColors.forBrightness(Theme.of(context).brightness);

  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;

  PhaseSwatch phase(CyclePhase phase) => switch (phase) {
        CyclePhase.menstrual => _build(
            AppColors.period,
            AppColors.menstrualGradient,
          ),
        CyclePhase.follicular => _build(
            AppColors.info,
            AppColors.follicularGradient,
          ),
        CyclePhase.ovulation => _build(
            AppColors.ovulation,
            AppColors.ovulationGradient,
          ),
        CyclePhase.luteal => _build(
            AppColors.luteal,
            AppColors.lutealGradient,
          ),
      };

  /// Period days that have actually been logged.
  PhaseSwatch get period => _build(AppColors.period, AppColors.menstrualGradient);

  /// Predicted, not-yet-confirmed period days. Intentionally softer than
  /// [period] so a forecast is never mistaken for a record.
  PhaseSwatch get predicted =>
      _build(AppColors.predicted, const [AppColors.predicted, AppColors.period]);

  PhaseSwatch get fertile =>
      _build(AppColors.fertile, const [AppColors.fertile, Color(0xFF7FD8C4)]);

  PhaseSwatch get ovulation =>
      _build(AppColors.ovulation, AppColors.ovulationGradient);

  PhaseSwatch get logged =>
      _build(AppColors.ovulation, AppColors.ovulationGradient);

  /// The luteal / premenstrual wash. A method rather than a getter to keep it
  /// visually distinct at call sites from the confirmed-state getters above.
  PhaseSwatch luteal() => _build(AppColors.luteal, AppColors.lutealGradient);

  PhaseSwatch _build(Color base, List<Color> gradient) {
    if (_dark) {
      // On dark surfaces the hue is lifted toward white so it keeps its
      // identity without the muddiness a pure hue picks up against near-black,
      // and the tint is kept very low-alpha so large fills don't glow.
      final lifted = Color.lerp(base, Colors.white, 0.18)!;
      return PhaseSwatch(
        fill: lifted,
        onFill: AppColors.darkBg,
        surface: base.withOpacity(0.20),
        border: lifted.withOpacity(0.42),
        text: Color.lerp(base, Colors.white, 0.34)!,
        gradient: [
          Color.lerp(gradient.first, Colors.white, 0.12)!,
          Color.lerp(gradient.last, Colors.white, 0.12)!,
        ],
      );
    }

    return PhaseSwatch(
      fill: base,
      onFill: Colors.white,
      surface: base.withOpacity(0.13),
      border: base.withOpacity(0.34),
      // Darkened for body-text contrast. The pastel fills are pretty but
      // several fail contrast targets as text on white.
      text: Color.lerp(base, AppColors.ink, 0.30)!,
      gradient: gradient,
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

  /// Default card fill.
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.white;

  /// Page background.
  Color get canvasColor => isDark ? AppColors.darkBg : AppColors.cream;

  /// The active palette's seed, for accenting non-semantic elements.
  Color get accentColor => Theme.of(this).colorScheme.primary;
}
