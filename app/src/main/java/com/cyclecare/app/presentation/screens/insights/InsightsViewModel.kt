package com.cyclecare.app.presentation.screens.insights

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.model.CycleInsights
import com.cyclecare.app.domain.repository.PeriodRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class InsightsViewModel @Inject constructor(
    private val periodRepository: PeriodRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(InsightsUiState())
    val uiState: StateFlow<InsightsUiState> = _uiState.asStateFlow()

    init {
        loadInsights()
    }

    private fun loadInsights() {
        viewModelScope.launch {
            try {
                val insights = periodRepository.getCycleInsights()
                _uiState.update { 
                    it.copy(insights = insights, isLoading = false)
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = e.message, isLoading = false)
                }
            }
        }
    }
}

data class InsightsUiState(
    val insights: CycleInsights? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)
