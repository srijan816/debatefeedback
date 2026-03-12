//
//  TeacherSessionRecovery.swift
//  DebateFeedback
//

import Foundation

extension DebateSession {
    var hasRecoverableContent: Bool {
        if !(speechRecordings?.isEmpty ?? true) {
            return true
        }

        return backendDebateId?.isEmpty == false
    }

    func matches(teacher: Teacher) -> Bool {
        if let sessionTeacherId = self.teacher?.id, sessionTeacherId == teacher.id {
            return true
        }

        guard let sessionTeacherName = self.teacher?.name else {
            return false
        }

        return sessionTeacherName.compare(
            teacher.name,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) == .orderedSame
    }

    var isRecoverableTeacherSession: Bool {
        teacher == nil && hasRecoverableContent
    }
}
