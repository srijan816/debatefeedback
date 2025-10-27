//
//  AuthenticationService.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData

@Observable
final class AuthenticationService {
    static let shared = AuthenticationService()

    private(set) var isAuthenticated = false
    private(set) var currentTeacher: Teacher?
    private let apiClient = APIClient.shared

    private init() {
        checkStoredAuth()
    }

    // MARK: - Authentication Methods

    func loginAsTeacher(name: String) async throws -> Teacher {
        guard let deviceId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.deviceId) else {
            throw NetworkError.unknown(NSError(domain: "No device ID", code: -1))
        }

        // In mock mode, create a fake teacher
        if Constants.API.useMockData {
            let teacher = Teacher(
                name: name,
                deviceId: deviceId,
                authToken: "mock_token_\(UUID().uuidString)",
                isAdmin: false
            )

            // Store auth token
            await apiClient.setAuthToken(teacher.authToken)
            UserDefaults.standard.set(teacher.authToken, forKey: Constants.UserDefaultsKeys.authToken)
            UserDefaults.standard.set(teacher.id.uuidString, forKey: Constants.UserDefaultsKeys.currentTeacherId)

            self.currentTeacher = teacher
            self.isAuthenticated = true

            return teacher
        }

        // Real API call
        let response: LoginResponse = try await apiClient.request(
            endpoint: .login,
            body: LoginRequest(teacherId: name, deviceId: deviceId)
        )

        let teacher = Teacher(
            id: UUID(uuidString: response.teacher.id) ?? UUID(),
            name: response.teacher.name,
            deviceId: deviceId,
            authToken: response.token,
            isAdmin: response.teacher.isAdmin
        )

        // Store auth token
        await apiClient.setAuthToken(response.token)
        UserDefaults.standard.set(response.token, forKey: Constants.UserDefaultsKeys.authToken)
        UserDefaults.standard.set(teacher.id.uuidString, forKey: Constants.UserDefaultsKeys.currentTeacherId)

        self.currentTeacher = teacher
        self.isAuthenticated = true

        return teacher
    }

    func loginAsGuest() {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.isGuestMode)
        self.isAuthenticated = true
        self.currentTeacher = nil
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.authToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentTeacherId)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.isGuestMode)

        Task {
            await apiClient.setAuthToken(nil)
        }

        self.currentTeacher = nil
        self.isAuthenticated = false
    }

    // MARK: - Private Methods

    private func checkStoredAuth() {
        if let token = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.authToken),
           let teacherIdString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentTeacherId),
           let _ = UUID(uuidString: teacherIdString) {

            // In production, validate token with backend
            // For now, just restore the session
            Task {
                await apiClient.setAuthToken(token)
            }

            // Would need to fetch teacher details from DB here
            self.isAuthenticated = true
        } else if UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isGuestMode) {
            self.isAuthenticated = true
            self.currentTeacher = nil
        }
    }

    // MARK: - Helper Properties

    var isGuestMode: Bool {
        isAuthenticated && currentTeacher == nil
    }

    var canAccessHistory: Bool {
        isAuthenticated && currentTeacher != nil
    }
}

// MARK: - Request Models

struct LoginRequest: Encodable {
    let teacherId: String
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case teacherId = "teacher_id"
        case deviceId = "device_id"
    }
}
