package com.debatefeedback.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.repository.DebateRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class HistoryViewModel(private val repository: DebateRepository) : ViewModel() {
    private val _state = MutableStateFlow(HistoryUiState())
    val state: StateFlow<HistoryUiState> = _state

    init {
        viewModelScope.launch {
            repository.observeSessions().collect { sessions ->
                _state.value = HistoryUiState(sessions = sessions)
            }
        }
    }
}

data class HistoryUiState(
    val sessions: List<DebateSession> = emptyList()
)
