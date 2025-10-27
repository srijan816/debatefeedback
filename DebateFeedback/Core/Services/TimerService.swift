//
//  TimerService.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import AVFoundation
import Foundation
import UIKit

@Observable
@MainActor
final class TimerService {
    enum State {
        case idle
        case running
        case paused
        case stopped
    }

    private(set) var state: State = .idle
    private(set) var elapsedTime: TimeInterval = 0

    private var startTime: Date?
    private var displayLink: CADisplayLink?
    private var bellPlayers: [AVAudioPlayer] = []

    private let speechDuration: TimeInterval
    private var bellsScheduled: [TimeInterval] = []
    private var bellsFired: Set<Int> = []

    // Bell sounds
    private var singleBellPlayer: AVAudioPlayer?
    private var doubleBellPlayer: AVAudioPlayer?
    private var tripleBellPlayer: AVAudioPlayer?

    init(speechDuration: TimeInterval) {
        self.speechDuration = speechDuration
        setupBellPlayers()
        scheduleBells()
    }

    // MARK: - Timer Control

    func start() {
        guard state == .idle else { return }

        startTime = Date()
        state = .running
        elapsedTime = 0
        bellsFired.removeAll()

        // Setup display link for smooth updates
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        guard state == .running || state == .paused else { return }

        state = .stopped
        displayLink?.invalidate()
        displayLink = nil
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        displayLink?.invalidate()
        displayLink = nil
    }

    func resume() {
        guard state == .paused else { return }

        // Adjust start time to account for pause
        if startTime != nil {
            startTime = Date().addingTimeInterval(-elapsedTime)
        }

        state = .running
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func reset() {
        stop()
        state = .idle
        elapsedTime = 0
        startTime = nil
        bellsFired.removeAll()
    }

    // MARK: - Private Methods

    @objc private func update() {
        guard let start = startTime, state == .running else { return }

        elapsedTime = Date().timeIntervalSince(start)

        // Check if any bells need to fire
        checkAndFireBells()
    }

    private func scheduleBells() {
        bellsScheduled = []

        // 1 bell at 1:00
        if speechDuration >= 60 {
            bellsScheduled.append(60.0)
        }

        // 1 bell at (duration - 1:00)
        if speechDuration >= 120 {
            bellsScheduled.append(speechDuration - 60.0)
        }

        // 2 bells at duration
        bellsScheduled.append(speechDuration)

        // 3 bells every 15s after duration
        var overtimePoint = speechDuration + 15.0
        for _ in 0..<20 { // Max 20 overtime bells (5 minutes overtime)
            bellsScheduled.append(overtimePoint)
            overtimePoint += 15.0
        }
    }

    private func checkAndFireBells() {
        for (index, bellTime) in bellsScheduled.enumerated() {
            // Check if bell time has passed and hasn't been fired yet
            if elapsedTime >= bellTime && !bellsFired.contains(index) {
                bellsFired.insert(index)
                fireBell(for: bellTime)
            }
        }
    }

    private func fireBell(for time: TimeInterval) {
        let bellCount: Int

        if time == 60.0 || time == speechDuration - 60.0 {
            bellCount = 1
        } else if time == speechDuration {
            bellCount = 2
        } else {
            bellCount = 3 // Overtime
        }

        playBell(count: bellCount)
    }

    // MARK: - Bell Audio

    private func setupBellPlayers() {
        // In a real app, load actual bell sound files
        // For now, we'll use system sounds
        // You'll need to add bell_1.mp3, bell_2.mp3, bell_3.mp3 to Resources/Sounds

        if Bundle.main.url(forResource: "bell_1", withExtension: "mp3") == nil {
            print("Warning: Bell sound files not found. Please add bell_1.mp3, bell_2.mp3, bell_3.mp3 to Resources/Sounds")
            return
        }

        // Load bell sounds (placeholder - will use actual files)
        // if let bellURL = Bundle.main.url(forResource: "bell_1", withExtension: "mp3") {
        //     singleBellPlayer = try? AVAudioPlayer(contentsOf: bellURL)
        //     doubleBellPlayer = try? AVAudioPlayer(contentsOf: bellURL)
        //     tripleBellPlayer = try? AVAudioPlayer(contentsOf: bellURL)
        // }
    }

    private func playBell(count: Int) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Play system sound as placeholder
        AudioServicesPlaySystemSound(1103) // System bell sound

        // In production, play actual bell sounds:
        /*
        switch count {
        case 1:
            singleBellPlayer?.play()
        case 2:
            doubleBellPlayer?.play()
        case 3:
            tripleBellPlayer?.play()
        default:
            break
        }
        */

        print("🔔 Bell fired: \(count) ding(s) at \(elapsedTime.toMinutesSeconds())")
    }

    // MARK: - Manual Bell Control

    /// Manually trigger a single bell sound (e.g., when user taps the bell icon)
    func ringBellManually() {
        playBell(count: 1)
    }

    // MARK: - Computed Properties

    var isRunning: Bool {
        state == .running
    }

    var formattedTime: String {
        elapsedTime.toMinutesSeconds()
    }

    var isOvertime: Bool {
        elapsedTime > speechDuration
    }

    var progressPercentage: Double {
        min(elapsedTime / speechDuration, 1.0)
    }

    deinit {
        // Note: displayLink cleanup handled automatically when object is deallocated
        // Cannot use async Task in deinit as it creates a closure that outlives deinit
    }
}
