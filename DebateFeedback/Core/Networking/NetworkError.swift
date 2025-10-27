//
//  NetworkError.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case serverError(statusCode: Int)
    case decodingError
    case encodingError
    case unauthorized
    case notFound
    case timeout
    case uploadFailed(reason: String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noConnection:
            return Constants.ErrorMessages.networkUnavailable
        case .serverError(let statusCode):
            return "Server error (Status: \(statusCode))"
        case .decodingError:
            return "Failed to decode server response"
        case .encodingError:
            return "Failed to encode request data"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timed out. Please try again."
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var isRetriable: Bool {
        switch self {
        case .noConnection, .timeout:
            return true
        case .serverError(let code):
            return code >= 500 // Retry server errors but not client errors
        default:
            return false
        }
    }
}
