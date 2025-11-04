//
//  SetupViewModel.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class SetupViewModel {
    // Motion
    var motion = ""

    // Format and settings
    var selectedFormat: DebateFormat = .wsdc
    var studentLevel: StudentLevel = .secondary
    var speechTimeSeconds: Int = 300
    var replyTimeSeconds: Int? = 180 {
        didSet {
            if let value = replyTimeSeconds {
                lastReplyTimeSeconds = value
            }
        }
    }

    // Students
    var students: [Student] = []
    var newStudentName = ""
    var includeReplySpeeches = false

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
    var isLoadingSchedule = false
    var scheduleNotice: String?
    var selectedClassId: String?
    var availableAlternatives: [ScheduleAlternative] = []

    @ObservationIgnored private var hasLoadedSchedule = false
    @ObservationIgnored private var lastReplyTimeSeconds: Int?
    @ObservationIgnored private var cachedTeacher: Teacher?
    @ObservationIgnored private var cachedTimestamp: String?
    @ObservationIgnored private var scheduleCache: [String: ScheduleResponse] = [:]

    enum SetupStep {
        case basicInfo
        case students
        case teamAssignment
    }

    init() {
        updateTimeDefaults()
    }

    // MARK: - Prefill

    @MainActor
    func loadScheduleIfNeeded(for teacher: Teacher?) async {
        guard !hasLoadedSchedule, let teacher else { return }

        cachedTeacher = teacher
        cachedTimestamp = Date().iso8601String
        scheduleNotice = nil

        await loadSchedule(forClassId: nil)
        hasLoadedSchedule = true
    }

    @MainActor
    func switchToAlternative(_ alternative: ScheduleAlternative) async {
        guard alternative.classId != selectedClassId else { return }
        await loadSchedule(forClassId: alternative.classId)
    }

    @MainActor
    private func loadSchedule(forClassId classId: String?) async {
        guard let teacher = cachedTeacher else { return }

        scheduleNotice = nil

        if let classId,
           let cached = scheduleCache[classId] {
            applySchedule(cached)
            return
        }

        let timestamp = cachedTimestamp ?? Date().iso8601String
        if cachedTimestamp == nil {
            cachedTimestamp = timestamp
        }

        isLoadingSchedule = true
        defer { isLoadingSchedule = false }

        do {
            let response: ScheduleResponse = try await APIClient.shared.request(
                endpoint: .getCurrentSchedule(
                    teacherId: teacher.id.uuidString,
                    timestamp: timestamp,
                    classId: classId
                )
            )

            scheduleCache[response.classId] = response
            applySchedule(response)

        } catch let networkError as NetworkError {
            handleScheduleError(networkError)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleScheduleError(_ error: NetworkError) {
        switch error {
        case .notFound:
            scheduleNotice = "No schedule found for this time. You can enter details manually."
        default:
            errorMessage = error.localizedDescription
            showError = true
        }
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

    func createDebate(context: ModelContext, teacher: Teacher?) async -> DebateSession? {
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

        // Create debate on backend if not in mock mode
        if !Constants.API.useMockData {
            do {
                let backendDebateId = try await createDebateOnBackend(session: session)
                session.backendDebateId = backendDebateId
            } catch {
                errorMessage = "Failed to create debate on server: \(error.localizedDescription)"
                showError = true
                return nil
            }
        }

        // Insert into database
        context.insert(session)
        for student in students {
            context.insert(student)
        }

        try? context.save()

        return session
    }

    // MARK: - Schedule Helpers

    @MainActor
    private func applySchedule(_ response: ScheduleResponse) {
        selectedClassId = response.classId

        if let alternatives = response.alternatives {
            var seen = Set<String>()
            availableAlternatives = alternatives.compactMap { option in
                guard option.classId != response.classId else { return nil }
                if seen.insert(option.classId).inserted {
                    return option
                }
                return nil
            }
        } else {
            availableAlternatives = []
        }
        scheduleNotice = nil

        if let suggested = response.suggestedMotion {
            motion = suggested
        } else if motion.isEmpty {
            motion = ""
        }

        if let fetchedFormat = DebateFormat(rawValue: response.format) {
            selectedFormat = fetchedFormat
        }

        updateTimeDefaults()
        speechTimeSeconds = response.speechTime

        // Update student level based on the first student, if provided
        if let firstLevel = response.students.first?.level.lowercased(),
           let level = StudentLevel(rawValue: firstLevel) {
            studentLevel = level
        }

        // Replace current students with the class roster
        students = response.students.map { student in
            let level = StudentLevel(rawValue: student.level.lowercased()) ?? studentLevel
            let identifier = UUID(uuidString: student.id) ?? UUID()
            return Student(id: identifier, name: student.name, level: level)
        }

        // Reset teams to allow fresh assignment
        propTeam.removeAll()
        oppTeam.removeAll()
        ogTeam.removeAll()
        ooTeam.removeAll()
        cgTeam.removeAll()
        coTeam.removeAll()
    }

    private func createDebateOnBackend(session: DebateSession) async throws -> String {
        // Prepare teams data
        var teamsData = TeamsData()
        guard let composition = session.teamComposition else {
            throw NetworkError.unknown(NSError(domain: "No team composition", code: -1))
        }

        switch selectedFormat {
        case .wsdc, .modifiedWsdc, .australs:
            if let propIds = composition.prop {
                teamsData.prop = propIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "Prop \(index + 1)")
                }
            }
            if let oppIds = composition.opp {
                teamsData.opp = oppIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "Opp \(index + 1)")
                }
            }
        case .bp:
            if let ogIds = composition.og {
                teamsData.og = ogIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "OG \(index + 1)")
                }
            }
            if let ooIds = composition.oo {
                teamsData.oo = ooIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "OO \(index + 1)")
                }
            }
            if let cgIds = composition.cg {
                teamsData.cg = cgIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "CG \(index + 1)")
                }
            }
            if let coIds = composition.co {
                teamsData.co = coIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "CO \(index + 1)")
                }
            }
        case .ap:
            if let propIds = composition.prop {
                teamsData.prop = propIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "Gov \(index + 1)")
                }
            }
            if let oppIds = composition.opp {
                teamsData.opp = oppIds.enumerated().map { index, id in
                    let student = students.first(where: { $0.id.uuidString == id })
                    return StudentData(name: student?.name ?? "Unknown", position: "Opp \(index + 1)")
                }
            }
        }

        let request = CreateDebateRequest(
            motion: session.motion,
            format: session.format.rawValue,
            studentLevel: session.studentLevel.rawValue,
            speechTimeSeconds: session.speechTimeSeconds,
            teams: teamsData
        )

        let response: CreateDebateResponse = try await APIClient.shared.request(
            endpoint: .createDebate,
            body: request
        )

        return response.id
    }

    // MARK: - Helper Methods

    func updateTimeDefaults() {
        speechTimeSeconds = selectedFormat.defaultSpeechTime
        if selectedFormat.hasReplySpeeches {
            if let defaultReply = selectedFormat.defaultReplyTime {
                lastReplyTimeSeconds = defaultReply
            }
            if includeReplySpeeches {
                replyTimeSeconds = selectedFormat.defaultReplyTime ?? lastReplyTimeSeconds ?? 120
            } else {
                replyTimeSeconds = nil
            }
        } else {
            includeReplySpeeches = false
            replyTimeSeconds = nil
        }
    }

    func setReplySpeechesEnabled(_ enabled: Bool) {
        includeReplySpeeches = enabled

        if enabled {
            if let stored = lastReplyTimeSeconds {
                replyTimeSeconds = stored
            } else {
                replyTimeSeconds = selectedFormat.defaultReplyTime ?? 120
            }
        } else {
            if let current = replyTimeSeconds {
                lastReplyTimeSeconds = current
            }
            replyTimeSeconds = nil
        }
    }

    enum TeamType {
        case prop, opp, og, oo, cg, co
    }
}
