package com.cyclecare.app.domain.model

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
    val pin: String = "",
    val isBiometricEnabled: Boolean = false,
    val isPrivacyModeEnabled: Boolean = false,
    val notificationsEnabled: Boolean = true,
    val pregnancyMode: Boolean = false,
    val breastfeedingMode: Boolean = false,
    val menopauseMode: Boolean = false
)

enum class ThemeMode {
    LIGHT, DARK, SYSTEM
}

enum class TemperatureUnit {
    CELSIUS, FAHRENHEIT
}
