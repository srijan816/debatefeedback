package com.debatefeedback.domain.model

enum class UploadStatus {
    PENDING,
    UPLOADING,
    UPLOADED,
    FAILED
}

enum class ProcessingStatus {
    PENDING,
    PROCESSING,
    COMPLETE,
    FAILED;

    val isComplete: Boolean get() = this == COMPLETE

    companion object {
        fun fromApi(status: String?): ProcessingStatus = when (status?.lowercase()) {
            "processing", "running", "in_progress" -> PROCESSING
            "complete", "completed", "done" -> COMPLETE
            "failed", "error" -> FAILED
            else -> PENDING
        }
    }
}
