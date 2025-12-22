package com.debatefeedback.data.remote.api

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class LoginRequest(
    @SerialName("teacher_id") val teacherId: String,
    @SerialName("device_id") val deviceId: String
)

@Serializable
data class LoginResponse(
    val token: String,
    val teacher: TeacherResponse
)

@Serializable
data class TeacherResponse(
    val id: String,
    val name: String,
    @SerialName("is_admin") val isAdmin: Boolean = false
)

@Serializable
data class ScheduleResponse(
    @SerialName("class_id") val classId: String,
    val students: List<StudentResponse>,
    @SerialName("suggested_motion") val suggestedMotion: String? = null,
    val format: String,
    @SerialName("speech_time") val speechTime: Int,
    val alternatives: List<ScheduleAlternative>? = null,
    @SerialName("start_date_time") val startDateTime: String? = null,
    @SerialName("available_classes") val availableClasses: List<ClassInfo>? = null
) {
    @Serializable
data class ClassInfo(
        @SerialName("class_id") val classId: String,
        @SerialName("schedule_id") val scheduleId: String? = null,
        val source: String? = null,
        @SerialName("display_label") val displayLabel: String? = null,
        @SerialName("day_of_week") val dayOfWeek: Int? = null,
        @SerialName("day_name") val dayName: String? = null,
        @SerialName("start_time") val startTime: String? = null,
        @SerialName("end_time") val endTime: String? = null,
        val format: String? = null,
        @SerialName("speech_time") val speechTime: Int? = null,
        @SerialName("suggested_motion") val suggestedMotion: String? = null,
        val students: List<StudentResponse> = emptyList()
    )
}

@Serializable
data class ScheduleAlternative(
    @SerialName("class_id") val classId: String,
    @SerialName("start_time") val startTime: String,
    @SerialName("start_date_time") val startDateTime: String? = null
)

@Serializable
data class StudentResponse(
    val id: String,
    val name: String,
    val level: String,
    val grade: String? = null
)

@Serializable
data class CreateDebateRequest(
    val motion: String,
    val format: String,
    @SerialName("student_level") val studentLevel: String,
    @SerialName("speech_time_seconds") val speechTimeSeconds: Int,
    val teams: TeamsData,
    @SerialName("class_id") val classId: String? = null,
    @SerialName("schedule_id") val scheduleId: String? = null
)

@Serializable
data class TeamsData(
    val prop: List<StudentData>? = null,
    val opp: List<StudentData>? = null,
    val og: List<StudentData>? = null,
    val oo: List<StudentData>? = null,
    val cg: List<StudentData>? = null,
    val co: List<StudentData>? = null
)

@Serializable
data class StudentData(
    val name: String,
    val position: String
)

@Serializable
data class CreateDebateResponse(
    @SerialName("debate_id") val debateIdSnake: String? = null,
    val debateId: String? = null
) {
    val resolvedId: String
        get() = debateIdSnake ?: debateId ?: ""
}

@Serializable
data class UploadResponse(
    @SerialName("speech_id") val speechId: String,
    val status: String,
    @SerialName("processing_started") val processingStarted: Boolean = true
)

@Serializable
data class SpeechStatusResponse(
    val status: String,
    @SerialName("google_doc_url") val googleDocUrl: String? = null,
    @SerialName("error_message") val errorMessage: String? = null,
    @SerialName("transcription_status") val transcriptionStatus: String? = null,
    @SerialName("transcription_error") val transcriptionError: String? = null,
    @SerialName("feedback_status") val feedbackStatus: String? = null,
    @SerialName("feedback_error") val feedbackError: String? = null,
    @SerialName("transcript_url") val transcriptUrl: String? = null,
    @SerialName("transcript_text") val transcriptText: String? = null,
    @SerialName("transcript_download_url") val transcriptDownloadUrl: String? = null
)

@Serializable
data class FeedbackContentResponse(
    @SerialName("speech_id") val speechId: String,
    @SerialName("feedback_text") val feedbackText: String,
    val scores: Map<String, Double>? = null,
    val sections: List<FeedbackSection>? = null
) {
    @Serializable
data class FeedbackSection(
        val title: String,
        val content: String
    )
}

@Serializable
data class DebateHistoryResponse(
    val debates: List<DebateHistoryItem> = emptyList()
)

@Serializable
data class DebateHistoryItem(
    @SerialName("debate_id") val debateId: String,
    val motion: String,
    val date: String,
    val speeches: List<SpeechHistoryItem> = emptyList()
)

@Serializable
data class SpeechHistoryItem(
    @SerialName("speaker_name") val speakerName: String,
    @SerialName("feedback_url") val feedbackUrl: String? = null,
    val scores: Map<String, Double>? = null
)
