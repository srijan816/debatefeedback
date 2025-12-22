package com.debatefeedback.repository

import com.debatefeedback.SessionManager
import com.debatefeedback.core.Constants
import com.debatefeedback.data.local.DebateFeedbackDao
import com.debatefeedback.data.remote.api.CreateDebateRequest
import com.debatefeedback.data.remote.api.DebateFeedbackApi
import com.debatefeedback.data.remote.api.StudentData
import com.debatefeedback.data.remote.api.TeamsData
import com.debatefeedback.domain.model.DebateFormat
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.domain.model.Student
import com.debatefeedback.domain.model.TeamComposition
import com.debatefeedback.domain.model.UploadStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext

class DebateRepository(
    private val api: DebateFeedbackApi,
    private val dao: DebateFeedbackDao,
    private val sessionManager: SessionManager
) {

    fun observeSessions(): Flow<List<DebateSession>> = dao.observeSessions()

    suspend fun getSession(sessionId: String): DebateSession? = dao.getSession(sessionId)

    suspend fun saveSession(session: DebateSession, students: List<Student>) = withContext(Dispatchers.IO) {
        dao.upsertSession(session)
        dao.replaceStudents(session.id, students)
    }

    suspend fun getStudents(sessionId: String): List<Student> = dao.getStudentsForSession(sessionId)

    suspend fun createBackendDebate(session: DebateSession, students: List<Student>): DebateSession = withContext(Dispatchers.IO) {
        val composition = session.teamComposition ?: error("Missing team composition")
        val teams = buildTeamsData(composition, session.format, students)
        val request = CreateDebateRequest(
            motion = session.motion,
            format = session.format.displayName,
            studentLevel = session.studentLevel.name.lowercase(),
            speechTimeSeconds = session.speechTimeSeconds,
            teams = teams,
            classId = session.classId,
            scheduleId = session.scheduleId
        )
        val response = api.createDebate(request)
        val updated = session.copy(backendDebateId = response.resolvedId.ifBlank { session.backendDebateId })
        dao.upsertSession(updated)
        updated
    }

    fun observeRecordings(sessionId: String): Flow<List<SpeechRecording>> = dao.observeRecordings(sessionId)

    suspend fun addRecording(recording: SpeechRecording) = dao.upsertRecording(recording)

    suspend fun updateRecording(recording: SpeechRecording) = dao.updateRecording(recording)

    suspend fun getRecordings(sessionId: String): List<SpeechRecording> = dao.getRecordings(sessionId)

    suspend fun deleteSession(session: DebateSession) = withContext(Dispatchers.IO) {
        dao.deleteRecordings(session.id)
        dao.deleteStudentsForSession(session.id)
        // no explicit delete for session; reuse update to remove? For now rely on Room cascading? simple manual delete not defined.
    }

    suspend fun ensureDeviceId(): String = sessionManager.ensureDeviceId()

    suspend fun fetchSpeechStatus(speechId: String) = api.getSpeechStatus(speechId)

    suspend fun fetchFeedbackContent(speechId: String) = api.getFeedbackContent(speechId)

    private fun buildTeamsData(
        composition: TeamComposition,
        format: DebateFormat,
        students: List<Student>
    ): TeamsData {
        fun mapStudents(ids: List<String>?, prefix: String): List<StudentData>? {
            if (ids == null) return null
            return ids.mapIndexed { index, studentId ->
                val studentName = students.firstOrNull { it.id == studentId }?.name ?: "Unknown"
                StudentData(name = studentName, position = "$prefix ${index + 1}")
            }
        }

        return when (format) {
            DebateFormat.WSDC, DebateFormat.MODIFIED_WSDC, DebateFormat.AUSTRALS -> TeamsData(
                prop = mapStudents(composition.prop, "Prop"),
                opp = mapStudents(composition.opp, "Opp")
            )
            DebateFormat.BP -> TeamsData(
                og = mapStudents(composition.og, "OG"),
                oo = mapStudents(composition.oo, "OO"),
                cg = mapStudents(composition.cg, "CG"),
                co = mapStudents(composition.co, "CO")
            )
            DebateFormat.AP -> TeamsData(
                prop = mapStudents(composition.prop, "Gov"),
                opp = mapStudents(composition.opp, "Opp")
            )
        }
    }
}
