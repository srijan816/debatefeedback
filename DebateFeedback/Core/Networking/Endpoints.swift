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
    case uploadSpeech(debateId: String)
    case getSpeechStatus(speechId: String)
    case getFeedbackContent(speechId: String)
    case getDebateHistory(teacherId: String, limit: Int)

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
        case .uploadSpeech(let debateId):
            return "/debates/\(debateId)/speeches"
        case .getSpeechStatus(let speechId):
            return "/speeches/\(speechId)/status"
        case .getFeedbackContent(let speechId):
            return "/speeches/\(speechId)/feedback"
        case .getDebateHistory(let teacherId, let limit):
            return "/teachers/\(teacherId)/debates?limit=\(limit)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createDebate, .uploadSpeech:
            return .post
        case .getCurrentSchedule, .getSpeechStatus, .getFeedbackContent, .getDebateHistory:
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
