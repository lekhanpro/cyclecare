package com.cyclecare.app.presentation.screens.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cyclecare.app.domain.model.ThemeMode

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsState()
    val reminders by viewModel.reminders.collectAsState()
    
    var showThemeDialog by remember { mutableStateOf(false) }
    var showCycleLengthDialog by remember { mutableStateOf(false) }
    var showPeriodLengthDialog by remember { mutableStateOf(false) }
    var showExportDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Settings",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item { Spacer(modifier = Modifier.height(8.dp)) }
            
            // Appearance Section
            item {
                SectionHeader("Appearance")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.Palette,
                    title = "Theme",
                    subtitle = when(settings.theme) {
                        ThemeMode.LIGHT -> "Light"
                        ThemeMode.DARK -> "Dark"
                        ThemeMode.SYSTEM -> "System Default"
                    },
                    onClick = { showThemeDialog = true }
                )
            }
            
            // Cycle Settings Section
            item {
                SectionHeader("Cycle Settings")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.CalendarMonth,
                    title = "Average Cycle Length",
                    subtitle = "${settings.averageCycleLength} days",
                    onClick = { showCycleLengthDialog = true }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.Event,
                    title = "Average Period Length",
                    subtitle = "${settings.averagePeriodLength} days",
                    onClick = { showPeriodLengthDialog = true }
                )
            }
            
            // Notifications Section
            item {
                SectionHeader("Notifications")
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Default.Notifications,
                    title = "Enable Notifications",
                    subtitle = "Get reminders for period and ovulation",
                    checked = settings.notificationsEnabled,
                    onCheckedChange = { viewModel.toggleNotifications(it) }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.NotificationsActive,
                    title = "Manage Reminders",
                    subtitle = "${reminders.size} reminders configured",
                    onClick = { /* TODO: Navigate to reminders */ }
                )
            }
            
            // Privacy & Security Section
            item {
                SectionHeader("Privacy & Security")
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Default.Lock,
                    title = "PIN Lock",
                    subtitle = "Protect your data with a PIN",
                    checked = settings.isPinEnabled,
                    onCheckedChange = { viewModel.togglePinLock(it) }
                )
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Default.Fingerprint,
                    title = "Biometric Authentication",
                    subtitle = "Use fingerprint or face unlock",
                    checked = settings.isBiometricEnabled,
                    onCheckedChange = { viewModel.toggleBiometric(it) }
                )
            }
            
            // Advanced Modes Section
            item {
                SectionHeader("Advanced Modes")
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Default.PregnantWoman,
                    title = "Pregnancy Mode",
                    subtitle = "Track pregnancy instead of cycles",
                    checked = settings.pregnancyMode,
                    onCheckedChange = { viewModel.togglePregnancyMode(it) }
                )
            }
            
            // Privacy Card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Lock,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                "Privacy & Data",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            "Your data is stored locally on your device and never shared with anyone. We don't collect any personal information.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }
            
            // Data Management
            item {
                SectionHeader("Data Management")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.FileDownload,
                    title = "Export Data",
                    subtitle = "Download your data as CSV or PDF",
                    onClick = { showExportDialog = true }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.Backup,
                    title = "Create Backup",
                    subtitle = "Backup all your data",
                    onClick = { 
                        viewModel.createBackup { path ->
                            // TODO: Show success message
                        }
                    }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Default.Delete,
                    title = "Clear All Data",
                    subtitle = "Permanently delete all your data",
                    onClick = { /* TODO: Implement clear */ },
                    isDestructive = true
                )
            }
            
            // About
            item {
                SectionHeader("About")
            }
            
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp)
                    ) {
                        Text(
                            "CycleCare",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "Version 1.0.0",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            "A privacy-first menstrual cycle tracking app designed for your wellbeing.",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
            
            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
    
    // Theme Dialog
    if (showThemeDialog) {
        AlertDialog(
            onDismissRequest = { showThemeDialog = false },
            title = { Text("Choose Theme") },
            text = {
                Column {
                    ThemeMode.values().forEach { mode ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = settings.theme == mode,
                                onClick = {
                                    viewModel.updateTheme(mode)
                                    showThemeDialog = false
                                }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                when(mode) {
                                    ThemeMode.LIGHT -> "Light"
                                    ThemeMode.DARK -> "Dark"
                                    ThemeMode.SYSTEM -> "System Default"
                                }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showThemeDialog = false }) {
                    Text("Close")
                }
            }
        )
    }
    
    // Cycle Length Dialog
    if (showCycleLengthDialog) {
        var tempLength by remember { mutableStateOf(settings.averageCycleLength) }
        AlertDialog(
            onDismissRequest = { showCycleLengthDialog = false },
            title = { Text("Average Cycle Length") },
            text = {
                Column {
                    Text("Select your average cycle length (21-35 days)")
                    Spacer(modifier = Modifier.height(16.dp))
                    Slider(
                        value = tempLength.toFloat(),
                        onValueChange = { tempLength = it.toInt() },
                        valueRange = 21f..35f,
                        steps = 13
                    )
                    Text(
                        "$tempLength days",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updateCycleLength(tempLength)
                    showCycleLengthDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCycleLengthDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Period Length Dialog
    if (showPeriodLengthDialog) {
        var tempLength by remember { mutableStateOf(settings.averagePeriodLength) }
        AlertDialog(
            onDismissRequest = { showPeriodLengthDialog = false },
            title = { Text("Average Period Length") },
            text = {
                Column {
                    Text("Select your average period length (3-7 days)")
                    Spacer(modifier = Modifier.height(16.dp))
                    Slider(
                        value = tempLength.toFloat(),
                        onValueChange = { tempLength = it.toInt() },
                        valueRange = 3f..7f,
                        steps = 3
                    )
                    Text(
                        "$tempLength days",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updatePeriodLength(tempLength)
                    showPeriodLengthDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showPeriodLengthDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Export Dialog
    if (showExportDialog) {
        AlertDialog(
            onDismissRequest = { showExportDialog = false },
            title = { Text("Export Data") },
            text = {
                Column {
                    Text("Choose export format:")
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            viewModel.exportDataAsCsv { path ->
                                // TODO: Show success message
                            }
                            showExportDialog = false
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.TableChart, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Export as CSV")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(
                        onClick = {
                            viewModel.exportDataAsPdf { path ->
                                // TODO: Show success message
                            }
                            showExportDialog = false
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.PictureAsPdf, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Export as PDF")
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showExportDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun SectionHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    isDestructive: Boolean = false
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = if (isDestructive) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.errorContainer
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isDestructive) {
                    MaterialTheme.colorScheme.onErrorContainer
                } else {
                    MaterialTheme.colorScheme.primary
                }
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isDestructive) {
                        MaterialTheme.colorScheme.onErrorContainer
                    } else {
                        MaterialTheme.colorScheme.onSurface
                    }
                )
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isDestructive) {
                        MaterialTheme.colorScheme.onErrorContainer.copy(alpha = 0.7f)
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = if (isDestructive) {
                    MaterialTheme.colorScheme.onErrorContainer
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
            )
        }
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSwitchItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}
