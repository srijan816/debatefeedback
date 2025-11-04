//
//  DebateFeedbackApp.swift
//  DebateFeedback
//
//  Created by Srijan on 10/24/25.
//

import SwiftUI
import SwiftData

@main
struct DebateFeedbackApp: App {
    @State private var coordinator = AppCoordinator()
    private let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .modelContainer(dataController.container)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // Generate device ID if not exists
        if UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.deviceId) == nil {
            let deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: Constants.UserDefaultsKeys.deviceId)
        }

        // Clean up old audio files
        FileManager.cleanupOldRecordings()
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentScreen {
                case .authentication:
                    AuthView()
                case .debateSetup:
                    DebateSetupView()
                case .timer(let session):
                    TimerMainView(debateSession: session)
                case .feedback(let session):
                    FeedbackListView(debateSession: session)
                case .history:
                    HistoryListView()
                }
            }
        }
    }
}
