import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Haptics
//
// Touch feedback is the cheapest way to make an interface feel physical, and
// the fastest way to make it feel cheap if overused. The rule here: haptics
// confirm that a *state changed*, never that a finger moved. Scrolling,
// hovering, and navigating stay silent; selecting, saving, and completing
// speak.
//
// Every call is fire-and-forget and swallows platform errors — a device
// without a haptic engine must never surface an exception into the UI.
// ─────────────────────────────────────────────────────────────────────────────

class Haptics {
  Haptics._();

  /// Mirrors the user's haptics preference. Kept as a plain static so any
  /// widget can fire feedback without threading a provider through the tree.
  /// `AppSettingsNotifier` is the single writer.
  static bool enabled = true;

  static Future<void> _fire(Future<void> Function() action) async {
    if (!enabled) return;
    try {
      await action();
    } catch (_) {
      // No haptic engine, or the platform refused. Not worth surfacing.
    }
  }

  /// Discrete selection change: a chip toggled, a segment picked, a day tapped.
  static Future<void> selection() => _fire(HapticFeedback.selectionClick);

  /// A button press registered.
  static Future<void> tap() => _fire(HapticFeedback.lightImpact);

  /// A meaningful commit: log saved, period marked, reminder created.
  static Future<void> commit() => _fire(HapticFeedback.mediumImpact);

  /// Destructive or irreversible: data deleted, period removed.
  static Future<void> warn() => _fire(HapticFeedback.heavyImpact);

  /// Celebration — pet level-up, streak milestone, achievement unlocked.
  /// Two taps in quick succession read as "something good happened" in a way
  /// a single impact does not.
  static Future<void> celebrate() async {
    if (!enabled) return;
    await _fire(HapticFeedback.mediumImpact);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await _fire(HapticFeedback.lightImpact);
  }

  /// Long-press affordance recognised.
  static Future<void> longPress() => _fire(HapticFeedback.vibrate);
}

/// Debug helper: asserts haptics aren't being fired from a scroll callback,
/// which is the most common way this kind of feedback turns annoying.
@visibleForTesting
bool debugHapticsEnabled() => Haptics.enabled;
