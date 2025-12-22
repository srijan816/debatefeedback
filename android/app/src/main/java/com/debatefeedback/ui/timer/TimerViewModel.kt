package com.debatefeedback.ui.timer

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.core.Constants
import com.debatefeedback.data.remote.api.SpeechStatusResponse
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.ProcessingStatus
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.domain.model.TeamComposition
import com.debatefeedback.domain.model.UploadStatus
import com.debatefeedback.repository.DebateRepository
import com.debatefeedback.repository.UploadRepository
import com.debatefeedback.services.AudioRecordingService
import com.debatefeedback.services.TimerService
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import java.io.File

class TimerViewModel(
    private val sessionId: String,
    private val debateRepository: DebateRepository,
    private val uploadRepository: UploadRepository,
    private val recordingService: AudioRecordingService,
    private val timerServiceFactory: (Int) -> TimerService
) : ViewModel() {

    private val _state = MutableStateFlow(TimerUiState())
    val state: StateFlow<TimerUiState> = _state

    private var timerService: TimerService? = null

    init {
        viewModelScope.launch { loadSession() }
        viewModelScope.launch {
            debateRepository.observeRecordings(sessionId).collect { recordings ->
                _state.value = _state.value.copy(recordings = recordings)
            }
        }
    }

    private suspend fun loadSession() {
        val session = debateRepository.getSession(sessionId)
        if (session == null) {
            _state.value = _state.value.copy(isLoading = false, errorMessage = "Session not found")
            return
        }
        timerService = timerServiceFactory(session.speechTimeSeconds).also { service ->
            service.onBell { count ->
                _state.value = _state.value.copy(lastBellCount = count, bellTimestamp = System.currentTimeMillis())
            }
            viewModelScope.launch {
                service.elapsedMillis.collect { elapsed ->
                    _state.value = _state.value.copy(elapsedMillis = elapsed)
                }
            }
        }
        val students = debateRepository.getStudents(sessionId)
        val speakers = buildSpeakers(session, students)
        _state.value = _state.value.copy(
            session = session,
            students = students,
            speakers = speakers,
            isLoading = false
        )
    }

    private fun buildSpeakers(session: DebateSession, students: List<com.debatefeedback.domain.model.Student>): List<SpeakerDisplay> {
        val composition = session.teamComposition ?: TeamComposition(prop = students.take(3).map { it.id }, opp = students.drop(3).take(3).map { it.id })
        val order = composition.speakerOrder(session.format)
        return if (order.isNotEmpty()) {
            order.map { slot ->
                val student = students.firstOrNull { it.id == slot.studentId }
                SpeakerDisplay(
                    studentId = slot.studentId,
                    speakerName = student?.name ?: slot.position,
                    position = slot.position
                )
            }
        } else {
            students.mapIndexed { index, student ->
                SpeakerDisplay(student.id, student.name, "Speaker ${index + 1}")
            }
        }
    }

    fun startRecording() {
        val session = _state.value.session ?: return
        val speaker = currentSpeaker() ?: return
        if (_state.value.isRecording) return
        val timer = timerService ?: return
        viewModelScope.launch {
            runCatching {
                recordingService.startRecording(session.id, speaker.speakerName, speaker.position)
            }.onSuccess { file ->
                timer.reset()
                timer.start()
                _state.value = _state.value.copy(isRecording = true, activeRecordingFile = file)
            }.onFailure { error ->
                _state.value = _state.value.copy(errorMessage = error.localizedMessage)
            }
        }
    }

    fun stopRecording() {
        if (!_state.value.isRecording) return
        val session = _state.value.session ?: return
        val speaker = currentSpeaker() ?: return
        val timer = timerService ?: return
        viewModelScope.launch {
            val result = recordingService.stopRecording()
            timer.stop()
            if (result == null) {
                _state.value = _state.value.copy(isRecording = false, activeRecordingFile = null)
                return@launch
            }
            val recording = SpeechRecording(
                speakerName = speaker.speakerName,
                speakerPosition = speaker.position,
                studentId = speaker.studentId,
                localFilePath = result.file.absolutePath,
                durationSeconds = result.durationSeconds,
                debateSessionId = session.id
            )
            debateRepository.addRecording(recording)
            uploadRecording(recording, result.file)
            _state.value = _state.value.copy(isRecording = false, activeRecordingFile = null)
            advanceSpeaker()
        }
    }

    fun cancelRecording() {
        viewModelScope.launch {
            recordingService.cancelRecording()
            timerService?.reset()
            _state.value = _state.value.copy(isRecording = false, activeRecordingFile = null)
        }
    }

    fun previousSpeaker() {
        if (_state.value.isRecording) return
        val newIndex = (_state.value.currentSpeakerIndex - 1).coerceAtLeast(0)
        _state.value = _state.value.copy(currentSpeakerIndex = newIndex)
        timerService?.reset()
    }

    fun nextSpeaker() {
        if (_state.value.isRecording) return
        val newIndex = (_state.value.currentSpeakerIndex + 1).coerceAtMost(_state.value.speakers.lastIndex)
        _state.value = _state.value.copy(currentSpeakerIndex = newIndex)
        timerService?.reset()
    }

    private fun advanceSpeaker() {
        val current = _state.value.currentSpeakerIndex
        if (current < _state.value.speakers.size - 1) {
            _state.value = _state.value.copy(currentSpeakerIndex = current + 1)
        }
        timerService?.reset()
    }

    fun dismissError() {
        _state.value = _state.value.copy(errorMessage = null)
    }

    private fun currentSpeaker(): SpeakerDisplay? = _state.value.speakers.getOrNull(_state.value.currentSpeakerIndex)

    private fun uploadRecording(recording: SpeechRecording, file: File) {
        viewModelScope.launch {
            val session = _state.value.session ?: return@launch
            val debateId = session.backendDebateId ?: session.id
            val metadata = mapOf(
                "speaker_name" to recording.speakerName,
                "speaker_position" to recording.speakerPosition,
                "duration_seconds" to recording.durationSeconds.toString(),
                "student_level" to session.studentLevel.name.lowercase(),
                "content_type" to "audio/m4a"
            )
            val uploadingRecording = recording.copy(uploadStatus = UploadStatus.UPLOADING, transcriptionStatus = ProcessingStatus.PROCESSING, feedbackStatus = ProcessingStatus.PENDING)
            debateRepository.updateRecording(uploadingRecording)
            _state.value = _state.value.copy(uploadProgress = _state.value.uploadProgress + (recording.id to 0.0))
            runCatching {
                uploadRepository.uploadSpeech(debateId, file, metadata) { progress ->
                    _state.value = _state.value.copy(uploadProgress = _state.value.uploadProgress + (recording.id to progress))
                }
            }.onSuccess { response ->
                val updated = uploadingRecording.copy(
                    uploadStatus = UploadStatus.UPLOADED,
                    speechId = response.speechId,
                    feedbackStatus = ProcessingStatus.PROCESSING,
                    transcriptionStatus = ProcessingStatus.PROCESSING
                )
                debateRepository.updateRecording(updated)
                pollSpeechStatus(updated)
            }.onFailure { error ->
                val failed = recording.copy(uploadStatus = UploadStatus.FAILED)
                debateRepository.updateRecording(failed)
                _state.value = _state.value.copy(errorMessage = error.localizedMessage)
            }
        }
    }

    private fun pollSpeechStatus(recording: SpeechRecording) {
        val speechId = recording.speechId ?: return
        viewModelScope.launch {
            var latest = recording
            repeat(60) {
                delay(Constants.API.FEEDBACK_POLL_SECONDS * 1000)
                val status = runCatching { debateRepository.fetchSpeechStatus(speechId) }
                    .getOrElse { error ->
                        _state.value = _state.value.copy(errorMessage = error.localizedMessage)
                        return@repeat
                    }
                val updated = applyStatus(latest, status)
                debateRepository.updateRecording(updated)
                latest = updated
                if (updated.feedbackStatus == ProcessingStatus.COMPLETE || updated.feedbackStatus == ProcessingStatus.FAILED) {
                    return@launch
                }
            }
        }
    }

    private fun applyStatus(recording: SpeechRecording, status: SpeechStatusResponse): SpeechRecording {
        val transcriptionStatus = ProcessingStatus.fromApi(status.transcriptionStatus)
        val feedbackStatus = ProcessingStatus.fromApi(status.feedbackStatus)
        return recording.copy(
            transcriptionStatus = transcriptionStatus,
            feedbackStatus = feedbackStatus,
            transcriptUrl = status.transcriptUrl ?: recording.transcriptUrl,
            feedbackUrl = status.googleDocUrl ?: recording.feedbackUrl,
            feedbackErrorMessage = status.feedbackError ?: recording.feedbackErrorMessage,
            transcriptionErrorMessage = status.transcriptionError ?: recording.transcriptionErrorMessage
        )
    }
}

data class TimerUiState(
    val session: DebateSession? = null,
    val students: List<com.debatefeedback.domain.model.Student> = emptyList(),
    val speakers: List<SpeakerDisplay> = emptyList(),
    val currentSpeakerIndex: Int = 0,
    val elapsedMillis: Long = 0L,
    val isRecording: Boolean = false,
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val recordings: List<SpeechRecording> = emptyList(),
    val uploadProgress: Map<String, Double> = emptyMap(),
    val lastBellCount: Int? = null,
    val bellTimestamp: Long? = null,
    val activeRecordingFile: File? = null
)

data class SpeakerDisplay(
    val studentId: String?,
    val speakerName: String,
    val position: String
)
