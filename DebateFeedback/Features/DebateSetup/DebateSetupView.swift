//
//  DebateSetupView.swift
//  DebateFeedback
//
//

import SwiftUI
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers
import UIKit

struct DebateSetupView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = SetupViewModel()
    @FocusState private var isStudentNameFieldFocused: Bool
    @State private var isUnassignedDropTargeted = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Light background with subtle glitters
                Constants.Colors.backgroundLight
                    .ignoresSafeArea()

                SubtleGlitterView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressBar

                    // Content based on current step
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.currentStep {
                            case .basicInfo:
                                basicInfoStep
                            case .teamAssignment:
                                teamAssignmentStep
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text field
                        UIApplication.shared.endEditing()
                        isStudentNameFieldFocused = false
                    }

                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationTitle("Setup Debate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Constants.Colors.backgroundLight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // Track setup started (first time)
                viewModel.trackSetupStarted()

                // If returning from a debate (coordinator has an active session),
                // restore the state and go to team assignment step
                if let session = coordinator.currentDebateSession {
                    restoreStateFromSession(session)
                }
            }
            .onDisappear {
                // Track abandonment if user leaves without completing
                if viewModel.currentStep != .teamAssignment || coordinator.currentDebateSession == nil {
                    viewModel.trackSetupAbandoned()
                }
            }
            // Removed .toolbarColorScheme(.light) to allow dark mode adaptation
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        coordinator.logout()
                    }
                    .foregroundColor(Constants.Colors.softPink)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .subtleBoundaryEffects(showTopEdge: true, showBottomEdge: true, intensity: 0.05)
        .preferredColorScheme(ThemeManager.shared.preferredColorScheme)
        .toast(
            isShowing: $viewModel.showToast,
            message: viewModel.toastMessage,
            icon: "checkmark.circle.fill",
            type: viewModel.toastType
        )
        .task {
            await viewModel.loadScheduleIfNeeded(for: coordinator.currentTeacher)
        }
    }

    // MARK: - State Restoration

    private func restoreStateFromSession(_ session: DebateSession) {
        // Restore basic info
        viewModel.motion = session.motion
        viewModel.selectedFormat = session.format
        viewModel.studentLevel = session.studentLevel
        viewModel.speechTimeSeconds = session.speechTimeSeconds

        // Restore students
        if let students = session.students {
            viewModel.students = students
        }

        // Restore team assignments from composition
        if let composition = session.teamComposition, let students = session.students {
            // Helper to find students by ID
            func findStudents(ids: [String]?) -> [Student] {
                guard let ids = ids else { return [] }
                return ids.compactMap { idString in
                    students.first { $0.id.uuidString == idString }
                }
            }

            viewModel.propTeam = findStudents(ids: composition.prop)
            viewModel.oppTeam = findStudents(ids: composition.opp)
            viewModel.ogTeam = findStudents(ids: composition.og)
            viewModel.ooTeam = findStudents(ids: composition.oo)
            viewModel.cgTeam = findStudents(ids: composition.cg)
            viewModel.coTeam = findStudents(ids: composition.co)
            viewModel.propReplySpeakerId = composition.propReply.flatMap { UUID(uuidString: $0) }
            viewModel.oppReplySpeakerId = composition.oppReply.flatMap { UUID(uuidString: $0) }
            viewModel.setReplySpeaker(team: .prop, studentId: viewModel.propReplySpeakerId)
            viewModel.setReplySpeaker(team: .opp, studentId: viewModel.oppReplySpeakerId)
        }

        // Go to team assignment step
        viewModel.currentStep = .teamAssignment
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach([SetupViewModel.SetupStep.basicInfo, .teamAssignment], id: \.self) { step in
                Rectangle()
                    .fill(stepIndex(step) <= stepIndex(viewModel.currentStep) ?
                          Constants.Gradients.primaryButton : LinearGradient(colors: [Constants.Colors.textTertiary.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
        .background(Constants.Colors.backgroundSecondary)
    }

    private func stepIndex(_ step: SetupViewModel.SetupStep) -> Int {
        switch step {
        case .basicInfo: return 0
        case .teamAssignment: return 1
        }
    }

    // MARK: - Basic Info Step

    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            if viewModel.hasScheduleDefaults {
                scheduleDefaultsBadge
            }

            if let notice = viewModel.scheduleNotice {
                scheduleNoticeView(notice)
            }

            if viewModel.selectedClassId != nil || !viewModel.availableAlternatives.isEmpty {
                classSelectionSection
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Motion")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textSecondary)
                    Spacer()
                    Text("\(viewModel.motionCharCount)/200")
                        .font(.caption2)
                        .foregroundColor(viewModel.motionCharCountColor)
                }

                TextField("Enter debate motion...", text: $viewModel.motion, axis: .vertical)
                    .padding()
                    .background(Constants.Colors.backgroundSecondary)
                    .foregroundColor(Constants.Colors.textPrimary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.motionBorderColor, lineWidth: 1.5)
                    )
                    .lineLimit(2...4)
                    .accessibilityLabel("Motion text field")
                    .accessibilityHint("Enter the debate motion between 5 and 200 characters")

                if !viewModel.motionValidationMessage.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(viewModel.motionValidationMessage)
                            .font(.caption2)
                    }
                    .foregroundColor(Constants.Colors.failed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Format")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textSecondary)

                Picker("Debate Format", selection: Binding(
                    get: { viewModel.selectedFormat },
                    set: { newValue in
                        viewModel.selectedFormat = newValue
                        viewModel.updateTimeDefaults()
                    }
                )) {
                    ForEach(DebateFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Constants.Colors.backgroundSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                )
            }



            // Time Settings Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Time Settings")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textSecondary)

                if viewModel.selectedFormat.hasReplySpeeches {
                    Toggle(
                        "Include reply speeches",
                        isOn: Binding(
                            get: { viewModel.includeReplySpeeches },
                            set: { viewModel.setReplySpeechesEnabled($0) }
                        )
                    )
                    .toggleStyle(SwitchToggleStyle(tint: Constants.Colors.primaryBlue))
                    .foregroundColor(Constants.Colors.textPrimary)
                }

                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Speech Time")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                        Text("\(viewModel.speechTimeSeconds / 60)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Constants.Gradients.primaryButton)
                        Text("min")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)

                        HStack(spacing: 16) {
                            Button {
                                if viewModel.speechTimeSeconds > 60 {
                                    viewModel.speechTimeSeconds -= 60
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Constants.Gradients.primaryButton)
                            }

                            Button {
                                if viewModel.speechTimeSeconds < 900 {
                                    viewModel.speechTimeSeconds += 60
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Constants.Gradients.primaryButton)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassmorphism(borderColor: Constants.Colors.softCyan)

                    if viewModel.selectedFormat.hasReplySpeeches,
                       viewModel.includeReplySpeeches,
                       let replyTime = viewModel.replyTimeSeconds {
                        VStack(spacing: 8) {
                            Text("Reply Time")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.textSecondary)
                            Text("\(replyTime / 60)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Constants.Gradients.secondaryButton)
                            Text("min")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.textSecondary)

                            HStack(spacing: 16) {
                                Button {
                                    if replyTime > 60 {
                                        viewModel.replyTimeSeconds = replyTime - 30
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Constants.Gradients.secondaryButton)
                                }

                                Button {
                                    if replyTime < 300 {
                                        viewModel.replyTimeSeconds = replyTime + 30
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Constants.Gradients.secondaryButton)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .glassmorphism(borderColor: Constants.Colors.softPink)
                    }
                }
            }
        }
    }

    private var classSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.classPickerOptions.isEmpty {
                let selectionBinding = Binding<String?>(
                    get: { viewModel.selectedClassId },
                    set: { newValue in
                        guard let newValue else { return }
                        viewModel.selectClass(withId: newValue)
                    }
                )

                Picker(selection: selectionBinding) {
                    ForEach(viewModel.classPickerOptions) { option in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Constants.Colors.textPrimary)
                            if let subtitle = option.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(Constants.Colors.textSecondary)
                            }
                        }
                        .tag(String?.some(option.id))
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(Constants.Colors.primaryBlue)

                        if let classId = viewModel.selectedClassId {
                            if let dayTime = viewModel.selectedClassDayTime {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dayTime)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Constants.Colors.textPrimary)
                                    Text(classId)
                                        .font(.caption)
                                        .foregroundColor(Constants.Colors.textSecondary)
                                }
                            } else {
                                Text("Class ID: \(classId)")
                                    .font(.subheadline)
                                    .foregroundColor(Constants.Colors.textPrimary)
                            }
                        }

                        Spacer()

                        if viewModel.isLoadingSchedule {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                }
                .pickerStyle(.menu)
            } else if let classId = viewModel.selectedClassId {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(Constants.Colors.primaryBlue)

                    if let dayTime = viewModel.selectedClassDayTime {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayTime)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Constants.Colors.textPrimary)
                            Text(classId)
                                .font(.caption)
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                    } else {
                        Text("Class ID: \(classId)")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.textPrimary)
                    }

                    Spacer()

                    if viewModel.isLoadingSchedule {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            } else if !viewModel.availableAlternatives.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "building.2")
                        .foregroundColor(Constants.Colors.primaryBlue)
                    Text("Select a class to auto-fill details")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                    Spacer()
                }
            }

            if !viewModel.availableAlternatives.isEmpty {
                Text("Other classes today")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.availableAlternatives, id: \.classId) { alternative in
                            alternativeButton(for: alternative)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .softCard(
            backgroundColor: Constants.Colors.cardBackground,
            borderColor: Constants.Colors.textTertiary.opacity(0.2),
            cornerRadius: 16
        )
    }

    private func alternativeButton(for alternative: ScheduleAlternative) -> some View {
        let isSelected = viewModel.selectedClassId == alternative.classId

        return Button {
            Task {
                await viewModel.switchToAlternative(alternative)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(alternative.dayTimeString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : Constants.Colors.textPrimary)

                Text(alternative.classId)
                    .font(.caption)
                    .foregroundColor(
                        isSelected ? Color.white.opacity(0.8) : Constants.Colors.textSecondary
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                        ? Constants.Gradients.primaryButton
                        : LinearGradient(
                            colors: [Constants.Colors.backgroundSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Constants.Colors.primaryBlue : Constants.Colors.textTertiary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoadingSchedule)
    }

    private func scheduleNoticeView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .softCard(
            backgroundColor: Constants.Colors.backgroundSecondary,
            borderColor: Constants.Colors.textTertiary.opacity(0.3),
            cornerRadius: 14
        )
    }

    private var scheduleDefaultsBadge: some View {
        let detail = viewModel.selectedClassDayTime ?? viewModel.selectedClassId ?? "Schedule"
        return HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("Auto-filled from \(detail)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(Constants.Colors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Team Assignment Step

    private var teamAssignmentStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Students & Drag to Assign")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            // MARK: - Add Student Section (Prominent)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Enter student name", text: $viewModel.newStudentName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .focused($isStudentNameFieldFocused)
                        .onSubmit {
                            if viewModel.isStudentNameValid {
                                viewModel.addStudent()
                                isStudentNameFieldFocused = false // Dismiss keyboard
                            }
                        }
                        .submitLabel(.done)
                        .padding()
                        .background(Constants.Colors.backgroundSecondary)
                        .foregroundColor(Constants.Colors.textPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.newStudentName.isEmpty
                                        ? Constants.Colors.softCyan.opacity(0.3)
                                        : (viewModel.isStudentNameValid ? Constants.Colors.complete.opacity(0.5) : Constants.Colors.failed.opacity(0.5)),
                                    lineWidth: 1.5
                                )
                        )
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isStudentNameFieldFocused = false
                                }
                            }
                        }
                        .accessibilityLabel("Student name text field")
                        .accessibilityHint("Enter a student name between 2 and 50 characters")

                    Button(action: {
                        HapticManager.shared.medium()
                        viewModel.addStudent()
                        isStudentNameFieldFocused = false // Dismiss keyboard after adding
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Constants.Gradients.primaryButton)
                    }
                    .disabled(!viewModel.isStudentNameValid)
                    .opacity(viewModel.isStudentNameValid ? 1.0 : 0.5)
                    .accessibilityLabel("Add student button")
                    .accessibilityHint(viewModel.isStudentNameValid ? "Tap to add student" : "Enter a valid name first")
                }

                if !viewModel.studentNameValidationMessage.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(viewModel.studentNameValidationMessage)
                            .font(.caption2)
                    }
                    .foregroundColor(Constants.Colors.failed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .glassmorphism(borderColor: Constants.Colors.softCyan)

            unassignedStudentsPanel

            // MARK: - Teams based on format
            switch viewModel.selectedFormat {
            case .wsdc, .australs:
                twoTeamLayout
            case .bp:
                britishParliamentaryLayout
            case .ap:
                asianParliamentaryLayout
            }

            if viewModel.selectedFormat.hasReplySpeeches && viewModel.shouldIncludeReplySpeeches {
                replySpeakerSelection
            }
        }
    }

    private var replySpeakerSelection: some View {
        let propCandidates = Array(viewModel.propTeam.prefix(2))
        let oppCandidates = Array(viewModel.oppTeam.prefix(2))
        let propAuto = viewModel.propTeam.count >= 4
        let oppAuto = viewModel.oppTeam.count >= 4

        return VStack(alignment: .leading, spacing: 12) {
            Text("Reply Speakers")
                .font(.headline)
                .foregroundColor(Constants.Colors.textPrimary)

            if viewModel.hasAutoReplySpeakers {
                Text("Reply speakers are auto-selected when a 4th speaker is assigned.")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
            } else {
                Text("Choose the reply speaker from the first two speakers.")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
            }

            replySpeakerRow(
                title: teamTitle(.prop),
                candidates: propCandidates,
                selection: Binding(
                    get: { viewModel.propReplySpeakerId },
                    set: { viewModel.setReplySpeaker(team: .prop, studentId: $0) }
                ),
                isAuto: propAuto,
                autoName: viewModel.propTeam.count >= 4 ? viewModel.propTeam[3].name : nil
            )

            replySpeakerRow(
                title: teamTitle(.opp),
                candidates: oppCandidates,
                selection: Binding(
                    get: { viewModel.oppReplySpeakerId },
                    set: { viewModel.setReplySpeaker(team: .opp, studentId: $0) }
                ),
                isAuto: oppAuto,
                autoName: viewModel.oppTeam.count >= 4 ? viewModel.oppTeam[3].name : nil
            )
        }
        .padding()
        .glassmorphism(borderColor: Constants.Colors.softPink)
    }

    private func replySpeakerRow(
        title: String,
        candidates: [Student],
        selection: Binding<UUID?>,
        isAuto: Bool,
        autoName: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) Reply")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)

            if isAuto {
                let name = autoName ?? "Auto"
                Text("\(name) (auto)")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.textPrimary)
            } else if candidates.count < 2 {
                Text("Add at least two speakers to choose.")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.textSecondary)
            } else {
                Picker("Reply Speaker", selection: selection) {
                    ForEach(candidates, id: \.id) { student in
                        Text(student.name).tag(Optional(student.id))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var unassignedStudentsPanel: some View {
        let unassigned = viewModel.unassignedStudents()
        let total = viewModel.students.count
        let assignedCount = max(0, total - unassigned.count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Students")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textPrimary)

                Text("\(unassigned.count) unassigned")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.backgroundSecondary)
                    .cornerRadius(10)

                Spacer()

                Text("\(assignedCount)/\(total) assigned")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
            }

            Text("Drag students into a team slot to assign. Drag within a team to reorder.")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)

            if viewModel.students.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 36))
                        .foregroundStyle(Constants.Gradients.primaryButton)
                    Text("Add students above to assign them to teams.")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else if unassigned.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Constants.Colors.complete)
                    Text("All students assigned.")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(unassigned, id: \.id) { student in
                        DraggableStudentRow(
                            student: student,
                            onRemove: {
                                viewModel.removeStudent(student)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .glassmorphism(borderColor: Constants.Colors.softCyan)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnassignedDropTargeted ? Constants.Colors.primaryBlue.opacity(0.7) : .clear, lineWidth: 2)
        )
        .dropDestination(for: StudentDragPayload.self, action: { items, _ in
            guard let payload = items.first else { return false }
            return handleUnassignDrop(payload)
        }, isTargeted: { isTargeting in
            isUnassignedDropTargeted = isTargeting
        })
    }

    private func teamTitle(_ team: SetupViewModel.TeamType) -> String {
        switch team {
        case .prop:
            return viewModel.selectedFormat == .ap ? "Government" : "Proposition"
        case .opp:
            return "Opposition"
        case .og:
            return "OG"
        case .oo:
            return "OO"
        case .cg:
            return "CG"
        case .co:
            return "CO"
        }
    }

    private func teamGradient(_ team: SetupViewModel.TeamType) -> LinearGradient {
        switch team {
        case .prop, .og:
            return Constants.Gradients.propTeam
        case .opp, .oo:
            return Constants.Gradients.oppTeam
        case .cg:
            return LinearGradient(
                colors: [Constants.Colors.cgTeam],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .co:
            return LinearGradient(
                colors: [Constants.Colors.coTeam],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func teamBorderColor(_ team: SetupViewModel.TeamType) -> Color {
        switch team {
        case .prop, .og:
            return Constants.Colors.softCyan
        case .opp, .oo:
            return Constants.Colors.softPink
        case .cg:
            return Constants.Colors.softMint
        case .co:
            return Constants.Colors.softPurple
        }
    }

    private func student(with id: UUID) -> Student? {
        viewModel.students.first { $0.id == id }
    }

    private func handleDrop(
        _ payload: StudentDragPayload,
        team: SetupViewModel.TeamType,
        position: Int?
    ) -> Bool {
        guard let student = student(with: payload.studentId) else { return false }
        viewModel.assignToTeam(student, team: team, position: position)
        return true
    }

    private func handleUnassignDrop(_ payload: StudentDragPayload) -> Bool {
        guard let student = student(with: payload.studentId) else { return false }
        viewModel.removeFromAllTeams(student)
        return true
    }

    private var twoTeamLayout: some View {
        HStack(spacing: 16) {
            TeamSlotBox(
                title: teamTitle(.prop),
                gradient: teamGradient(.prop),
                borderColor: teamBorderColor(.prop),
                students: viewModel.propTeam,
                maxSlots: viewModel.maxSlots(for: .prop),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .prop, position: position)
                }
            )

            TeamSlotBox(
                title: teamTitle(.opp),
                gradient: teamGradient(.opp),
                borderColor: teamBorderColor(.opp),
                students: viewModel.oppTeam,
                maxSlots: viewModel.maxSlots(for: .opp),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .opp, position: position)
                }
            )
        }
    }

    private var britishParliamentaryLayout: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            TeamSlotBox(
                title: teamTitle(.og),
                gradient: teamGradient(.og),
                borderColor: teamBorderColor(.og),
                students: viewModel.ogTeam,
                maxSlots: viewModel.maxSlots(for: .og),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .og, position: position)
                }
            )

            TeamSlotBox(
                title: teamTitle(.oo),
                gradient: teamGradient(.oo),
                borderColor: teamBorderColor(.oo),
                students: viewModel.ooTeam,
                maxSlots: viewModel.maxSlots(for: .oo),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .oo, position: position)
                }
            )

            TeamSlotBox(
                title: teamTitle(.cg),
                gradient: teamGradient(.cg),
                borderColor: teamBorderColor(.cg),
                students: viewModel.cgTeam,
                maxSlots: viewModel.maxSlots(for: .cg),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .cg, position: position)
                }
            )

            TeamSlotBox(
                title: teamTitle(.co),
                gradient: teamGradient(.co),
                borderColor: teamBorderColor(.co),
                students: viewModel.coTeam,
                maxSlots: viewModel.maxSlots(for: .co),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .co, position: position)
                }
            )
        }
    }

    private var asianParliamentaryLayout: some View {
        HStack(spacing: 16) {
            TeamSlotBox(
                title: teamTitle(.prop),
                gradient: teamGradient(.prop),
                borderColor: teamBorderColor(.prop),
                students: viewModel.propTeam,
                maxSlots: viewModel.maxSlots(for: .prop),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .prop, position: position)
                }
            )

            TeamSlotBox(
                title: teamTitle(.opp),
                gradient: teamGradient(.opp),
                borderColor: teamBorderColor(.opp),
                students: viewModel.oppTeam,
                maxSlots: viewModel.maxSlots(for: .opp),
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onDrop: { payload, position in
                    handleDrop(payload, team: .opp, position: position)
                }
            )
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .basicInfo {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Constants.Colors.textPrimary)
                    .frame(minWidth: 100)
                    .frame(height: Constants.Sizing.minimumTapTarget)
                    .padding(.horizontal, 20)
                    .background(Constants.Colors.backgroundSecondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Constants.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Spacer()

            if viewModel.currentStep == .teamAssignment {
                Button {
                    Task {
                        await startDebate()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isCreatingDebate {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Start Debate")
                            .fontWeight(.bold)
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(minWidth: 140)
                    .frame(height: Constants.Sizing.minimumTapTarget)
                    .padding(.horizontal, 28)
                }
                .gradientButtonStyle(isEnabled: !viewModel.isCreatingDebate)
                .disabled(viewModel.isCreatingDebate)
            } else {
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: 8) {
                        Text("Next")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(minWidth: 120)
                    .frame(height: Constants.Sizing.minimumTapTarget)
                    .padding(.horizontal, 24)
                }
                .gradientButtonStyle()
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Constants.Colors.backgroundLight)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
    }

    @MainActor
    private func startDebate() async {
        viewModel.isCreatingDebate = true
        defer { viewModel.isCreatingDebate = false }

        guard let session = await viewModel.createDebate(
            context: modelContext,
            teacher: coordinator.currentTeacher
        ) else {
            return
        }

        coordinator.startDebate(session: session)
    }
}

// MARK: - Supporting Views

struct DraggableStudentRow: View {
    let student: Student
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(student.name)
                .font(.headline)
                .foregroundColor(Constants.Colors.textPrimary)

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Constants.Colors.softPink)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(student.name)")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .draggable(StudentDragPayload(studentId: student.id))
        .accessibilityHint("Drag to assign \(student.name) to a team")
    }
}

struct StudentDragPayload: Codable, Hashable, Transferable {
    let studentId: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

struct TeamSlotBox: View {
    let title: String
    let gradient: LinearGradient
    let borderColor: Color
    let students: [Student]
    let maxSlots: Int
    let onRemove: (Student) -> Void
    let onDrop: (StudentDragPayload, Int?) -> Bool

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            slotsView
        }
        .padding()
        .background(backgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isTargeted ? borderColor.opacity(0.8) : .clear, lineWidth: 2)
        )
        .dropDestination(for: StudentDragPayload.self, action: { items, _ in
            guard let payload = items.first else { return false }
            return onDrop(payload, nil)
        }, isTargeted: { isTargeting in
            isTargeted = isTargeting
        })
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .foregroundStyle(gradient)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)
        }
    }

    private var slotsView: some View {
        VStack(spacing: 8) {
            ForEach(0..<maxSlots, id: \.self) { index in
                let position = index + 1
                TeamSlotRow(
                    position: position,
                    student: index < students.count ? students[index] : nil,
                    gradient: gradient,
                    borderColor: borderColor,
                    onRemove: onRemove,
                    onDrop: onDrop
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Constants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct TeamSlotRow: View {
    let position: Int
    let student: Student?
    let gradient: LinearGradient
    let borderColor: Color
    let onRemove: (Student) -> Void
    let onDrop: (StudentDragPayload, Int?) -> Bool

    @State private var isTargeted = false

    var body: some View {
        HStack(spacing: 10) {
            Text("\(position).")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)
                .frame(width: 18, alignment: .leading)

            if let student {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(Constants.Colors.textTertiary)
                Text(student.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.textPrimary)
                Spacer()
                Button {
                    onRemove(student)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Constants.Colors.softPink)
                }
                .buttonStyle(.borderless)
            } else {
                Text("Drop student here")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.textSecondary)
                Spacer()
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(gradient)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isTargeted ? borderColor.opacity(0.8) : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .draggableIfAvailable(student.map { StudentDragPayload(studentId: $0.id) })
        .dropDestination(for: StudentDragPayload.self, action: { items, _ in
            guard let payload = items.first else { return false }
            return onDrop(payload, position)
        }, isTargeted: { isTargeting in
            isTargeted = isTargeting
        })
    }

    private var rowBackground: some View {
        Group {
            if student != nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Constants.Colors.backgroundSecondary)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [5]))
            }
        }
    }
}

extension View {
    @ViewBuilder
    func draggableIfAvailable(_ payload: StudentDragPayload?) -> some View {
        if let payload {
            self.draggable(payload)
        } else {
            self
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    DebateSetupView()
        .environment(AppCoordinator())
        .modelContainer(DataController.shared.container)
}
