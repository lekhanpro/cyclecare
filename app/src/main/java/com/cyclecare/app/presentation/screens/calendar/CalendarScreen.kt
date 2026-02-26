package com.cyclecare.app.presentation.screens.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import com.cyclecare.app.presentation.theme.FertileGreen
import com.cyclecare.app.presentation.theme.OvulationBlue
import com.cyclecare.app.presentation.theme.PeriodRed
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showAddPeriodDialog by remember { mutableStateOf(false) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(null) }
    var currentMonth by remember { mutableStateOf(YearMonth.now()) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Cycle Calendar",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                actions = {
                    IconButton(onClick = { /* TODO: Settings */ }) {
                        Icon(Icons.Default.Settings, "Settings")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showAddPeriodDialog = true },
                icon = { Icon(Icons.Default.Add, "Add Period") },
                text = { Text("Log Period") },
                containerColor = MaterialTheme.colorScheme.primary
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item { Spacer(modifier = Modifier.height(8.dp)) }
            
            // Month Navigation
            item {
                MonthNavigator(
                    currentMonth = currentMonth,
                    onPreviousMonth = { currentMonth = currentMonth.minusMonths(1) },
                    onNextMonth = { currentMonth = currentMonth.plusMonths(1) },
                    onToday = { currentMonth = YearMonth.now() }
                )
            }
            
            // Calendar Grid
            item {
                CalendarGrid(
                    yearMonth = currentMonth,
                    periods = uiState.periods,
                    prediction = uiState.prediction,
                    onDateClick = { date ->
                        selectedDate = date
                        showAddPeriodDialog = true
                    }
                )
            }
            
            // Prediction Card
            item {
                uiState.prediction?.let { prediction ->
                    PredictionCard(prediction)
                } ?: EmptyStateCard()
            }
            
            // Legend
            item {
                LegendCard()
            }
            
            // Cycle Summary
            item {
                CycleSummaryCard(uiState)
            }
            
            // Recent Periods
            item {
                Text(
                    "Period History",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
            
            items(uiState.periods.take(10)) { period ->
                PeriodCard(period, onEdit = { /* TODO */ }, onDelete = { /* TODO */ })
            }
            
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
    
    if (showAddPeriodDialog) {
        AddPeriodDialog(
            selectedDate = selectedDate ?: LocalDate.now(),
            onDismiss = { showAddPeriodDialog = false },
            onSave = { startDate, endDate ->
                viewModel.addPeriod(startDate, endDate)
                showAddPeriodDialog = false
            }
        )
    }
}

@Composable
fun MonthNavigator(
    currentMonth: YearMonth,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onToday: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onPreviousMonth) {
                Icon(Icons.Default.ChevronLeft, "Previous Month")
            }
            
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    currentMonth.format(DateTimeFormatter.ofPattern("MMMM yyyy")),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                TextButton(onClick = onToday) {
                    Text("Today", style = MaterialTheme.typography.bodySmall)
                }
            }
            
            IconButton(onClick = onNextMonth) {
                Icon(Icons.Default.ChevronRight, "Next Month")
            }
        }
    }
}

@Composable
fun CalendarGrid(
    yearMonth: YearMonth,
    periods: List<com.cyclecare.app.domain.model.Period>,
    prediction: com.cyclecare.app.domain.model.CyclePrediction?,
    onDateClick: (LocalDate) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Day headers
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat").forEach { day ->
                    Text(
                        day,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Calendar days
            val firstDayOfMonth = yearMonth.atDay(1)
            val lastDayOfMonth = yearMonth.atEndOfMonth()
            val firstDayOfWeek = firstDayOfMonth.dayOfWeek.value % 7
            val daysInMonth = yearMonth.lengthOfMonth()
            
            val weeks = (firstDayOfWeek + daysInMonth + 6) / 7
            
            for (week in 0 until weeks) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    for (dayOfWeek in 0..6) {
                        val dayNumber = week * 7 + dayOfWeek - firstDayOfWeek + 1
                        if (dayNumber in 1..daysInMonth) {
                            val date = yearMonth.atDay(dayNumber)
                            CalendarDay(
                                date = date,
                                isToday = date == LocalDate.now(),
                                isPeriod = periods.any { period ->
                                    date >= period.startDate && 
                                    (period.endDate == null || date <= period.endDate)
                                },
                                isFertile = prediction?.let {
                                    date >= it.nextFertileWindowStart && date <= it.nextFertileWindowEnd
                                } ?: false,
                                isOvulation = prediction?.nextOvulation == date,
                                onClick = { onDateClick(date) }
                            )
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
fun RowScope.CalendarDay(
    date: LocalDate,
    isToday: Boolean,
    isPeriod: Boolean,
    isFertile: Boolean,
    isOvulation: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = when {
        isPeriod -> PeriodRed.copy(alpha = 0.2f)
        isOvulation -> OvulationBlue.copy(alpha = 0.2f)
        isFertile -> FertileGreen.copy(alpha = 0.2f)
        else -> Color.Transparent
    }
    
    val borderColor = if (isToday) MaterialTheme.colorScheme.primary else Color.Transparent
    
    Box(
        modifier = Modifier
            .weight(1f)
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(CircleShape)
            .background(backgroundColor)
            .border(2.dp, borderColor, CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = date.dayOfMonth.toString(),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
            color = when {
                isPeriod -> PeriodRed
                isOvulation -> OvulationBlue
                isFertile -> FertileGreen
                else -> MaterialTheme.colorScheme.onSurface
            }
        )
    }
}

@Composable
fun CycleSummaryCard(uiState: CalendarUiState) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        )
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text(
                "Cycle Summary",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                SummaryItem(
                    icon = Icons.Default.CalendarToday,
                    label = "Cycle Day",
                    value = "Day ${calculateCycleDay(uiState.periods)}"
                )
                SummaryItem(
                    icon = Icons.Default.TrendingUp,
                    label = "Next Period",
                    value = uiState.prediction?.let {
                        "${java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(), it.nextPeriodStart)} days"
                    } ?: "N/A"
                )
            }
        }
    }
}

@Composable
fun SummaryItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSecondaryContainer
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSecondaryContainer
        )
        Text(
            label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
        )
    }
}

fun calculateCycleDay(periods: List<com.cyclecare.app.domain.model.Period>): Int {
    if (periods.isEmpty()) return 0
    val lastPeriod = periods.first()
    return java.time.temporal.ChronoUnit.DAYS.between(lastPeriod.startDate, LocalDate.now()).toInt() + 1
}

@Composable
fun AddPeriodDialog(
    selectedDate: LocalDate,
    onDismiss: () -> Unit,
    onSave: (LocalDate, LocalDate?) -> Unit
) {
    var startDate by remember { mutableStateOf(selectedDate) }
    var endDate by remember { mutableStateOf<LocalDate?>(null) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    "Log Period",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    "Start Date: ${startDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy"))}",
                    style = MaterialTheme.typography.bodyLarge
                )
                
                if (showEndDatePicker) {
                    OutlinedTextField(
                        value = endDate?.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) ?: "",
                        onValueChange = {},
                        label = { Text("End Date (Optional)") },
                        readOnly = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    TextButton(onClick = { showEndDatePicker = true }) {
                        Text("Add End Date")
                    }
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    Button(
                        onClick = { onSave(startDate, endDate) },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Save")
                    }
                }
            }
        }
    }
}

@Composable
fun PredictionCard(prediction: com.cyclecare.app.domain.model.CyclePrediction) {
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
            Text(
                "Next Period Prediction",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            PredictionRow(
                label = "Period Start",
                date = prediction.nextPeriodStart,
                color = PeriodRed
            )
            PredictionRow(
                label = "Ovulation",
                date = prediction.nextOvulation,
                color = OvulationBlue
            )
            PredictionRow(
                label = "Fertile Window",
                date = prediction.nextFertileWindowStart,
                color = FertileGreen
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                "Confidence: ${(prediction.confidence * 100).toInt()}%",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
fun PredictionRow(
    label: String,
    date: java.time.LocalDate,
    color: androidx.compose.ui.graphics.Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(color)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                label,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
        Text(
            date.format(DateTimeFormatter.ofPattern("MMM dd")),
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )
    }
}

@Composable
fun EmptyStateCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Start Tracking",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                "Log your periods to see predictions and insights",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun LegendCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            LegendItem("Period", PeriodRed)
            LegendItem("Fertile", FertileGreen)
            LegendItem("Ovulation", OvulationBlue)
        }
    }
}

@Composable
fun LegendItem(label: String, color: androidx.compose.ui.graphics.Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            label,
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
fun PeriodCard(
    period: com.cyclecare.app.domain.model.Period,
    onEdit: () -> Unit = {},
    onDelete: () -> Unit = {}
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier.weight(1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(PeriodRed.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.WaterDrop,
                        contentDescription = null,
                        tint = PeriodRed
                    )
                }
                
                Column {
                    Text(
                        period.startDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    period.endDate?.let { endDate ->
                        val duration = java.time.temporal.ChronoUnit.DAYS.between(period.startDate, endDate) + 1
                        Text(
                            "$duration days • ${period.flow.name.lowercase().capitalize()}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } ?: Text(
                        "Ongoing",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                IconButton(onClick = onEdit) {
                    Icon(
                        Icons.Default.Edit,
                        contentDescription = "Edit",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = "Delete",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}
