//
//  AppCoordinator.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import SwiftUI

@Observable
final class AppCoordinator {
    enum Screen {
        case authentication
        case debateSetup
        case timer(debateSession: DebateSession)
        case feedback(debateSession: DebateSession)
        case history
    }

    var currentScreen: Screen = .authentication
    var navigationPath = [Screen]()

    // State management
    var isGuestMode: Bool = false
    var currentTeacher: Teacher?
    var currentDebateSession: DebateSession?

    init() {
        // Check if user was previously logged in
        checkPreviousSession()
    }

    // MARK: - Navigation Methods

    func navigateTo(_ screen: Screen) {
        currentScreen = screen
        navigationPath.append(screen)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            if let lastScreen = navigationPath.last {
                currentScreen = lastScreen
            } else {
                currentScreen = .authentication
            }
        }
    }

    func resetToRoot() {
        navigationPath.removeAll()
        currentScreen = .authentication
        currentDebateSession = nil
    }

    // MARK: - Authentication Flow

    func loginAsTeacher(_ teacher: Teacher) {
        self.currentTeacher = teacher
        self.isGuestMode = false
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.isGuestMode)
        navigateTo(.debateSetup)
    }

    func loginAsGuest() {
        self.isGuestMode = true
        self.currentTeacher = nil
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.isGuestMode)
        navigateTo(.debateSetup)
    }

    func logout() {
        currentTeacher = nil
        isGuestMode = false
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.isGuestMode)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.authToken)
        resetToRoot()
    }

    // MARK: - Debate Flow

    func startDebate(session: DebateSession) {
        self.currentDebateSession = session
        navigateTo(.timer(debateSession: session))
    }

    func finishDebate() {
        guard let session = currentDebateSession else { return }
        navigateTo(.feedback(debateSession: session))
    }

    func viewHistory() {
        navigateTo(.history)
    }

    // MARK: - Session Persistence

    private func checkPreviousSession() {
        let wasGuestMode = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isGuestMode)
        if wasGuestMode {
            // Guest sessions don't persist
            isGuestMode = false
        } else if UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentTeacherId) != nil {
            // Try to restore teacher session
            // This would normally query the database for the teacher
            // For now, we'll require re-login
            isGuestMode = false
        }
    }

    // MARK: - Helper Methods

    var canAccessHistory: Bool {
        !isGuestMode && currentTeacher != nil
    }

    var canAccessAutoPopulation: Bool {
        !isGuestMode && currentTeacher != nil
    }
}
