package com.debatefeedback.ui.feedback

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.repository.DebateRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class FeedbackListViewModel(
    private val sessionId: String,
    private val repository: DebateRepository
) : ViewModel() {

    private val _state = MutableStateFlow(FeedbackListState())
    val state: StateFlow<FeedbackListState> = _state

    init {
        viewModelScope.launch {
            val session = repository.getSession(sessionId)
            _state.value = _state.value.copy(session = session, isLoading = false)
        }
        viewModelScope.launch {
            repository.observeRecordings(sessionId).collect { recordings ->
                _state.value = _state.value.copy(recordings = recordings)
            }
        }
    }
}

data class FeedbackListState(
    val session: DebateSession? = null,
    val recordings: List<SpeechRecording> = emptyList(),
    val isLoading: Boolean = true
)
