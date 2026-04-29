package com.cyclecare.app.data.notification

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@AndroidEntryPoint
class NotificationActionReceiver : BroadcastReceiver() {
    
    @Inject
    lateinit var birthControlRepository: com.cyclecare.app.domain.repository.BirthControlRepository
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra("notification_id", -1)
        val actionType = intent.getStringExtra("action_type")
        
        when (actionType) {
            ACTION_MARK_TAKEN -> {
                scope.launch {
                    try {
                        birthControlRepository.markPillTaken(LocalDate.now().toString())
                        Toast.makeText(context, "Pill marked as taken", Toast.LENGTH_SHORT).show()
                        dismissNotification(context, notificationId)
                    } catch (e: Exception) {
                        Toast.makeText(context, "Failed to mark pill", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            ACTION_SNOOZE -> {
                // Snooze for 30 minutes
                Toast.makeText(context, "Snoozed for 30 minutes", Toast.LENGTH_SHORT).show()
                dismissNotification(context, notificationId)
                // TODO: Reschedule notification for 30 minutes later
            }
            ACTION_DISMISS -> {
                dismissNotification(context, notificationId)
            }
        }
    }
    
    private fun dismissNotification(context: Context, notificationId: Int) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
    }
    
    companion object {
        const val ACTION_MARK_TAKEN = "com.cyclecare.app.ACTION_MARK_TAKEN"
        const val ACTION_SNOOZE = "com.cyclecare.app.ACTION_SNOOZE"
        const val ACTION_DISMISS = "com.cyclecare.app.ACTION_DISMISS"
    }
}
