package com.debatefeedback.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.debatefeedback.domain.model.DebateSession
import com.debatefeedback.domain.model.SpeechRecording
import com.debatefeedback.domain.model.Student
import com.debatefeedback.domain.model.Teacher

@Database(
    entities = [Teacher::class, Student::class, DebateSession::class, SpeechRecording::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(RoomConverters::class)
abstract class DebateFeedbackDatabase : RoomDatabase() {
    abstract fun debateDao(): DebateFeedbackDao

    companion object {
        fun build(context: Context): DebateFeedbackDatabase = Room.databaseBuilder(
            context.applicationContext,
            DebateFeedbackDatabase::class.java,
            "debate_feedback.db"
        ).fallbackToDestructiveMigration().build()
    }
}
