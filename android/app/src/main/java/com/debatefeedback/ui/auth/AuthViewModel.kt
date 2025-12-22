package com.debatefeedback.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.core.Constants
import com.debatefeedback.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AuthViewModel(private val repository: AuthRepository) : ViewModel() {
    private val _state = MutableStateFlow(AuthUiState())
    val state: StateFlow<AuthUiState> = _state

    fun onNameChanged(name: String) {
        _state.value = _state.value.copy(teacherName = name)
    }

    fun loginAsTeacher() {
        val name = _state.value.teacherName.trim()
        if (name.length < Constants.Validation.SPEAKER_MIN) {
            _state.value = _state.value.copy(errorMessage = "Please enter a valid name")
            return
        }
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, errorMessage = null)
            runCatching { repository.loginTeacher(name) }
                .onSuccess {
                    _state.value = _state.value.copy(isLoading = false, isAuthenticated = true)
                }
                .onFailure { error ->
                    _state.value = _state.value.copy(isLoading = false, errorMessage = error.localizedMessage)
                }
        }
    }

    fun loginAsGuest() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, errorMessage = null)
            runCatching { repository.loginGuest() }
                .onSuccess {
                    _state.value = _state.value.copy(isLoading = false, isAuthenticated = true)
                }
                .onFailure { error ->
                    _state.value = _state.value.copy(isLoading = false, errorMessage = error.localizedMessage)
                }
        }
    }

    fun dismissError() {
        _state.value = _state.value.copy(errorMessage = null)
    }
}

data class AuthUiState(
    val teacherName: String = "",
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val isAuthenticated: Boolean = false
)
