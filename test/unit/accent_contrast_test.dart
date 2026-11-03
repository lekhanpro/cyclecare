// Contrast floors for the redesign's eight accents.
//
// Five of the design's swatches are mid-tones (Peach #b98263, Rose #bc667d,
// Lavender #8975ac, Ocean #537ca1, Teal #4c837c). White label text on any of
// them measures below 4.5:1, so a filled control must resolve a measured
// foreground rather than assuming white. These tests hold that floor for every
// palette in both appearances, so a later tweak to a swatch or to the
// derivation cannot quietly ship an unreadable button.

import 'package:cyclecare/core/theme/app_accents.dart';
import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccentRoles contrast', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        final label = '${palette.label} / ${brightness.name}';
        final roles = AccentRoles.resolve(palette.seed, brightness);
        final canvas = brightness == Brightness.dark
            ? AppColors.darkCanvas
            : AppColors.canvas;

        test('$label: filled-button text clears 4.5:1', () {
          final ratio = AccentRoles.contrast(roles.fill, roles.onFill);
          expect(
            ratio,
            greaterThanOrEqualTo(kTextContrastFloor),
            reason: 'onFill ${roles.onFill} on fill ${roles.fill} '
                'measured ${ratio.toStringAsFixed(2)}:1',
          );
        });

        test('$label: border clears 3:1 against the canvas', () {
          final ratio = AccentRoles.contrast(roles.border, canvas);
          expect(
            ratio,
            greaterThanOrEqualTo(kEdgeContrastFloor),
            reason: 'border ${roles.border} on canvas $canvas '
                'measured ${ratio.toStringAsFixed(2)}:1',
          );
        });

        test('$label: accent text clears 4.5:1 against the canvas', () {
          final ratio = AccentRoles.contrast(roles.text, canvas);
          expect(
            ratio,
            greaterThanOrEqualTo(kTextContrastFloor),
            reason: 'text ${roles.text} on canvas $canvas '
                'measured ${ratio.toStringAsFixed(2)}:1',
          );
        });

        test('$label: text on the soft surface clears 4.5:1', () {
          final ratio = AccentRoles.contrast(roles.onSurface, roles.surface);
          expect(
            ratio,
            greaterThanOrEqualTo(kTextContrastFloor),
            reason: 'onSurface ${roles.onSurface} on surface ${roles.surface} '
                'measured ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    }

    test('the foreground is measured, not assumed to be white', () {
      // Peach is the clearest case: white on #b98263 is 3.26:1, so the
      // resolver must reach for the design's dark ink instead.
      final peach = AccentRoles.resolve(AppPalette.peach.seed, Brightness.light);
      expect(peach.onFill, kDarkOnAccent);
      expect(
        AccentRoles.contrast(AppColors.plum, Colors.white),
        greaterThanOrEqualTo(kTextContrastFloor),
      );
    });

    test('dark mode flips the primary foreground to the design ink', () {
      // `.dark .primary{background:var(--plum);color:#32212a}`.
      final dark = AccentRoles.resolve(AppPalette.pinkRose.seed, Brightness.dark);
      expect(dark.fill, AppColors.darkPlum);
      expect(dark.onFill, kDarkOnAccent);
    });

    test('the default palette returns the delivered tokens verbatim', () {
      final light =
          AccentRoles.resolve(AppPalette.pinkRose.seed, Brightness.light);
      expect(light.fill, AppColors.plum);
      expect(light.onFill, Colors.white);
      expect(light.surface, AppColors.plumSoft);

      final dark =
          AccentRoles.resolve(AppPalette.pinkRose.seed, Brightness.dark);
      expect(dark.surface, AppColors.darkPlumSoft);
    });

    test(
      'the dark-lift rule reproduces the design own plum pair',
      () {
        // The handoff resolved exactly one light/dark accent pair by hand.
        // Applying the rule to the light token must land on the delivered dark
        // token, which is what justifies using it for the other seven accents.
        final lifted = AccentRoles.liftForDark(AppColors.plum);
        final delivered = AppColors.darkPlum;
        // Channels are doubles in 0..1 here, so the tolerance is expressed in
        // those units: 2/255 is a two-step difference in 8-bit terms.
        const tolerance = 2 / 255;
        expect((lifted.r - delivered.r).abs(), lessThanOrEqualTo(tolerance));
        expect((lifted.g - delivered.g).abs(), lessThanOrEqualTo(tolerance));
        expect((lifted.b - delivered.b).abs(), lessThanOrEqualTo(tolerance));
      },
    );

    test('contrast() matches known WCAG values', () {
      expect(
        AccentRoles.contrast(Colors.black, Colors.white),
        closeTo(21, 0.01),
      );
      expect(
        AccentRoles.contrast(Colors.white, Colors.white),
        closeTo(1, 0.001),
      );
      // The design destructive fill, #a14d60, carries white at 5.61:1.
      expect(
        AccentRoles.contrast(const Color(0xFFA14D60), Colors.white),
        closeTo(5.61, 0.05),
      );
    });
  });
}
