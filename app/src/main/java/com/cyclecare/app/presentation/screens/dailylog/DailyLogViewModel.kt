package com.cyclecare.app.presentation.screens.dailylog

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.DailyLog
import com.cyclecare.app.domain.model.DischargeType
import com.cyclecare.app.domain.model.FlowIntensity
import com.cyclecare.app.domain.model.IntimacyType
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.model.TestResult
import com.cyclecare.app.domain.repository.DailyLogRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class DailyLogViewModel @Inject constructor(
    private val dailyLogRepository: DailyLogRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DailyLogUiState())
    val uiState: StateFlow<DailyLogUiState> = _uiState.asStateFlow()

    init {
        loadLog(LocalDate.now())
    }

    fun loadLog(date: LocalDate) {
        viewModelScope.launch {
            val existing = dailyLogRepository.getLogByDate(date)
            _uiState.update {
                it.copy(
                    selectedDate = date,
                    currentLog = existing ?: DailyLog(date = date),
                    isLoading = false,
                    isSaved = false,
                    error = null
                )
            }
        }
    }

    fun updateFlow(flow: FlowIntensity?) = updateLog { copy(flow = flow) }
    fun updateMood(mood: Mood?) = updateLog { copy(mood = mood) }
    fun updateDischarge(dischargeType: DischargeType?) = updateLog { copy(discharge = dischargeType) }
    fun updateWeight(weightKg: Float?) = updateLog { copy(weightKg = weightKg) }
    fun updateTemperature(temperature: Float?) = updateLog { copy(temperature = temperature) }
    fun updateSleep(hours: Float?) = updateLog { copy(sleepHours = hours) }
    fun updateWater(waterMl: Int) = updateLog { copy(waterMl = waterMl.coerceAtLeast(0)) }
    fun updateIntimacy(intimacyType: IntimacyType) = updateLog {
        copy(
            intimacy = intimacyType,
            sexualActivity = intimacyType != IntimacyType.NONE
        )
    }

    fun updateOvulationTest(result: TestResult) = updateLog { copy(ovulationTest = result) }
    fun updatePregnancyTest(result: TestResult) = updateLog { copy(pregnancyTest = result) }
    fun updateNotes(notes: String) = updateLog { copy(notes = notes) }

    fun toggleSymptom(symptom: Symptom) {
        updateLog {
            val mutable = symptoms.toMutableList()
            if (mutable.contains(symptom)) mutable.remove(symptom) else mutable.add(symptom)
            copy(symptoms = mutable)
        }
    }

    fun saveLog() {
        viewModelScope.launch {
            runCatching {
                dailyLogRepository.upsertLog(_uiState.value.currentLog)
            }.onSuccess {
                _uiState.update { state -> state.copy(isSaved = true, error = null) }
            }.onFailure { throwable ->
                _uiState.update { state -> state.copy(error = throwable.message ?: "Failed to save") }
            }
        }
    }

    fun quickLog(flow: FlowIntensity?, mood: Mood?) {
        updateLog {
            copy(flow = flow ?: this.flow, mood = mood ?: this.mood)
        }
        saveLog()
    }

    private fun updateLog(transform: DailyLog.() -> DailyLog) {
        _uiState.update { state ->
            state.copy(
                currentLog = state.currentLog.transform(),
                isSaved = false
            )
        }
    }
}

data class DailyLogUiState(
    val selectedDate: LocalDate = LocalDate.now(),
    val currentLog: DailyLog = DailyLog(date = LocalDate.now()),
    val isLoading: Boolean = true,
    val isSaved: Boolean = false,
    val error: String? = null
)
