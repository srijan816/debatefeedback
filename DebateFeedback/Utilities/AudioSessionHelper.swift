//
//  AudioSessionHelper.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import AVFoundation
import Foundation

final class AudioSessionHelper {
    static let shared = AudioSessionHelper()

    private init() {}

    /// Configures audio session for recording and playback
    func configureForRecording() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        try session.setActive(true)
    }

    /// Configures audio session for playback only (bells)
    func configureForPlayback() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playback,
            mode: .default,
            options: []
        )

        try session.setActive(true)
    }

    /// Requests microphone permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Checks current microphone permission status
    var microphonePermissionStatus: Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied, .undetermined:
            return false
        @unknown default:
            return false
        }
    }

    /// Deactivates audio session
    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
