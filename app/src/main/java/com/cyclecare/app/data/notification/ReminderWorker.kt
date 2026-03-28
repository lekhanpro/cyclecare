package com.cyclecare.app.data.notification

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class ReminderWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val title = inputData.getString("title") ?: "CycleCare Reminder"
        val message = inputData.getString("message") ?: "Time to log your data"
        val type = inputData.getString("type") ?: "general"
        val hideContent = inputData.getBoolean("hideContent", false)
        val reminderId = inputData.getLong("reminderId", -1L)

        val channelId = NotificationHelper.getChannelForReminderType(type)
        val notificationId = if (reminderId > 0) reminderId.toInt() else type.hashCode()
        
        // Add action buttons for pill reminders
        val actions = if (type.uppercase() == "PILL" || type.uppercase() == "BIRTH_CONTROL") {
            listOf(
                NotificationAction(
                    action = NotificationActionReceiver.ACTION_MARK_TAKEN,
                    title = "Mark Taken",
                    requestCode = notificationId * 10 + 1
                ),
                NotificationAction(
                    action = NotificationActionReceiver.ACTION_SNOOZE,
                    title = "Snooze",
                    requestCode = notificationId * 10 + 2
                )
            )
        } else {
            emptyList()
        }
        
        NotificationHelper.showNotification(
            context = applicationContext,
            id = notificationId,
            channelId = channelId,
            title = title,
            message = message,
            hideContent = hideContent,
            actions = actions
        )
        
        return Result.success()
    }
}
