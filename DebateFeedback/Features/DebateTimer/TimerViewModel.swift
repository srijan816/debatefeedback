//
//  TimerViewModel.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData
import AVFoundation

@Observable
@MainActor
final class TimerViewModel {
    let debateSession: DebateSession
    private let modelContext: ModelContext

    // Services
    private var timerService: TimerService
    private let audioService = AudioRecordingService()
    private let playbackService = AudioPlaybackService()
    private let uploadService = UploadService.shared

    // State
    private(set) var currentSpeakerIndex = 0
    private(set) var speakers: [(name: String, position: String, studentId: String)] = []
    private(set) var isRecording = false
    private(set) var currentRecordingURL: URL?
    private(set) var recordings: [SpeechRecording] = []

    // Playback State
    private(set) var playingRecordingId: UUID?
    var isPlaying: Bool {
        playbackService.isPlaying
    }

    // UI State
    var showError = false
    var errorMessage = ""
    var uploadProgress: [UUID: Double] = [:]

    // Warning state tracking (to avoid repeated haptics)
    @ObservationIgnored private var has60sWarningFired = false
    @ObservationIgnored private var has30sWarningFired = false
    @ObservationIgnored private var has15sWarningFired = false

    init(debateSession: DebateSession, modelContext: ModelContext) {
        self.debateSession = debateSession
        self.modelContext = modelContext
        self.timerService = TimerService(speechDuration: TimeInterval(debateSession.speechTimeSeconds))

        setupSpeakers()
        checkMicrophonePermission()
    }

    // MARK: - Setup

    private func setupSpeakers() {
        guard let composition = debateSession.teamComposition else { return }
        let speakerOrder = composition.getSpeakerOrder(format: debateSession.format)

        // Convert to the format expected by speakers array
        speakers = speakerOrder.map { (studentId, position) in
            // Find student name from debateSession.students
            let studentName = debateSession.students?.first(where: { $0.id.uuidString == studentId })?.name ?? "Unknown"
            return (name: studentName, position: position, studentId: studentId)
        }
    }

    private func checkMicrophonePermission() {
        Task {
            let granted = await audioService.requestPermission()
            if !granted {
                errorMessage = Constants.ErrorMessages.microphonePermissionDenied
                showError = true
            }
        }
    }

    // MARK: - Timer Control

    var timerState: TimerService.State {
        timerService.state
    }

    var elapsedTime: TimeInterval {
        timerService.elapsedTime
    }

    var formattedTime: String {
        timerService.formattedTime
    }

    var isOvertime: Bool {
        timerService.isOvertime
    }

    var progressPercentage: Double {
        timerService.progressPercentage
    }

    // MARK: - Smart Timer Features

    /// Time remaining until expected end
    var timeRemaining: TimeInterval {
        let expectedDuration = TimeInterval(debateSession.speechTimeSeconds)
        return max(0, expectedDuration - elapsedTime)
    }

    /// Warning state based on time remaining
    enum WarningLevel {
        case none
        case oneMinute      // 60 seconds remaining
        case thirtySeconds  // 30 seconds remaining
        case fifteenSeconds // 15 seconds remaining
    }

    var currentWarningLevel: WarningLevel {
        if isOvertime {
            return .none
        }

        let remaining = timeRemaining
        if remaining <= 15 {
            return .fifteenSeconds
        } else if remaining <= 30 {
            return .thirtySeconds
        } else if remaining <= 60 {
            return .oneMinute
        } else {
            return .none
        }
    }

    /// Average speech time from completed recordings
    var averageSpeechTime: TimeInterval? {
        guard !recordings.isEmpty else { return nil }
        let total = recordings.reduce(0) { $0 + TimeInterval($1.durationSeconds) }
        return total / Double(recordings.count)
    }

    var formattedAverageSpeechTime: String? {
        guard let avg = averageSpeechTime else { return nil }
        let minutes = Int(avg) / 60
        let seconds = Int(avg) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Predicted total debate duration based on average
    var predictedTotalDuration: TimeInterval? {
        guard let avg = averageSpeechTime else { return nil }
        return avg * Double(speakers.count)
    }

    var formattedPredictedDuration: String? {
        guard let total = predictedTotalDuration else { return nil }
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Check and fire warnings with haptic feedback
    func checkAndFireWarnings() {
        guard isRecording && !isOvertime else {
            // Reset warning flags when not recording or in overtime
            if !isRecording {
                has60sWarningFired = false
                has30sWarningFired = false
                has15sWarningFired = false
            }
            return
        }

        switch currentWarningLevel {
        case .oneMinute:
            if !has60sWarningFired {
                HapticManager.shared.warning()
                has60sWarningFired = true
            }
        case .thirtySeconds:
            if !has30sWarningFired {
                HapticManager.shared.warning()
                has30sWarningFired = true
            }
        case .fifteenSeconds:
            if !has15sWarningFired {
                HapticManager.shared.warning()
                has15sWarningFired = true
            }
        case .none:
            break
        }
    }

    func startTimer() {
        guard !isRecording else { return }

        do {
            // Start recording
            let url = try audioService.startRecording(
                debateId: debateSession.id.uuidString,
                speakerName: currentSpeaker.name,
                position: currentSpeaker.position
            )

            currentRecordingURL = url
            isRecording = true

            // Start timer
            timerService.start()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func stopTimer() {
        guard isRecording else { return }

        // Stop recording
        guard let result = audioService.stopRecording() else {
            errorMessage = "Failed to stop recording"
            showError = true
            return
        }

        // Stop timer
        timerService.stop()

        isRecording = false
        currentRecordingURL = nil

        // Create recording record
        let recording = SpeechRecording(
            speakerName: currentSpeaker.name,
            speakerPosition: currentSpeaker.position,
            localFilePath: result.url.path,
            durationSeconds: Int(result.duration),
            debateSession: debateSession
        )

        modelContext.insert(recording)
        recordings.append(recording)

        try? modelContext.save()

        // Start upload
        uploadRecording(recording)

        // Move to next speaker automatically
        if currentSpeakerIndex < speakers.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.nextSpeaker()
            }
        }
    }

    /// Ring the bell manually when user taps the bell icon
    func ringBell() {
        timerService.ringBellManually()
    }

    // MARK: - Speaker Navigation

    var currentSpeaker: (name: String, position: String, studentId: String) {
        speakers[currentSpeakerIndex]
    }

    var canGoBack: Bool {
        currentSpeakerIndex > 0
    }

    var canGoForward: Bool {
        currentSpeakerIndex < speakers.count - 1
    }

    var speakerProgress: String {
        "\(currentSpeakerIndex + 1) / \(speakers.count)"
    }

    func nextSpeaker() {
        guard canGoForward && !isRecording else { return }

        currentSpeakerIndex += 1
        timerService.reset()

        // Reset warning flags for new speaker
        has60sWarningFired = false
        has30sWarningFired = false
        has15sWarningFired = false
    }

    func previousSpeaker() {
        guard canGoBack && !isRecording else { return }

        currentSpeakerIndex -= 1
        timerService.reset()

        // Reset warning flags for new speaker
        has60sWarningFired = false
        has30sWarningFired = false
        has15sWarningFired = false
    }

    // MARK: - Upload Management

    private func uploadRecording(_ recording: SpeechRecording) {
        Task {
            do {
                recording.uploadStatus = .uploading
                try? modelContext.save()

                let speechId = try await uploadService.uploadSpeech(
                    recording: recording,
                    debateSession: debateSession
                ) { progress in
                    Task { @MainActor in
                        recording.uploadProgress = progress
                        self.uploadProgress[recording.id] = progress
                    }
                }

                recording.uploadStatus = .uploaded
                recording.processingStatus = .processing
                recording.speechId = speechId // Store the speech ID
                try? modelContext.save()

                // Start polling for feedback
                pollForFeedback(recording: recording, speechId: speechId)

            } catch {
                recording.uploadStatus = .failed
                try? modelContext.save()

                errorMessage = "Failed to upload \(recording.speakerName)'s speech: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    func retryUpload(for recording: SpeechRecording) {
        uploadRecording(recording)
    }

    // MARK: - Feedback Polling

    private func pollForFeedback(recording: SpeechRecording, speechId: String) {
        Task {
            var attempts = 0
            let maxAttempts = 60 // 5 minutes max

            while attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: UInt64(Constants.API.feedbackPollingInterval * 1_000_000_000))

                do {
                    let status: SpeechStatusResponse = try await APIClient.shared.request(
                        endpoint: .getSpeechStatus(speechId: speechId)
                    )

                    if status.status == "complete", let url = status.googleDocUrl {
                        recording.processingStatus = .complete
                        recording.feedbackUrl = url
                        try? modelContext.save()
                        return
                    } else if status.status == "failed" {
                        recording.processingStatus = .failed
                        try? modelContext.save()
                        return
                    }

                } catch {
                    print("Polling error: \(error)")
                }

                attempts += 1
            }

            // Timeout
            recording.processingStatus = .failed
            try? modelContext.save()
        }
    }

    // MARK: - Completion

    var isDebateComplete: Bool {
        recordings.count == speakers.count
    }

    var completedSpeeches: Int {
        recordings.count
    }

    func viewFeedback() {
        // Navigation handled by coordinator
    }

    // MARK: - Playback Management

    func togglePlayback(for recording: SpeechRecording) {
        // If this recording is currently playing, pause it
        if playingRecordingId == recording.id && isPlaying {
            playbackService.pause()
            return
        }

        // If this recording was paused, resume it
        if playingRecordingId == recording.id && !isPlaying {
            playbackService.resume()
            return
        }

        // Otherwise, start playing this recording
        playRecording(recording)
    }

    private func playRecording(_ recording: SpeechRecording) {
        guard let url = URL(string: "file://\(recording.localFilePath)") else {
            errorMessage = "Invalid recording file path"
            showError = true
            return
        }

        // Check if file exists
        guard FileManager.default.fileExists(atPath: recording.localFilePath) else {
            errorMessage = "Recording file not found. It may have been deleted."
            showError = true
            return
        }

        do {
            try playbackService.play(from: url)
            playingRecordingId = recording.id
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
            showError = true
        }
    }

    func stopPlayback() {
        playbackService.stop()
        playingRecordingId = nil
    }

    func getPlaybackProgress(for recording: SpeechRecording) -> Double {
        guard playingRecordingId == recording.id else { return 0 }
        return playbackService.progress
    }

    func getPlaybackTime(for recording: SpeechRecording) -> String {
        guard playingRecordingId == recording.id else {
            return formatDuration(recording.durationSeconds)
        }
        return "\(playbackService.formattedCurrentTime) / \(playbackService.formattedDuration)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Cleanup

    deinit {
        // Note: Cannot reliably cancel recording in deinit due to async/MainActor requirements
        // Recording will be stopped when the service is deallocated
        playbackService.stop()
    }
}
