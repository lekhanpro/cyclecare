package com.cyclecare.app.data.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.cyclecare.app.R
import com.cyclecare.app.presentation.MainActivity

object NotificationHelper {
    
    const val CHANNEL_PERIOD = "period_reminders"
    const val CHANNEL_PILL = "pill_reminders"
    const val CHANNEL_HEALTH = "health_reminders"
    const val CHANNEL_APPOINTMENTS = "appointment_reminders"
    const val CHANNEL_GENERAL = "general_reminders"
    
    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            val channels = listOf(
                NotificationChannel(
                    CHANNEL_PERIOD,
                    "Period Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications about upcoming periods and cycle tracking"
                },
                NotificationChannel(
                    CHANNEL_PILL,
                    "Birth Control Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Daily reminders to take birth control pills"
                },
                NotificationChannel(
                    CHANNEL_HEALTH,
                    "Health Reminders",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Reminders for logging health data, hydration, and exercise"
                },
                NotificationChannel(
                    CHANNEL_APPOINTMENTS,
                    "Appointment Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Reminders for medical appointments"
                },
                NotificationChannel(
                    CHANNEL_GENERAL,
                    "General Reminders",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Other CycleCare reminders"
                }
            )
            
            channels.forEach { notificationManager.createNotificationChannel(it) }
        }
    }
    
    fun showNotification(
        context: Context,
        id: Int,
        channelId: String,
        title: String,
        message: String,
        hideContent: Boolean = false,
        actions: List<NotificationAction> = emptyList()
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(if (hideContent) "Open CycleCare for details" else message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
        
        // Add action buttons
        actions.forEach { action ->
            val actionIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                this.action = action.action
                putExtra("notification_id", id)
                putExtra("action_type", action.action)
            }
            val actionPendingIntent = PendingIntent.getBroadcast(
                context,
                action.requestCode,
                actionIntent,
                PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, action.title, actionPendingIntent)
        }
        
        notificationManager.notify(id, builder.build())
    }
    
    fun getChannelForReminderType(type: String): String {
        return when (type.uppercase()) {
            "PERIOD" -> CHANNEL_PERIOD
            "PILL", "BIRTH_CONTROL" -> CHANNEL_PILL
            "HEALTH", "HYDRATION", "EXERCISE" -> CHANNEL_HEALTH
            "APPOINTMENT" -> CHANNEL_APPOINTMENTS
            else -> CHANNEL_GENERAL
        }
    }
}

data class NotificationAction(
    val action: String,
    val title: String,
    val requestCode: Int
)
