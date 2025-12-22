package com.debatefeedback.ui.setup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.debatefeedback.core.Constants
import com.debatefeedback.domain.model.DebateFormat
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.Student
import com.debatefeedback.domain.model.StudentLevel
import com.debatefeedback.domain.model.TeamComposition
import com.debatefeedback.repository.DebateRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class SetupViewModel(private val repository: DebateRepository) : ViewModel() {
    private val _state = MutableStateFlow(SetupUiState())
    val state: StateFlow<SetupUiState> = _state

    fun updateMotion(motion: String) {
        _state.value = _state.value.copy(motion = motion.take(Constants.Validation.MOTION_MAX))
    }

    fun selectFormat(format: DebateFormat) {
        val replyTime = if (format.hasReplySpeeches) format.defaultReplyTime else null
        val includeReply = replyTime != null
        val filteredAssignments = _state.value.studentEntries.map {
            val group = it.group
            if (group != null && !group.allowedFor(format)) {
                it.copy(group = null)
            } else it
        }
        _state.value = _state.value.copy(
            format = format,
            speechTimeSeconds = format.defaultSpeechTime,
            includeReplySpeeches = includeReply,
            replyTimeSeconds = replyTime,
            studentEntries = filteredAssignments
        )
    }

    fun selectLevel(level: StudentLevel) {
        _state.value = _state.value.copy(studentLevel = level)
    }

    fun addStudent(name: String) {
        if (name.length < Constants.Validation.SPEAKER_MIN) return
        val student = Student(name = name.trim(), level = _state.value.studentLevel)
        _state.value = _state.value.copy(
            newStudentName = "",
            studentEntries = _state.value.studentEntries + StudentEntry(student)
        )
    }

    fun updateNewStudentName(name: String) {
        _state.value = _state.value.copy(newStudentName = name)
    }

    fun removeStudent(id: String) {
        _state.value = _state.value.copy(
            studentEntries = _state.value.studentEntries.filterNot { it.student.id == id }
        )
    }

    fun assignStudent(studentId: String, group: TeamGroup?) {
        val updated = _state.value.studentEntries.map {
            if (it.student.id == studentId) it.copy(group = group) else it
        }
        _state.value = _state.value.copy(studentEntries = updated)
    }

    fun navigateTo(step: SetupStep) {
        _state.value = _state.value.copy(currentStep = step)
    }

    fun updateSpeechTime(seconds: Int) {
        val clamped = seconds.coerceIn(Constants.Validation.SPEECH_TIME_MIN, Constants.Validation.SPEECH_TIME_MAX)
        _state.value = _state.value.copy(speechTimeSeconds = clamped)
    }

    fun updateReplyEnabled(enabled: Boolean) {
        _state.value = _state.value.copy(includeReplySpeeches = enabled)
        if (!enabled) {
            _state.value = _state.value.copy(replyTimeSeconds = null)
        } else {
            val default = _state.value.format.defaultReplyTime ?: 120
            _state.value = _state.value.copy(replyTimeSeconds = default)
        }
    }

    fun updateReplyTime(seconds: Int) {
        _state.value = _state.value.copy(replyTimeSeconds = seconds)
    }

    fun createDebate(onReady: (String) -> Unit) {
        val current = _state.value
        val validation = validate(current)
        if (validation != null) {
            _state.value = current.copy(errorMessage = validation)
            return
        }

        val teamComposition = buildTeamComposition(current)
        val session = DebateSession(
            motion = current.motion.trim(),
            format = current.format,
            studentLevel = current.studentLevel,
            speechTimeSeconds = current.speechTimeSeconds,
            replyTimeSeconds = current.replyTimeSeconds,
            isGuestMode = false,
            teamComposition = teamComposition
        )
        val students = current.studentEntries.map { it.student.copy(level = current.studentLevel, sessionId = session.id) }

        viewModelScope.launch {
            _state.value = _state.value.copy(isCreating = true, errorMessage = null)
            runCatching {
                repository.saveSession(session, students)
                repository.createBackendDebate(session, students)
            }.onSuccess { updated ->
                _state.value = _state.value.copy(isCreating = false)
                onReady(updated.id)
            }.onFailure { error ->
                _state.value = _state.value.copy(isCreating = false, errorMessage = error.localizedMessage)
            }
        }
    }

    fun dismissError() {
        _state.value = _state.value.copy(errorMessage = null)
    }

    private fun validate(state: SetupUiState): String? {
        if (!state.motion.trim().isValidMotion()) return Constants.ErrorMessages.INVALID_MOTION
        if (state.studentEntries.isEmpty()) return "Please add at least one student"
        if (state.studentEntries.any { it.group == null }) return Constants.ErrorMessages.INCOMPLETE_TEAMS
        return null
    }

    private fun buildTeamComposition(state: SetupUiState): TeamComposition {
        fun idsFor(group: TeamGroup) = state.studentEntries.filter { it.group == group }.map { it.student.id }.takeIf { it.isNotEmpty() }
        return TeamComposition(
            prop = idsFor(TeamGroup.PROP),
            opp = idsFor(TeamGroup.OPP),
            og = idsFor(TeamGroup.OG),
            oo = idsFor(TeamGroup.OO),
            cg = idsFor(TeamGroup.CG),
            co = idsFor(TeamGroup.CO)
        )
    }

    private fun String.isValidMotion(): Boolean {
        val trimmed = trim()
        return trimmed.length in Constants.Validation.MOTION_MIN..Constants.Validation.MOTION_MAX
    }
}

data class SetupUiState(
    val motion: String = "",
    val format: DebateFormat = DebateFormat.WSDC,
    val studentLevel: StudentLevel = StudentLevel.SECONDARY,
    val speechTimeSeconds: Int = DebateFormat.WSDC.defaultSpeechTime,
    val includeReplySpeeches: Boolean = true,
    val replyTimeSeconds: Int? = DebateFormat.WSDC.defaultReplyTime,
    val newStudentName: String = "",
    val studentEntries: List<StudentEntry> = emptyList(),
    val currentStep: SetupStep = SetupStep.BASIC_INFO,
    val isCreating: Boolean = false,
    val errorMessage: String? = null
)

data class StudentEntry(
    val student: Student,
    val group: TeamGroup? = null
)

enum class SetupStep { BASIC_INFO, STUDENTS, TEAMS }

enum class TeamGroup(val displayName: String) {
    PROP("Proposition"),
    OPP("Opposition"),
    OG("Opening Government"),
    OO("Opening Opposition"),
    CG("Closing Government"),
    CO("Closing Opposition");

    fun allowedFor(format: DebateFormat): Boolean = when (format) {
        DebateFormat.WSDC, DebateFormat.MODIFIED_WSDC, DebateFormat.AUSTRALS -> this == PROP || this == OPP
        DebateFormat.AP -> this == PROP || this == OPP
        DebateFormat.BP -> this == OG || this == OO || this == CG || this == CO
    }

    companion object {
        fun optionsFor(format: DebateFormat): List<TeamGroup> = when (format) {
            DebateFormat.WSDC, DebateFormat.MODIFIED_WSDC, DebateFormat.AUSTRALS -> listOf(PROP, OPP)
            DebateFormat.AP -> listOf(PROP, OPP)
            DebateFormat.BP -> listOf(OG, OO, CG, CO)
        }
    }
}
