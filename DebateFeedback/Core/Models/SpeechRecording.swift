//
//  SpeechRecording.swift
//  DebateFeedback
//
//

import Foundation
import SwiftData

@Model
final class SpeechRecording {
    var id: UUID
    var speakerName: String
    var speakerPosition: String
    var localFilePath: String
    var durationSeconds: Int
    var uploadStatus: UploadStatus
    var processingStatus: ProcessingStatus
    var transcriptionStatus: ProcessingStatus
    var feedbackStatus: ProcessingStatus
    var feedbackUrl: String?
    var speechId: String? // Backend speech ID for fetching feedback
    var feedbackContent: String? // Cached feedback content
    var transcriptUrl: String?
    var transcriptText: String?
    var transcriptionErrorMessage: String?
    var feedbackErrorMessage: String?
    var recordedAt: Date
    var uploadProgress: Double

    // Relationships
    var debateSession: DebateSession?

    init(
        id: UUID = UUID(),
        speakerName: String,
        speakerPosition: String,
        localFilePath: String,
        durationSeconds: Int,
        debateSession: DebateSession? = nil
    ) {
        self.id = id
        self.speakerName = speakerName
        self.speakerPosition = speakerPosition
        self.localFilePath = localFilePath
        self.durationSeconds = durationSeconds
        self.uploadStatus = .pending
        self.processingStatus = .pending
        self.transcriptionStatus = .pending
        self.feedbackStatus = .pending
        self.recordedAt = Date()
        self.uploadProgress = 0.0
        self.debateSession = debateSession
    }
}

extension SpeechRecording {
    /// Returns a synthesized status that mirrors the slowest stage
    var aggregatedProcessingStatus: ProcessingStatus {
        if feedbackStatus == .failed || transcriptionStatus == .failed {
            return .failed
        }

        if feedbackStatus == .complete {
            return .complete
        }

        if feedbackStatus == .processing || transcriptionStatus == .complete {
            return .processing
        }

        if transcriptionStatus == .processing {
            return .processing
        }

        return .pending
    }

    func updateAggregatedStatus() {
        processingStatus = aggregatedProcessingStatus
    }

    var failureDetails: String? {
        if transcriptionStatus == .failed {
            return transcriptionErrorMessage ?? "Transcription failed"
        }
        if feedbackStatus == .failed {
            return feedbackErrorMessage ?? "Feedback generation failed"
        }
        return nil
    }
}

enum UploadStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .uploading: return "Uploading..."
        case .uploaded: return "Uploaded"
        case .failed: return "Failed"
        }
    }

    var isComplete: Bool {
        self == .uploaded
    }
}

enum ProcessingStatus: String, Codable {
    case pending
    case processing
    case complete
    case failed

    init(apiStatus: String?) {
        guard let value = apiStatus?.lowercased() else {
            self = .pending
            return
        }

        switch value {
        case "processing", "running", "in_progress":
            self = .processing
        case "complete", "completed", "done":
            self = .complete
        case "failed", "error":
            self = .failed
        default:
            self = .pending
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing..."
        case .complete: return "Complete"
        case .failed: return "Failed"
        }
    }

    var isComplete: Bool {
        self == .complete
    }
}
