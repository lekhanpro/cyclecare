package com.cyclecare.app.presentation.screens.insights

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.CycleInsights
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.repository.DailyLogRepository
import com.cyclecare.app.domain.repository.PeriodRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class InsightsViewModel @Inject constructor(
    private val periodRepository: PeriodRepository,
    private val dailyLogRepository: DailyLogRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(InsightsUiState())
    val uiState: StateFlow<InsightsUiState> = _uiState.asStateFlow()

    init {
        loadInsights()
    }

    private fun loadInsights() {
        viewModelScope.launch {
            combine(
                periodRepository.getAllPeriods(),
                dailyLogRepository.getAllLogs()
            ) { periods, logs ->
                val insights = periodRepository.getCycleInsights()

                val symptomFrequency = logs
                    .flatMap { it.symptoms }
                    .groupingBy { it }
                    .eachCount()
                    .entries
                    .sortedByDescending { it.value }
                    .take(8)
                    .associate { it.key to it.value }

                val moodPatterns = logs
                    .mapNotNull { it.mood }
                    .groupingBy { it }
                    .eachCount()
                    .entries
                    .sortedByDescending { it.value }
                    .associate { it.key to it.value }

                val tempTrend = logs.mapNotNull { it.temperature }.takeLast(14)
                val weightTrend = logs.mapNotNull { it.weightKg }.takeLast(14)
                val flowTrend = logs.mapNotNull { it.flow }.groupingBy { it }.eachCount()

                val insightsText = buildInsightsText(insights, symptomFrequency, moodPatterns)

                InsightsUiState(
                    insights = insights,
                    temperatureTrend = tempTrend,
                    weightTrend = weightTrend,
                    symptomFrequency = symptomFrequency,
                    moodPatterns = moodPatterns,
                    flowTrends = flowTrend,
                    insightsText = insightsText,
                    isLoading = false
                )
            }.collect { state ->
                _uiState.update { state }
            }
        }
    }

    private fun buildInsightsText(
        cycleInsights: CycleInsights?,
        symptomFrequency: Map<Symptom, Int>,
        moodPatterns: Map<Mood, Int>
    ): List<String> {
        val results = mutableListOf<String>()

        cycleInsights?.let {
            results += if (it.cycleRegularity >= 0.75f) {
                "Your cycle pattern looks consistent this month."
            } else {
                "Your cycle shows variability; predictions are conservative."
            }
            results += "Average cycle is ${it.averageCycleLength} days and period is ${it.averagePeriodLength} days."
        }

        symptomFrequency.entries.firstOrNull()?.let { top ->
            results += "Most frequent symptom: ${top.key.name.replace('_', ' ').lowercase()} (${top.value} logs)."
        }

        moodPatterns.entries.firstOrNull()?.let { topMood ->
            results += "Most common mood logged: ${topMood.key.name.lowercase()} (${topMood.value} days)."
        }

        if (results.isEmpty()) {
            results += "Track a few more days to unlock personalized insights."
        }
        return results
    }
}

data class InsightsUiState(
    val insights: CycleInsights? = null,
    val temperatureTrend: List<Float> = emptyList(),
    val weightTrend: List<Float> = emptyList(),
    val symptomFrequency: Map<Symptom, Int> = emptyMap(),
    val moodPatterns: Map<Mood, Int> = emptyMap(),
    val flowTrends: Map<com.cyclecare.app.domain.model.FlowIntensity, Int> = emptyMap(),
    val insightsText: List<String> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)
