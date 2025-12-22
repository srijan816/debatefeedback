package com.debatefeedback.domain.model

import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
@Entity(tableName = "teachers")
data class Teacher(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val deviceId: String,
    val authToken: String? = null,
    val isAdmin: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)

@Serializable
@Entity(tableName = "students")
data class Student(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val level: StudentLevel,
    val createdAt: Long = System.currentTimeMillis(),
    val sessionId: String? = null
)

@Serializable
@Entity(tableName = "speech_recordings")
data class SpeechRecording(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val speakerName: String,
    val speakerPosition: String,
    val studentId: String? = null,
    val localFilePath: String,
    val durationSeconds: Int,
    val recordedAt: Long = System.currentTimeMillis(),
    val uploadStatus: UploadStatus = UploadStatus.PENDING,
    val processingStatus: ProcessingStatus = ProcessingStatus.PENDING,
    val transcriptionStatus: ProcessingStatus = ProcessingStatus.PENDING,
    val feedbackStatus: ProcessingStatus = ProcessingStatus.PENDING,
    val feedbackUrl: String? = null,
    val speechId: String? = null,
    val feedbackContent: String? = null,
    val transcriptUrl: String? = null,
    val transcriptText: String? = null,
    val transcriptionErrorMessage: String? = null,
    val feedbackErrorMessage: String? = null,
    val uploadProgress: Double = 0.0,
    val debateSessionId: String
) {
    @Ignore
    val aggregatedStatus: ProcessingStatus = when {
        feedbackStatus == ProcessingStatus.FAILED || transcriptionStatus == ProcessingStatus.FAILED -> ProcessingStatus.FAILED
        feedbackStatus == ProcessingStatus.COMPLETE -> ProcessingStatus.COMPLETE
        feedbackStatus == ProcessingStatus.PROCESSING || transcriptionStatus == ProcessingStatus.COMPLETE -> ProcessingStatus.PROCESSING
        transcriptionStatus == ProcessingStatus.PROCESSING -> ProcessingStatus.PROCESSING
        else -> ProcessingStatus.PENDING
    }
}

@Serializable
@Entity(tableName = "debate_sessions")
data class DebateSession(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val motion: String,
    val format: DebateFormat,
    val studentLevel: StudentLevel,
    val speechTimeSeconds: Int,
    val replyTimeSeconds: Int? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val isGuestMode: Boolean = false,
    val teacherId: String? = null,
    val classId: String? = null,
    val scheduleId: String? = null,
    val backendDebateId: String? = null,
    val teamComposition: TeamComposition? = null
)
