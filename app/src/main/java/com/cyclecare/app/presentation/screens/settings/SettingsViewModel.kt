package com.cyclecare.app.presentation.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.data.export.DataExporter
import com.cyclecare.app.data.notification.ReminderScheduler
import com.cyclecare.app.domain.model.AppSettings
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ThemeMode
import com.cyclecare.app.domain.model.UserProfile
import com.cyclecare.app.domain.repository.ReminderRepository
import com.cyclecare.app.domain.repository.PeriodRepository
import com.cyclecare.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.security.MessageDigest
import java.time.LocalTime
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val reminderRepository: ReminderRepository,
    private val dataExporter: DataExporter,
    private val periodRepository: PeriodRepository,
    private val reminderScheduler: ReminderScheduler
) : ViewModel() {

    init {
        viewModelScope.launch {
            seedDefaultRemindersIfNeeded()
        }
    }

    val settings = settingsRepository.getSettings()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = AppSettings()
        )

    val reminders = reminderRepository.getAllReminders()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList()
        )

    fun updateTheme(theme: ThemeMode) = updateSettings { copy(theme = theme) }

    fun updateCycleLength(length: Int) = updateSettings {
        val safeLength = length.coerceIn(21, 40)
        copy(
            averageCycleLength = safeLength,
            userProfile = userProfile.copy(cycleLengthHint = safeLength)
        )
    }

    fun updatePeriodLength(length: Int) = updateSettings {
        val safeLength = length.coerceIn(2, 10)
        copy(
            averagePeriodLength = safeLength,
            userProfile = userProfile.copy(periodLengthHint = safeLength)
        )
    }

    fun updateOnboarding(
        name: String,
        cycleLength: Int,
        periodLength: Int,
        tryingToConceive: Boolean
    ) = updateSettings {
        copy(
            averageCycleLength = cycleLength.coerceIn(21, 40),
            averagePeriodLength = periodLength.coerceIn(2, 10),
            onboardingCompleted = true,
            userProfile = userProfile.copy(
                name = name.trim(),
                cycleLengthHint = cycleLength.coerceIn(21, 40),
                periodLengthHint = periodLength.coerceIn(2, 10),
                tryingToConceive = tryingToConceive
            )
        )
    }

    fun updateUserProfile(profile: UserProfile) = updateSettings {
        copy(userProfile = profile)
    }

    fun toggleNotifications(enabled: Boolean) {
        if (!enabled) {
            reminderScheduler.cancelAllReminders()
        }
        updateSettings {
            copy(notificationsEnabled = enabled)
        }
    }

    fun toggleHiddenNotificationContent(enabled: Boolean) = updateSettings {
        copy(hideNotificationContent = enabled)
    }

    fun togglePinLock(enabled: Boolean) = updateSettings {
        copy(isPinEnabled = enabled)
    }

    fun setPin(pin: String) {
        val pinHash = hashPin(pin)
        updateSettings {
            copy(pinHash = pinHash, isPinEnabled = true)
        }
    }

    fun verifyPin(pin: String): Boolean {
        val currentHash = settings.value.pinHash
        return currentHash.isNotBlank() && currentHash == hashPin(pin)
    }

    fun toggleBiometric(enabled: Boolean) = updateSettings {
        copy(isBiometricEnabled = enabled)
    }

    fun togglePregnancyMode(enabled: Boolean) = updateSettings {
        copy(pregnancyMode = enabled)
    }

    fun updateQuietHours(enabled: Boolean, start: LocalTime, end: LocalTime) = updateSettings {
        copy(
            quietHoursEnabled = enabled,
            quietHoursStart = start,
            quietHoursEnd = end
        )
    }

    fun updateDefaultReminderTime(time: LocalTime) = updateSettings {
        copy(defaultReminderTime = time)
    }

    fun exportDataAsCsv(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            onComplete(dataExporter.exportToCsv())
        }
    }

    fun exportDataAsPdf(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            onComplete(dataExporter.exportToPdf())
        }
    }

    fun createBackup(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            onComplete(dataExporter.createBackup())
        }
    }

    fun deleteAllData(onComplete: () -> Unit) {
        viewModelScope.launch {
            dataExporter.deleteAllData()
            onComplete()
        }
    }

    fun updateReminder(reminder: Reminder) {
        viewModelScope.launch {
            reminderRepository.updateReminder(reminder)
            schedule(reminder)
        }
    }

    fun createReminder(reminder: Reminder) {
        viewModelScope.launch {
            val id = reminderRepository.insertReminder(reminder)
            schedule(reminder.copy(id = id))
        }
    }

    fun deleteReminder(reminder: Reminder) {
        viewModelScope.launch {
            reminderRepository.deleteReminder(reminder)
        }
    }

    private fun updateSettings(update: AppSettings.() -> AppSettings) {
        viewModelScope.launch {
            settingsRepository.updateSettings(settings.value.update())
        }
    }

    private suspend fun schedule(reminder: Reminder) {
        val prediction = periodRepository.predict()
        reminderScheduler.scheduleReminder(
            reminder = reminder,
            prediction = prediction,
            hideContent = settings.value.hideNotificationContent
        )
    }

    private fun hashPin(pin: String): String {
        return MessageDigest.getInstance("SHA-256")
            .digest(pin.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }

    private suspend fun seedDefaultRemindersIfNeeded() {
        val existing = reminderRepository.getAllReminders().first()
        if (existing.isNotEmpty()) return

        val config = settings.value
        val defaults = listOf(
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.PERIOD,
                time = config.defaultReminderTime,
                title = "Upcoming period",
                message = "Your next period is approaching",
                daysBeforePeriod = 2,
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            ),
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.OVULATION,
                time = config.defaultReminderTime,
                title = "Ovulation reminder",
                message = "Ovulation is expected soon",
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            ),
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.FERTILE_WINDOW,
                time = config.defaultReminderTime,
                title = "Fertile window",
                message = "Fertile window is starting",
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            ),
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.MEDICATION,
                time = config.medicationReminderTime,
                title = "Medication",
                message = "Time for your medication",
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            ),
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.HYDRATION,
                time = config.hydrationReminderTime,
                title = "Hydration",
                message = "Log your water intake",
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            ),
            Reminder(
                type = com.cyclecare.app.domain.model.ReminderType.BODY_METRICS,
                time = config.bodyMetricsReminderTime,
                title = "Weight & temperature",
                message = "Log your body metrics",
                quietHoursEnabled = config.quietHoursEnabled,
                quietHoursStart = config.quietHoursStart,
                quietHoursEnd = config.quietHoursEnd
            )
        )

        defaults.forEach { reminder ->
            val id = reminderRepository.insertReminder(reminder)
            schedule(reminder.copy(id = id))
        }
    }
}
