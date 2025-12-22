package com.debatefeedback.repository

import com.debatefeedback.SessionManager
import com.debatefeedback.core.Constants
import com.debatefeedback.data.remote.api.DebateFeedbackApi
import com.debatefeedback.data.remote.api.UploadResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okio.Buffer
import okio.BufferedSink
import okio.source
import java.io.File

class UploadRepository(
    private val api: DebateFeedbackApi,
    private val sessionManager: SessionManager
) {
    private val textMediaType = "text/plain".toMediaType()

    suspend fun uploadSpeech(
        debateId: String,
        file: File,
        metadata: Map<String, String>,
        onProgress: suspend (Double) -> Unit
    ): UploadResponse = withContext(Dispatchers.IO) {
        val requestBody = ProgressRequestBody(file, metadata["content_type"] ?: "audio/m4a") { progress ->
            onProgress(progress)
        }
        val filePart = MultipartBody.Part.createFormData("audio_file", file.name, requestBody)
        val partMap = metadata.filterKeys { it != "content_type" }
            .mapValues { (_, value) -> value.toRequestBody(textMediaType) }
        api.uploadSpeech(debateId, filePart, partMap)
    }
}

private class ProgressRequestBody(
    private val file: File,
    private val contentType: String,
    private val listener: suspend (Double) -> Unit
) : RequestBody() {
    override fun contentType() = contentType.toMediaType()

    override fun contentLength(): Long = file.length()

    override fun writeTo(sink: BufferedSink) {
        file.source().use { source ->
            var total: Long = 0
            val buffer = Buffer()
            val length = contentLength().coerceAtLeast(1)
            var read: Long
            while (source.read(buffer, DEFAULT_BUFFER_SIZE.toLong()).also { read = it } != -1L) {
                sink.write(buffer, read)
                total += read
                val progress = total.toDouble() / length.toDouble()
                runBlocking { listener(progress) }
            }
        }
    }

    companion object {
        private const val DEFAULT_BUFFER_SIZE = 8 * 1024
    }
}
