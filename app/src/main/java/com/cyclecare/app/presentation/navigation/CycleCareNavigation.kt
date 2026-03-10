package com.cyclecare.app.presentation.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.cyclecare.app.presentation.screens.calendar.CalendarScreen
import com.cyclecare.app.presentation.screens.dailylog.DailyLogScreen
import com.cyclecare.app.presentation.screens.insights.InsightsScreen
import com.cyclecare.app.presentation.screens.settings.SettingsScreen

sealed class Screen(val route: String, val title: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    object Calendar : Screen("calendar", "Calendar", Icons.Default.CalendarToday)
    object DailyLog : Screen("daily_log", "Log", Icons.Default.Edit)
    object Insights : Screen("insights", "Insights", Icons.Default.Insights)
    object Settings : Screen("settings", "Settings", Icons.Default.Settings)
}

@Composable
fun CycleCareNavigation() {
    val lockViewModel: AppLockViewModel = hiltViewModel()
    val lockState by lockViewModel.uiState.collectAsState()

    if (lockState.isPinEnabled && !lockState.isUnlocked) {
        AppLockScreen(
            isBiometricEnabled = lockState.isBiometricEnabled,
            error = lockState.error,
            onUnlockWithPin = lockViewModel::unlockWithPin,
            onBiometricUnlock = lockViewModel::unlockWithBiometricFallback
        )
        return
    }

    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val items = listOf(
        Screen.Calendar,
        Screen.DailyLog,
        Screen.Insights,
        Screen.Settings
    )

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 8.dp
            ) {
                items.forEach { screen ->
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = MaterialTheme.colorScheme.primary,
                            selectedTextColor = MaterialTheme.colorScheme.primary,
                            indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                            unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    )
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Calendar.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            composable(Screen.Calendar.route) { CalendarScreen() }
            composable(Screen.DailyLog.route) { DailyLogScreen() }
            composable(Screen.Insights.route) { InsightsScreen() }
            composable(Screen.Settings.route) { SettingsScreen() }
        }
    }
}

@Composable
private fun AppLockScreen(
    isBiometricEnabled: Boolean,
    error: String?,
    onUnlockWithPin: (String) -> Unit,
    onBiometricUnlock: () -> Unit
) {
    var pin by remember { mutableStateOf("") }

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
        Card(modifier = Modifier.padding(24.dp)) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text("CycleCare is locked", style = MaterialTheme.typography.titleMedium)
                OutlinedTextField(
                    value = pin,
                    onValueChange = { pin = it.take(6) },
                    label = { Text("Enter PIN") },
                    visualTransformation = PasswordVisualTransformation()
                )
                Button(onClick = { onUnlockWithPin(pin) }, modifier = Modifier.fillMaxWidth()) {
                    Text("Unlock")
                }
                if (isBiometricEnabled) {
                    OutlinedButton(onClick = onBiometricUnlock, modifier = Modifier.fillMaxWidth()) {
                        Text("Unlock with biometric")
                    }
                }
                error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        }
    }
}
