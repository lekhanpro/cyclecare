package com.cyclecare.app.data.notification

import android.content.Context
import androidx.work.*
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ReminderType
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.Duration
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val workManager = WorkManager.getInstance(context)

    fun schedulePeriodReminder(daysBeforePeriod: Int, time: LocalTime) {
        val data = workDataOf(
            "title" to "Period Coming Soon",
            "message" to "Your period is expected in $daysBeforePeriod days",
            "type" to "period"
        )

        val delay = calculateDelay(time)
        
        val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("period_reminder")
            .build()

        workManager.enqueueUniquePeriodicWork(
            "period_reminder",
            ExistingPeriodicWorkPolicy.REPLACE,
            request
        )
    }

    fun scheduleOvulationReminder(time: LocalTime) {
        val data = workDataOf(
            "title" to "Ovulation Window",
            "message" to "You're in your fertile window",
            "type" to "ovulation"
        )

        val delay = calculateDelay(time)
        
        val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("ovulation_reminder")
            .build()

        workManager.enqueueUniquePeriodicWork(
            "ovulation_reminder",
            ExistingPeriodicWorkPolicy.REPLACE,
            request
        )
    }

    fun scheduleDailyLogReminder(time: LocalTime) {
        val data = workDataOf(
            "title" to "Daily Log",
            "message" to "Don't forget to log your day!",
            "type" to "daily_log"
        )

        val delay = calculateDelay(time)
        
        val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("daily_log_reminder")
            .build()

        workManager.enqueueUniquePeriodicWork(
            "daily_log_reminder",
            ExistingPeriodicWorkPolicy.REPLACE,
            request
        )
    }

    fun schedulePillReminder(time: LocalTime) {
        val data = workDataOf(
            "title" to "Pill Reminder",
            "message" to "Time to take your pill",
            "type" to "pill"
        )

        val delay = calculateDelay(time)
        
        val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("pill_reminder")
            .build()

        workManager.enqueueUniquePeriodicWork(
            "pill_reminder",
            ExistingPeriodicWorkPolicy.REPLACE,
            request
        )
    }

    fun scheduleCustomReminder(reminder: Reminder) {
        val data = workDataOf(
            "title" to reminder.title,
            "message" to reminder.message,
            "type" to "custom_${reminder.id}"
        )

        val delay = calculateDelay(reminder.time)
        
        val request = PeriodicWorkRequestBuilder<ReminderWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("custom_reminder_${reminder.id}")
            .build()

        workManager.enqueueUniquePeriodicWork(
            "custom_reminder_${reminder.id}",
            ExistingPeriodicWorkPolicy.REPLACE,
            request
        )
    }

    fun cancelReminder(type: ReminderType, id: Long? = null) {
        val tag = when (type) {
            ReminderType.PERIOD -> "period_reminder"
            ReminderType.OVULATION -> "ovulation_reminder"
            ReminderType.DAILY_LOG -> "daily_log_reminder"
            ReminderType.PILL -> "pill_reminder"
            ReminderType.CUSTOM -> "custom_reminder_$id"
            else -> return
        }
        workManager.cancelAllWorkByTag(tag)
    }

    fun cancelAllReminders() {
        workManager.cancelAllWork()
    }

    private fun calculateDelay(time: LocalTime): Long {
        val now = LocalDateTime.now()
        var scheduledTime = now.with(time)
        
        if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.plusDays(1)
        }
        
        return Duration.between(now, scheduledTime).toMillis()
    }
}
