//
//  FeedbackDocumentURLResolver.swift
//  DebateFeedback
//
//

import Foundation

enum FeedbackDocumentURLResolver {
    static func resolve(speechId: String?, feedbackURL: String?) -> URL? {
        if let speechId, !speechId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return documentURL(for: speechId)
        }

        guard let feedbackURL else {
            return nil
        }

        return normalize(urlString: feedbackURL)
    }

    static func documentURL(for speechId: String) -> URL? {
        urlForPath("feedback/view/\(speechId)")
    }

    private static var siteRootURL: URL? {
        guard let apiURL = URL(string: Constants.API.baseURL),
              var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func normalize(urlString: String) -> URL? {
        let sanitized = sanitize(urlString)
        guard !sanitized.isEmpty else {
            return nil
        }

        if sanitized.hasPrefix("https://") || sanitized.hasPrefix("http://") {
            return URL(string: sanitized)
        }

        if sanitized.hasPrefix("api.genalphai.com") {
            return URL(string: "https://\(sanitized)")
        }

        if sanitized.hasPrefix("/") {
            return urlForPath(sanitized)
        }

        if sanitized.hasPrefix("feedback/view/") || sanitized.hasPrefix("api/") {
            return urlForPath(sanitized)
        }

        if let feedbackPathRange = sanitized.range(of: "feedback/view/") {
            let feedbackPath = String(sanitized[feedbackPathRange.lowerBound...])
            return urlForPath(feedbackPath)
        }

        return nil
    }

    private static func sanitize(_ rawValue: String) -> String {
        var sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

        while sanitized.hasPrefix(".") {
            sanitized.removeFirst()
        }

        while sanitized.hasSuffix(".") {
            sanitized.removeLast()
        }

        return sanitized
    }

    private static func urlForPath(_ path: String) -> URL? {
        guard let root = siteRootURL,
              var components = URLComponents(url: root, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/\(trimmedPath)"
        return components.url
    }
}
