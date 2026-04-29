package com.cyclecare.app.presentation.screens.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.time.LocalDate

@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            if (state.currentStep > 0) {
                TopAppBar(
                    title = { Text("Setup (${state.currentStep + 1}/5)") },
                    navigationIcon = {
                        IconButton(onClick = { viewModel.previousStep() }) {
                            Icon(Icons.Default.ArrowBack, "Back")
                        }
                    }
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            when (state.currentStep) {
                0 -> WelcomeStep(onNext = { viewModel.nextStep() })
                1 -> LastPeriodStep(
                    selectedDate = state.lastPeriodDate,
                    onDateSelected = { viewModel.updateLastPeriodDate(it) },
                    onNext = { viewModel.nextStep() }
                )
                2 -> CycleLengthStep(
                    cycleLength = state.averageCycleLength,
                    onCycleLengthChanged = { viewModel.updateCycleLength(it) },
                    onNext = { viewModel.nextStep() }
                )
                3 -> PeriodLengthStep(
                    periodLength = state.averagePeriodLength,
                    onPeriodLengthChanged = { viewModel.updatePeriodLength(it) },
                    onNext = { viewModel.nextStep() }
                )
                4 -> GoalSelectionStep(
                    selectedGoal = state.selectedGoal,
                    onGoalSelected = { viewModel.updateGoal(it) },
                    onComplete = { viewModel.completeOnboarding(onComplete) }
                )
            }
        }
    }
}

@Composable
private fun WelcomeStep(onNext: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Spacer(modifier = Modifier.height(48.dp))
        
        Icon(
            imageVector = Icons.Default.Favorite,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = "Welcome to CycleCare",
            style = MaterialTheme.typography.headlineMedium,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Your privacy-first companion for menstrual health tracking",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                PrivacyFeature(Icons.Default.Lock, "100% Local Storage")
                PrivacyFeature(Icons.Default.CloudOff, "No Cloud Sync")
                PrivacyFeature(Icons.Default.Security, "PIN & Biometric Lock")
                PrivacyFeature(Icons.Default.Block, "No Ads or Tracking")
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Button(
            onClick = onNext,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Get Started")
        }
    }
}

@Composable
private fun PrivacyFeature(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun LastPeriodStep(
    selectedDate: LocalDate?,
    onDateSelected: (LocalDate) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "When did your last period start?",
            style = MaterialTheme.typography.headlineSmall
        )
        
        Text(
            text = "This helps us predict your next cycle",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Simple date picker - in production, use DatePickerDialog
        OutlinedButton(
            onClick = { onDateSelected(LocalDate.now().minusDays(7)) },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(selectedDate?.toString() ?: "Select Date")
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Button(
            onClick = onNext,
            modifier = Modifier.fillMaxWidth(),
            enabled = selectedDate != null
        ) {
            Text("Continue")
        }
    }
}

@Composable
private fun CycleLengthStep(
    cycleLength: Int,
    onCycleLengthChanged: (Int) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "What's your average cycle length?",
            style = MaterialTheme.typography.headlineSmall
        )
        
        Text(
            text = "The number of days from the first day of one period to the first day of the next",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "$cycleLength days",
            style = MaterialTheme.typography.displaySmall,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        
        Slider(
            value = cycleLength.toFloat(),
            onValueChange = { onCycleLengthChanged(it.toInt()) },
            valueRange = 21f..45f,
            steps = 23
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text("21 days", style = MaterialTheme.typography.bodySmall)
            Text("45 days", style = MaterialTheme.typography.bodySmall)
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Button(
            onClick = onNext,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Continue")
        }
    }
}

@Composable
private fun PeriodLengthStep(
    periodLength: Int,
    onPeriodLengthChanged: (Int) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "How long does your period usually last?",
            style = MaterialTheme.typography.headlineSmall
        )
        
        Text(
            text = "The number of days you typically bleed",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "$periodLength days",
            style = MaterialTheme.typography.displaySmall,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        
        Slider(
            value = periodLength.toFloat(),
            onValueChange = { onPeriodLengthChanged(it.toInt()) },
            valueRange = 2f..10f,
            steps = 7
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text("2 days", style = MaterialTheme.typography.bodySmall)
            Text("10 days", style = MaterialTheme.typography.bodySmall)
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Button(
            onClick = onNext,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Continue")
        }
    }
}

@Composable
private fun GoalSelectionStep(
    selectedGoal: TrackingGoal,
    onGoalSelected: (TrackingGoal) -> Unit,
    onComplete: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "What's your primary goal?",
            style = MaterialTheme.typography.headlineSmall
        )
        
        Text(
            text = "We'll customize your experience based on your needs",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        TrackingGoal.values().forEach { goal ->
            GoalCard(
                goal = goal,
                isSelected = selectedGoal == goal,
                onSelected = { onGoalSelected(goal) }
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Button(
            onClick = onComplete,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Complete Setup")
        }
    }
}

@Composable
private fun GoalCard(
    goal: TrackingGoal,
    isSelected: Boolean,
    onSelected: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(
                selected = isSelected,
                onClick = onSelected
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            }
        ),
        border = if (isSelected) {
            CardDefaults.outlinedCardBorder()
        } else null
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = goal.displayName,
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = goal.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
