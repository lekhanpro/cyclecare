import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Contrast
//
// The plan requires verified contrast rather than a confident eye, and the
// delivered palette needs it: measured against the WCAG formula, several of
// the redesign's own values miss the 4.5:1 body-text floor on the surfaces
// they are actually used on. The muted grey is 4.09:1 on a plum-soft card,
// rose is 3.18:1 as text on paper, and white on the Peach accent is 2.9:1.
//
// So contrast is computed here instead of guessed. A token keeps the design's
// hue and is moved toward ink or white by the smallest step that clears the
// floor, which is a change of a few percent that nobody can see beside the
// original and that makes the text readable.
//
// `test/unit/design_tokens_test.dart` asserts the floors for every pair the
// app actually paints, so a later tweak to a token cannot quietly break one.
// ─────────────────────────────────────────────────────────────────────────────

class AppContrast {
  AppContrast._();

  /// The WCAG body-text floor. Also the floor for an icon that carries meaning
  /// on its own.
  static const double bodyFloor = 4.5;

  /// The WCAG floor for large text (about 18.5pt bold or 24pt regular), for a
  /// non-text mark such as a calendar day dot, and for a control's border.
  static const double largeFloor = 3.0;

  /// Relative luminance, per WCAG 2.
  static double luminance(Color color) {
    double channel(int value) {
      final v = value / 255;
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(color.red) +
        0.7152 * channel(color.green) +
        0.0722 * channel(color.blue);
  }

  /// Contrast ratio between two opaque colours, from 1 to 21.
  static double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Whichever of [onLight] and [onDark] reads better on [background].
  ///
  /// Measured rather than inferred from the hue: several of the phase tokens
  /// are mid-tones where the better choice is not the one a glance suggests
  /// (the rose token carries ink better than white, by a wide margin).
  static Color onColor(
    Color background, {
    Color onLight = AppColors.ink,
    Color onDark = Colors.white,
  }) =>
      ratio(background, onLight) >= ratio(background, onDark) ? onLight : onDark;

  /// [base] moved toward [toward] by the smallest step that lifts its contrast
  /// against [against] to [floor]; [base] unchanged when it already clears it.
  ///
  /// Returns the fully-stepped colour if even that cannot reach the floor, so
  /// a caller always gets the best available rather than a silent failure.
  static Color adjust(
    Color base, {
    required Color toward,
    required Color against,
    double floor = bodyFloor,
    int steps = 100,
  }) {
    if (ratio(base, against) >= floor) return base;
    for (var i = 1; i <= steps; i++) {
      final candidate = Color.lerp(base, toward, i / steps)!;
      if (ratio(candidate, against) >= floor) return candidate;
    }
    return toward;
  }

  /// A filled control's background and foreground for an arbitrary accent.
  ///
  /// The palette now carries the design's eight accents exactly as its swatch
  /// shows them, and five of those are mid-tones that cannot hold white label
  /// text: Peach is 2.86:1, Rose 3.85:1, Ocean 4.14:1, Teal 4.12:1, Lavender
  /// 4.31:1. Rather than drop the design's colours or ship unreadable buttons,
  /// the fill is deepened (light) or lightened (dark) just far enough.
  ///
  /// This mirrors what the design itself does between appearances: light mode
  /// is white text on the deep plum, dark mode is dark ink on the pale plum.
  static ({Color background, Color foreground}) filledPair(
    Color accent, {
    required bool isDark,
  }) {
    if (isDark) {
      const foreground = AppColors.darkOnAccent;
      return (
        background: adjust(accent, toward: Colors.white, against: foreground),
        foreground: foreground,
      );
    }
    return (
      background: adjust(accent, toward: AppColors.ink, against: Colors.white),
      foreground: Colors.white,
    );
  }

  /// The accent as text or an icon on [surface], deepened or lightened only as
  /// far as the floor requires.
  static Color readable(
    Color accent, {
    required Color surface,
    required bool isDark,
    double floor = bodyFloor,
  }) =>
      adjust(
        accent,
        toward: isDark ? Colors.white : AppColors.ink,
        against: surface,
        floor: floor,
      );
}
