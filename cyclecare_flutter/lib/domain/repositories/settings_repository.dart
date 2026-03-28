import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<Settings?> getSettings();
  Stream<Settings?> watchSettings();
  Future<bool> updateSettings(Settings settings);
  Future<void> updateCycleSettings(int cycleLength, int periodLength);
  Future<void> updatePrivacySettings(bool pinEnabled, bool biometricEnabled, bool privacyMode);
  Future<void> updateNotificationSettings(bool enabled, bool quietHours, String start, String end);
  Future<void> completeOnboarding();
}
