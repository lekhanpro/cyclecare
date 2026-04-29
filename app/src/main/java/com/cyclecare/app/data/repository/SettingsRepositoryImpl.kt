package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.SettingsDao
import com.cyclecare.app.data.local.entity.SettingsEntity
import com.cyclecare.app.domain.model.AppSettings
import com.cyclecare.app.domain.model.TemperatureUnit
import com.cyclecare.app.domain.model.ThemeMode
import com.cyclecare.app.domain.model.UserProfile
import com.cyclecare.app.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalTime
import java.time.ZoneId
import javax.inject.Inject

class SettingsRepositoryImpl @Inject constructor(
    private val settingsDao: SettingsDao
) : SettingsRepository {

    override fun getSettings(): Flow<AppSettings> {
        return settingsDao.getSettings().map { entity -> entity?.toDomain() ?: AppSettings() }
    }

    override suspend fun updateSettings(settings: AppSettings) {
        settingsDao.insertSettings(settings.toEntity())
    }

    private fun SettingsEntity.toDomain(): AppSettings {
        val fallbackZone = runCatching { ZoneId.systemDefault().id }.getOrDefault("UTC")
        return AppSettings(
            theme = runCatching { ThemeMode.valueOf(theme) }.getOrDefault(ThemeMode.SYSTEM),
            primaryColor = primaryColor,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            lutealPhaseLength = lutealPhaseLength,
            temperatureUnit = runCatching { TemperatureUnit.valueOf(temperatureUnit) }.getOrDefault(TemperatureUnit.CELSIUS),
            dateFormat = dateFormat,
            language = language,
            isPinEnabled = isPinEnabled,
            pinHash = pinHash,
            isBiometricEnabled = isBiometricEnabled,
            isPrivacyModeEnabled = isPrivacyModeEnabled,
            hideNotificationContent = hideNotificationContent,
            notificationsEnabled = notificationsEnabled,
            quietHoursEnabled = quietHoursEnabled,
            quietHoursStart = runCatching { LocalTime.parse(quietHoursStart) }.getOrDefault(LocalTime.of(22, 0)),
            quietHoursEnd = runCatching { LocalTime.parse(quietHoursEnd) }.getOrDefault(LocalTime.of(7, 0)),
            defaultReminderTime = runCatching { LocalTime.parse(defaultReminderTime) }.getOrDefault(LocalTime.of(20, 0)),
            medicationReminderTime = runCatching { LocalTime.parse(medicationReminderTime) }.getOrDefault(LocalTime.of(9, 0)),
            hydrationReminderTime = runCatching { LocalTime.parse(hydrationReminderTime) }.getOrDefault(LocalTime.of(12, 0)),
            bodyMetricsReminderTime = runCatching { LocalTime.parse(bodyMetricsReminderTime) }.getOrDefault(LocalTime.of(7, 30)),
            onboardingCompleted = onboardingCompleted,
            pregnancyMode = pregnancyMode,
            breastfeedingMode = breastfeedingMode,
            menopauseMode = menopauseMode,
            userProfile = UserProfile(
                name = profileName,
                birthYear = profileBirthYear,
                cycleLengthHint = averageCycleLength,
                periodLengthHint = averagePeriodLength,
                tryingToConceive = profileTryingToConceive,
                timezoneId = profileTimezoneId.ifBlank { fallbackZone }
            )
        )
    }

    private fun AppSettings.toEntity(): SettingsEntity {
        return SettingsEntity(
            id = 1,
            theme = theme.name,
            primaryColor = primaryColor,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            lutealPhaseLength = lutealPhaseLength,
            temperatureUnit = temperatureUnit.name,
            dateFormat = dateFormat,
            language = language,
            isPinEnabled = isPinEnabled,
            pinHash = pinHash,
            isBiometricEnabled = isBiometricEnabled,
            isPrivacyModeEnabled = isPrivacyModeEnabled,
            hideNotificationContent = hideNotificationContent,
            notificationsEnabled = notificationsEnabled,
            quietHoursEnabled = quietHoursEnabled,
            quietHoursStart = quietHoursStart.toString(),
            quietHoursEnd = quietHoursEnd.toString(),
            defaultReminderTime = defaultReminderTime.toString(),
            medicationReminderTime = medicationReminderTime.toString(),
            hydrationReminderTime = hydrationReminderTime.toString(),
            bodyMetricsReminderTime = bodyMetricsReminderTime.toString(),
            onboardingCompleted = onboardingCompleted,
            profileName = userProfile.name,
            profileBirthYear = userProfile.birthYear,
            profileTryingToConceive = userProfile.tryingToConceive,
            profileTimezoneId = userProfile.timezoneId,
            pregnancyMode = pregnancyMode,
            breastfeedingMode = breastfeedingMode,
            menopauseMode = menopauseMode
        )
    }
}
