// Contrast floors for every token pair the app actually paints.
//
// The redesign's palette is beautiful and several of its values are, measured
// against WCAG, too light for the surfaces they sit on: the muted grey is
// 4.09:1 on a plum-soft card, rose is 3.18:1 as text on paper, and white on
// the Peach accent is 2.86:1. The theme corrects each by the smallest step
// that clears the floor, which is invisible beside the original.
//
// These tests hold those corrections. If someone later retunes a token toward
// the raw design value, the failure says which pair broke and by how much,
// instead of the app quietly shipping unreadable text.

import 'package:cyclecare/core/theme/app_colors.dart';
import 'package:cyclecare/core/theme/app_contrast.dart';
import 'package:cyclecare/core/theme/phase_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts [foreground] on [background] clears [floor], reporting the measured
/// ratio either way so a failure is actionable.
void expectContrast(
  String label,
  Color foreground,
  Color background, {
  double floor = AppContrast.bodyFloor,
}) {
  final ratio = AppContrast.ratio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(floor),
    reason: '$label measured ${ratio.toStringAsFixed(2)}:1, needs $floor:1',
  );
}

void main() {
  group('neutral text', () {
    // Every tinted surface the design puts muted copy on: the peach care
    // note, the rose hero, the sage check-in, the plum-soft panels.
    const lightSurfaces = <String, Color>{
      'canvas': AppColors.canvas,
      'paper': AppColors.paper,
      'plumSoft': AppColors.plumSoft,
      'roseSoft': AppColors.roseSoft,
      'sageSoft': AppColors.sageSoft,
      'violetSoft': AppColors.violetSoft,
      'peach': AppColors.peach,
    };

    test('ink and muted clear the floor on every light surface', () {
      lightSurfaces.forEach((name, surface) {
        expectContrast('ink on $name', AppColors.ink, surface);
        expectContrast('muted on $name', AppColors.muted, surface);
      });
    });

    test('dark text and muted clear the floor on every dark surface', () {
      const darkSurfaces = <String, Color>{
        'darkCanvas': AppColors.darkCanvas,
        'darkPaper': AppColors.darkPaper,
        'darkCardElevated': AppColors.darkCardElevated,
        'darkPlumSoft': AppColors.darkPlumSoft,
        'darkRoseSoft': AppColors.darkRoseSoft,
        'darkSageSoft': AppColors.darkSageSoft,
        'darkVioletSoft': AppColors.darkVioletSoft,
      };
      darkSurfaces.forEach((name, surface) {
        expectContrast('darkText on $name', AppColors.darkText, surface);
        expectContrast('darkMuted on $name', AppColors.darkMuted, surface);
      });
    });
  });

  group('phase swatches', () {
    for (final brightness in Brightness.values) {
      final colors = PhaseColors.forBrightness(brightness);
      final isDark = brightness == Brightness.dark;
      final canvas = isDark ? AppColors.darkCanvas : AppColors.canvas;
      final paper = isDark ? AppColors.darkPaper : AppColors.paper;
      final swatches = <String, PhaseSwatch>{
        'period': colors.period,
        'follicular': colors.follicular,
        'fertile': colors.fertile,
        'ovulation': colors.ovulation,
        'luteal': colors.luteal(),
        'pms': colors.pms,
      };

      test('${brightness.name}: text reads on paper, canvas and own surface', () {
        swatches.forEach((name, swatch) {
          expectContrast('$name text on paper', swatch.text, paper);
          expectContrast('$name text on canvas', swatch.text, canvas);
          expectContrast('$name text on own surface', swatch.text, swatch.surface);
        });
      });

      test('${brightness.name}: a filled phase control carries its label', () {
        swatches.forEach((name, swatch) {
          expectContrast(
            '$name onFillStrong on fillStrong',
            swatch.onFillStrong,
            swatch.fillStrong,
          );
        });
      });

      test('${brightness.name}: a phase mark is visible as a mark', () {
        // The large-text / non-text floor: a calendar day fill or a dot is a
        // mark, not a paragraph, and always carries a number or label too.
        swatches.forEach((name, swatch) {
          expectContrast(
            '$name onFill on fill',
            swatch.onFill,
            swatch.fill,
            floor: AppContrast.largeFloor,
          );
        });
      });

      test('${brightness.name}: a hero gradient carries white text', () {
        swatches.forEach((name, swatch) {
          // The lightest stop is the worst case, before the radial highlight
          // lightens it further.
          expectContrast('$name hero', Colors.white, swatch.hero.first);
        });
      });

      test('${brightness.name}: bands separate from the track they sit on', () {
        // Deliberately a low floor. These are 11px bands on paper, read as a
        // proportion rather than a value, and the cycle bar always carries
        // labelled, iconed phase tabs beneath it — so the band is never the
        // only signal for a phase. This only asserts a band is not invisible.
        swatches.forEach((name, swatch) {
          expectContrast('$name band on paper', swatch.band, paper, floor: 1.5);
        });
      });
    }
  });

  group('palette accents', () {
    test('every accent can carry a filled control label', () {
      for (final palette in AppPalette.values) {
        for (final isDark in [false, true]) {
          final pair = AppContrast.filledPair(palette.seed, isDark: isDark);
          expectContrast(
            '${palette.label} filled (${isDark ? 'dark' : 'light'})',
            pair.foreground,
            pair.background,
          );
        }
      }
    });

    test('every accent can be read as text on its page', () {
      for (final palette in AppPalette.values) {
        for (final isDark in [false, true]) {
          final surface = isDark ? AppColors.darkPaper : AppColors.paper;
          final color = AppContrast.readable(
            palette.seed,
            surface: surface,
            isDark: isDark,
          );
          expectContrast(
            '${palette.label} text (${isDark ? 'dark' : 'light'})',
            color,
            surface,
          );
        }
      }
    });

    test('the display order covers every palette exactly once', () {
      expect(
        AppPalette.displayOrder.toSet(),
        AppPalette.values.toSet(),
        reason: 'the appearance picker would hide or repeat an accent',
      );
      expect(AppPalette.displayOrder.length, AppPalette.values.length);
    });
  });

  group('status colours', () {
    test('error and warning carry white at button size', () {
      expectContrast('white on error', Colors.white, AppColors.error);
      expectContrast('white on warning', Colors.white, AppColors.warning);
    });

    test('error is distinguishable from the period rose', () {
      // Both are warm reds. If they converge, an error state reads as a
      // period marker, which is the one confusion this app cannot afford.
      final ratio = AppContrast.ratio(AppColors.error, AppColors.period);
      expect(ratio, greaterThanOrEqualTo(1.5),
          reason: 'error ${AppColors.error} vs period ${AppColors.period} '
              'measured ${ratio.toStringAsFixed(2)}:1');
    });
  });

  group('contrast helpers', () {
    test('ratio is symmetric and spans the full range', () {
      expect(AppContrast.ratio(Colors.white, Colors.black), closeTo(21, 0.01));
      expect(AppContrast.ratio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(AppContrast.ratio(Colors.white, Colors.white), closeTo(1, 0.01));
    });

    test('adjust leaves a passing colour untouched', () {
      const passing = AppColors.plum;
      expect(
        AppContrast.adjust(
          passing,
          toward: AppColors.ink,
          against: Colors.white,
        ),
        passing,
      );
    });

    test('adjust moves a failing colour just far enough', () {
      // Raw rose on white is 3.23:1.
      final fixed = AppContrast.adjust(
        AppColors.roseToken,
        toward: AppColors.ink,
        against: Colors.white,
      );
      expect(fixed, isNot(AppColors.roseToken));
      expectContrast('adjusted rose on white', fixed, Colors.white);
    });

    test('onColor picks the better foreground by measurement', () {
      // The rose token carries ink better than white, which a glance at a
      // mid-tone pink does not suggest.
      expect(AppContrast.onColor(AppColors.roseToken), AppColors.ink);
      expect(AppContrast.onColor(AppColors.plum), Colors.white);
    });
  });
}
