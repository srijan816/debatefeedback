//
//  Constants.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import SwiftUI

enum Constants {

    // MARK: - API Configuration
    enum API {
        static let baseURL = "https://api.genalphai.com/api"
        static let requestTimeout: TimeInterval = 30.0
        static let uploadTimeout: TimeInterval = 120.0
        static let maxRetryAttempts = 3
        static let feedbackPollingInterval: TimeInterval = 5.0

        // Development mode
        static var useMockData = false
    }

    // MARK: - Audio Configuration
    enum Audio {
        static let fileExtension = "m4a"
        static let sampleRate: Double = 44100.0
        static let bitRate = 128000 // 128kbps
        static let numberOfChannels = 1 // Mono

        // Bell timings (in seconds)
        static let firstBellTime: TimeInterval = 60.0
        static let overtimeBellInterval: TimeInterval = 15.0

        // Audio file names
        static let bellSingleSound = "bell_1"
        static let bellDoubleSound = "bell_2"
        static let bellTripleSound = "bell_3"
    }

    // MARK: - Timer Configuration
    enum Timer {
        static let displayRefreshRate = 60 // FPS for timer updates
        static let timerAccuracyTolerance: TimeInterval = 0.1 // ±100ms
    }

    // MARK: - UI Colors
    enum Colors {
        // Primary colors
        static let primaryAction = Color.blue
        static let recordingActive = Color.red
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red

        // Team colors
        static let propTeam = Color.blue.opacity(0.2)
        static let oppTeam = Color.red.opacity(0.2)

        // BP Teams
        static let ogTeam = Color.blue.opacity(0.2)
        static let ooTeam = Color.red.opacity(0.2)
        static let cgTeam = Color.green.opacity(0.2)
        static let coTeam = Color.orange.opacity(0.2)

        // Status colors
        static let pending = Color.gray
        static let uploading = Color.blue
        static let uploaded = Color.green
        static let failed = Color.red
        static let processing = Color.orange
        static let complete = Color.green
    }

    // MARK: - UI Sizing
    enum Sizing {
        static let minimumTapTarget: CGFloat = 44.0
        static let buttonCornerRadius: CGFloat = 12.0
        static let cardCornerRadius: CGFloat = 16.0
        static let standardPadding: CGFloat = 16.0
        static let compactPadding: CGFloat = 8.0

        // Timer display
        static let timerFontSizeiPhone: CGFloat = 72.0
        static let timerFontSizeiPad: CGFloat = 120.0
    }

    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }

    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let deviceId = "com.debatefeedback.deviceId"
        static let authToken = "com.debatefeedback.authToken"
        static let currentTeacherId = "com.debatefeedback.teacherId"
        static let isGuestMode = "com.debatefeedback.isGuestMode"
        static let hasShownOnboarding = "com.debatefeedback.hasShownOnboarding"
    }

    // MARK: - File Management
    enum Files {
        static let audioDirectory = "Recordings"
        static let maxLocalStorageDays = 7 // Delete files older than 7 days
    }

    // MARK: - Debate Formats
    static let debateFormats: [DebateFormat] = [.wsdc, .modifiedWsdc, .bp, .ap, .australs]

    // MARK: - Validation
    enum Validation {
        static let minimumMotionLength = 5
        static let maximumMotionLength = 200
        static let minimumSpeakerName = 2
        static let maximumSpeakerName = 50
        static let minimumSpeechTime = 60 // 1 minute
        static let maximumSpeechTime = 900 // 15 minutes
    }

    // MARK: - Error Messages
    enum ErrorMessages {
        static let networkUnavailable = "No internet connection. Please check your network settings."
        static let uploadFailed = "Failed to upload recording. Tap to retry."
        static let microphonePermissionDenied = "Microphone access is required. Please enable it in Settings."
        static let recordingFailed = "Failed to start recording. Please try again."
        static let invalidMotion = "Please enter a valid motion (5-200 characters)."
        static let noStudentsSelected = "Please add at least one student to each team."
        static let teamAssignmentIncomplete = "Please assign all students to teams."
    }
}

// MARK: - Device Type Helper
extension Constants {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var timerFontSize: CGFloat {
        isIPad ? Sizing.timerFontSizeiPad : Sizing.timerFontSizeiPhone
    }
}
