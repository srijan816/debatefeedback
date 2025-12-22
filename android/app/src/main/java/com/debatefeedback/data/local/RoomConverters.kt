package com.debatefeedback.data.local

import androidx.room.TypeConverter
import com.debatefeedback.domain.model.DebateFormat
import com.debatefeedback.domain.model.ProcessingStatus
import com.debatefeedback.domain.model.StudentLevel
import com.debatefeedback.domain.model.TeamComposition
import com.debatefeedback.domain.model.UploadStatus
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class RoomConverters {
    private val json = Json { ignoreUnknownKeys = true }

    @TypeConverter
    fun fromTeamComposition(composition: TeamComposition?): String? = composition?.let { json.encodeToString(it) }

    @TypeConverter
    fun toTeamComposition(raw: String?): TeamComposition? = raw?.let { json.decodeFromString(it) }

    @TypeConverter
    fun fromFormat(format: DebateFormat?): String? = format?.name

    @TypeConverter
    fun toFormat(value: String?): DebateFormat? = value?.let { DebateFormat.valueOf(it) }

    @TypeConverter
    fun fromLevel(level: StudentLevel?): String? = level?.name

    @TypeConverter
    fun toLevel(value: String?): StudentLevel? = value?.let { StudentLevel.valueOf(it) }

    @TypeConverter
    fun fromUploadStatus(status: UploadStatus?): String? = status?.name

    @TypeConverter
    fun toUploadStatus(value: String?): UploadStatus? = value?.let { UploadStatus.valueOf(it) }

    @TypeConverter
    fun fromProcessingStatus(status: ProcessingStatus?): String? = status?.name

    @TypeConverter
    fun toProcessingStatus(value: String?): ProcessingStatus? = value?.let { ProcessingStatus.valueOf(it) }
}
