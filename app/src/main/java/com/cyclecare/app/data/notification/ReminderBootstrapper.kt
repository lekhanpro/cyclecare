package com.cyclecare.app.data.notification

import com.cyclecare.app.domain.repository.PeriodRepository
import com.cyclecare.app.domain.repository.ReminderRepository
import com.cyclecare.app.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReminderBootstrapper @Inject constructor(
    private val reminderRepository: ReminderRepository,
    private val periodRepository: PeriodRepository,
    private val settingsRepository: SettingsRepository,
    private val reminderScheduler: ReminderScheduler
) {
    suspend fun synchronizeEnabledReminders() {
        val settings = settingsRepository.getSettings().first()
        if (!settings.notificationsEnabled) {
            reminderScheduler.cancelAllReminders()
            return
        }

        val reminders = reminderRepository.getEnabledReminders().first()
        val prediction = periodRepository.predict()
        reminders.forEach { reminder ->
            reminderScheduler.scheduleReminder(
                reminder = reminder,
                prediction = prediction,
                hideContent = settings.hideNotificationContent
            )
        }
    }
}
