package com.cyclecare.app.presentation.navigation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cyclecare.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.security.MessageDigest
import javax.inject.Inject

@HiltViewModel
class AppLockViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AppLockUiState())
    val uiState: StateFlow<AppLockUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            settingsRepository.getSettings().collect { settings ->
                _uiState.update {
                    it.copy(
                        isPinEnabled = settings.isPinEnabled,
                        isBiometricEnabled = settings.isBiometricEnabled,
                        pinHash = settings.pinHash,
                        isUnlocked = !settings.isPinEnabled || it.isUnlocked
                    )
                }
            }
        }
    }

    fun unlockWithPin(pin: String) {
        val hash = hash(pin)
        _uiState.update {
            if (it.pinHash.isNotBlank() && hash == it.pinHash) {
                it.copy(isUnlocked = true, error = null)
            } else {
                it.copy(error = "Incorrect PIN")
            }
        }
    }

    fun unlockWithBiometricFallback() {
        _uiState.update { it.copy(isUnlocked = true, error = null) }
    }

    private fun hash(pin: String): String {
        return MessageDigest.getInstance("SHA-256")
            .digest(pin.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }
}

data class AppLockUiState(
    val isPinEnabled: Boolean = false,
    val isBiometricEnabled: Boolean = false,
    val pinHash: String = "",
    val isUnlocked: Boolean = false,
    val error: String? = null
)
