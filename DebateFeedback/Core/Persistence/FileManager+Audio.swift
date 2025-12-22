//
//  FileManager+Audio.swift
//  DebateFeedback
//
//

import Foundation

extension FileManager {
    /// Returns the URL for the audio recordings directory
    static var audioRecordingsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioDir = documentsPath.appendingPathComponent(Constants.Files.audioDirectory)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: audioDir.path) {
            try? FileManager.default.createDirectory(
                at: audioDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return audioDir
    }

    /// Generates a unique filename for an audio recording
    static func generateAudioFilename(
        debateId: String,
        speakerName: String,
        position: String
    ) -> String {
        let timestamp = Date().iso8601String
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "")
        let sanitizedName = speakerName.sanitizedForFilename()
        let sanitizedPosition = position.sanitizedForFilename()

        return "\(debateId)_\(sanitizedName)_\(sanitizedPosition)_\(timestamp).\(Constants.Audio.fileExtension)"
    }

    /// Returns the full URL for a recording file
    static func audioFileURL(filename: String) -> URL {
        audioRecordingsDirectory.appendingPathComponent(filename)
    }

    /// Deletes a recording file
    static func deleteAudioFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.removeItem(at: url)
    }

    /// Cleans up old recordings (older than configured days)
    static func cleanupOldRecordings() {
        let audioDir = audioRecordingsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: audioDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let cutoffDate = Date().addingTimeInterval(-TimeInterval(Constants.Files.maxLocalStorageDays * 24 * 60 * 60))

        for file in files {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                  let creationDate = attributes[.creationDate] as? Date else {
                continue
            }

            if creationDate < cutoffDate {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// Returns the size of a file in bytes
    static func fileSize(at path: String) -> Int64? {
        let url = URL(fileURLWithPath: path)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}
