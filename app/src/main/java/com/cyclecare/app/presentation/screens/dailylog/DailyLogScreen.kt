package com.cyclecare.app.presentation.screens.dailylog

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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
import com.cyclecare.app.domain.model.DischargeType
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.IntimacyType
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.model.TestResult

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyLogScreen(
    viewModel: DailyLogViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Daily Log") }) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { viewModel.saveLog() },
                icon = { androidx.compose.material3.Icon(Icons.Default.Check, null) },
                text = { Text("Save") }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item { Spacer(modifier = Modifier.height(4.dp)) }
            item {
                ExpandableSection("Flow") {
                    ChipRow(
                        items = FlowIntensity.values().toList(),
                        selected = uiState.currentLog.flow,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updateFlow(it) }
                    )
                }
            }
            item {
                ExpandableSection("Symptoms") {
                    Symptom.values().chunked(3).forEach { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            row.forEach { symptom ->
                                FilterChip(
                                    selected = uiState.currentLog.symptoms.contains(symptom),
                                    onClick = { viewModel.toggleSymptom(symptom) },
                                    label = { Text(symptom.name.replace("_", " ").lowercase()) }
                                )
                            }
                        }
                    }
                }
            }
            item {
                ExpandableSection("Mood") {
                    ChipRow(
                        items = Mood.values().toList(),
                        selected = uiState.currentLog.mood,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updateMood(it) }
                    )
                }
            }
            item {
                ExpandableSection("Discharge") {
                    ChipRow(
                        items = DischargeType.values().toList(),
                        selected = uiState.currentLog.discharge,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updateDischarge(it) }
                    )
                }
            }
            item {
                ExpandableSection("Body Metrics") {
                    MetricField("Weight (kg)", uiState.currentLog.weightKg?.toString().orEmpty()) {
                        viewModel.updateWeight(it.toFloatOrNull())
                    }
                    MetricField("Temperature", uiState.currentLog.temperature?.toString().orEmpty()) {
                        viewModel.updateTemperature(it.toFloatOrNull())
                    }
                    MetricField("Sleep hours", uiState.currentLog.sleepHours?.toString().orEmpty()) {
                        viewModel.updateSleep(it.toFloatOrNull())
                    }
                    MetricField("Water (ml)", uiState.currentLog.waterMl.toString()) {
                        viewModel.updateWater(it.toIntOrNull() ?: 0)
                    }
                }
            }
            item {
                ExpandableSection("Intimacy & Tests") {
                    ChipRow(
                        items = IntimacyType.values().toList(),
                        selected = uiState.currentLog.intimacy,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updateIntimacy(it) }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Ovulation test", fontWeight = FontWeight.SemiBold)
                    ChipRow(
                        items = TestResult.values().toList(),
                        selected = uiState.currentLog.ovulationTest,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updateOvulationTest(it) }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Pregnancy test", fontWeight = FontWeight.SemiBold)
                    ChipRow(
                        items = TestResult.values().toList(),
                        selected = uiState.currentLog.pregnancyTest,
                        label = { it.name.lowercase() },
                        onSelected = { viewModel.updatePregnancyTest(it) }
                    )
                }
            }
            item {
                ExpandableSection("Notes") {
                    OutlinedTextField(
                        value = uiState.currentLog.notes,
                        onValueChange = { viewModel.updateNotes(it) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp),
                        placeholder = { Text("Write anything important for today") }
                    )
                }
            }
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
}

@Composable
private fun ExpandableSection(
    title: String,
    content: @Composable () -> Unit
) {
    var expanded by remember { mutableStateOf(true) }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            AssistChip(
                onClick = { expanded = !expanded },
                label = { Text(if (expanded) "Hide $title" else "Show $title") }
            )
            if (expanded) {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                content()
            }
        }
    }
}

@Composable
private fun MetricField(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
private fun <T> ChipRow(
    items: List<T>,
    selected: T?,
    label: (T) -> String,
    onSelected: (T) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { item ->
                    FilterChip(
                        selected = selected == item,
                        onClick = { onSelected(item) },
                        label = { Text(label(item)) }
                    )
                }
            }
        }
    }
}
