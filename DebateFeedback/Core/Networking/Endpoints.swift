//
//  Endpoints.swift
//  DebateFeedback
//
//

import Foundation

enum Endpoint {
    case login
    case getCurrentSchedule(teacherId: String, timestamp: String, classId: String? = nil)
    case createDebate
    case uploadSpeech
    case getSpeechStatus(speechId: String)
    case getFeedbackContent(speechId: String)
    case getSpeechTraining(speechId: String, generate: Bool)
    case getComparativeAnalysis(debateId: String, generate: Bool)
    case getStudentPortfolio(teacherName: String, studentName: String, limit: Int)
    case getStudentBenchmarks(teacherName: String, studentName: String, cohortLimit: Int)
    case getDebateHistory(teacherId: String, limit: Int)

    private func encodedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .getCurrentSchedule(let teacherId, let timestamp, let classId):
            var path = "/schedule/current?teacher_id=\(teacherId)&timestamp=\(timestamp)"
            if let classId {
                path += "&class_id=\(classId)"
            }
            return path
        case .createDebate:
            return "/debates/create"
        case .uploadSpeech:
            return "/speeches"
        case .getSpeechStatus(let speechId):
            return "/speeches/\(speechId)"
        case .getFeedbackContent(let speechId):
            return "/speeches/\(speechId)/feedback"
        case .getSpeechTraining(let speechId, let generate):
            return "/speeches/\(speechId)/training?generate=\(generate ? "true" : "false")"
        case .getComparativeAnalysis(let debateId, let generate):
            return "/debates/\(debateId)/comparative-analysis?generate=\(generate ? "true" : "false")"
        case .getStudentPortfolio(let teacherName, let studentName, let limit):
            return "/teachers/\(encodedPathComponent(teacherName))/students/\(encodedPathComponent(studentName))/portfolio?limit=\(limit)"
        case .getStudentBenchmarks(let teacherName, let studentName, let cohortLimit):
            return "/teachers/\(encodedPathComponent(teacherName))/students/\(encodedPathComponent(studentName))/benchmarks?cohort_limit=\(cohortLimit)"
        case .getDebateHistory(let teacherId, let limit):
            return "/teachers/\(teacherId)/debates?limit=\(limit)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createDebate, .uploadSpeech:
            return .post
        case .getCurrentSchedule, .getSpeechStatus, .getFeedbackContent, .getSpeechTraining, .getComparativeAnalysis, .getStudentPortfolio, .getStudentBenchmarks, .getDebateHistory:
            return .get
        }
    }

    func url(baseURL: String = Constants.API.baseURL) -> URL? {
        URL(string: baseURL + path)
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
