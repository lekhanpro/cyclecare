package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.SettingsDao
import com.cyclecare.app.data.local.entity.SettingsEntity
import com.cyclecare.app.domain.model.AppSettings
import com.cyclecare.app.domain.model.TemperatureUnit
import com.cyclecare.app.domain.model.ThemeMode
import com.cyclecare.app.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class SettingsRepositoryImpl @Inject constructor(
    private val settingsDao: SettingsDao
) : SettingsRepository {
    
    override fun getSettings(): Flow<AppSettings> {
        return settingsDao.getSettings().map { entity ->
            entity?.toDomain() ?: AppSettings()
        }
    }
    
    override suspend fun updateSettings(settings: AppSettings) {
        settingsDao.insertSettings(settings.toEntity())
    }
    
    private fun SettingsEntity.toDomain(): AppSettings {
        return AppSettings(
            theme = ThemeMode.valueOf(theme),
            primaryColor = primaryColor,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            lutealPhaseLength = lutealPhaseLength,
            temperatureUnit = TemperatureUnit.valueOf(temperatureUnit),
            dateFormat = dateFormat,
            language = language,
            isPinEnabled = isPinEnabled,
            pin = pin,
            isBiometricEnabled = isBiometricEnabled,
            isPrivacyModeEnabled = isPrivacyModeEnabled,
            notificationsEnabled = notificationsEnabled,
            pregnancyMode = pregnancyMode,
            breastfeedingMode = breastfeedingMode,
            menopauseMode = menopauseMode
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
            pin = pin,
            isBiometricEnabled = isBiometricEnabled,
            isPrivacyModeEnabled = isPrivacyModeEnabled,
            notificationsEnabled = notificationsEnabled,
            pregnancyMode = pregnancyMode,
            breastfeedingMode = breastfeedingMode,
            menopauseMode = menopauseMode
        )
    }
}
