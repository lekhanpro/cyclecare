import 'package:flutter/foundation.dart';

@immutable
class Settings {
  final int id;
  final String theme;
  final String primaryColor;
  final int averageCycleLength;
  final int averagePeriodLength;
  final int lutealPhaseLength;
  final String temperatureUnit;
  final String dateFormat;
  final String language;
  final bool isPinEnabled;
  final String pinHash;
  final bool isBiometricEnabled;
  final bool isPrivacyModeEnabled;
  final bool hideNotificationContent;
  final bool notificationsEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool onboardingCompleted;
  final String profileName;
  final int? profileBirthYear;
  final bool profileTryingToConceive;
  final bool pregnancyMode;
  final bool breastfeedingMode;
  final bool menopauseMode;

  const Settings({
    this.id = 1,
    this.theme = 'system',
    this.primaryColor = '#E91E63',
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.lutealPhaseLength = 14,
    this.temperatureUnit = 'celsius',
    this.dateFormat = 'MMM dd, yyyy',
    this.language = 'en',
    this.isPinEnabled = false,
    this.pinHash = '',
    this.isBiometricEnabled = false,
    this.isPrivacyModeEnabled = false,
    this.hideNotificationContent = true,
    this.notificationsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.onboardingCompleted = false,
    this.profileName = '',
    this.profileBirthYear,
    this.profileTryingToConceive = false,
    this.pregnancyMode = false,
    this.breastfeedingMode = false,
    this.menopauseMode = false,
  });

  Settings copyWith({
    int? id,
    String? theme,
    String? primaryColor,
    int? averageCycleLength,
    int? averagePeriodLength,
    int? lutealPhaseLength,
    String? temperatureUnit,
    String? dateFormat,
    String? language,
    bool? isPinEnabled,
    String? pinHash,
    bool? isBiometricEnabled,
    bool? isPrivacyModeEnabled,
    bool? hideNotificationContent,
    bool? notificationsEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? onboardingCompleted,
    String? profileName,
    int? profileBirthYear,
    bool? profileTryingToConceive,
    bool? pregnancyMode,
    bool? breastfeedingMode,
    bool? menopauseMode,
  }) {
    return Settings(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      primaryColor: primaryColor ?? this.primaryColor,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      dateFormat: dateFormat ?? this.dateFormat,
      language: language ?? this.language,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      pinHash: pinHash ?? this.pinHash,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPrivacyModeEnabled: isPrivacyModeEnabled ?? this.isPrivacyModeEnabled,
      hideNotificationContent: hideNotificationContent ?? this.hideNotificationContent,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileName: profileName ?? this.profileName,
      profileBirthYear: profileBirthYear ?? this.profileBirthYear,
      profileTryingToConceive: profileTryingToConceive ?? this.profileTryingToConceive,
      pregnancyMode: pregnancyMode ?? this.pregnancyMode,
      breastfeedingMode: breastfeedingMode ?? this.breastfeedingMode,
      menopauseMode: menopauseMode ?? this.menopauseMode,
    );
  }
}
