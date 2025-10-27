//
//  SetupViewModel.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData

@Observable
final class SetupViewModel {
    // Motion
    var motion = ""

    // Format and settings
    var selectedFormat: DebateFormat = .wsdc
    var studentLevel: StudentLevel = .secondary
    var speechTimeSeconds: Int = 300
    var replyTimeSeconds: Int? = 180

    // Students
    var students: [Student] = []
    var newStudentName = ""

    // Team assignments
    var propTeam: [Student] = []
    var oppTeam: [Student] = []
    var ogTeam: [Student] = []
    var ooTeam: [Student] = []
    var cgTeam: [Student] = []
    var coTeam: [Student] = []

    // UI State
    var showError = false
    var errorMessage = ""
    var isCreatingDebate = false
    var currentStep: SetupStep = .basicInfo

    enum SetupStep {
        case basicInfo
        case students
        case teamAssignment
    }

    init() {
        updateTimeDefaults()
    }

    // MARK: - Step Navigation

    func nextStep() {
        switch currentStep {
        case .basicInfo:
            if validateBasicInfo() {
                currentStep = .students
            }
        case .students:
            if validateStudents() {
                currentStep = .teamAssignment
            }
        case .teamAssignment:
            break
        }
    }

    func previousStep() {
        switch currentStep {
        case .basicInfo:
            break
        case .students:
            currentStep = .basicInfo
        case .teamAssignment:
            currentStep = .students
        }
    }

    // MARK: - Student Management

    func addStudent() {
        guard newStudentName.isValidSpeakerName else {
            errorMessage = "Please enter a valid name (2-50 characters)"
            showError = true
            return
        }

        let student = Student(name: newStudentName, level: studentLevel)
        students.append(student)
        newStudentName = ""
    }

    func removeStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
        // Also remove from teams
        removeFromAllTeams(student)
    }

    // MARK: - Team Assignment

    func assignToTeam(_ student: Student, team: TeamType) {
        // Remove from all teams first
        removeFromAllTeams(student)

        // Add to specified team
        switch team {
        case .prop:
            propTeam.append(student)
        case .opp:
            oppTeam.append(student)
        case .og:
            ogTeam.append(student)
        case .oo:
            ooTeam.append(student)
        case .cg:
            cgTeam.append(student)
        case .co:
            coTeam.append(student)
        }
    }

    func removeFromAllTeams(_ student: Student) {
        propTeam.removeAll { $0.id == student.id }
        oppTeam.removeAll { $0.id == student.id }
        ogTeam.removeAll { $0.id == student.id }
        ooTeam.removeAll { $0.id == student.id }
        cgTeam.removeAll { $0.id == student.id }
        coTeam.removeAll { $0.id == student.id }
    }

    func unassignedStudents() -> [Student] {
        students.filter { student in
            !propTeam.contains(where: { $0.id == student.id }) &&
            !oppTeam.contains(where: { $0.id == student.id }) &&
            !ogTeam.contains(where: { $0.id == student.id }) &&
            !ooTeam.contains(where: { $0.id == student.id }) &&
            !cgTeam.contains(where: { $0.id == student.id }) &&
            !coTeam.contains(where: { $0.id == student.id })
        }
    }

    func getTeamName(for student: Student) -> String? {
        if propTeam.contains(where: { $0.id == student.id }) {
            return "Proposition"
        } else if oppTeam.contains(where: { $0.id == student.id }) {
            return "Opposition"
        } else if ogTeam.contains(where: { $0.id == student.id }) {
            return "Opening Government"
        } else if ooTeam.contains(where: { $0.id == student.id }) {
            return "Opening Opposition"
        } else if cgTeam.contains(where: { $0.id == student.id }) {
            return "Closing Government"
        } else if coTeam.contains(where: { $0.id == student.id }) {
            return "Closing Opposition"
        }
        return nil
    }

    // MARK: - Validation

    private func validateBasicInfo() -> Bool {
        guard motion.isValidMotion else {
            errorMessage = Constants.ErrorMessages.invalidMotion
            showError = true
            return false
        }
        return true
    }

    private func validateStudents() -> Bool {
        guard !students.isEmpty else {
            errorMessage = "Please add at least one student"
            showError = true
            return false
        }
        return true
    }

    private func validateTeamAssignment() -> Bool {
        switch selectedFormat {
        case .wsdc, .modifiedWsdc, .australs:
            if propTeam.isEmpty || oppTeam.isEmpty {
                errorMessage = Constants.ErrorMessages.noStudentsSelected
                showError = true
                return false
            }
        case .bp:
            if ogTeam.isEmpty || ooTeam.isEmpty || cgTeam.isEmpty || coTeam.isEmpty {
                errorMessage = "Please assign students to all four teams (OG, OO, CG, CO)"
                showError = true
                return false
            }
        case .ap:
            if propTeam.isEmpty || oppTeam.isEmpty {
                errorMessage = Constants.ErrorMessages.noStudentsSelected
                showError = true
                return false
            }
        }

        if !unassignedStudents().isEmpty {
            errorMessage = "Some students are not assigned to teams. Remove them or assign them."
            showError = true
            return false
        }

        return true
    }

    // MARK: - Debate Creation

    func createDebate(context: ModelContext, teacher: Teacher?) -> DebateSession? {
        guard validateTeamAssignment() else {
            return nil
        }

        let session = DebateSession(
            motion: motion,
            format: selectedFormat,
            studentLevel: studentLevel,
            speechTimeSeconds: speechTimeSeconds,
            replyTimeSeconds: replyTimeSeconds,
            isGuestMode: teacher == nil,
            teacher: teacher
        )

        // Set team composition
        var composition = TeamComposition()
        switch selectedFormat {
        case .wsdc, .modifiedWsdc, .australs:
            composition.prop = propTeam.map { $0.id.uuidString }
            composition.opp = oppTeam.map { $0.id.uuidString }
        case .bp:
            composition.og = ogTeam.map { $0.id.uuidString }
            composition.oo = ooTeam.map { $0.id.uuidString }
            composition.cg = cgTeam.map { $0.id.uuidString }
            composition.co = coTeam.map { $0.id.uuidString }
        case .ap:
            composition.prop = propTeam.map { $0.id.uuidString }
            composition.opp = oppTeam.map { $0.id.uuidString }
        }
        session.teamComposition = composition

        // Add students to session
        session.students = students

        // Insert into database
        context.insert(session)
        for student in students {
            context.insert(student)
        }

        try? context.save()

        return session
    }

    // MARK: - Helper Methods

    func updateTimeDefaults() {
        speechTimeSeconds = selectedFormat.defaultSpeechTime
        replyTimeSeconds = selectedFormat.defaultReplyTime
    }

    enum TeamType {
        case prop, opp, og, oo, cg, co
    }
}
