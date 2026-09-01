import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/security_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App lock status
//
// `SecurityService` answers three separate async questions — is the lock on,
// which kind is it, can this device do biometrics. Settings needs all three at
// once to render a single row, so they are resolved together here rather than
// with three futures racing inside a widget.
//
// The lock itself stays in `SecurityService`; this only reads it and is
// invalidated after every change so the row never shows a stale state.
// ─────────────────────────────────────────────────────────────────────────────

final Provider<SecurityService> securityServiceProvider =
    Provider<SecurityService>((ref) => SecurityService());

@immutable
class LockStatus {
  const LockStatus({
    required this.enabled,
    required this.type,
    required this.biometricAvailable,
  });

  final bool enabled;
  final LockType type;

  /// False on devices with no enrolled biometrics, and on platforms where the
  /// plugin is unavailable. The toggle is disabled rather than hidden so the
  /// capability is discoverable once it exists.
  final bool biometricAvailable;

  bool get usesBiometric => enabled && type == LockType.biometric;

  /// A PIN is always set first, so an enabled lock of either kind has one.
  bool get hasPin => enabled;

  /// Short value for the settings row.
  String get badge {
    if (!enabled) return 'Off';
    return type == LockType.biometric ? 'Biometric' : 'PIN';
  }

  String get summary {
    if (!enabled) {
      return 'Anyone holding your phone can open CycleCare';
    }
    return type == LockType.biometric
        ? 'Face or fingerprint, with your PIN as backup'
        : 'A PIN is needed to open the app';
  }
}

final FutureProvider<LockStatus> lockStatusProvider =
    FutureProvider<LockStatus>((ref) async {
  final security = ref.watch(securityServiceProvider);

  final enabled = await security.isLockEnabled;
  final type = await security.lockType;

  // A device without a biometric sensor throws rather than returning false,
  // and that must never take the whole settings screen down with it.
  bool biometric = false;
  try {
    biometric = await security.canUseBiometric;
  } catch (_) {
    biometric = false;
  }

  return LockStatus(
    enabled: enabled,
    type: type,
    biometricAvailable: biometric,
  );
});
