//
//  HistoryListView.swift
//  DebateFeedback
//
//  Complete history view with filtering, search, and stats
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DebateSession.createdAt, order: .reverse)
    private var allSessions: [DebateSession]

    @State private var searchText = ""
    @State private var selectedFormat: DebateFormat?
    @State private var selectedLevel: StudentLevel?
    @State private var showFilters = false
    @State private var sessionToDelete: DebateSession?
    @State private var showDeleteConfirmation = false

    private var filteredSessions: [DebateSession] {
        allSessions.filter { session in
            let matchesSearch = searchText.isEmpty || session.motion.localizedCaseInsensitiveContains(searchText) ||
                session.students.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })

            let matchesFormat = selectedFormat == nil || session.format == selectedFormat
            let matchesLevel = selectedLevel == nil || session.studentLevel == selectedLevel

            return matchesSearch && matchesFormat && matchesLevel
        }
    }

    var body: some View {
        Group {
            if allSessions.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search motions or students")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.light()
                    showFilters.toggle()
                } label: {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(Constants.Colors.primaryBlue)
                }
                .accessibilityLabel("Filter button")
                .accessibilityHint("Toggle filters for format and level")
            }
        }
        .sheet(isPresented: $showFilters) {
            filtersSheet
        }
        .alert("Delete Debate", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Are you sure you want to delete this debate session? This action cannot be undone.")
        }
        .preferredColorScheme(ThemeManager.shared.preferredColorScheme)
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            // Summary stats
            if !allSessions.isEmpty {
                Section {
                    summaryStats
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Filtered results info
            if selectedFormat != nil || selectedLevel != nil {
                Section {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(Constants.Colors.primaryBlue)
                        Text("Showing \(filteredSessions.count) of \(allSessions.count) debates")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.textSecondary)
                        Spacer()
                        Button("Clear Filters") {
                            HapticManager.shared.light()
                            clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(Constants.Colors.primaryBlue)
                    }
                }
            }

            // Debate sessions
            Section {
                if filteredSessions.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredSessions, id: \.id) { session in
                        NavigationLink(destination: FeedbackListView(debateSession: session)) {
                            HistoryCard(session: session)
                        }
                        .accessibilityLabel("Debate session: \(session.motion)")
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(Constants.Gradients.primaryButton)

            VStack(spacing: 12) {
                Text("No Debate History")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.textPrimary)

                Text("Your past debates will appear here.\nCreate your first debate to get started!")
                    .font(.body)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                HapticManager.shared.medium()
                coordinator.navigateTo(.debateSetup)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Debate")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .gradientButtonStyle()
            .accessibilityLabel("Create debate button")
            .accessibilityHint("Navigate to debate setup screen")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.backgroundLight)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Constants.Colors.textTertiary)

            Text("No matching debates")
                .font(.headline)
                .foregroundColor(Constants.Colors.textPrimary)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        VStack(spacing: 16) {
            Text("Your Debate Statistics")
                .font(.headline)
                .foregroundColor(Constants.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                StatBox(
                    title: "Total Debates",
                    value: "\(allSessions.count)",
                    icon: "graduationcap.fill",
                    color: Constants.Colors.primaryBlue
                )

                StatBox(
                    title: "Students",
                    value: "\(totalUniqueStudents)",
                    icon: "person.3.fill",
                    color: Constants.Colors.softCyan
                )

                StatBox(
                    title: "Recordings",
                    value: "\(totalRecordings)",
                    icon: "mic.fill",
                    color: Constants.Colors.softPink
                )
            }
        }
        .padding()
        .background(Constants.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Filters Sheet

    private var filtersSheet: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Debate Format", selection: $selectedFormat) {
                        Text("All Formats").tag(nil as DebateFormat?)
                        ForEach(DebateFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format as DebateFormat?)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Student Level") {
                    Picker("Student Level", selection: $selectedLevel) {
                        Text("All Levels").tag(nil as StudentLevel?)
                        ForEach(StudentLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as StudentLevel?)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Button("Clear All Filters") {
                        HapticManager.shared.light()
                        clearFilters()
                    }
                    .foregroundColor(Constants.Colors.primaryBlue)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.light()
                        showFilters = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Computed Properties

    private var totalUniqueStudents: Int {
        var studentNames = Set<String>()
        for session in allSessions {
            for student in session.students {
                studentNames.insert(student.name)
            }
        }
        return studentNames.count
    }

    private var totalRecordings: Int {
        allSessions.reduce(0) { $0 + $1.recordings.count }
    }

    // MARK: - Actions

    private func clearFilters() {
        selectedFormat = nil
        selectedLevel = nil
    }

    private func deleteSessions(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        sessionToDelete = filteredSessions[index]
        showDeleteConfirmation = true
    }

    private func deleteSession() {
        guard let session = sessionToDelete else { return }

        HapticManager.shared.medium()

        // Delete all related recordings and students
        for recording in session.recordings {
            modelContext.delete(recording)
        }
        for student in session.students {
            modelContext.delete(student)
        }

        modelContext.delete(session)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete session: \(error)")
        }

        sessionToDelete = nil
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let session: DebateSession

    private var completionRate: Double {
        guard !session.recordings.isEmpty else { return 0 }
        let completed = session.recordings.filter { $0.processingStatus == .complete }.count
        return Double(completed) / Double(session.recordings.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Motion
            Text(session.motion)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Constants.Colors.textPrimary)
                .lineLimit(2)

            // Metadata
            HStack(spacing: 16) {
                Label(session.format.displayName, systemImage: "person.3")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)

                Label(session.studentLevel.displayName, systemImage: "graduationcap")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)

                if let date = session.createdAt {
                    Label(formattedDate(date), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }

            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.recordings.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.Colors.primaryBlue)
                    Text("Speeches")
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.Colors.complete)
                    Text("Processed")
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textTertiary)
            }
        }
        .padding()
        .background(Constants.Colors.cardBackground)
        .cornerRadius(12)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryListView()
            .environment(AppCoordinator())
            .modelContainer(DataController.shared.container)
    }
}
