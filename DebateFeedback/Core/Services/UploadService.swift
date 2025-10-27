//
//  UploadService.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData

@Observable
final class UploadService: NSObject {
    static let shared = UploadService()

    private var activeUploads: [UUID: UploadTask] = [:]
    private let apiClient = APIClient.shared

    private override init() {
        super.init()
    }

    // MARK: - Upload Methods

    func uploadSpeech(
        recording: SpeechRecording,
        debateSession: DebateSession,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        let uploadId = recording.id

        // Create upload task
        let task = UploadTask(
            id: uploadId,
            fileURL: URL(fileURLWithPath: recording.localFilePath)
        )
        activeUploads[uploadId] = task

        // Prepare metadata
        let metadata: [String: Any] = [
            "speaker_name": recording.speakerName,
            "speaker_position": recording.speakerPosition,
            "duration_seconds": recording.durationSeconds,
            "student_level": debateSession.studentLevel.rawValue
        ]

        do {
            // Use backend debate ID if available, otherwise fall back to local ID
            let debateId = debateSession.backendDebateId ?? debateSession.id.uuidString

            // Attempt upload
            let response = try await apiClient.upload(
                endpoint: .uploadSpeech(debateId: debateId),
                fileURL: task.fileURL,
                metadata: metadata,
                progressHandler: progressHandler
            )

            // Remove from active uploads
            activeUploads.removeValue(forKey: uploadId)

            return response.speechId

        } catch {
            // Retry logic
            if let networkError = error as? NetworkError, networkError.isRetriable {
                return try await retryUpload(
                    recording: recording,
                    debateSession: debateSession,
                    task: task,
                    progressHandler: progressHandler,
                    attemptNumber: 1
                )
            }

            // Remove from active uploads
            activeUploads.removeValue(forKey: uploadId)
            throw error
        }
    }

    private func retryUpload(
        recording: SpeechRecording,
        debateSession: DebateSession,
        task: UploadTask,
        progressHandler: @escaping (Double) -> Void,
        attemptNumber: Int
    ) async throws -> String {
        guard attemptNumber <= Constants.API.maxRetryAttempts else {
            activeUploads.removeValue(forKey: recording.id)
            throw NetworkError.uploadFailed(reason: "Max retry attempts reached")
        }

        // Exponential backoff: 1s, 2s, 4s
        let delay = TimeInterval(pow(2.0, Double(attemptNumber - 1)))
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        print("Retrying upload (attempt \(attemptNumber + 1)) for \(recording.speakerName)...")

        let metadata: [String: Any] = [
            "speaker_name": recording.speakerName,
            "speaker_position": recording.speakerPosition,
            "duration_seconds": recording.durationSeconds,
            "student_level": debateSession.studentLevel.rawValue
        ]

        do {
            // Use backend debate ID if available, otherwise fall back to local ID
            let debateId = debateSession.backendDebateId ?? debateSession.id.uuidString

            let response = try await apiClient.upload(
                endpoint: .uploadSpeech(debateId: debateId),
                fileURL: task.fileURL,
                metadata: metadata,
                progressHandler: progressHandler
            )

            activeUploads.removeValue(forKey: recording.id)
            return response.speechId

        } catch {
            if let networkError = error as? NetworkError, networkError.isRetriable {
                return try await retryUpload(
                    recording: recording,
                    debateSession: debateSession,
                    task: task,
                    progressHandler: progressHandler,
                    attemptNumber: attemptNumber + 1
                )
            }

            activeUploads.removeValue(forKey: recording.id)
            throw error
        }
    }

    // MARK: - Upload Management

    func cancelUpload(for recordingId: UUID) {
        activeUploads.removeValue(forKey: recordingId)
    }

    func isUploading(recordingId: UUID) -> Bool {
        activeUploads[recordingId] != nil
    }

    // MARK: - Helper Types

    private struct UploadTask {
        let id: UUID
        let fileURL: URL
        var progress: Double = 0.0
    }
}
