//
//  DebateSession.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import Foundation
import SwiftData

@Model
final class DebateSession {
    var id: UUID
    var motion: String
    var format: DebateFormat
    var studentLevel: StudentLevel
    var speechTimeSeconds: Int
    var replyTimeSeconds: Int?
    var createdAt: Date
    var isGuestMode: Bool

    // Backend integration
    var backendDebateId: String? // The debate ID from the backend API

    // Team composition stored as JSON-encoded data
    var teamCompositionData: Data?

    // Relationships
    var teacher: Teacher?
    var students: [Student]?

    @Relationship(deleteRule: .cascade, inverse: \SpeechRecording.debateSession)
    var speechRecordings: [SpeechRecording]?

    init(
        id: UUID = UUID(),
        motion: String,
        format: DebateFormat,
        studentLevel: StudentLevel,
        speechTimeSeconds: Int,
        replyTimeSeconds: Int? = nil,
        isGuestMode: Bool = false,
        teacher: Teacher? = nil
    ) {
        self.id = id
        self.motion = motion
        self.format = format
        self.studentLevel = studentLevel
        self.speechTimeSeconds = speechTimeSeconds
        self.replyTimeSeconds = replyTimeSeconds
        self.isGuestMode = isGuestMode
        self.createdAt = Date()
        self.teacher = teacher
    }

    // Helper to work with team composition
    var teamComposition: TeamComposition? {
        get {
            guard let data = teamCompositionData else { return nil }
            return try? JSONDecoder().decode(TeamComposition.self, from: data)
        }
        set {
            teamCompositionData = try? JSONEncoder().encode(newValue)
        }
    }
}

enum DebateFormat: String, Codable, CaseIterable {
    case wsdc = "WSDC"
    case modifiedWsdc = "Modified WSDC"
    case bp = "BP"
    case ap = "AP"
    case australs = "Australs"

    var displayName: String { rawValue }

    var defaultSpeechTime: Int {
        switch self {
        case .wsdc: return 480 // 8 minutes
        case .modifiedWsdc: return 240 // 4 minutes
        case .bp: return 420 // 7 minutes
        case .ap: return 360 // 6 minutes
        case .australs: return 480 // 8 minutes
        }
    }

    var hasReplySpeeches: Bool {
        switch self {
        case .wsdc, .modifiedWsdc, .australs: return true
        case .bp, .ap: return false
        }
    }

    var defaultReplyTime: Int? {
        switch self {
        case .wsdc: return 240 // 4 minutes
        case .modifiedWsdc: return 120 // 2 minutes
        case .australs: return 180 // 3 minutes
        case .bp, .ap: return nil
        }
    }

    var teamStructure: TeamStructure {
        switch self {
        case .wsdc, .modifiedWsdc, .australs:
            return .propOpp
        case .bp:
            return .britishParliamentary
        case .ap:
            return .asianParliamentary
        }
    }
}

enum TeamStructure {
    case propOpp // Prop/Opp (3v3)
    case britishParliamentary // OG, OO, CG, CO (2 per team)
    case asianParliamentary // Government/Opposition (2v2)
}

struct TeamComposition: Codable {
    // Standard 3v3 formats
    var prop: [String]? // Student IDs
    var opp: [String]?

    // British Parliamentary
    var og: [String]?
    var oo: [String]?
    var cg: [String]?
    var co: [String]?

    // Helper to get all speaker positions in order
    func getSpeakerOrder(format: DebateFormat) -> [(studentId: String, position: String)] {
        switch format {
        case .wsdc, .modifiedWsdc, .australs:
            var speakers: [(String, String)] = []
            if let prop = prop {
                for (index, id) in prop.enumerated() {
                    speakers.append((id, "Prop \(index + 1)"))
                }
            }
            if let opp = opp {
                for (index, id) in opp.enumerated() {
                    speakers.append((id, "Opp \(index + 1)"))
                }
            }
            return speakers

        case .bp:
            var speakers: [(String, String)] = []
            if let og = og {
                for (index, id) in og.enumerated() {
                    speakers.append((id, "OG \(index + 1)"))
                }
            }
            if let oo = oo {
                for (index, id) in oo.enumerated() {
                    speakers.append((id, "OO \(index + 1)"))
                }
            }
            if let cg = cg {
                for (index, id) in cg.enumerated() {
                    speakers.append((id, "CG \(index + 1)"))
                }
            }
            if let co = co {
                for (index, id) in co.enumerated() {
                    speakers.append((id, "CO \(index + 1)"))
                }
            }
            return speakers

        case .ap:
            var speakers: [(String, String)] = []
            if let prop = prop {
                for (index, id) in prop.enumerated() {
                    speakers.append((id, "Gov \(index + 1)"))
                }
            }
            if let opp = opp {
                for (index, id) in opp.enumerated() {
                    speakers.append((id, "Opp \(index + 1)"))
                }
            }
            return speakers
        }
    }
}
