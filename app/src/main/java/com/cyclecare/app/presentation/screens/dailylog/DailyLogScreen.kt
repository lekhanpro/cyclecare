package com.cyclecare.app.presentation.screens.dailylog

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyLogScreen(
    viewModel: DailyLogViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    LaunchedEffect(uiState.isSaved) {
        if (uiState.isSaved) {
            // Show success message
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Daily Log",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { viewModel.saveLog() },
                icon = { Icon(Icons.Default.Check, "Save") },
                text = { Text("Save Log") },
                containerColor = MaterialTheme.colorScheme.primary
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            item { Spacer(modifier = Modifier.height(8.dp)) }
            
            // Mood Section
            item {
                Text(
                    "How are you feeling?",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(12.dp))
                MoodSelector(
                    selectedMood = uiState.currentLog.mood,
                    onMoodSelected = { viewModel.updateMood(it) }
                )
            }
            
            // Symptoms Section
            item {
                Text(
                    "Symptoms",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(12.dp))
                SymptomSelector(
                    selectedSymptoms = uiState.currentLog.symptoms,
                    onSymptomToggle = { viewModel.toggleSymptom(it) }
                )
            }
            
            // Notes Section
            item {
                Text(
                    "Notes",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = uiState.currentLog.notes,
                    onValueChange = { viewModel.updateNotes(it) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    placeholder = { Text("Add any notes about your day...") },
                    shape = RoundedCornerShape(12.dp)
                )
            }
            
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
}

@Composable
fun MoodSelector(
    selectedMood: Mood?,
    onMoodSelected: (Mood) -> Unit
) {
    val moods = listOf(
        Mood.HAPPY to "😊",
        Mood.SAD to "😢",
        Mood.ANXIOUS to "😰",
        Mood.IRRITABLE to "😠",
        Mood.CALM to "😌",
        Mood.ENERGETIC to "⚡",
        Mood.TIRED to "😴",
        Mood.STRESSED to "😫"
    )
    
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.height(200.dp)
    ) {
        items(moods.size) { index ->
            val (mood, emoji) = moods[index]
            MoodChip(
                emoji = emoji,
                label = mood.name.lowercase().capitalize(),
                isSelected = selectedMood == mood,
                onClick = { onMoodSelected(mood) }
            )
        }
    }
}

@Composable
fun MoodChip(
    emoji: String,
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    FilterChip(
        selected = isSelected,
        onClick = onClick,
        label = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
            ) {
                Text(emoji, style = MaterialTheme.typography.headlineSmall)
                Text(
                    label,
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1
                )
            }
        },
        modifier = Modifier
            .aspectRatio(1f)
            .padding(2.dp)
    )
}

@Composable
fun SymptomSelector(
    selectedSymptoms: List<Symptom>,
    onSymptomToggle: (Symptom) -> Unit
) {
    val symptoms = Symptom.values().toList()
    
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.height(300.dp)
    ) {
        items(symptoms) { symptom ->
            SymptomChip(
                symptom = symptom,
                isSelected = selectedSymptoms.contains(symptom),
                onClick = { onSymptomToggle(symptom) }
            )
        }
    }
}

@Composable
fun SymptomChip(
    symptom: Symptom,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    FilterChip(
        selected = isSelected,
        onClick = onClick,
        label = {
            Text(
                symptom.name.replace("_", " ").lowercase()
                    .split(" ")
                    .joinToString(" ") { it.capitalize() }
            )
        },
        modifier = Modifier.fillMaxWidth()
    )
}
