//
//  Endpoints.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation

enum Endpoint {
    case login
    case getCurrentSchedule(teacherId: String, timestamp: String)
    case createDebate
    case uploadSpeech(debateId: String)
    case getSpeechStatus(speechId: String)
    case getDebateHistory(teacherId: String, limit: Int)

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .getCurrentSchedule(let teacherId, let timestamp):
            return "/schedule/current?teacher_id=\(teacherId)&timestamp=\(timestamp)"
        case .createDebate:
            return "/debates/create"
        case .uploadSpeech(let debateId):
            return "/debates/\(debateId)/speeches"
        case .getSpeechStatus(let speechId):
            return "/speeches/\(speechId)/status"
        case .getDebateHistory(let teacherId, let limit):
            return "/teachers/\(teacherId)/debates?limit=\(limit)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createDebate, .uploadSpeech:
            return .post
        case .getCurrentSchedule, .getSpeechStatus, .getDebateHistory:
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
