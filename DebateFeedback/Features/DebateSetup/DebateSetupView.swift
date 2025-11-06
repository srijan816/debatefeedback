//
//  DebateSetupView.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import SwiftUI
import SwiftData

struct DebateSetupView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = SetupViewModel()

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
                            case .students:
                                studentsStep
                            case .teamAssignment:
                                teamAssignmentStep
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                    }

                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationTitle("Setup Debate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Constants.Colors.backgroundLight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
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

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach([SetupViewModel.SetupStep.basicInfo, .students, .teamAssignment], id: \.self) { step in
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
        case .students: return 1
        case .teamAssignment: return 2
        }
    }

    // MARK: - Basic Info Step

    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DebateFormat.allCases, id: \.self) { format in
                            Button {
                                viewModel.selectedFormat = format
                                viewModel.updateTimeDefaults()
                            } label: {
                                Text(format.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.selectedFormat == format ?
                                        Constants.Gradients.primaryButton :
                                        LinearGradient(colors: [Constants.Colors.backgroundSecondary], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(viewModel.selectedFormat == format ? .white : Constants.Colors.textPrimary)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                viewModel.selectedFormat == format ?
                                                Constants.Colors.primaryBlue :
                                                Constants.Colors.textTertiary.opacity(0.3),
                                                lineWidth: viewModel.selectedFormat == format ? 2 : 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Student Level")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textSecondary)

                HStack(spacing: 12) {
                    ForEach(StudentLevel.allCases, id: \.self) { level in
                        Button {
                            viewModel.studentLevel = level
                        } label: {
                            Text(level.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.studentLevel == level ?
                                    LinearGradient(colors: [Constants.Colors.softPink], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Constants.Colors.backgroundSecondary], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(viewModel.studentLevel == level ? .white : Constants.Colors.textPrimary)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            viewModel.studentLevel == level ?
                                            Constants.Colors.softPink :
                                            Constants.Colors.textTertiary.opacity(0.3),
                                            lineWidth: viewModel.studentLevel == level ? 2 : 1
                                        )
                                )
                        }
                    }
                }
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

    // MARK: - Students Step

    private var studentsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Students")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TextField("Enter student name", text: $viewModel.newStudentName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .onSubmit {
                            if viewModel.isStudentNameValid {
                                viewModel.addStudent()
                            }
                        }
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
                        .accessibilityLabel("Student name text field")
                        .accessibilityHint("Enter a student name between 2 and 50 characters")

                    Button(action: {
                        HapticManager.shared.medium()
                        viewModel.addStudent()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
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

            if viewModel.isLoadingSchedule {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading roster...")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .softCard(backgroundColor: Constants.Colors.cardBackground, borderColor: Constants.Colors.textTertiary.opacity(0.2), cornerRadius: 16)

            } else if viewModel.students.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundStyle(Constants.Gradients.primaryButton)
                    Text("No Students Added")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                    Text("Add students using the field above")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                    if let notice = viewModel.scheduleNotice {
                        Text(notice)
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .padding()
                .glassmorphism(borderColor: Constants.Colors.softCyan)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(viewModel.students.count) Students Added")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textSecondary)

                    ForEach(viewModel.students, id: \.id) { student in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Constants.Gradients.primaryButton)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(student.name.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(student.name)
                                    .foregroundColor(Constants.Colors.textPrimary)
                                    .fontWeight(.medium)

                                if let teamName = viewModel.getTeamName(for: student) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Constants.Colors.softPink)
                                            .frame(width: 6, height: 6)
                                        Text(teamName)
                                            .font(.caption2)
                                            .foregroundColor(Constants.Colors.textSecondary)
                                    }
                                }
                            }

                            Spacer()

                            // Toggle-style team buttons
                            HStack(spacing: 8) {
                                Button {
                                    viewModel.assignToTeam(student, team: .prop)
                                } label: {
                                    Text("Prop")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            viewModel.propTeam.contains(where: { $0.id == student.id }) ?
                                            Constants.Gradients.propTeam :
                                            LinearGradient(colors: [Constants.Colors.backgroundSecondary], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .foregroundColor(viewModel.propTeam.contains(where: { $0.id == student.id }) ? .white : Constants.Colors.textPrimary)
                                        .cornerRadius(12)
                                }

                                Button {
                                    viewModel.assignToTeam(student, team: .opp)
                                } label: {
                                    Text("Opp")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            viewModel.oppTeam.contains(where: { $0.id == student.id }) ?
                                            Constants.Gradients.oppTeam :
                                            LinearGradient(colors: [Constants.Colors.backgroundSecondary], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .foregroundColor(viewModel.oppTeam.contains(where: { $0.id == student.id }) ? .white : Constants.Colors.textPrimary)
                                        .cornerRadius(12)
                                }

                                Button {
                                    viewModel.removeStudent(student)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Constants.Colors.softPink)
                                        .font(.title3)
                                }
                            }
                        }
                        .padding()
                        .background(Constants.Colors.backgroundSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Constants.Colors.softCyan.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Team Assignment Step

    private var teamAssignmentStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Assign Teams")
                .font(.title2)
                .fontWeight(.bold)

            // Unassigned students
            if !viewModel.unassignedStudents().isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drag students to teams:")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.unassignedStudents(), id: \.id) { student in
                                StudentChip(student: student)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }

            // Teams based on format
            switch viewModel.selectedFormat {
            case .wsdc, .modifiedWsdc, .australs:
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
    @State private var isDragging = false

    var body: some View {
        Text(student.name)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Constants.Gradients.secondaryButton)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(
                color: isDragging ? Constants.Colors.softPink.opacity(0.6) : Constants.Colors.softPink.opacity(0.3),
                radius: isDragging ? 12 : 8,
                x: 0,
                y: isDragging ? 8 : 4
            )
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .draggable(student.id.uuidString)
            .accessibilityLabel("Student chip: \(student.name)")
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

    @State private var isTargeted = false

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
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(gradient)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.textPrimary)
            }

            VStack(spacing: 8) {
                ForEach(Array(students.enumerated()), id: \.element.id) { index, student in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                            .frame(width: 20)
                        Text(student.name)
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Spacer()
                        Button {
                            HapticManager.shared.light()
                            onRemove(student)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.softPink)
                        }
                        .accessibilityLabel("Remove \(student.name)")
                        .accessibilityHint("Remove student from this team")
                    }
                    .padding(10)
                    .background(Constants.Colors.backgroundSecondary)
                    .cornerRadius(10)
                    .transition(.scale.combined(with: .opacity))
                }

                if students.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.circle.dotted")
                            .font(.title)
                            .foregroundStyle(gradient)
                            .symbolEffect(.bounce, value: isTargeted)
                        Text(isTargeted ? "Drop here" : "Drop to add")
                            .font(.caption)
                            .fontWeight(isTargeted ? .semibold : .regular)
                            .foregroundColor(isTargeted ? Constants.Colors.textPrimary : Constants.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .padding()
            .background(
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
            )
            .scaleEffect(isTargeted ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
            .dropDestination(for: String.self) { items, location in
                guard let studentIdString = items.first,
                      let studentId = UUID(uuidString: studentIdString),
                      let student = allStudents.first(where: { $0.id == studentId })
                else { return false }

                // Haptic feedback on successful drop
                HapticManager.shared.medium()

                // Call the drop handler
                onDrop(student)

                return true
            } isTargeted: { targeted in
                withAnimation {
                    isTargeted = targeted
                }
            }
            .accessibilityLabel("\(title) team drop zone")
            .accessibilityHint("Drop students here to assign them to \(title)")
        }
    }
}

#Preview {
    DebateSetupView()
        .environment(AppCoordinator())
        .modelContainer(DataController.shared.container)
}
