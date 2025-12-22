package com.debatefeedback.services

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import androidx.core.content.ContextCompat
import com.debatefeedback.core.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class AudioRecordingService(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var startTime: Long = 0

    suspend fun startRecording(
        debateId: String,
        speakerName: String,
        position: String
    ): File = withContext(Dispatchers.IO) {
        stopInternal(deleteFile = false)
        val directory = ContextCompat.getExternalFilesDirs(context, Environment.DIRECTORY_MUSIC)
            .firstOrNull() ?: context.filesDir
        val recordingsDir = File(directory, Constants.Files.AUDIO_DIRECTORY)
        if (!recordingsDir.exists()) recordingsDir.mkdirs()
        val filename = "${debateId}_${speakerName}_${position}_${System.currentTimeMillis()}.${Constants.Audio.FILE_EXTENSION}"
        val file = File(recordingsDir, filename)

        val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else MediaRecorder()
        mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        mediaRecorder.setAudioEncodingBitRate(Constants.Audio.BIT_RATE)
        mediaRecorder.setAudioSamplingRate(Constants.Audio.SAMPLE_RATE)
        mediaRecorder.setOutputFile(file.absolutePath)
        mediaRecorder.prepare()
        mediaRecorder.start()

        recorder = mediaRecorder
        outputFile = file
        startTime = System.currentTimeMillis()
        file
    }

    suspend fun stopRecording(): RecordingResult? = withContext(Dispatchers.IO) {
        val file = outputFile ?: return@withContext null
        val duration = ((System.currentTimeMillis() - startTime) / 1000.0).toInt()
        stopInternal(deleteFile = false)
        RecordingResult(file, duration)
    }

    suspend fun cancelRecording() = withContext(Dispatchers.IO) {
        stopInternal(deleteFile = true)
    }

    private fun stopInternal(deleteFile: Boolean) {
        try {
            recorder?.apply {
                runCatching { stop() }
                runCatching { reset() }
                runCatching { release() }
            }
        } catch (_: Exception) {
        }
        recorder = null
        if (deleteFile) {
            outputFile?.delete()
        }
        outputFile = null
        startTime = 0
    }

    data class RecordingResult(val file: File, val durationSeconds: Int)
}
