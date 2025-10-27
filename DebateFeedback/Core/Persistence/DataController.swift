//
//  DataController.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData

@Observable
final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            DebateSession.self,
            SpeechRecording.self,
            Student.self,
            Teacher.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // Convenience computed property for main context
    @MainActor
    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: - Helper Methods

    /// Creates a background context for async operations
    func backgroundContext() -> ModelContext {
        let context = ModelContext(container)
        return context
    }

    /// Saves the main context if there are changes
    @MainActor
    func save() {
        if mainContext.hasChanges {
            try? mainContext.save()
        }
    }
}
