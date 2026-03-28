package com.cyclecare.app.presentation.screens.calendar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.CyclePrediction
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Period
import com.cyclecare.app.domain.repository.DailyLogRepository
import com.cyclecare.app.domain.repository.PeriodRepository
import com.cyclecare.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject

@HiltViewModel
class CalendarViewModel @Inject constructor(
    private val periodRepository: PeriodRepository,
    private val dailyLogRepository: DailyLogRepository,
    private val settingsRepository: SettingsRepository,
    private val amenorrheaDetectionEngine: com.cyclecare.app.domain.engine.AmenorrheaDetectionEngine
) : ViewModel() {

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    init {
        observePeriods()
        refreshPrediction()
        observeOnboarding()
        checkAmenorrhea()
    }

    private fun observePeriods() {
        viewModelScope.launch {
            periodRepository.getAllPeriods()
                .catch { throwable ->
                    _uiState.update { it.copy(error = throwable.message) }
                }
                .collect { periods ->
                    _uiState.update { state ->
                        state.copy(
                            periods = periods,
                            isLoading = false,
                            cycleDay = calculateCycleDay(periods),
                            lastPeriodStart = periods.firstOrNull()?.startDate
                        )
                    }
                    refreshPrediction()
                }
        }
    }

    private fun observeOnboarding() {
        viewModelScope.launch {
            settingsRepository.getSettings().collect { settings ->
                _uiState.update {
                    it.copy(showOnboarding = !settings.onboardingCompleted)
                }
            }
        }
    }

    fun completeOnboarding(name: String, cycleLength: Int, periodLength: Int, tryingToConceive: Boolean) {
        viewModelScope.launch {
            val settings = settingsRepository.getSettings().first()
            settingsRepository.updateSettings(
                settings.copy(
                    onboardingCompleted = true,
                    averageCycleLength = cycleLength,
                    averagePeriodLength = periodLength,
                    userProfile = settings.userProfile.copy(
                        name = name,
                        cycleLengthHint = cycleLength,
                        periodLengthHint = periodLength,
                        tryingToConceive = tryingToConceive
                    )
                )
            )
            _uiState.update { it.copy(showOnboarding = false) }
        }
    }

    fun dismissOnboarding() {
        _uiState.update { it.copy(showOnboarding = false) }
    }

    fun refreshPrediction() {
        viewModelScope.launch {
            val prediction = periodRepository.predictNextCycle()
            val today = LocalDate.now()
            val countdown = prediction?.let { ChronoUnit.DAYS.between(today, it.nextPeriodStart).toInt() }

            _uiState.update {
                it.copy(
                    prediction = prediction,
                    countdownToPeriod = countdown,
                    fertilityStatus = fertilityStatus(today, prediction)
                )
            }
        }
    }

    fun addPeriod(startDate: LocalDate, endDate: LocalDate?) {
        viewModelScope.launch {
            runCatching {
                val sanitizedEndDate = endDate?.takeIf { it >= startDate }
                periodRepository.insertPeriod(
                    Period(
                        startDate = startDate,
                        endDate = sanitizedEndDate
                    )
                )
            }.onFailure { throwable ->
                _uiState.update { it.copy(error = throwable.message) }
            }
            refreshPrediction()
        }
    }

    fun quickLog(flow: FlowIntensity?, mood: Mood?) {
        viewModelScope.launch {
            val date = LocalDate.now()
            val existing = dailyLogRepository.getLogByDate(date)
            dailyLogRepository.upsertLog(
                (existing ?: com.cyclecare.app.domain.model.DailyLog(date = date)).copy(
                    flow = flow ?: existing?.flow,
                    mood = mood ?: existing?.mood
                )
            )
        }
    }

    private fun calculateCycleDay(periods: List<Period>): Int? {
        val lastStart = periods.firstOrNull()?.startDate ?: return null
        val day = ChronoUnit.DAYS.between(lastStart, LocalDate.now()).toInt() + 1
        return day.takeIf { it > 0 }
    }

    private fun fertilityStatus(today: LocalDate, prediction: CyclePrediction?): String {
        if (prediction == null) return "Need more data"
        return when {
            today in prediction.nextFertileWindowStart..prediction.nextFertileWindowEnd -> "Fertile window"
            today == prediction.nextOvulation -> "Ovulation day"
            today > prediction.nextPeriodStart -> "Period expected"
            else -> "Low fertility"
        }
    }
    
    private fun checkAmenorrhea() {
        viewModelScope.launch {
            val periods = periodRepository.getAllPeriods().first()
            val recentLogs = dailyLogRepository.getLogsInRange(
                LocalDate.now().minusDays(90),
                LocalDate.now()
            ).first()
            val settings = settingsRepository.getSettings().first()
            
            val result = amenorrheaDetectionEngine.detectAmenorrhea(
                periods = periods,
                recentLogs = recentLogs,
                isPregnant = settings.pregnancyMode,
                isBreastfeeding = settings.breastfeedingMode,
                isMenopause = settings.menopauseMode
            )
            
            _uiState.update { it.copy(amenorrheaAlert = result) }
        }
    }
    
    fun dismissAmenorrheaAlert() {
        _uiState.update { it.copy(amenorrheaAlert = null) }
    }
}

data class CalendarUiState(
    val periods: List<Period> = emptyList(),
    val prediction: CyclePrediction? = null,
    val cycleDay: Int? = null,
    val countdownToPeriod: Int? = null,
    val fertilityStatus: String = "Need more data",
    val lastPeriodStart: LocalDate? = null,
    val showOnboarding: Boolean = false,
    val amenorrheaAlert: com.cyclecare.app.domain.model.AmenorrheaResult? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)
