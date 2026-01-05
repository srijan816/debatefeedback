//
//  SetupViewModel.swift
//  DebateFeedback
//
//

import Foundation
import SwiftUI
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
    var selectedScheduleId: String?
    var selectedClassDayTime: String? // Formatted day/time for current class
    var availableClasses: [ScheduleResponse.ClassInfo] = []
    var availableAlternatives: [ScheduleAlternative] = []
    var hasScheduleDefaults = false

    struct ClassPickerOption: Identifiable, Hashable {
        let id: String
        let title: String
        let subtitle: String?
    }

    var classPickerOptions: [ClassPickerOption] {
        if !availableClasses.isEmpty {
            return availableClasses.map { option in
                ClassPickerOption(
                    id: option.classId,
                    title: option.displayTitle,
                    subtitle: option.displaySubtitle
                )
            }
        }

        guard let classId = selectedClassId else { return [] }
        var options: [ClassPickerOption] = []
        var seen = Set<String>()

        let title = selectedClassDayTime ?? classId
        let subtitle = selectedClassDayTime == nil ? nil : classId
        options.append(ClassPickerOption(id: classId, title: title, subtitle: subtitle))
        seen.insert(classId)

        for alternative in availableAlternatives where seen.insert(alternative.classId).inserted {
            options.append(
                ClassPickerOption(
                    id: alternative.classId,
                    title: alternative.dayTimeString,
                    subtitle: alternative.classId
                )
            )
        }

        return options
    }

    /// Returns the currently selected alternative, if any
    var selectedAlternative: ScheduleAlternative? {
        guard let selectedClassId else { return nil }
        return availableAlternatives.first { $0.classId == selectedClassId }
    }

    // Toast notification state
    var showToast = false
    var toastMessage = ""
    var toastType: ToastView.ToastType = .success

    @ObservationIgnored private var hasLoadedSchedule = false
    @ObservationIgnored private var lastReplyTimeSeconds: Int?
    @ObservationIgnored private var cachedTeacher: Teacher?
    @ObservationIgnored private var cachedTimestamp: String?
    @ObservationIgnored private var scheduleCache: [String: ScheduleResponse] = [:]
    @ObservationIgnored private var setupStartTime: Date?
    @ObservationIgnored private var step1StartTime: Date?

    enum SetupStep {
        case basicInfo
        case teamAssignment
    }

    init() {
        updateTimeDefaults()
    }

    // MARK: - Analytics

    func trackSetupStarted() {
        setupStartTime = Date()
        step1StartTime = Date()
        AnalyticsService.shared.logSetupStarted()
    }

    func trackSetupAbandoned() {
        AnalyticsService.shared.logSetupAbandoned(currentStep: currentStep == .basicInfo ? 1 : 2)
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
    func selectClass(withId classId: String) {
        guard classId != selectedClassId else { return }

        if let classInfo = classInfo(for: classId) {
            applyClassInfo(classInfo, fallbackResponse: nil)

            Task {
                await loadSchedule(forClassId: classId)
            }
            return
        }

        if let alternative = availableAlternatives.first(where: { $0.classId == classId }) {
            Task {
                await switchToAlternative(alternative)
            }
        }
    }

    @MainActor
    private func loadSchedule(forClassId classId: String?) async {
        guard let teacher = cachedTeacher else { return }

        scheduleNotice = nil

        if let classId,
           let cached = scheduleCache[classId] {
            applySchedule(cached, preferredClassId: classId)
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
            applySchedule(response, preferredClassId: classId ?? selectedClassId)

        } catch let networkError as NetworkError {
            handleScheduleError(networkError)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func classInfo(for classId: String) -> ScheduleResponse.ClassInfo? {
        availableClasses.first { $0.classId == classId }
    }

    @MainActor
    private func applyClassInfo(
        _ classInfo: ScheduleResponse.ClassInfo,
        fallbackResponse: ScheduleResponse?
    ) {
        let fallbackMatchesSelectedClass = fallbackResponse?.classId == classInfo.classId

        selectedClassId = classInfo.classId
        selectedScheduleId = classInfo.scheduleId
        let resolvedDayTime = classInfo.dayTimeString ?? (fallbackMatchesSelectedClass ? fallbackResponse?.classDayTimeString : nil)
        if let resolvedDayTime, resolvedDayTime != classInfo.classId {
            selectedClassDayTime = resolvedDayTime
        } else {
            selectedClassDayTime = nil
        }

        let roster: [StudentResponse]
        if !classInfo.students.isEmpty {
            roster = classInfo.students
        } else if fallbackMatchesSelectedClass, let fallbackStudents = fallbackResponse?.students {
            roster = fallbackStudents
        } else {
            roster = []
        }
        updateRoster(with: roster)

        let fallbackFormat = fallbackMatchesSelectedClass ? fallbackResponse?.format : nil
        let fallbackSpeechTime = fallbackMatchesSelectedClass ? fallbackResponse?.speechTime : nil
        applyFormatAndTiming(
            formatString: classInfo.format,
            fallbackFormat: fallbackFormat,
            speechTime: classInfo.speechTime,
            fallbackSpeechTime: fallbackSpeechTime
        )

        let fallbackMotion = fallbackMatchesSelectedClass ? fallbackResponse?.suggestedMotion : nil
        applySuggestedMotion(classInfo.suggestedMotion, fallback: fallbackMotion)

        scheduleNotice = nil
        hasScheduleDefaults = true
    }

    private func updateRoster(with responses: [StudentResponse]) {
        if let firstLevel = responses.first?.level.lowercased(),
           let level = StudentLevel(rawValue: firstLevel) {
            studentLevel = level
        }

        students = responses.map { student in
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

    private func applyFormatAndTiming(
        formatString: String?,
        fallbackFormat: String?,
        speechTime: Int?,
        fallbackSpeechTime: Int?
    ) {
        if let formatName = formatString ?? fallbackFormat,
           let newFormat = DebateFormat(rawValue: formatName) {
            selectedFormat = newFormat
            updateTimeDefaults()
        }

        if let time = speechTime ?? fallbackSpeechTime {
            speechTimeSeconds = time
        }
    }

    private func applySuggestedMotion(_ suggested: String?, fallback: String?) {
        if let suggestion = suggested?.trimmingCharacters(in: .whitespacesAndNewlines), !suggestion.isEmpty {
            motion = suggestion
            return
        }

        if let fallback = fallback?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty {
            motion = fallback
            return
        }

        // Keep showing the last known motion until we explicitly receive a new one.
    }

    private func handleScheduleError(_ error: NetworkError) {
        switch error {
        case .notFound:
            scheduleNotice = "No schedule found for this time. You can enter details manually."
            hasScheduleDefaults = false
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
                // Track step 1 completion
                let step1Time = step1StartTime.map { Date().timeIntervalSince($0) } ?? 0
                AnalyticsService.shared.logSetupStep1Completed(
                    format: selectedFormat,
                    studentLevel: studentLevel,
                    motionLength: motion.count,
                    speechTime: speechTimeSeconds,
                    replyTime: replyTimeSeconds,
                    usedSchedule: selectedClassId != nil
                )

                currentStep = .teamAssignment

                // Track step 2 started
                AnalyticsService.shared.logSetupStep2Started()
            }
        case .teamAssignment:
            break
        }
    }

    func previousStep() {
        switch currentStep {
        case .basicInfo:
            break
        case .teamAssignment:
            currentStep = .basicInfo
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

        // Track student added
        AnalyticsService.shared.logSetupStudentAdded(studentCount: students.count)

        // Show success toast
        showSuccessToast("Student added")

        // Haptic feedback
        HapticManager.shared.medium()
    }

    // MARK: - Toast Helpers

    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        showToast = true

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showToast = false
        }
    }

    func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showToast = false
        }
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
        var position = 0
        switch team {
        case .prop:
            propTeam.append(student)
            position = propTeam.count
        case .opp:
            oppTeam.append(student)
            position = oppTeam.count
        case .og:
            ogTeam.append(student)
            position = ogTeam.count
        case .oo:
            ooTeam.append(student)
            position = ooTeam.count
        case .cg:
            cgTeam.append(student)
            position = cgTeam.count
        case .co:
            coTeam.append(student)
            position = coTeam.count
        }

        // Track student assigned
        AnalyticsService.shared.logSetupStudentAssigned(team: team.rawValue, position: position)
    }

    func removeFromAllTeams(_ student: Student) {
        propTeam.removeAll { $0.id == student.id }
        oppTeam.removeAll { $0.id == student.id }
        ogTeam.removeAll { $0.id == student.id }
        ooTeam.removeAll { $0.id == student.id }
        cgTeam.removeAll { $0.id == student.id }
        coTeam.removeAll { $0.id == student.id }
    }

    func reorderTeam(_ team: TeamType, from sourceIndex: Int, to destinationIndex: Int) {
        switch team {
        case .prop:
            guard sourceIndex < propTeam.count, destinationIndex < propTeam.count else { return }
            let student = propTeam.remove(at: sourceIndex)
            propTeam.insert(student, at: destinationIndex)
        case .opp:
            guard sourceIndex < oppTeam.count, destinationIndex < oppTeam.count else { return }
            let student = oppTeam.remove(at: sourceIndex)
            oppTeam.insert(student, at: destinationIndex)
        case .og:
            guard sourceIndex < ogTeam.count, destinationIndex < ogTeam.count else { return }
            let student = ogTeam.remove(at: sourceIndex)
            ogTeam.insert(student, at: destinationIndex)
        case .oo:
            guard sourceIndex < ooTeam.count, destinationIndex < ooTeam.count else { return }
            let student = ooTeam.remove(at: sourceIndex)
            ooTeam.insert(student, at: destinationIndex)
        case .cg:
            guard sourceIndex < cgTeam.count, destinationIndex < cgTeam.count else { return }
            let student = cgTeam.remove(at: sourceIndex)
            cgTeam.insert(student, at: destinationIndex)
        case .co:
            guard sourceIndex < coTeam.count, destinationIndex < coTeam.count else { return }
            let student = coTeam.remove(at: sourceIndex)
            coTeam.insert(student, at: destinationIndex)
        }

        // Track student reordered
        AnalyticsService.shared.logSetupStudentReordered(
            team: team.rawValue,
            fromPosition: sourceIndex + 1,
            toPosition: destinationIndex + 1
        )
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

    // Real-time validation properties for inline feedback
    var motionValidationMessage: String {
        let count = motion.count
        if count == 0 {
            return ""
        } else if count < Constants.Validation.minimumMotionLength {
            return "Motion is too short (min 5 characters)"
        } else if count > Constants.Validation.maximumMotionLength {
            return "Motion is too long (max 200 characters)"
        }
        return ""
    }

    var isMotionValid: Bool {
        motion.isValidMotion
    }

    var motionCharCount: Int {
        motion.count
    }

    var motionBorderColor: Color {
        if motion.isEmpty {
            return Constants.Colors.textTertiary.opacity(0.3)
        }
        return isMotionValid ? Constants.Colors.complete.opacity(0.5) : Constants.Colors.failed.opacity(0.5)
    }

    var motionCharCountColor: Color {
        let count = motion.count
        if count == 0 {
            return Constants.Colors.textSecondary
        } else if count < Constants.Validation.minimumMotionLength {
            return Constants.Colors.failed
        } else if count > Constants.Validation.maximumMotionLength {
            return Constants.Colors.failed
        } else if count > 180 {
            return Constants.Colors.warning
        }
        return Constants.Colors.complete
    }

    var studentNameValidationMessage: String {
        let count = newStudentName.count
        if count == 0 {
            return ""
        } else if count < Constants.Validation.minimumSpeakerName {
            return "Name is too short (min 2 characters)"
        } else if count > Constants.Validation.maximumSpeakerName {
            return "Name is too long (max 50 characters)"
        }
        return ""
    }

    var isStudentNameValid: Bool {
        newStudentName.isValidSpeakerName
    }

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
        case .wsdc, .australs:
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

    @MainActor
    func createDebate(context: ModelContext, teacher: Teacher?) async -> DebateSession? {
        guard validateTeamAssignment() else {
            return nil
        }

        // Track setup completed
        let totalSetupTime = setupStartTime.map { Date().timeIntervalSince($0) } ?? 0
        AnalyticsService.shared.logSetupCompleted(
            format: selectedFormat,
            numStudents: students.count,
            totalSetupTime: totalSetupTime
        )

        let session = DebateSession(
            motion: motion,
            format: selectedFormat,
            studentLevel: studentLevel,
            speechTimeSeconds: speechTimeSeconds,
            replyTimeSeconds: replyTimeSeconds,
            isGuestMode: teacher == nil,
            teacher: teacher,
            classId: selectedClassId,
            scheduleId: selectedScheduleId
        )

        // Set team composition
        var composition = TeamComposition()
        switch selectedFormat {
        case .wsdc, .australs:
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
    private func applySchedule(_ response: ScheduleResponse, preferredClassId: String? = nil) {
        selectedScheduleId = nil

        var classOptions: [ScheduleResponse.ClassInfo] = []
        var seen = Set<String>()

        if let providedOptions = response.availableClasses {
            for option in providedOptions where seen.insert(option.classId).inserted {
                classOptions.append(option)
            }
        }

        if seen.insert(response.classId).inserted {
            classOptions.insert(.primaryFallback(from: response), at: 0)
        }

        availableClasses = classOptions

        let targetClassId = preferredClassId ?? selectedClassId ?? response.classId

        if let preferredOption = classInfo(for: targetClassId) {
            applyClassInfo(preferredOption, fallbackResponse: response)
        } else if let currentOption = classInfo(for: response.classId) {
            applyClassInfo(currentOption, fallbackResponse: response)
        } else {
            // Fallback to legacy handling if the response class is missing from availableClasses
            selectedClassId = response.classId
            if response.classDayTimeString != response.classId {
                selectedClassDayTime = response.classDayTimeString
            } else {
                selectedClassDayTime = nil
            }
            selectedScheduleId = nil
            updateRoster(with: response.students)
            applyFormatAndTiming(
                formatString: response.format,
                fallbackFormat: nil,
                speechTime: response.speechTime,
                fallbackSpeechTime: nil
            )
            applySuggestedMotion(response.suggestedMotion, fallback: nil)
            scheduleNotice = nil
        }

        if let alternatives = response.alternatives {
            var seenAlternatives = Set<String>()
            availableAlternatives = alternatives.compactMap { option in
                guard option.classId != response.classId else { return nil }
                if seenAlternatives.insert(option.classId).inserted {
                    return option
                }
                return nil
            }
        } else {
            availableAlternatives = []
        }
    }

    private func createDebateOnBackend(session: DebateSession) async throws -> String {
        // Prepare teams data
        var teamsData = TeamsData()
        guard let composition = session.teamComposition else {
            throw NetworkError.unknown(NSError(domain: "No team composition", code: -1))
        }

        switch selectedFormat {
        case .wsdc, .australs:
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
            teams: teamsData,
            classId: session.classId,
            scheduleId: session.scheduleId
        )

        let response: CreateDebateResponse = try await APIClient.shared.request(
            endpoint: .createDebate,
            body: request
        )

        return response.debateId
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
