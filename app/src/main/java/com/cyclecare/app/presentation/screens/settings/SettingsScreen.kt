package com.cyclecare.app.presentation.screens.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ReminderType
import com.cyclecare.app.domain.model.ThemeMode
import java.time.LocalTime

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val reminders by viewModel.reminders.collectAsStateWithLifecycle()

    var showPinDialog by remember { mutableStateOf(false) }
    var showExportDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var statusMessage by remember { mutableStateOf("") }
    var reminderTimeText by remember(settings.defaultReminderTime) { mutableStateOf(settings.defaultReminderTime.toString()) }
    var quietStartText by remember(settings.quietHoursStart) { mutableStateOf(settings.quietHoursStart.toString()) }
    var quietEndText by remember(settings.quietHoursEnd) { mutableStateOf(settings.quietHoursEnd.toString()) }

    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                SettingCard("Appearance") {
                    ThemeMode.values().forEach { mode ->
                        RowSetting(
                            title = mode.name.lowercase().replaceFirstChar { it.uppercase() },
                            trailing = {
                                Switch(
                                    checked = settings.theme == mode,
                                    onCheckedChange = { checked -> if (checked) viewModel.updateTheme(mode) }
                                )
                            }
                        )
                    }
                }
            }

            item {
                SettingCard("Cycle defaults") {
                    RowSetting("Cycle length: ${settings.averageCycleLength} days") {
                        Button(onClick = { viewModel.updateCycleLength(settings.averageCycleLength + 1) }) { Text("+") }
                    }
                    RowSetting("Period length: ${settings.averagePeriodLength} days") {
                        Button(onClick = { viewModel.updatePeriodLength(settings.averagePeriodLength + 1) }) { Text("+") }
                    }
                }
            }

            item {
                SettingCard("Reminders") {
                    RowSetting("Enable reminders") {
                        Switch(
                            checked = settings.notificationsEnabled,
                            onCheckedChange = { viewModel.toggleNotifications(it) }
                        )
                    }
                    RowSetting("Hide notification content") {
                        Switch(
                            checked = settings.hideNotificationContent,
                            onCheckedChange = { viewModel.toggleHiddenNotificationContent(it) }
                        )
                    }
                    RowSetting("Quiet hours") {
                        Switch(
                            checked = settings.quietHoursEnabled,
                            onCheckedChange = {
                                viewModel.updateQuietHours(
                                    enabled = it,
                                    start = settings.quietHoursStart,
                                    end = settings.quietHoursEnd
                                )
                            }
                        )
                    }
                    OutlinedTextField(
                        value = reminderTimeText,
                        onValueChange = { reminderTimeText = it },
                        label = { Text("Reminder time (HH:mm)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = quietStartText,
                        onValueChange = { quietStartText = it },
                        label = { Text("Quiet start (HH:mm)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = quietEndText,
                        onValueChange = { quietEndText = it },
                        label = { Text("Quiet end (HH:mm)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Button(onClick = {
                        val reminderTime = runCatching { LocalTime.parse(reminderTimeText) }.getOrNull()
                        val quietStart = runCatching { LocalTime.parse(quietStartText) }.getOrNull()
                        val quietEnd = runCatching { LocalTime.parse(quietEndText) }.getOrNull()
                        if (reminderTime != null) viewModel.updateDefaultReminderTime(reminderTime)
                        if (quietStart != null && quietEnd != null) {
                            viewModel.updateQuietHours(
                                enabled = settings.quietHoursEnabled,
                                start = quietStart,
                                end = quietEnd
                            )
                        }
                    }) {
                        Text("Apply reminder times")
                    }
                    Text("Configured reminders: ${reminders.size}")
                    Button(
                        onClick = {
                            viewModel.createReminder(
                                Reminder(
                                    type = ReminderType.HYDRATION,
                                    time = settings.hydrationReminderTime,
                                    title = "Hydration",
                                    message = "Log your water intake"
                                )
                            )
                        }
                    ) {
                        Text("Add hydration reminder")
                    }
                }
            }

            item {
                SettingCard("Privacy & Security") {
                    RowSetting("PIN lock") {
                        Switch(
                            checked = settings.isPinEnabled,
                            onCheckedChange = {
                                viewModel.togglePinLock(it)
                                if (it) showPinDialog = true
                            }
                        )
                    }
                    RowSetting("Biometric unlock") {
                        Switch(
                            checked = settings.isBiometricEnabled,
                            onCheckedChange = { viewModel.toggleBiometric(it) }
                        )
                    }
                    Button(onClick = { showExportDialog = true }) { Text("Export data") }
                    Button(onClick = { showDeleteDialog = true }) { Text("Delete all data") }
                    if (statusMessage.isNotBlank()) {
                        Text(statusMessage, color = MaterialTheme.colorScheme.primary)
                    }
                }
            }

            item {
                SettingCard("About") {
                    Text("CycleCare")
                    Text("Local-first. Private by default.")
                }
            }
            item { Spacer(modifier = Modifier.height(64.dp)) }
        }
    }

    if (showPinDialog) {
        var pin by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showPinDialog = false },
            title = { Text("Set PIN") },
            text = {
                OutlinedTextField(
                    value = pin,
                    onValueChange = { pin = it.take(6) },
                    label = { Text("PIN") }
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (pin.length >= 4) {
                        viewModel.setPin(pin)
                        showPinDialog = false
                    }
                }) {
                    Text("Save")
                }
            },
            dismissButton = { TextButton(onClick = { showPinDialog = false }) { Text("Cancel") } }
        )
    }

    if (showExportDialog) {
        AlertDialog(
            onDismissRequest = { showExportDialog = false },
            title = { Text("Export data") },
            text = { Text("Choose export format") },
            confirmButton = {
                Row {
                    TextButton(onClick = {
                        viewModel.exportDataAsCsv { statusMessage = "CSV exported: $it" }
                        showExportDialog = false
                    }) { Text("CSV") }
                    TextButton(onClick = {
                        viewModel.createBackup { statusMessage = "Backup saved: $it" }
                        showExportDialog = false
                    }) { Text("Backup") }
                }
            },
            dismissButton = {
                TextButton(onClick = { showExportDialog = false }) { Text("Cancel") }
            }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete all data?") },
            text = { Text("This permanently removes all local records.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteAllData {
                        statusMessage = "All data deleted"
                    }
                    showDeleteDialog = false
                }) { Text("Delete") }
            },
            dismissButton = { TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun SettingCard(title: String, content: @Composable Column.() -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            content = {
                Text(title, fontWeight = FontWeight.Bold)
                content()
            }
        )
    }
}

@Composable
private fun RowSetting(
    title: String,
    trailing: @Composable () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(title)
        trailing()
    }
}
