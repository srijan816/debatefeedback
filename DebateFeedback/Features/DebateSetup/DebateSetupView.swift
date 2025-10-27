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
                    .padding()
                }

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Setup Debate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        coordinator.logout()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach([SetupViewModel.SetupStep.basicInfo, .students, .teamAssignment], id: \.self) { step in
                Rectangle()
                    .fill(stepIndex(step) <= stepIndex(viewModel.currentStep) ?
                          Constants.Colors.primaryAction : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
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

            VStack(alignment: .leading, spacing: 12) {
                Text("Motion")
                    .font(.headline)
                TextField("Enter debate motion", text: $viewModel.motion, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Format")
                    .font(.headline)
                Picker("Format", selection: $viewModel.selectedFormat) {
                    ForEach(DebateFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedFormat) { _, _ in
                    viewModel.updateTimeDefaults()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Student Level")
                    .font(.headline)
                Picker("Level", selection: $viewModel.studentLevel) {
                    ForEach(StudentLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speech Time")
                        .font(.subheadline)
                    Stepper("\(viewModel.speechTimeSeconds / 60) min",
                            value: $viewModel.speechTimeSeconds,
                            in: 60...900,
                            step: 60)
                }

                if viewModel.selectedFormat.hasReplySpeeches {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reply Time")
                            .font(.subheadline)
                        Stepper("\((viewModel.replyTimeSeconds ?? 180) / 60) min",
                                value: Binding(
                                    get: { viewModel.replyTimeSeconds ?? 180 },
                                    set: { viewModel.replyTimeSeconds = $0 }
                                ),
                                in: 60...300,
                                step: 30)
                    }
                }
            }
        }
    }

    // MARK: - Students Step

    private var studentsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Students")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                TextField("Student name", text: $viewModel.newStudentName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .onSubmit {
                        viewModel.addStudent()
                    }

                Button(action: viewModel.addStudent) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Constants.Colors.primaryAction)
                }
                .disabled(viewModel.newStudentName.isEmpty)
            }

            if viewModel.students.isEmpty {
                ContentUnavailableView(
                    "No Students Added",
                    systemImage: "person.3",
                    description: Text("Add students using the field above")
                )
                .frame(height: 200)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(viewModel.students.count) Students")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.students, id: \.id) { student in
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(student.name)

                                // Show team assignment if any
                                if let teamName = viewModel.getTeamName(for: student) {
                                    Text(teamName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Quick assign buttons
                            Button {
                                viewModel.assignToTeam(student, team: .prop)
                            } label: {
                                Text("Prop")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(viewModel.propTeam.contains(where: { $0.id == student.id }) ?
                                               Constants.Colors.propTeam : Constants.Colors.propTeam.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }

                            Button {
                                viewModel.assignToTeam(student, team: .opp)
                            } label: {
                                Text("Opp")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(viewModel.oppTeam.contains(where: { $0.id == student.id }) ?
                                               Constants.Colors.oppTeam : Constants.Colors.oppTeam.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }

                            Button {
                                viewModel.removeStudent(student)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
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
        HStack {
            if viewModel.currentStep != .basicInfo {
                Button("Back") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.currentStep == .teamAssignment {
                Button("Start Debate") {
                    startDebate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCreatingDebate)
            } else {
                Button("Next") {
                    viewModel.nextStep()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private func startDebate() {
        guard let session = viewModel.createDebate(
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

    var body: some View {
        Text(student.name)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Constants.Colors.primaryAction.opacity(0.2))
            .foregroundColor(Constants.Colors.primaryAction)
            .cornerRadius(16)
            .draggable(student.id.uuidString)
    }
}

struct TeamDropZone: View {
    let title: String
    let students: [Student]
    let allStudents: [Student]
    let color: Color
    let onDrop: (Student) -> Void
    let onRemove: (Student) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Array(students.enumerated()), id: \.element.id) { index, student in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(student.name)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            onRemove(student)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(6)
                }

                if students.isEmpty {
                    Text("Drop students here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .padding()
            .background(color)
            .cornerRadius(12)
            .dropDestination(for: String.self) { items, location in
                guard let studentIdString = items.first,
                      let studentId = UUID(uuidString: studentIdString),
                      let student = allStudents.first(where: { $0.id == studentId })
                else { return false }

                onDrop(student)
                return true
            }
        }
    }
}

#Preview {
    DebateSetupView()
        .environment(AppCoordinator())
        .modelContainer(DataController.shared.container)
}
