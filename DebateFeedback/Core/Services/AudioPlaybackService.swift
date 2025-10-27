//
//  AudioPlaybackService.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import AVFoundation
import Foundation

@Observable
final class AudioPlaybackService: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private var currentFileURL: URL?

    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    // Timer to update playback progress
    private var progressTimer: Timer?

    // MARK: - Playback Control

    func play(from url: URL) throws {
        // Stop any current playback
        stop()

        // Configure audio session for playback
        try AudioSessionHelper.shared.configureForPlayback()

        // Create player
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()

        guard let player = audioPlayer else {
            throw PlaybackError.failedToInitialize
        }

        duration = player.duration
        currentFileURL = url

        // Start playback
        guard player.play() else {
            throw PlaybackError.failedToStart
        }

        isPlaying = true
        startProgressTimer()
    }

    func pause() {
        guard let player = audioPlayer, isPlaying else { return }

        player.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func resume() {
        guard let player = audioPlayer, !isPlaying else { return }

        player.play()
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
        audioPlayer = nil
        currentFileURL = nil
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }

        player.currentTime = time
        currentTime = time
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Helper Properties

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Cleanup

    deinit {
        stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Playback decode error: \(error?.localizedDescription ?? "Unknown")")
        isPlaying = false
        stopProgressTimer()
    }
}

// MARK: - Playback Errors

enum PlaybackError: LocalizedError {
    case failedToInitialize
    case failedToStart
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .failedToInitialize:
            return "Failed to initialize audio player"
        case .failedToStart:
            return "Failed to start playback"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}
