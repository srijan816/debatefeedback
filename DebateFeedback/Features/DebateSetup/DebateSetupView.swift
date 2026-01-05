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

            // MARK: - Unassigned Students
            if viewModel.students.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundStyle(Constants.Gradients.primaryButton)
                    Text("No Students Yet")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                    Text("Add students above to assign them to teams")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .padding()
                .glassmorphism(borderColor: Constants.Colors.softCyan)
            } else if !viewModel.unassignedStudents().isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drag students to teams:")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.unassignedStudents(), id: \.id) { student in
                                StudentChip(student: student, onRemove: {
                                    viewModel.removeStudent(student)
                                })
                            }
                        }
                    }
                }
                .padding(.bottom)
            }

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

    private var twoTeamLayout: some View {
        HStack(spacing: 16) {
            TeamDropZone(
                title: "Proposition",
                students: viewModel.propTeam,
                allStudents: viewModel.students,
                color: Constants.Colors.propTeam,
                onDrop: { student in
                    viewModel.assignToTeam(student, team: .prop)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onReorder: { from, to in
                    viewModel.reorderTeam(.prop, from: from, to: to)
                }
            )

            TeamDropZone(
                title: "Opposition",
                students: viewModel.oppTeam,
                allStudents: viewModel.students,
                color: Constants.Colors.oppTeam,
                onDrop: { student in
                    viewModel.assignToTeam(student, team: .opp)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onReorder: { from, to in
                    viewModel.reorderTeam(.opp, from: from, to: to)
                }
            )
        }
    }

    private var britishParliamentaryLayout: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                TeamDropZone(
                    title: "OG",
                    students: viewModel.ogTeam,
                    allStudents: viewModel.students,
                    color: Constants.Colors.ogTeam,
                    onDrop: { student in
                        viewModel.assignToTeam(student, team: .og)
                    },
                    onRemove: { student in
                        viewModel.removeFromAllTeams(student)
                    },
                    onReorder: { from, to in
                        viewModel.reorderTeam(.og, from: from, to: to)
                    }
                )

                TeamDropZone(
                    title: "OO",
                    students: viewModel.ooTeam,
                    allStudents: viewModel.students,
                    color: Constants.Colors.ooTeam,
                    onDrop: { student in
                        viewModel.assignToTeam(student, team: .oo)
                    },
                    onRemove: { student in
                        viewModel.removeFromAllTeams(student)
                    },
                    onReorder: { from, to in
                        viewModel.reorderTeam(.oo, from: from, to: to)
                    }
                )
            }

            HStack(spacing: 16) {
                TeamDropZone(
                    title: "CG",
                    students: viewModel.cgTeam,
                    allStudents: viewModel.students,
                    color: Constants.Colors.cgTeam,
                    onDrop: { student in
                        viewModel.assignToTeam(student, team: .cg)
                    },
                    onRemove: { student in
                        viewModel.removeFromAllTeams(student)
                    },
                    onReorder: { from, to in
                        viewModel.reorderTeam(.cg, from: from, to: to)
                    }
                )

                TeamDropZone(
                    title: "CO",
                    students: viewModel.coTeam,
                    allStudents: viewModel.students,
                    color: Constants.Colors.coTeam,
                    onDrop: { student in
                        viewModel.assignToTeam(student, team: .co)
                    },
                    onRemove: { student in
                        viewModel.removeFromAllTeams(student)
                    },
                    onReorder: { from, to in
                        viewModel.reorderTeam(.co, from: from, to: to)
                    }
                )
            }
        }
    }

    private var asianParliamentaryLayout: some View {
        HStack(spacing: 16) {
            TeamDropZone(
                title: "Government",
                students: viewModel.propTeam,
                allStudents: viewModel.students,
                color: Constants.Colors.propTeam,
                onDrop: { student in
                    viewModel.assignToTeam(student, team: .prop)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onReorder: { from, to in
                    viewModel.reorderTeam(.prop, from: from, to: to)
                }
            )

            TeamDropZone(
                title: "Opposition",
                students: viewModel.oppTeam,
                allStudents: viewModel.students,
                color: Constants.Colors.oppTeam,
                onDrop: { student in
                    viewModel.assignToTeam(student, team: .opp)
                },
                onRemove: { student in
                    viewModel.removeFromAllTeams(student)
                },
                onReorder: { from, to in
                    viewModel.reorderTeam(.opp, from: from, to: to)
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

struct StudentChip: View {
    let student: Student
    let onRemove: () -> Void
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 8) {
            Text(student.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Constants.Gradients.secondaryButton)
        .cornerRadius(24)
        .shadow(
            color: isDragging ? Constants.Colors.softPink.opacity(0.6) : Constants.Colors.softPink.opacity(0.3),
            radius: isDragging ? 12 : 8,
            x: 0,
            y: isDragging ? 8 : 4
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .opacity(isDragging ? 0.8 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .onLongPressGesture(minimumDuration: 0.05, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isDragging = pressing
            }
        }) { } // Action handled by drag
        .draggable(student.id.uuidString)
        .accessibilityLabel("Student: \(student.name)")
        .accessibilityHint("Drag to assign to a team")
    }
}

struct TeamDropZone: View {
    let title: String
    let students: [Student]
    let allStudents: [Student]
    let color: Color
    let onDrop: (Student) -> Void
    let onRemove: (Student) -> Void
    let onReorder: (Int, Int) -> Void

    @State private var isTargeted = false
    @State private var draggedStudent: Student?

    private var gradient: LinearGradient {
        if title.contains("Prop") || title.contains("Government") || title == "OG" || title == "CG" {
            return Constants.Gradients.propTeam
        } else {
            return Constants.Gradients.oppTeam
        }
    }

    private var borderColor: Color {
        if title.contains("Prop") || title.contains("Government") || title == "OG" || title == "CG" {
            return Constants.Colors.softCyan
        } else {
            return Constants.Colors.softPink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundStyle(gradient)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 8) {
            studentsList
            emptyState
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(backgroundView)
        .scaleEffect(isTargeted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
        .dropDestination(for: String.self) { items, _ in
            handleDrop(items: items)
        } isTargeted: { targeted in
            withAnimation {
                isTargeted = targeted
            }
        }
        .accessibilityLabel("\(title) team drop zone")
        .accessibilityHint("Drop students here to assign them to \(title)")
    }

    // MARK: - Students List

    private var studentsList: some View {
        ForEach(Array(students.enumerated()), id: \.element.id) { index, student in
            studentRow(index: index, student: student)
        }
    }

    private func studentRow(index: Int, student: Student) -> some View {
        HStack(spacing: 12) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(Constants.Colors.textTertiary)
            
            Text("\(index + 1).")
                .font(.headline)
                .foregroundColor(Constants.Colors.textSecondary)
                .frame(width: 28)
            Text(student.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)
            Spacer()
            removeButton(for: student)
        }
        .padding(.vertical, 16) // Increased for easier touch
        .padding(.horizontal, 12)
        .frame(minHeight: 56) // Minimum touch target
        .background(studentRowBackground(for: student))
        .contentShape(Rectangle()) // Make entire row tappable/draggable
        .opacity(draggedStudent?.id == student.id ? 0.6 : 1.0)
        .draggable(student.id.uuidString) {
            dragPreview(for: student)
        }
        .dropDestination(for: String.self) { items, _ in
            handleReorder(items: items, toIndex: index, targetStudent: student)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func removeButton(for student: Student) -> some View {
        Button {
            HapticManager.shared.light()
            onRemove(student)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundColor(Constants.Colors.softPink)
        }
        .accessibilityLabel("Remove \(student.name)")
        .accessibilityHint("Remove student from this team")
    }

    private func studentRowBackground(for student: Student) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(draggedStudent?.id == student.id ? Constants.Colors.backgroundSecondary : Color.clear)
    }

    private func dragPreview(for student: Student) -> some View {
        Text(student.name)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(gradient)
            .foregroundColor(.white)
            .cornerRadius(20)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if students.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.circle.dotted")
                    .font(.system(size: 32))
                    .foregroundStyle(gradient)
                    .symbolEffect(.bounce, value: isTargeted)
                Text(isTargeted ? "Drop here" : "Drop to add")
                    .font(.headline)
                    .fontWeight(isTargeted ? .semibold : .medium)
                    .foregroundColor(isTargeted ? Constants.Colors.textPrimary : Constants.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Constants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isTargeted ? borderColor : borderColor.opacity(0.4),
                        lineWidth: isTargeted ? 3 : 1.5
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
            .shadow(
                color: isTargeted ? borderColor.opacity(0.3) : Color.black.opacity(0.08),
                radius: isTargeted ? 16 : 12,
                x: 0,
                y: 4
            )
    }

    // MARK: - Handlers

    private func handleDrop(items: [String]) -> Bool {
        guard let studentIdString = items.first,
              let studentId = UUID(uuidString: studentIdString),
              let student = allStudents.first(where: { $0.id == studentId })
        else { return false }

        HapticManager.shared.medium()
        onDrop(student)
        return true
    }

    private func handleReorder(items: [String], toIndex: Int, targetStudent: Student) -> Bool {
        guard let studentIdString = items.first,
              let droppedStudentId = UUID(uuidString: studentIdString),
              students.contains(where: { $0.id == droppedStudentId }),
              let fromIndex = students.firstIndex(where: { $0.id == droppedStudentId }),
              droppedStudentId != targetStudent.id
        else { return false }

        HapticManager.shared.light()
        onReorder(fromIndex, toIndex)
        return true
    }
}

#Preview {
    DebateSetupView()
        .environment(AppCoordinator())
        .modelContainer(DataController.shared.container)
}
