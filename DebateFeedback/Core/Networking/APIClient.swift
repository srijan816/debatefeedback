//
//  APIClient.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
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
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                } else if httpResponse.statusCode == 404 {
                    throw NetworkError.notFound
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decodingError
            }

        } catch let error as NetworkError {
            throw error
        } catch {
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
            throw NetworkError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

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
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
            return decoded

        } catch let error as NetworkError {
            throw error
        } catch {
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
            let response = ScheduleResponse(
                classId: primaryClassId,
                students: [
                    StudentResponse(id: UUID().uuidString, name: "Alice Smith", level: "secondary"),
                    StudentResponse(id: UUID().uuidString, name: "Bob Johnson", level: "secondary"),
                    StudentResponse(id: UUID().uuidString, name: "Carol White", level: "secondary")
                ],
                suggestedMotion: "This house believes that social media does more harm than good",
                format: "WSDC",
                speechTime: 300,
                alternatives: [
                    ScheduleAlternative(classId: primaryClassId + "-ALT1", startTime: "18:00"),
                    ScheduleAlternative(classId: primaryClassId + "-ALT2", startTime: "20:00")
                ]
            )
            return response as! T

        case .createDebate:
            let uuid = UUID().uuidString
            let response = CreateDebateResponse(debateId: uuid, debate_id: uuid)
            return response as! T

        case .getSpeechStatus:
            let response = SpeechStatusResponse(
                status: "complete",
                googleDocUrl: "https://docs.google.com/document/d/mock_doc_id",
                errorMessage: nil
            )
            return response as! T

        case .getDebateHistory:
            let response = DebateHistoryResponse(debates: [])
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
}

struct ScheduleAlternative: Codable, Hashable {
    let classId: String
    let startTime: String
}

struct StudentResponse: Codable {
    let id: String
    let name: String
    let level: String
}

struct CreateDebateRequest: Codable {
    let motion: String
    let format: String
    let studentLevel: String
    let speechTimeSeconds: Int
    let teams: TeamsData

    enum CodingKeys: String, CodingKey {
        case motion, format, teams
        case studentLevel = "student_level"
        case speechTimeSeconds = "speech_time_seconds"
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
    let debate_id: String? // Backend might return both formats

    var id: String {
        return debate_id ?? debateId
    }

    enum CodingKeys: String, CodingKey {
        case debateId
        case debate_id
    }
}

struct UploadResponse: Codable {
    let speechId: String
    let status: String
    let processingStarted: Bool
}

struct SpeechStatusResponse: Codable {
    let status: String
    let googleDocUrl: String?
    let errorMessage: String?
}

struct FeedbackContentResponse: Codable {
    let speechId: String
    let feedbackText: String
    let scores: [String: Double]?
    let sections: [FeedbackSection]?

    struct FeedbackSection: Codable {
        let title: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case speechId = "speech_id"
        case feedbackText = "feedback_text"
        case scores
        case sections
    }
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
    let scores: [String: Double]?
}
