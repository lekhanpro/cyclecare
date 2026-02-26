package com.cyclecare.app.presentation.screens.dailylog

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.DailyLog
import com.cyclecare.app.domain.model.Mood
import com.cyclecare.app.domain.model.Symptom
import com.cyclecare.app.domain.repository.DailyLogRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
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
        loadTodayLog()
    }

    private fun loadTodayLog() {
        viewModelScope.launch {
            try {
                val today = LocalDate.now()
                val log = dailyLogRepository.getLogByDate(today)
                _uiState.update { 
                    it.copy(
                        currentLog = log ?: DailyLog(date = today),
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message, isLoading = false) }
            }
        }
    }

    fun updateMood(mood: Mood) {
        _uiState.update { 
            it.copy(currentLog = it.currentLog.copy(mood = mood))
        }
    }

    fun toggleSymptom(symptom: Symptom) {
        _uiState.update { state ->
            val symptoms = state.currentLog.symptoms.toMutableList()
            if (symptoms.contains(symptom)) {
                symptoms.remove(symptom)
            } else {
                symptoms.add(symptom)
            }
            state.copy(currentLog = state.currentLog.copy(symptoms = symptoms))
        }
    }

    fun updateNotes(notes: String) {
        _uiState.update { 
            it.copy(currentLog = it.currentLog.copy(notes = notes))
        }
    }

    fun saveLog() {
        viewModelScope.launch {
            try {
                val log = _uiState.value.currentLog
                if (log.id == 0L) {
                    dailyLogRepository.insertLog(log)
                } else {
                    dailyLogRepository.updateLog(log)
                }
                _uiState.update { it.copy(isSaved = true) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }
}

data class DailyLogUiState(
    val currentLog: DailyLog = DailyLog(date = LocalDate.now()),
    val isLoading: Boolean = true,
    val isSaved: Boolean = false,
    val error: String? = null
)
