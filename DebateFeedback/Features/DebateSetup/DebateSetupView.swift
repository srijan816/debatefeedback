//
//  DebateSetupView.swift
//  DebateFeedback
//
//

import SwiftUI
import SwiftData

struct DebateSetupView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = SetupViewModel()
    @FocusState private var isStudentNameFieldFocused: Bool
    @State private var assignmentContext: AssignmentContext?

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
        .sheet(item: $assignmentContext) { context in
            AssignmentSheet(
                context: context,
                unassignedStudents: viewModel.unassignedStudents(),
                availableTeams: availableTeams,
                teamTitle: teamTitle,
                maxSlots: { team in
                    viewModel.maxSlots(for: team)
                },
                teamStudents: teamStudents(for:),
                onAssign: { student, team, position in
                    viewModel.assignToTeam(student, team: team, position: position)
                }
            )
        }
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
            Text("Add Students & Assign Teams")
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
                        UnassignedStudentRow(
                            student: student,
                            onAssign: {
                                presentAssignmentSheet(student: student, team: nil, position: nil)
                            },
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
    }

    private var availableTeams: [SetupViewModel.TeamType] {
        switch viewModel.selectedFormat.teamStructure {
        case .propOpp:
            return [.prop, .opp]
        case .britishParliamentary:
            return [.og, .oo, .cg, .co]
        case .asianParliamentary:
            return [.prop, .opp]
        }
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

    private func teamStudents(for team: SetupViewModel.TeamType) -> [Student] {
        switch team {
        case .prop:
            return viewModel.propTeam
        case .opp:
            return viewModel.oppTeam
        case .og:
            return viewModel.ogTeam
        case .oo:
            return viewModel.ooTeam
        case .cg:
            return viewModel.cgTeam
        case .co:
            return viewModel.coTeam
        }
    }

    private func presentAssignmentSheet(
        student: Student?,
        team: SetupViewModel.TeamType?,
        position: Int?
    ) {
        assignmentContext = AssignmentContext(
            student: student,
            team: team,
            position: position,
            allowsStudentSelection: student == nil
        )
    }

    private var twoTeamLayout: some View {
        HStack(spacing: 16) {
            TeamSlotBox(
                title: teamTitle(.prop),
                gradient: teamGradient(.prop),
                borderColor: teamBorderColor(.prop),
                students: viewModel.propTeam,
                maxSlots: viewModel.maxSlots(for: .prop),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .prop, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                }
            )

            TeamSlotBox(
                title: teamTitle(.opp),
                gradient: teamGradient(.opp),
                borderColor: teamBorderColor(.opp),
                students: viewModel.oppTeam,
                maxSlots: viewModel.maxSlots(for: .opp),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .opp, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
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
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .og, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                }
            )

            TeamSlotBox(
                title: teamTitle(.oo),
                gradient: teamGradient(.oo),
                borderColor: teamBorderColor(.oo),
                students: viewModel.ooTeam,
                maxSlots: viewModel.maxSlots(for: .oo),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .oo, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                }
            )

            TeamSlotBox(
                title: teamTitle(.cg),
                gradient: teamGradient(.cg),
                borderColor: teamBorderColor(.cg),
                students: viewModel.cgTeam,
                maxSlots: viewModel.maxSlots(for: .cg),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .cg, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                }
            )

            TeamSlotBox(
                title: teamTitle(.co),
                gradient: teamGradient(.co),
                borderColor: teamBorderColor(.co),
                students: viewModel.coTeam,
                maxSlots: viewModel.maxSlots(for: .co),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .co, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
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
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .prop, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                }
            )

            TeamSlotBox(
                title: teamTitle(.opp),
                gradient: teamGradient(.opp),
                borderColor: teamBorderColor(.opp),
                students: viewModel.oppTeam,
                maxSlots: viewModel.maxSlots(for: .opp),
                onSlotTap: { position, student in
                    presentAssignmentSheet(student: student, team: .opp, position: position)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
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

struct UnassignedStudentRow: View {
    let student: Student
    let onAssign: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAssign) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Constants.Gradients.primaryButton)
                    Text(student.name)
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                }
            }
            .buttonStyle(.plain)

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
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(12)
        .accessibilityHint("Tap to assign \(student.name)")
    }
}

struct TeamSlotBox: View {
    let title: String
    let gradient: LinearGradient
    let borderColor: Color
    let students: [Student]
    let maxSlots: Int
    let onSlotTap: (Int, Student?) -> Void
    let onRemove: (Student) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            slotsView
        }
        .padding()
        .background(backgroundView)
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
                if index < students.count {
                    filledSlotRow(position: position, student: students[index])
                } else {
                    emptySlotRow(position: position)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func filledSlotRow(position: Int, student: Student) -> some View {
        HStack(spacing: 10) {
            Text("\(position).")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)
                .frame(width: 18, alignment: .leading)
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
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onSlotTap(position, student)
        }
    }

    private func emptySlotRow(position: Int) -> some View {
        let isActive = position == students.count + 1
        HStack(spacing: 10) {
            Text("\(position).")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)
                .frame(width: 18, alignment: .leading)
            Text(isActive ? "Tap to assign" : "Fill above first")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)
            Spacer()
            Image(systemName: "plus.circle")
                .foregroundStyle(gradient)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [5]))
        )
        .contentShape(Rectangle())
        .opacity(isActive ? 1.0 : 0.45)
        .onTapGesture {
            if isActive {
                onSlotTap(position, nil)
            }
        }
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

struct AssignmentContext: Identifiable {
    let id = UUID()
    let student: Student?
    let team: SetupViewModel.TeamType?
    let position: Int?
    let allowsStudentSelection: Bool
}

struct AssignmentSheet: View {
    let context: AssignmentContext
    let unassignedStudents: [Student]
    let availableTeams: [SetupViewModel.TeamType]
    let teamTitle: (SetupViewModel.TeamType) -> String
    let maxSlots: (SetupViewModel.TeamType) -> Int
    let teamStudents: (SetupViewModel.TeamType) -> [Student]
    let onAssign: (Student, SetupViewModel.TeamType, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeam: SetupViewModel.TeamType
    @State private var selectedPosition: Int
    @State private var selectedStudentId: UUID?

    init(
        context: AssignmentContext,
        unassignedStudents: [Student],
        availableTeams: [SetupViewModel.TeamType],
        teamTitle: @escaping (SetupViewModel.TeamType) -> String,
        maxSlots: @escaping (SetupViewModel.TeamType) -> Int,
        teamStudents: @escaping (SetupViewModel.TeamType) -> [Student],
        onAssign: @escaping (Student, SetupViewModel.TeamType, Int) -> Void
    ) {
        self.context = context
        self.unassignedStudents = unassignedStudents
        self.availableTeams = availableTeams
        self.teamTitle = teamTitle
        self.maxSlots = maxSlots
        self.teamStudents = teamStudents
        self.onAssign = onAssign

        let defaultTeam = context.team ?? availableTeams.first ?? .prop
        _selectedTeam = State(initialValue: defaultTeam)
        _selectedPosition = State(initialValue: context.position ?? 1)
        _selectedStudentId = State(initialValue: context.student?.id ?? unassignedStudents.first?.id)
    }

    private var studentOptions: [Student] {
        guard context.allowsStudentSelection else {
            return context.student.map { [$0] } ?? []
        }

        var options = unassignedStudents
        if let student = context.student, !options.contains(where: { $0.id == student.id }) {
            options.insert(student, at: 0)
        }
        return options
    }

    private var selectedStudent: Student? {
        if let student = context.student, !context.allowsStudentSelection {
            return student
        }
        if let selectedId = selectedStudentId {
            return studentOptions.first(where: { $0.id == selectedId })
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Student") {
                    if context.allowsStudentSelection {
                        if studentOptions.isEmpty {
                            Text("No unassigned students available.")
                                .foregroundColor(Constants.Colors.textSecondary)
                        } else {
                            Picker("Student", selection: $selectedStudentId) {
                                ForEach(studentOptions, id: \.id) { student in
                                    Text(student.name).tag(Optional(student.id))
                                }
                            }
                        }
                    } else {
                        Text(context.student?.name ?? "Select student")
                            .font(.headline)
                    }
                }

                Section("Team") {
                    Picker("Team", selection: $selectedTeam) {
                        ForEach(availableTeams, id: \.self) { team in
                            Text(teamTitle(team)).tag(team)
                        }
                    }
                    .pickerStyle(availableTeams.count <= 2 ? .segmented : .menu)
                }

                Section("Position") {
                    Picker("Position", selection: $selectedPosition) {
                        let assignments = teamStudents(selectedTeam)
                        let isAlreadyInTeam = selectedStudent.map { student in
                            assignments.contains(where: { $0.id == student.id })
                        } ?? false
                        let maxPosition = isAlreadyInTeam
                            ? maxSlots(selectedTeam)
                            : min(maxSlots(selectedTeam), assignments.count + 1)
                        ForEach(1...maxPosition, id: \.self) { position in
                            let occupant = position <= assignments.count ? assignments[position - 1].name : nil
                            Text(occupant == nil ? "Position \(position)" : "Position \(position) · \(occupant)")
                                .tag(position)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Assign Student")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        guard let student = selectedStudent else { return }
                        onAssign(student, selectedTeam, selectedPosition)
                        dismiss()
                    }
                    .disabled(selectedStudent == nil)
                }
            }
            .onChange(of: selectedTeam) { newValue in
                let assignments = teamStudents(newValue)
                let isAlreadyInTeam = selectedStudent.map { student in
                    assignments.contains(where: { $0.id == student.id })
                } ?? false
                let maxPosition = isAlreadyInTeam
                    ? maxSlots(newValue)
                    : min(maxSlots(newValue), assignments.count + 1)
                if selectedPosition > maxPosition {
                    selectedPosition = maxPosition
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DebateSetupView()
        .environment(AppCoordinator())
        .modelContainer(DataController.shared.container)
}
