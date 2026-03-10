package com.cyclecare.app.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.lifecycleScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import com.cyclecare.app.data.notification.ReminderBootstrapper
import com.cyclecare.app.presentation.navigation.CycleCareNavigation
import com.cyclecare.app.presentation.theme.CycleCareTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var reminderBootstrapper: ReminderBootstrapper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        WindowCompat.setDecorFitsSystemWindows(window, false)

        lifecycleScope.launch {
            reminderBootstrapper.synchronizeEnabledReminders()
        }
        
        setContent {
            CycleCareTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    CycleCareNavigation()
                }
            }
        }
    }
}
