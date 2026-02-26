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
    val pin: String = "",
    val isBiometricEnabled: Boolean = false,
    val isPrivacyModeEnabled: Boolean = false,
    val notificationsEnabled: Boolean = true,
    val pregnancyMode: Boolean = false,
    val breastfeedingMode: Boolean = false,
    val menopauseMode: Boolean = false
)
