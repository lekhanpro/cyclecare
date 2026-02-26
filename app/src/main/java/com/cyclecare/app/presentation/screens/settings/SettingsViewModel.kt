package com.cyclecare.app.presentation.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.AppSettings
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ThemeMode
import com.cyclecare.app.domain.repository.SettingsRepository
import com.cyclecare.app.domain.repository.ReminderRepository
import com.cyclecare.app.data.export.DataExporter
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val reminderRepository: ReminderRepository,
    private val dataExporter: DataExporter
) : ViewModel() {

    val settings = settingsRepository.getSettings()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = AppSettings()
        )

    val reminders = reminderRepository.getAllReminders()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun updateTheme(theme: ThemeMode) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(theme = theme)
            )
        }
    }

    fun updateCycleLength(length: Int) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(averageCycleLength = length)
            )
        }
    }

    fun updatePeriodLength(length: Int) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(averagePeriodLength = length)
            )
        }
    }

    fun toggleNotifications(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(notificationsEnabled = enabled)
            )
        }
    }

    fun togglePinLock(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(isPinEnabled = enabled)
            )
        }
    }

    fun setPin(pin: String) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(pin = pin, isPinEnabled = true)
            )
        }
    }

    fun toggleBiometric(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(isBiometricEnabled = enabled)
            )
        }
    }

    fun togglePregnancyMode(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.updateSettings(
                settings.value.copy(pregnancyMode = enabled)
            )
        }
    }

    fun exportDataAsCsv(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            val result = dataExporter.exportToCsv()
            onComplete(result)
        }
    }

    fun exportDataAsPdf(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            val result = dataExporter.exportToPdf()
            onComplete(result)
        }
    }

    fun createBackup(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            val result = dataExporter.createBackup()
            onComplete(result)
        }
    }

    fun updateReminder(reminder: Reminder) {
        viewModelScope.launch {
            reminderRepository.updateReminder(reminder)
        }
    }

    fun deleteReminder(reminder: Reminder) {
        viewModelScope.launch {
            reminderRepository.deleteReminder(reminder)
        }
    }
}
