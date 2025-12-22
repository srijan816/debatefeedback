package com.debatefeedback.ui.feedback

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.repository.DebateRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class FeedbackDetailViewModel(
    private val sessionId: String,
    private val recordingId: String,
    private val repository: DebateRepository
) : ViewModel() {
    private val _state = MutableStateFlow(FeedbackDetailState())
    val state: StateFlow<FeedbackDetailState> = _state

    init {
        viewModelScope.launch {
            repository.observeRecordings(sessionId).collect { recordings ->
                val recording = recordings.firstOrNull { it.id == recordingId }
                _state.value = _state.value.copy(recording = recording, isLoading = false)
                if (recording?.speechId != null && _state.value.feedbackContent.isNullOrEmpty()) {
                    fetchFeedback(recording.speechId)
                }
            }
        }
    }

    private fun fetchFeedback(speechId: String) {
        viewModelScope.launch {
            runCatching { repository.fetchFeedbackContent(speechId) }
                .onSuccess { response ->
                    _state.value = _state.value.copy(feedbackContent = response.feedbackText)
                }
                .onFailure { error ->
                    _state.value = _state.value.copy(errorMessage = error.localizedMessage)
                }
        }
    }

    fun dismissError() {
        _state.value = _state.value.copy(errorMessage = null)
    }
}

data class FeedbackDetailState(
    val recording: SpeechRecording? = null,
    val feedbackContent: String? = null,
    val isLoading: Boolean = true,
    val errorMessage: String? = null
)
