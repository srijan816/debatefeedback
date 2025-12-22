package com.debatefeedback.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.domain.model.Student
import com.debatefeedback.domain.model.Teacher
import kotlinx.coroutines.flow.Flow

@Dao
interface DebateFeedbackDao {
    @Query("SELECT * FROM debate_sessions ORDER BY createdAt DESC")
    fun observeSessions(): Flow<List<DebateSession>>

    @Query("SELECT * FROM debate_sessions WHERE id = :id")
    suspend fun getSession(id: String): DebateSession?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSession(session: DebateSession)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertStudents(students: List<Student>)

    @Query("SELECT * FROM students WHERE sessionId = :sessionId ORDER BY createdAt ASC")
    suspend fun getStudentsForSession(sessionId: String): List<Student>

    @Query("DELETE FROM students WHERE sessionId = :sessionId")
    suspend fun deleteStudentsForSession(sessionId: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertRecording(recording: SpeechRecording)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertRecordings(recordings: List<SpeechRecording>)

    @Update
    suspend fun updateRecording(recording: SpeechRecording)

    @Query("SELECT * FROM speech_recordings WHERE debateSessionId = :sessionId ORDER BY recordedAt ASC")
    fun observeRecordings(sessionId: String): Flow<List<SpeechRecording>>

    @Query("SELECT * FROM speech_recordings WHERE debateSessionId = :sessionId ORDER BY recordedAt ASC")
    suspend fun getRecordings(sessionId: String): List<SpeechRecording>

    @Query("DELETE FROM speech_recordings WHERE debateSessionId = :sessionId")
    suspend fun deleteRecordings(sessionId: String)

    @Delete
    suspend fun deleteRecording(recording: SpeechRecording)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTeacher(teacher: Teacher)

    @Query("SELECT * FROM teachers WHERE id = :id LIMIT 1")
    suspend fun getTeacher(id: String): Teacher?

    @Query("DELETE FROM teachers")
    suspend fun clearTeachers()

    @Transaction
    suspend fun replaceStudents(sessionId: String, students: List<Student>) {
        deleteStudentsForSession(sessionId)
        upsertStudents(students)
    }

    @Transaction
    suspend fun replaceRecordings(sessionId: String, recordings: List<SpeechRecording>) {
        deleteRecordings(sessionId)
        upsertRecordings(recordings)
    }
}
