import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CycleCare Design System — Motion Tokens
//
// Three rules govern every animation in this app:
//
//  1. Entering and exiting elements use ease-out. It starts fast, so the
//     interface answers the user in the same instant they act. `ease-in` is
//     never used for UI — it delays the initial movement, which is exactly
//     the moment the user is watching most closely, and reads as sluggish
//     even at an identical duration.
//  2. UI motion stays under ~300ms. Anything longer is either explanatory
//     (a first-run reveal, seen once) or a bug.
//  3. Nothing appears from nothing. Entrances start at ~0.96 scale, never 0 —
//     objects in the real world don't pop into existence, and the eye knows it.
//
// Flutter's built-in curves are deliberately weak. The custom cubics below are
// the stronger variants that give motion intent instead of mush.
// ─────────────────────────────────────────────────────────────────────────────

class AppCurves {
  AppCurves._();

  /// Strong ease-out. The default for anything entering, exiting, or
  /// responding to a tap. Fast off the line, long gentle settle.
  static const Curve out = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out. For elements *moving* or morphing while already
  /// on screen, where symmetric acceleration reads as physical.
  static const Curve inOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// The iOS drawer curve (by way of Ionic). Near-instant response with a
  /// very long tail — the signature of a sheet that feels attached to
  /// the user's finger.
  static const Curve drawer = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Gentle overshoot, for playful confirmations only (pet reactions,
  /// achievement pops, streak bumps). Kept subtle on purpose; bounce in
  /// ordinary UI is noise.
  static const Curve springy = Cubic(0.34, 1.42, 0.64, 1.0);

  /// Plain ease, for colour and opacity crossfades where there is no
  /// spatial movement to accelerate.
  static const Curve fade = Curves.ease;
}

class AppDurations {
  AppDurations._();

  /// Press feedback. Must be short enough to feel like contact, not playback.
  static const Duration press = Duration(milliseconds: 120);

  /// Tooltips, small badges, icon swaps.
  static const Duration micro = Duration(milliseconds: 160);

  /// Chips, toggles, selection changes, dropdowns.
  static const Duration fast = Duration(milliseconds: 190);

  /// The workhorse: cards, list reflows, and content changes.
  static const Duration normal = Duration(milliseconds: 240);

  /// Frequent detail navigation stays especially crisp.
  static const Duration navigation = Duration(milliseconds: 220);

  /// Sheets and dialogs travel farther but remain under 300ms.
  static const Duration modal = Duration(milliseconds: 280);

  /// Fast reversal for dismissals and back navigation.
  static const Duration exit = Duration(milliseconds: 180);

  /// First-run and once-per-session reveals (the cycle ring drawing itself).
  /// Long durations are only acceptable when the user sees them rarely.
  static const Duration reveal = Duration(milliseconds: 620);

  /// Delay between staggered siblings. Short by design — long stagger makes
  /// an interface feel like it is buffering.
  static const Duration staggerStep = Duration(milliseconds: 40);
}

/// Resolves motion against the platform's "reduce motion" accessibility
/// setting.
///
/// Reduced motion does not mean *no* feedback: colour and immediate state
/// changes remain. Spatial movement, scaling, and decorative delays are
/// removed.
class Motion {
  const Motion._(this.reduced);

  factory Motion.of(BuildContext context) {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Motion._(disable);
  }

  final bool reduced;

  /// Duration, collapsed to near-zero when the user asked for less motion.
  Duration call(Duration duration) =>
      reduced ? const Duration(milliseconds: 1) : duration;

  /// Decorative delay. Staggers disappear entirely under reduced motion.
  Duration delay(Duration duration) => reduced ? Duration.zero : duration;

  /// Distance for a translate-based entrance. Zero under reduced motion, so
  /// the element can change in place instead of sliding.
  double offset(double distance) => reduced ? 0 : distance;

  /// Starting scale for an entrance. Held at 1 under reduced motion.
  double scale(double from) => reduced ? 1 : from;
}
