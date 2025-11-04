//
//  SpeechRecording.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
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
    var feedbackUrl: String?
    var speechId: String? // Backend speech ID for fetching feedback
    var feedbackContent: String? // Cached feedback content
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
        self.recordedAt = Date()
        self.uploadProgress = 0.0
        self.debateSession = debateSession
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
