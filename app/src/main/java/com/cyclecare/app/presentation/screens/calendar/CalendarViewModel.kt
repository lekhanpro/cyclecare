package com.cyclecare.app.presentation.screens.calendar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.CyclePrediction
import com.cyclecare.app.domain.model.Period
import com.cyclecare.app.domain.repository.PeriodRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class CalendarViewModel @Inject constructor(
    private val periodRepository: PeriodRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    init {
        loadPeriods()
        loadPrediction()
    }

    private fun loadPeriods() {
        viewModelScope.launch {
            periodRepository.getAllPeriods()
                .catch { e ->
                    _uiState.update { it.copy(error = e.message) }
                }
                .collect { periods ->
                    _uiState.update { it.copy(periods = periods, isLoading = false) }
                }
        }
    }

    private fun loadPrediction() {
        viewModelScope.launch {
            try {
                val prediction = periodRepository.predictNextCycle()
                _uiState.update { it.copy(prediction = prediction) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun addPeriod(startDate: LocalDate, endDate: LocalDate?) {
        viewModelScope.launch {
            try {
                val period = Period(
                    startDate = startDate,
                    endDate = endDate
                )
                periodRepository.insertPeriod(period)
                loadPrediction()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }
}

data class CalendarUiState(
    val periods: List<Period> = emptyList(),
    val prediction: CyclePrediction? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)
