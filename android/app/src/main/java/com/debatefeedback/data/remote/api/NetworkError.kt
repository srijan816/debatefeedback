package com.debatefeedback.data.remote.api

sealed class NetworkError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    object InvalidUrl : NetworkError("Invalid URL")
    object Unauthorized : NetworkError("Unauthorized. Please log in again.")
    object NotFound : NetworkError("Resource not found")
    object Timeout : NetworkError("Request timed out. Please try again.")
    class Server(val code: Int, body: String?) : NetworkError("Server error (Status: $code)${body?.let { ": $it" } ?: ""}")
    class UploadFailed(reason: String) : NetworkError("Upload failed: $reason")
    class Unknown(cause: Throwable) : NetworkError(cause.localizedMessage ?: "Unknown error", cause)

    val isRetriable: Boolean
        get() = when (this) {
            Timeout -> true
            is Server -> code >= 500
            else -> false
        }
}
