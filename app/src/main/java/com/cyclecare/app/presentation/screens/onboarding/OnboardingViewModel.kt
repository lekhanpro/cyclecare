package com.cyclecare.app.presentation.screens.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(OnboardingState())
    val uiState: StateFlow<OnboardingState> = _uiState.asStateFlow()

    fun updateLastPeriodDate(date: LocalDate) {
        _uiState.value = _uiState.value.copy(lastPeriodDate = date)
    }

    fun updateCycleLength(length: Int) {
        _uiState.value = _uiState.value.copy(averageCycleLength = length)
    }

    fun updatePeriodLength(length: Int) {
        _uiState.value = _uiState.value.copy(averagePeriodLength = length)
    }

    fun updateGoal(goal: TrackingGoal) {
        _uiState.value = _uiState.value.copy(selectedGoal = goal)
    }

    fun nextStep() {
        val currentStep = _uiState.value.currentStep
        if (currentStep < 4) {
            _uiState.value = _uiState.value.copy(currentStep = currentStep + 1)
        }
    }

    fun previousStep() {
        val currentStep = _uiState.value.currentStep
        if (currentStep > 0) {
            _uiState.value = _uiState.value.copy(currentStep = currentStep - 1)
        }
    }

    fun completeOnboarding(onComplete: () -> Unit) {
        viewModelScope.launch {
            try {
                val settings = settingsRepository.getSettings().first()
                val updatedSettings = settings.copy(
                    onboardingCompleted = true,
                    averageCycleLength = _uiState.value.averageCycleLength,
                    averagePeriodLength = _uiState.value.averagePeriodLength,
                    profileTryingToConceive = _uiState.value.selectedGoal == TrackingGoal.TRYING_TO_CONCEIVE,
                    pregnancyMode = _uiState.value.selectedGoal == TrackingGoal.PREGNANCY,
                    menopauseMode = _uiState.value.selectedGoal == TrackingGoal.PERIMENOPAUSE
                )
                settingsRepository.updateSettings(updatedSettings)
                onComplete()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.message)
            }
        }
    }
}

data class OnboardingState(
    val currentStep: Int = 0,
    val lastPeriodDate: LocalDate? = null,
    val averageCycleLength: Int = 28,
    val averagePeriodLength: Int = 5,
    val selectedGoal: TrackingGoal = TrackingGoal.TRACK_PERIODS,
    val error: String? = null
)

enum class TrackingGoal(val displayName: String, val description: String) {
    TRACK_PERIODS("Track Periods", "Monitor your menstrual cycle and symptoms"),
    TRYING_TO_CONCEIVE("Trying to Conceive", "Track fertility windows and ovulation"),
    PREGNANCY("Pregnancy", "Track pregnancy symptoms and milestones"),
    PERIMENOPAUSE("Perimenopause", "Monitor irregular cycles and symptoms")
}
