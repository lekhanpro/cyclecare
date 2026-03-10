package com.cyclecare.app.data.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.cyclecare.app.R
import com.cyclecare.app.presentation.MainActivity

class ReminderWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val title = inputData.getString("title") ?: "CycleCare Reminder"
        val message = inputData.getString("message") ?: "Time to log your data"
        val type = inputData.getString("type") ?: "general"
        val hideContent = inputData.getBoolean("hideContent", false)

        showNotification(title, message, type, hideContent)
        
        return Result.success()
    }

    private fun showNotification(title: String, message: String, type: String, hideContent: Boolean) {
        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CycleCare Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders for period tracking"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Create intent to open app
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(if (hideContent) "Open CycleCare for details" else message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(type.hashCode(), notification)
    }

    companion object {
        const val CHANNEL_ID = "cyclecare_reminders"
    }
}
