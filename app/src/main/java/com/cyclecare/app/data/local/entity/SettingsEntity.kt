package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "settings")
data class SettingsEntity(
    @PrimaryKey
    val id: Int = 1,
    val theme: String = "SYSTEM",
    val primaryColor: String = "#E91E63",
    val averageCycleLength: Int = 28,
    val averagePeriodLength: Int = 5,
    val lutealPhaseLength: Int = 14,
    val temperatureUnit: String = "CELSIUS",
    val dateFormat: String = "MMM dd, yyyy",
    val language: String = "en",
    val isPinEnabled: Boolean = false,
    val pinHash: String = "",
    val isBiometricEnabled: Boolean = false,
    val isPrivacyModeEnabled: Boolean = false,
    val hideNotificationContent: Boolean = true,
    val notificationsEnabled: Boolean = true,
    val quietHoursEnabled: Boolean = false,
    val quietHoursStart: String = "22:00",
    val quietHoursEnd: String = "07:00",
    val defaultReminderTime: String = "20:00",
    val medicationReminderTime: String = "09:00",
    val hydrationReminderTime: String = "12:00",
    val bodyMetricsReminderTime: String = "07:30",
    val onboardingCompleted: Boolean = false,
    val profileName: String = "",
    val profileBirthYear: Int? = null,
    val profileTryingToConceive: Boolean = false,
    val profileTimezoneId: String = "",
    val pregnancyMode: Boolean = false,
    val breastfeedingMode: Boolean = false,
    val menopauseMode: Boolean = false
)
