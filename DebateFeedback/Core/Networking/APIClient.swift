//
//  APIClient.swift
//  DebateFeedback
//
//

import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private var authToken: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.requestTimeout
        config.timeoutIntervalForResource = Constants.API.uploadTimeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Authentication

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Generic Request Methods

    func request<T: Decodable>(
        endpoint: Endpoint,
        body: Encodable? = nil
    ) async throws -> T {
        // Mock mode for development
        if Constants.API.useMockData {
            return try await mockResponse(for: endpoint)
        }

        guard let url = endpoint.url() else {
            // Track API error
            await MainActor.run {
                AnalyticsService.shared.logError(
                    type: "api_error",
                    message: "Invalid URL for endpoint: \(endpoint)",
                    code: "invalid_url",
                    screen: "APIClient",
                    action: "request"
                )
            }
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = endpoint.timeoutInterval

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw NetworkError.encodingError
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                // Track API error
                await MainActor.run {
                    AnalyticsService.shared.logError(
                        type: "api_error",
                        message: "Invalid HTTP response",
                        code: "invalid_response",
                        screen: "APIClient",
                        action: "request:\(endpoint)"
                    )
                }
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Track API error with status code
                await MainActor.run {
                    AnalyticsService.shared.logError(
                        type: "api_error",
                        message: "HTTP error: \(httpResponse.statusCode)",
                        code: "\(httpResponse.statusCode)",
                        screen: "APIClient",
                        action: "request:\(endpoint)"
                    )
                }
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                } else if httpResponse.statusCode == 404 {
                    throw NetworkError.notFound
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                // DIAGNOSTIC: Print raw response and decoding error
                print("========== DECODING ERROR DIAGNOSTICS ==========")
                print("❌ Failed to decode response as: \(T.self)")
                print("📦 Raw response data (\(data.count) bytes):")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString.prefix(2000)) // Print first 2000 chars
                }
                print("🔥 Decoding error: \(error)")
                print("================================================")

                // Track decoding error
                await MainActor.run {
                    AnalyticsService.shared.logError(
                        type: "api_error",
                        message: "Failed to decode \(T.self): \(error.localizedDescription)",
                        code: "decoding_error",
                        screen: "APIClient",
                        action: "request:\(endpoint)"
                    )
                }
                throw NetworkError.decodingError
            }

        } catch let error as NetworkError {
            throw error
        } catch {
            // Track unknown network error
            await MainActor.run {
                AnalyticsService.shared.logError(
                    type: "network_error",
                    message: "Network request failed: \(error.localizedDescription)",
                    code: "unknown",
                    screen: "APIClient",
                    action: "request:\(endpoint)"
                )
            }
            throw NetworkError.unknown(error)
        }
    }

    // MARK: - Upload with Progress

    func upload(
        endpoint: Endpoint,
        fileURL: URL,
        metadata: [String: Any],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UploadResponse {
        // Mock mode for development
        if Constants.API.useMockData {
            // Simulate upload progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                await MainActor.run {
                    progressHandler(Double(i) / 10.0)
                }
            }
            return UploadResponse(
                speechId: UUID().uuidString,
                status: "uploaded",
                processingStarted: true
            )
        }

        guard let url = endpoint.url() else {
            // Track upload error
            await MainActor.run {
                AnalyticsService.shared.logError(
                    type: "upload_error",
                    message: "Invalid URL for upload endpoint: \(endpoint)",
                    code: "invalid_url",
                    screen: "APIClient",
                    action: "upload"
                )
            }
            throw NetworkError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = endpoint.timeoutInterval

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Create multipart form data
        let httpBody = createMultipartBody(
            boundary: boundary,
            fileURL: fileURL,
            metadata: metadata
        )

        do {
            let (data, response) = try await session.upload(for: request, from: httpBody)

            guard let httpResponse = response as? HTTPURLResponse else {
                // Track upload error
                await MainActor.run {
                    AnalyticsService.shared.logError(
                        type: "upload_error",
                        message: "Invalid HTTP response during upload",
                        code: "invalid_response",
                        screen: "APIClient",
                        action: "upload:\(endpoint)"
                    )
                }
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Track upload error with status code
                await MainActor.run {
                    AnalyticsService.shared.logError(
                        type: "upload_error",
                        message: "Upload failed with HTTP \(httpResponse.statusCode)",
                        code: "\(httpResponse.statusCode)",
                        screen: "APIClient",
                        action: "upload:\(endpoint)"
                    )
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(UploadResponse.self, from: data)
            return decoded

        } catch let error as NetworkError {
            throw error
        } catch {
            // Track upload failure
            await MainActor.run {
                AnalyticsService.shared.logError(
                    type: "upload_error",
                    message: "Upload failed: \(error.localizedDescription)",
                    code: "upload_failed",
                    screen: "APIClient",
                    action: "upload:\(endpoint)"
                )
            }
            throw NetworkError.uploadFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Multipart Form Data Helper

    private func createMultipartBody(
        boundary: String,
        fileURL: URL,
        metadata: [String: Any]
    ) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        // Add metadata fields
        for (key, value) in metadata {
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        // Add file
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".utf8))
            body.append(Data("Content-Type: audio/m4a\r\n\r\n".utf8))
            body.append(fileData)
            body.append(Data("\r\n".utf8))
        }

        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    // MARK: - Mock Responses (for development without backend)

    private func mockResponse<T: Decodable>(for endpoint: Endpoint) async throws -> T {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        switch endpoint {
        case .login:
            let response = LoginResponse(
                token: "mock_token_\(UUID().uuidString)",
                teacher: TeacherResponse(
                    id: UUID().uuidString,
                    name: "Mock Teacher",
                    isAdmin: false
                )
            )
            return response as! T

        case .getCurrentSchedule(_, _, let classId):
            let primaryClassId = classId ?? UUID().uuidString
            let mockStudents = [
                StudentResponse(id: UUID().uuidString, name: "Alice Smith", level: "secondary", grade: "9"),
                StudentResponse(id: UUID().uuidString, name: "Bob Johnson", level: "secondary", grade: "10"),
                StudentResponse(id: UUID().uuidString, name: "Carol White", level: "secondary", grade: "9")
            ]
            let response = ScheduleResponse(
                classId: primaryClassId,
                students: mockStudents,
                suggestedMotion: "This house believes that social media does more harm than good",
                format: "WSDC",
                speechTime: 300,
                alternatives: [
                    ScheduleAlternative(
                        classId: primaryClassId + "-ALT1",
                        startTime: "18:00",
                        startDateTime: "2025-11-08T18:00:00.000Z" // Friday 6:00 PM
                    ),
                    ScheduleAlternative(
                        classId: primaryClassId + "-ALT2",
                        startTime: "20:00",
                        startDateTime: "2025-11-08T20:00:00.000Z" // Friday 8:00 PM
                    )
                ],
                startDateTime: "2025-11-08T16:30:00.000Z", // Friday 4:30 PM for the main class
                availableClasses: [
                    ScheduleResponse.ClassInfo(
                        classId: primaryClassId,
                        scheduleId: "sched-001",
                        source: "teacher",
                        displayLabel: "Friday 4:30 PM",
                        dayOfWeek: 5,
                        dayName: "Friday",
                        startTime: "16:30",
                        endTime: "18:00",
                        format: "WSDC",
                        speechTime: 300,
                        suggestedMotion: "This house believes that social media does more harm than good",
                        students: mockStudents
                    ),
                    ScheduleResponse.ClassInfo(
                        classId: primaryClassId + "-ALT1",
                        scheduleId: "sched-002",
                        source: "teacher",
                        displayLabel: "Friday 6:00 PM",
                        dayOfWeek: 5,
                        dayName: "Friday",
                        startTime: "18:00",
                        endTime: "19:30",
                        format: "BP",
                        speechTime: 420,
                        suggestedMotion: "This house would ban single-use plastics",
                        students: mockStudents.shuffled()
                    ),
                    ScheduleResponse.ClassInfo(
                        classId: primaryClassId + "-SAT",
                        scheduleId: "sched-003",
                        source: "teacher",
                        displayLabel: "Saturday 1:00 PM",
                        dayOfWeek: 6,
                        dayName: "Saturday",
                        startTime: "13:00",
                        endTime: "14:30",
                        format: "AP",
                        speechTime: 360,
                        suggestedMotion: nil,
                        students: mockStudents
                    )
                ]
            )
            return response as! T

        case .createDebate:
            let uuid = UUID().uuidString
            let response = CreateDebateResponse(debateId: uuid)
            return response as! T

        case .getSpeechStatus:
            let response = SpeechStatusResponse(
                status: "complete",
                feedbackUrl: "https://api.genalphai.com/feedback/view/mock_speech",
                errorMessage: nil,
                transcriptionStatus: "completed",
                transcriptionError: nil,
                feedbackStatus: "completed",
                feedbackError: nil,
                transcriptUrl: "https://docs.google.com/document/d/mock_transcript_id",
                transcriptText: "Mock transcript body"
            )
            return response as! T

        case .getDebateHistory:
            let response = DebateHistoryResponse(debates: [])
            return response as! T

        case .getSpeechTraining:
            let response = SpeechTrainingResponse(
                speechId: "mock-speech",
                studentName: "Mock Student",
                studentLevel: "secondary",
                motion: "This house would regulate social media algorithms",
                position: "Prop 1",
                debateFormat: "WSDC",
                summary: SpeechTrainingSummary(
                    averageScore: 2.9,
                    strongestRubric: "Delivery & Style",
                    weakestRubric: "Argument Completeness",
                    speakingRateWpm: 156,
                    improvementFocus: "Argument Completeness: the mechanism was asserted but not explained."
                ),
                drill: PracticeDrill(
                    title: "Mechanism Drill",
                    focusArea: "Argument Completeness",
                    focusScore: 2,
                    weaknessSummary: "The speech states the outcome but does not show the chain of causation.",
                    goal: "Practice adding the missing middle step between claim and impact.",
                    steps: ["State the claim in one sentence", "Add the causal chain in two sentences", "Finish with one comparative impact sentence"],
                    selfCheck: ["Did I explain why the outcome happens?", "Did I compare why my side matters more?"],
                    coachNote: "Keep it short and mechanistic.",
                    provider: "mock",
                    model: "mock-model",
                    generatedAt: "2026-03-11T00:00:00Z"
                ),
                ghostDebater: GhostDebaterArtifact(
                    strategicBrief: "Attack the student’s missing mechanisms and out-weigh on probability.",
                    speechText: "Your case assumes platforms automatically suppress dissent, but that only follows if the regulation is badly designed...",
                    counterplayTargets: ["Missing mechanism", "Weak weighing", "No trade-off analysis"],
                    provider: "mock",
                    model: "mock-model",
                    generatedAt: "2026-03-11T00:00:00Z"
                )
            )
            return response as! T

        case .getComparativeAnalysis:
            let response = ComparativeAnalysisResponse(
                debateId: "mock-debate",
                motion: "This house would regulate social media algorithms",
                format: "WSDC",
                studentLevel: "secondary",
                debateSummary: ComparativeDebateSummary(
                    motion: "This house would regulate social media algorithms",
                    overallWinner: "Proposition",
                    margin: "narrow",
                    keyReason: "Proposition better explained the democratic harms and won the weighing on long-term institutional trust."
                ),
                clashes: [
                    ComparativeClash(
                        number: 1,
                        label: "Democracy vs platform efficiency",
                        propPosition: "Algorithms distort public discourse.",
                        oppPosition: "Private ordering delivers better user outcomes.",
                        winner: "Proposition",
                        reason: "Opposition never answered why efficiency outweighs democratic legitimacy.",
                        losingSideNeeded: "Show why targeted platform flexibility solves harms better than state regulation."
                    )
                ],
                burdenAnalysis: ComparativeBurdenAnalysis.empty,
                weighing: ComparativeWeighing.empty,
                speakerRankings: [],
                teamFeedback: ComparativeTeamFeedback.empty,
                provider: "mock",
                model: "mock-model",
                generatedAt: "2026-03-11T00:00:00Z"
            )
            return response as! T

        case .getStudentPortfolio:
            let response = StudentPortfolioResponse(
                studentName: "Mock Student",
                studentLevel: "secondary",
                totalSpeeches: 4,
                totalDebates: 2,
                lastActivityAt: nil,
                rubrics: [],
                recentFeedback: []
            )
            return response as! T

        case .getStudentBenchmarks:
            let response = StudentBenchmarksResponse(
                studentName: "Mock Student",
                studentLevel: "secondary",
                totals: BenchmarksTotals(speeches: 4, debates: 2),
                speakingRateWpm: BenchmarkDelta(studentAvg: 156, cohortAvg: 149, delta: 7),
                durationSeconds: BenchmarkDelta(studentAvg: 290, cohortAvg: 300, delta: -10),
                rubricScore: BenchmarkDelta(studentAvg: 2.9, cohortAvg: 3.2, delta: -0.3),
                latestSpeech: nil,
                limitations: []
            )
            return response as! T

        default:
            throw NetworkError.unknown(NSError(domain: "Mock not implemented", code: -1))
        }
    }
}

// MARK: - Response Models

struct LoginResponse: Codable {
    let token: String
    let teacher: TeacherResponse
}

struct TeacherResponse: Codable {
    let id: String
    let name: String
    let isAdmin: Bool
}

struct ScheduleResponse: Codable {
    let classId: String
    let students: [StudentResponse]
    let suggestedMotion: String?
    let format: String
    let speechTime: Int
    let alternatives: [ScheduleAlternative]?
    let startDateTime: String? // Full ISO8601 datetime for the main class
    let availableClasses: [ClassInfo]?

    /// Returns formatted display string for the main class
    var classDisplayString: String {
        let dayTime = formattedDayTime()
        if dayTime == classId {
            return classId
        }
        return "\(dayTime) - \(classId)"
    }

    /// Returns just day and time for the main class
    var classDayTimeString: String {
        formattedDayTime()
    }

    private func formattedDayTime() -> String {
        ClassScheduleFormatter.dayTimeString(
            classId: classId,
            startDateTime: startDateTime,
            fallbackStartTime: nil
        ) ?? classId
    }

    struct ClassInfo: Codable {
        let classId: String
        let scheduleId: String?
        let source: String?
        let displayLabel: String?
        let dayOfWeek: Int?
        let dayName: String?
        let startTime: String?
        let endTime: String?
        let format: String?
        let speechTime: Int?
        let suggestedMotion: String?
        let students: [StudentResponse]

        var dayTimeString: String? {
            if let displayLabel, !displayLabel.isEmpty {
                return displayLabel
            }

            return ClassScheduleFormatter.dayTimeString(
                classId: classId,
                startDateTime: nil,
                fallbackStartTime: startTime,
                explicitDayName: dayName
            )
        }

        var displayTitle: String {
            dayTimeString ?? classId
        }

        var displaySubtitle: String? {
            guard dayTimeString != nil else { return nil }
            return classId
        }

        static func primaryFallback(from response: ScheduleResponse) -> ClassInfo {
            ClassInfo(
                classId: response.classId,
                scheduleId: nil,
                source: "primary",
                displayLabel: response.classDayTimeString == response.classId ? nil : response.classDayTimeString,
                dayOfWeek: nil,
                dayName: nil,
                startTime: nil,
                endTime: nil,
                format: response.format,
                speechTime: response.speechTime,
                suggestedMotion: response.suggestedMotion,
                students: response.students
            )
        }
    }
}

struct ScheduleAlternative: Codable, Hashable {
    let classId: String
    let startTime: String // Keep for backward compatibility
    let startDateTime: String? // Full ISO8601 datetime from backend

    /// Returns formatted display string like "Friday 4:30 PM - BEG-FRI-1430"
    var displayString: String {
        let dayTimeString = formattedDayTime()
        if dayTimeString == classId {
            return classId
        }
        return "\(dayTimeString) - \(classId)"
    }

    /// Returns just the day and time portion like "Friday 4:30 PM"
    var dayTimeString: String {
        formattedDayTime()
    }

    private func formattedDayTime() -> String {
        ClassScheduleFormatter.dayTimeString(
            classId: classId,
            startDateTime: startDateTime,
            fallbackStartTime: startTime
        ) ?? classId
    }
}

// MARK: - Schedule Formatting Helpers

fileprivate enum ClassScheduleFormatter {
    static func dayTimeString(
        classId: String,
        startDateTime: String?,
        fallbackStartTime: String?,
        explicitDayName: String? = nil
    ) -> String? {
        if let startDateTime,
           let date = Date.from(iso8601String: startDateTime) {
            return formattedDayTime(from: date)
        }

        let day = explicitDayName ?? dayName(fromClassId: classId)
        let time = formattedTime(fromExplicit: fallbackStartTime) ?? formattedTime(fromClassId: classId)

        switch (day, time) {
        case let (day?, time?):
            return "\(day) \(time)"
        case let (day?, nil):
            return day
        case let (nil, time?):
            return time
        default:
            return nil
        }
    }

    private static func formattedDayTime(from date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let day = dayFormatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let time = timeFormatter.string(from: date)

        return "\(day) \(time)"
    }

    private static func dayName(fromClassId classId: String) -> String? {
        let components = classId.split(separator: "-")
        for component in components {
            let upper = component.uppercased()
            if let fullName = dayLookup[upper] {
                return fullName
            }
        }
        return nil
    }

    private static func formattedTime(fromExplicit explicit: String?) -> String? {
        guard let explicit, !explicit.isEmpty else { return nil }

        if explicit.contains(":") {
            let parts = explicit.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
            if parts.count == 2,
               let hour = Int(parts[0]),
               let minute = Int(parts[1]) {
                return formattedTime(hour: hour, minute: minute)
            }
        }

        if explicit.count == 4,
           let hour = Int(explicit.prefix(2)),
           let minute = Int(explicit.suffix(2)) {
            return formattedTime(hour: hour, minute: minute)
        }

        return nil
    }

    private static func formattedTime(fromClassId classId: String) -> String? {
        guard let lastComponent = classId.split(separator: "-").last else { return nil }
        let raw = String(lastComponent)
        guard raw.count == 4,
              let hour = Int(raw.prefix(2)),
              let minute = Int(raw.suffix(2)) else {
            return nil
        }
        return formattedTime(hour: hour, minute: minute)
    }

    private static func formattedTime(hour: Int, minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let normalizedHour: Int
        if hour == 0 {
            normalizedHour = 12
        } else if hour > 12 {
            normalizedHour = hour - 12
        } else {
            normalizedHour = hour
        }
        return String(format: "%d:%02d %@", normalizedHour, minute, period)
    }

    private static let dayLookup: [String: String] = [
        "MON": "Monday",
        "TUE": "Tuesday",
        "WED": "Wednesday",
        "THU": "Thursday",
        "FRI": "Friday",
        "SAT": "Saturday",
        "SUN": "Sunday"
    ]
}

struct StudentResponse: Codable {
    let id: String
    let name: String
    let level: String
    let grade: String?
}

struct CreateDebateRequest: Codable {
    let motion: String
    let format: String
    let studentLevel: String
    let speechTimeSeconds: Int
    let replyTimeSeconds: Int?
    let teams: TeamsData
    let classId: String?
    let scheduleId: String?

    enum CodingKeys: String, CodingKey {
        case motion, format, teams
        case studentLevel = "student_level"
        case speechTimeSeconds = "speech_time_seconds"
        case replyTimeSeconds = "reply_time_seconds"
        case classId = "class_id"
        case scheduleId = "schedule_id"
    }
}

struct TeamsData: Codable {
    var prop: [StudentData]?
    var opp: [StudentData]?
    var og: [StudentData]?
    var oo: [StudentData]?
    var cg: [StudentData]?
    var co: [StudentData]?
}

struct StudentData: Codable {
    let name: String
    let position: String
}

struct CreateDebateResponse: Codable {
    let debateId: String
}

struct UploadResponse: Codable {
    let speechId: String
    let status: String
    let processingStarted: Bool
}

struct SpeechStatusResponse: Codable {
    let status: String
    let feedbackUrl: String?
    let errorMessage: String?
    let transcriptionStatus: String?
    let transcriptionError: String?
    let feedbackStatus: String?
    let feedbackError: String?
    let transcriptUrl: String?
    let transcriptText: String?
}

struct FeedbackContentResponse: Codable {
    let speechId: String
    let scores: [String: RubricScore]?
    let qualitativeFeedback: QualitativeFeedback?
    let feedbackText: String?
    let sections: [FeedbackSection]?
    let playableMoments: [PlayableMoment]?
    let audioUrl: String?

    struct QualitativeFeedback: Codable {
        let feedbackText: String?
    }

    struct FeedbackSection: Codable {
        let title: String
        let content: String
    }

    // Note: No explicit CodingKeys needed - decoder uses .convertFromSnakeCase
    // which automatically converts:
    //   speech_id -> speechId
    //   qualitative_feedback -> qualitativeFeedback
    //   feedback_text -> feedbackText
    //   playable_moments -> playableMoments
    //   audio_url -> audioUrl
    
    /// Helper to get feedback text from both top-level and nested payloads.
    var resolvedFeedbackText: String {
        feedbackText ?? qualitativeFeedback?.feedbackText ?? ""
    }
}

struct SpeechTrainingResponse: Codable {
    let speechId: String
    let studentName: String
    let studentLevel: String
    let motion: String
    let position: String
    let debateFormat: String
    let summary: SpeechTrainingSummary
    let drill: PracticeDrill?
    let ghostDebater: GhostDebaterArtifact?
}

struct SpeechTrainingSummary: Codable {
    let averageScore: Double?
    let strongestRubric: String?
    let weakestRubric: String?
    let speakingRateWpm: Double?
    let improvementFocus: String?
}

struct PracticeDrill: Codable {
    let title: String
    let focusArea: String
    let focusScore: Double?
    let weaknessSummary: String
    let goal: String
    let steps: [String]
    let selfCheck: [String]
    let coachNote: String?
    let provider: String?
    let model: String?
    let generatedAt: String?
}

struct GhostDebaterArtifact: Codable {
    let strategicBrief: String
    let speechText: String
    let counterplayTargets: [String]
    let provider: String?
    let model: String?
    let generatedAt: String?
}

struct ComparativeAnalysisResponse: Codable {
    let debateId: String
    let motion: String
    let format: String
    let studentLevel: String
    let debateSummary: ComparativeDebateSummary
    let clashes: [ComparativeClash]
    let burdenAnalysis: ComparativeBurdenAnalysis
    let weighing: ComparativeWeighing
    let speakerRankings: [ComparativeSpeakerRanking]
    let teamFeedback: ComparativeTeamFeedback
    let provider: String?
    let model: String?
    let generatedAt: String?
}

struct ComparativeDebateSummary: Codable {
    let motion: String
    let overallWinner: String
    let margin: String
    let keyReason: String
}

struct ComparativeClash: Codable, Identifiable {
    var id: String { "\(number)-\(label)" }
    let number: Int
    let label: String
    let propPosition: String
    let oppPosition: String
    let winner: String
    let reason: String
    let losingSideNeeded: String
}

struct ComparativeBurdenSide: Codable {
    let burdenSet: String?
    let burdenMet: String?
    let gaps: [String]?
}

struct ComparativeBurdenAnalysis: Codable {
    let proposition: ComparativeBurdenSide?
    let opposition: ComparativeBurdenSide?

    static let empty = ComparativeBurdenAnalysis(proposition: nil, opposition: nil)
}

struct ComparativeWeighing: Codable {
    let decisionMetric: String?
    let scopeWinner: String?
    let severityWinner: String?
    let probabilityWinner: String?
    let reversibilityWinner: String?

    static let empty = ComparativeWeighing(
        decisionMetric: nil,
        scopeWinner: nil,
        severityWinner: nil,
        probabilityWinner: nil,
        reversibilityWinner: nil
    )
}

struct ComparativeSpeakerRanking: Codable, Identifiable {
    var id: String { "\(rank)-\(position)" }
    let rank: Int
    let position: String
    let score: Double
    let justification: String
}

struct ComparativeTeamSideFeedback: Codable {
    let strengths: [String]?
    let gaps: [String]?
    let toWinNeeded: String?
}

struct ComparativeTeamFeedback: Codable {
    let proposition: ComparativeTeamSideFeedback?
    let opposition: ComparativeTeamSideFeedback?

    static let empty = ComparativeTeamFeedback(proposition: nil, opposition: nil)
}

struct StudentPortfolioResponse: Codable {
    let studentName: String
    let studentLevel: String?
    let totalSpeeches: Int
    let totalDebates: Int
    let lastActivityAt: String?
    let rubrics: [PortfolioRubricSeries]
    let recentFeedback: [PortfolioFeedbackItem]
}

struct PortfolioRubricSeries: Codable, Identifiable {
    var id: String { rubric }
    let rubric: String
    let points: [PortfolioPoint]
    let averageScore: Double?
    let latestScore: Double?
    let trendDelta: Double?
}

struct PortfolioPoint: Codable, Identifiable {
    var id: String { "\(speechId)-\(date)" }
    let date: String
    let score: Double?
    let speechId: Int
    let debateId: String
    let motion: String
}

struct PortfolioFeedbackItem: Codable, Identifiable {
    var id: String { "\(speechId)-\(createdAt)" }
    let speechId: Int
    let debateId: String
    let motion: String
    let createdAt: String
    let scores: [String: RubricScore]
    let feedbackUrl: String?
}

struct StudentBenchmarksResponse: Codable {
    let studentName: String
    let studentLevel: String?
    let totals: BenchmarksTotals
    let speakingRateWpm: BenchmarkDelta
    let durationSeconds: BenchmarkDelta
    let rubricScore: BenchmarkDelta
    let latestSpeech: BenchmarkLatestSpeech?
    let limitations: [String]
}

struct BenchmarksTotals: Codable {
    let speeches: Int
    let debates: Int
}

struct BenchmarkDelta: Codable {
    let studentAvg: Double?
    let cohortAvg: Double?
    let delta: Double?
}

struct BenchmarkLatestSpeech: Codable {
    let speechId: Int
    let debateId: String
    let motion: String
    let createdAt: String
    let speakingRateWpm: Double?
    let durationSeconds: Double?
}

struct DebateHistoryResponse: Codable {
    let debates: [DebateHistoryItem]
}

struct DebateHistoryItem: Codable {
    let debateId: String
    let motion: String
    let date: String
    let speeches: [SpeechHistoryItem]
}

struct SpeechHistoryItem: Codable {
    let speakerName: String
    let feedbackUrl: String?
    let scores: [String: RubricScore]?
}

enum RubricScore: Codable, Hashable, CustomStringConvertible {
    case number(Double)
    case notApplicable
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let number = try? container.decode(Double.self) {
            self = .number(number)
            return
        }

        if let string = try? container.decode(String.self) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let upper = trimmed.uppercased()
            if upper == "NA" || upper == "N/A" {
                self = .notApplicable
                return
            }
            if let parsed = Double(trimmed) {
                self = .number(parsed)
                return
            }
            self = .text(trimmed)
            return
        }

        self = .text("")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let value):
            try container.encode(value)
        case .notApplicable:
            try container.encode("NA")
        case .text(let value):
            try container.encode(value)
        }
    }

    var description: String {
        switch self {
        case .number(let value):
            return String(format: "%.2f", value)
        case .notApplicable:
            return "NA"
        case .text(let value):
            return value
        }
    }
}
