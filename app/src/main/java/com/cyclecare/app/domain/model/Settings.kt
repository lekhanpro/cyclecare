package com.cyclecare.app.domain.model

import java.time.LocalTime

data class AppSettings(
    val theme: ThemeMode = ThemeMode.SYSTEM,
    val primaryColor: String = "#E91E63",
    val averageCycleLength: Int = 28,
    val averagePeriodLength: Int = 5,
    val lutealPhaseLength: Int = 14,
    val temperatureUnit: TemperatureUnit = TemperatureUnit.CELSIUS,
    val dateFormat: String = "MMM dd, yyyy",
    val language: String = "en",
    val isPinEnabled: Boolean = false,
    val pinHash: String = "",
    val isBiometricEnabled: Boolean = false,
    val isPrivacyModeEnabled: Boolean = false,
    val hideNotificationContent: Boolean = true,
    val notificationsEnabled: Boolean = true,
    val quietHoursEnabled: Boolean = false,
    val quietHoursStart: LocalTime = LocalTime.of(22, 0),
    val quietHoursEnd: LocalTime = LocalTime.of(7, 0),
    val defaultReminderTime: LocalTime = LocalTime.of(20, 0),
    val medicationReminderTime: LocalTime = LocalTime.of(9, 0),
    val hydrationReminderTime: LocalTime = LocalTime.of(12, 0),
    val bodyMetricsReminderTime: LocalTime = LocalTime.of(7, 30),
    val onboardingCompleted: Boolean = false,
    val pregnancyMode: Boolean = false,
    val breastfeedingMode: Boolean = false,
    val menopauseMode: Boolean = false,
    val userProfile: UserProfile = UserProfile()
)

data class UserProfile(
    val name: String = "",
    val birthYear: Int? = null,
    val cycleLengthHint: Int = 28,
    val periodLengthHint: Int = 5,
    val tryingToConceive: Boolean = false,
    val timezoneId: String = ""
)

data class ReminderSettings(
    val type: ReminderType,
    val enabled: Boolean,
    val time: LocalTime,
    val daysBefore: Int = 0
)

enum class ThemeMode {
    LIGHT, DARK, SYSTEM
}

enum class TemperatureUnit {
    CELSIUS, FAHRENHEIT
}
