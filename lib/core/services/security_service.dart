import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/encryption_util.dart';

enum LockType { none, pin, biometric }

class SecurityService {
  SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'cyclecare.pin';
  static const _lockTypeKey = 'cyclecare.lock_type';
  static const _lockEnabledKey = 'cyclecare.lock_enabled';
  static const _hideInSwitcherKey = 'cyclecare.hide_in_switcher';

  Future<bool> get isLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  Future<LockType> get lockType async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lockTypeKey);
    return LockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LockType.none,
    );
  }

  Future<bool> get canUseBiometric async {
    final available = await _localAuth.canCheckBiometrics;
    final enrolled = await _localAuth.isDeviceSupported();
    return available && enrolled;
  }

  Future<bool> get hideInAppSwitcher async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideInSwitcherKey) ?? false;
  }

  Future<void> setHideInAppSwitcher(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideInSwitcherKey, value);
    if (value) {
      await _enableSecureFlag();
    } else {
      await _disableSecureFlag();
    }
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(
        key: _pinKey, value: EncryptionUtil.hashPin(pin));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, true);
    await prefs.setString(_lockTypeKey, LockType.pin.name);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored == EncryptionUtil.hashPin(pin);
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock CycleCare',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> enableBiometricLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, true);
    await prefs.setString(_lockTypeKey, LockType.biometric.name);
  }

  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setString(_lockTypeKey, LockType.none.name);
    await _secureStorage.delete(key: _pinKey);
  }

  Future<void> _enableSecureFlag() async {
    // Applied via AppLifecycleObserver in the main app widget
  }

  Future<void> _disableSecureFlag() async {
    // Applied via AppLifecycleObserver in the main app widget
  }
}
