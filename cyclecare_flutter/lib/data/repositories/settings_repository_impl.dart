import '../../domain/entities/settings.dart' as domain;
import '../../domain/repositories/settings_repository.dart';
import '../database/app_database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _database;

  SettingsRepositoryImpl(this._database);

  @override
  Future<domain.Settings?> getSettings() async {
    final settings = await _database.getSettings();
    return settings != null ? _toDomain(settings) : null;
  }

  @override
  Stream<domain.Settings?> watchSettings() {
    return _database.watchSettings().map(
          (settings) => settings != null ? _toDomain(settings) : null,
        );
  }

  @override
  Future<bool> updateSettings(domain.Settings settings) {
    return _database.updateSettings(_toData(settings));
  }

  @override
  Future<void> updateCycleSettings(int cycleLength, int periodLength) async {
    final current = await getSettings();
    if (current != null) {
      await updateSettings(
        current.copyWith(
          averageCycleLength: cycleLength,
          averagePeriodLength: periodLength,
        ),
      );
    }
  }

  @override
  Future<void> updatePrivacySettings(
      bool pinEnabled, bool biometricEnabled, bool privacyMode) async {
    final current = await getSettings();
    if (current != null) {
      await updateSettings(
        current.copyWith(
          isPinEnabled: pinEnabled,
          isBiometricEnabled: biometricEnabled,
          isPrivacyModeEnabled: privacyMode,
        ),
      );
    }
  }

  @override
  Future<void> updateNotificationSettings(
      bool enabled, bool quietHours, String start, String end) async {
    final current = await getSettings();
    if (current != null) {
      await updateSettings(
        current.copyWith(
          notificationsEnabled: enabled,
          quietHoursEnabled: quietHours,
          quietHoursStart: start,
          quietHoursEnd: end,
        ),
      );
    }
  }

  @override
  Future<void> completeOnboarding() async {
    final current = await getSettings();
    if (current != null) {
      await updateSettings(
        current.copyWith(onboardingCompleted: true),
      );
    }
  }

  domain.Settings _toDomain(Setting setting) {
    return domain.Settings(
      id: setting.id,
      theme: setting.theme,
      primaryColor: setting.primaryColor,
      averageCycleLength: setting.averageCycleLength,
      averagePeriodLength: setting.averagePeriodLength,
      lutealPhaseLength: setting.lutealPhaseLength,
      temperatureUnit: setting.temperatureUnit,
      dateFormat: setting.dateFormat,
      language: setting.language,
      isPinEnabled: setting.isPinEnabled,
      pinHash: setting.pinHash,
      isBiometricEnabled: setting.isBiometricEnabled,
      isPrivacyModeEnabled: setting.isPrivacyModeEnabled,
      hideNotificationContent: setting.hideNotificationContent,
      notificationsEnabled: setting.notificationsEnabled,
      quietHoursEnabled: setting.quietHoursEnabled,
      quietHoursStart: setting.quietHoursStart,
      quietHoursEnd: setting.quietHoursEnd,
      onboardingCompleted: setting.onboardingCompleted,
      profileName: setting.profileName,
      profileBirthYear: setting.profileBirthYear,
      profileTryingToConceive: setting.profileTryingToConceive,
      pregnancyMode: setting.pregnancyMode,
      breastfeedingMode: setting.breastfeedingMode,
      menopauseMode: setting.menopauseMode,
    );
  }

  Setting _toData(domain.Settings settings) {
    return Setting(
      id: settings.id,
      theme: settings.theme,
      primaryColor: settings.primaryColor,
      averageCycleLength: settings.averageCycleLength,
      averagePeriodLength: settings.averagePeriodLength,
      lutealPhaseLength: settings.lutealPhaseLength,
      temperatureUnit: settings.temperatureUnit,
      dateFormat: settings.dateFormat,
      language: settings.language,
      isPinEnabled: settings.isPinEnabled,
      pinHash: settings.pinHash,
      isBiometricEnabled: settings.isBiometricEnabled,
      isPrivacyModeEnabled: settings.isPrivacyModeEnabled,
      hideNotificationContent: settings.hideNotificationContent,
      notificationsEnabled: settings.notificationsEnabled,
      quietHoursEnabled: settings.quietHoursEnabled,
      quietHoursStart: settings.quietHoursStart,
      quietHoursEnd: settings.quietHoursEnd,
      onboardingCompleted: settings.onboardingCompleted,
      profileName: settings.profileName,
      profileBirthYear: settings.profileBirthYear,
      profileTryingToConceive: settings.profileTryingToConceive,
      pregnancyMode: settings.pregnancyMode,
      breastfeedingMode: settings.breastfeedingMode,
      menopauseMode: settings.menopauseMode,
    );
  }
}
