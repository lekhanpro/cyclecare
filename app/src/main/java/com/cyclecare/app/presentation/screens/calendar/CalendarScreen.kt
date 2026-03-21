package com.cyclecare.app.presentation.screens.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Period
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var selectedMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("CycleCare") })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { selectedDate = LocalDate.now() }) {
                Icon(Icons.Default.Add, contentDescription = "Add Period")
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item { Spacer(modifier = Modifier.height(4.dp)) }
            item {
                DashboardCard(
                    cycleDay = uiState.cycleDay,
                    countdown = uiState.countdownToPeriod,
                    fertilityStatus = uiState.fertilityStatus
                )
            }
            item {
                QuickLogCard(
                    onQuickLog = { flow, mood ->
                        viewModel.quickLog(flow, mood)
                    }
                )
            }
            item {
                MonthHeader(
                    month = selectedMonth,
                    onPrev = { selectedMonth = selectedMonth.minusMonths(1) },
                    onNext = { selectedMonth = selectedMonth.plusMonths(1) }
                )
            }
            item {
                CalendarGrid(
                    month = selectedMonth,
                    periods = uiState.periods,
                    prediction = uiState.prediction,
                    onDateClick = { selectedDate = it }
                )
            }
            uiState.prediction?.let { prediction ->
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("Prediction", fontWeight = FontWeight.Bold)
                            Text("Next period: ${prediction.nextPeriodStart} - ${prediction.nextPeriodEnd}")
                            Text("Ovulation: ${prediction.nextOvulation}")
                            Text("Fertile window: ${prediction.nextFertileWindowStart} to ${prediction.nextFertileWindowEnd}")
                            Text("Confidence: ${(prediction.confidence * 100).toInt()}%")
                        }
                    }
                }
            }
            item {
                Text(
                    "Recent periods",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            items(uiState.periods.take(8)) { period ->
                PeriodItem(period)
            }
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }

    if (selectedDate != null) {
        AddPeriodDialog(
            startDate = selectedDate!!,
            onDismiss = { selectedDate = null },
            onSave = { start, end ->
                viewModel.addPeriod(start, end)
                selectedDate = null
            }
        )
    }

    if (uiState.showOnboarding) {
        OnboardingDialog(
            onDismiss = { viewModel.dismissOnboarding() },
            onComplete = { name, cycleLength, periodLength, trying ->
                viewModel.completeOnboarding(name, cycleLength, periodLength, trying)
            }
        )
    }
}

@Composable
private fun DashboardCard(cycleDay: Int?, countdown: Int?, fertilityStatus: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Today", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleLarge)
            Text("Cycle day: ${cycleDay ?: "--"}")
            Text("Countdown: ${countdown?.let { "$it days" } ?: "Not available"}")
            Text("Fertility: $fertilityStatus")
        }
    }
}

@Composable
private fun QuickLogCard(onQuickLog: (FlowIntensity?, Mood?) -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Quick log (under 5 seconds)", fontWeight = FontWeight.Bold)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = { onQuickLog(FlowIntensity.LIGHT, null) }) {
                    Icon(Icons.Default.WaterDrop, contentDescription = null)
                    Text(" Light")
                }
                Button(onClick = { onQuickLog(FlowIntensity.HEAVY, null) }) {
                    Icon(Icons.Default.WaterDrop, contentDescription = null)
                    Text(" Heavy")
                }
                Button(onClick = { onQuickLog(null, Mood.HAPPY) }) {
                    Icon(Icons.Default.Favorite, contentDescription = null)
                    Text(" Happy")
                }
            }
        }
    }
}

@Composable
private fun MonthHeader(month: YearMonth, onPrev: () -> Unit, onNext: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextButton(onClick = onPrev) { Text("Prev") }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.CalendarMonth, contentDescription = null)
            Text(month.format(DateTimeFormatter.ofPattern("MMMM yyyy")))
        }
        TextButton(onClick = onNext) { Text("Next") }
    }
}

@Composable
private fun CalendarGrid(
    month: YearMonth,
    periods: List<Period>,
    prediction: com.cyclecare.app.domain.model.CyclePrediction?,
    onDateClick: (LocalDate) -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(modifier = Modifier.fillMaxWidth()) {
                listOf("S", "M", "T", "W", "T", "F", "S").forEach {
                    Text(
                        text = it,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            val first = month.atDay(1)
            val startOffset = first.dayOfWeek.value % 7
            val daysInMonth = month.lengthOfMonth()
            val weeks = (startOffset + daysInMonth + 6) / 7

            repeat(weeks) { week ->
                Row(modifier = Modifier.fillMaxWidth()) {
                    repeat(7) { dayOfWeek ->
                        val day = week * 7 + dayOfWeek - startOffset + 1
                        if (day in 1..daysInMonth) {
                            val date = month.atDay(day)
                            val isPeriod = periods.any { p -> date >= p.startDate && date <= (p.endDate ?: p.startDate) }
                            val isFertile = prediction?.let { date >= it.nextFertileWindowStart && date <= it.nextFertileWindowEnd } == true
                            val color = when {
                                isPeriod -> Color(0xFFFFD9E4)   // Soft rose
                                isFertile -> Color(0xFFCCF2EC)  // Soft mint
                                else -> Color.Transparent
                            }
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(2.dp)
                                    .background(color, RoundedCornerShape(8.dp))
                                    .clickable { onDateClick(date) }
                                    .padding(vertical = 10.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(day.toString())
                            }
                        } else {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PeriodItem(period: Period) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text("${period.startDate} - ${period.endDate ?: period.startDate}")
            Text("Flow: ${period.flow.name.lowercase()}")
            if (period.notes.isNotBlank()) {
                Text(period.notes, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun AddPeriodDialog(
    startDate: LocalDate,
    onDismiss: () -> Unit,
    onSave: (LocalDate, LocalDate?) -> Unit
) {
    var endDateInput by remember { mutableStateOf(startDate.toString()) }
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Log period") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Start date: $startDate")
                OutlinedTextField(
                    value = endDateInput,
                    onValueChange = { endDateInput = it },
                    label = { Text("End date (YYYY-MM-DD)") }
                )
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val endDate = runCatching { LocalDate.parse(endDateInput) }.getOrNull()
                onSave(startDate, endDate)
            }) {
                Text("Save")
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}

@Composable
private fun OnboardingDialog(
    onDismiss: () -> Unit,
    onComplete: (String, Int, Int, Boolean) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var cycleLength by remember { mutableStateOf("28") }
    var periodLength by remember { mutableStateOf("5") }
    var tryingToConceive by remember { mutableStateOf(false) }

    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Welcome to CycleCare") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Just a few essentials to personalize your predictions.")
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name (optional)") })
                OutlinedTextField(value = cycleLength, onValueChange = { cycleLength = it }, label = { Text("Cycle length") })
                OutlinedTextField(value = periodLength, onValueChange = { periodLength = it }, label = { Text("Period length") })
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.material3.Checkbox(
                        checked = tryingToConceive,
                        onCheckedChange = { tryingToConceive = it }
                    )
                    Text("Trying to conceive")
                }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                onComplete(
                    name,
                    cycleLength.toIntOrNull() ?: 28,
                    periodLength.toIntOrNull() ?: 5,
                    tryingToConceive
                )
            }) { Text("Continue") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Later") } }
    )
}
