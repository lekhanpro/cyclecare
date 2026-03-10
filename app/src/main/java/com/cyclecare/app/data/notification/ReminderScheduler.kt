package com.cyclecare.app.data.notification

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.cyclecare.app.domain.engine.ReminderScheduleEngine
import com.cyclecare.app.domain.model.PredictionResult
import com.cyclecare.app.domain.model.Reminder
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val reminderScheduleEngine: ReminderScheduleEngine
) {
    private val workManager = WorkManager.getInstance(context)

    fun scheduleReminder(
        reminder: Reminder,
        prediction: PredictionResult?,
        hideContent: Boolean,
        now: ZonedDateTime = ZonedDateTime.now()
    ) {
        val triggerTime = reminderScheduleEngine.nextTrigger(
            reminder = reminder,
            prediction = prediction,
            now = now
        ) ?: return

        val delay = reminderScheduleEngine.initialDelayMillis(now, triggerTime)
        val workName = uniqueName(reminder)
        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInputData(
                workDataOf(
                    "title" to reminder.title,
                    "message" to reminder.message,
                    "type" to reminder.type.name,
                    "hideContent" to hideContent,
                    "reminderId" to reminder.id
                )
            )
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .build()

        workManager.enqueueUniqueWork(workName, ExistingWorkPolicy.REPLACE, request)
    }

    fun cancelReminder(reminder: Reminder) {
        workManager.cancelUniqueWork(uniqueName(reminder))
    }

    fun cancelAllReminders() {
        workManager.cancelAllWork()
    }

    private fun uniqueName(reminder: Reminder): String {
        return "reminder_${reminder.type.name.lowercase()}_${reminder.id}"
    }
}
