package com.cyclecare.app.presentation.screens.insights

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.background
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun InsightsScreen(
    viewModel: InsightsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(topBar = { TopAppBar(title = { Text("Insights") }) }) { padding ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Text("Preparing insights...")
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("Cycle analytics", fontWeight = FontWeight.Bold)
                            Text("Avg cycle: ${uiState.insights?.averageCycleLength ?: "--"} days")
                            Text("Avg period: ${uiState.insights?.averagePeriodLength ?: "--"} days")
                            Text("Regularity: ${(((uiState.insights?.cycleRegularity ?: 0f) * 100).toInt())}%")
                        }
                    }
                }
                item {
                    TrendCard("Cycle length trend", uiState.insights?.cycleLengthTrend?.map { it.toFloat() } ?: emptyList())
                }
                item {
                    TrendCard("Period length trend", uiState.insights?.periodLengthTrend?.map { it.toFloat() } ?: emptyList())
                }
                item {
                    TrendCard("Temperature trend", uiState.temperatureTrend)
                }
                item {
                    TrendCard("Weight trend", uiState.weightTrend)
                }
                item {
                    FrequencyCard(
                        title = "Symptoms frequency",
                        values = uiState.symptomFrequency.mapKeys { it.key.name.replace('_', ' ').lowercase() }
                    )
                }
                item {
                    FrequencyCard(
                        title = "Mood patterns",
                        values = uiState.moodPatterns.mapKeys { it.key.name.lowercase() }
                    )
                }
                item {
                    FrequencyCard(
                        title = "Flow trends",
                        values = uiState.flowTrends.mapKeys { it.key.name.lowercase() }
                    )
                }
                item {
                    Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("Human-readable insights", fontWeight = FontWeight.Bold)
                            uiState.insightsText.forEach { insight -> Text("• $insight") }
                        }
                    }
                }
                item { Spacer(modifier = Modifier.height(32.dp)) }
            }
        }
    }
}

@Composable
private fun TrendCard(title: String, points: List<Float>) {
    val lineColor = MaterialTheme.colorScheme.primary
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            if (points.size < 2) {
                Text("Track more entries to view trend")
            } else {
                Canvas(modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)) {
                    val max = points.maxOrNull() ?: 1f
                    val min = points.minOrNull() ?: 0f
                    val spread = (max - min).takeIf { it > 0f } ?: 1f
                    val stepX = size.width / (points.size - 1)
                    for (index in 0 until points.size - 1) {
                        val x1 = stepX * index
                        val y1 = size.height - ((points[index] - min) / spread * size.height)
                        val x2 = stepX * (index + 1)
                        val y2 = size.height - ((points[index + 1] - min) / spread * size.height)
                        drawLine(
                            color = lineColor,
                            start = androidx.compose.ui.geometry.Offset(x1, y1),
                            end = androidx.compose.ui.geometry.Offset(x2, y2),
                            strokeWidth = 6f
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FrequencyCard(title: String, values: Map<String, Int>) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            if (values.isEmpty()) {
                Text("No entries yet")
            } else {
                val max = values.values.maxOrNull()?.coerceAtLeast(1) ?: 1
                values.entries.forEach { (label, value) ->
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(label)
                            Text(value.toString())
                        }
                        Box(
                            modifier = Modifier
                                .fillMaxWidth((value.toFloat() / max.toFloat()).coerceIn(0.1f, 1f))
                                .height(8.dp)
                                .background(Color(0xFFCE93D8), RoundedCornerShape(100))
                        )
                    }
                }
            }
        }
    }
}
