//
//  AudioCompositionService.swift
//  DebateFeedback
//
//

import AVFoundation
import Foundation

enum AudioCompositionService {
    static func appendAudio(
        originalURL: URL,
        appendedURL: URL,
        outputURL: URL
    ) async throws -> TimeInterval {
        let composition = AVMutableComposition()

        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw RecordingError.fileError
        }

        let originalAsset = AVURLAsset(url: originalURL)
        let originalDuration = try await insert(asset: originalAsset, into: compositionTrack, at: .zero)

        let appendedAsset = AVURLAsset(url: appendedURL)
        let appendedDuration = try await insert(asset: appendedAsset, into: compositionTrack, at: originalDuration)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw RecordingError.fileError
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        try await export(exportSession)

        return originalDuration.seconds + appendedDuration.seconds
    }

    private static func insert(
        asset: AVURLAsset,
        into track: AVMutableCompositionTrack,
        at time: CMTime
    ) async throws -> CMTime {
        guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw RecordingError.fileError
        }

        let duration = try await asset.load(.duration)
        try track.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetTrack, at: time)
        return duration
    }

    private static func export(_ session: AVAssetExportSession) async throws {
        try await withCheckedThrowingContinuation { continuation in
            session.exportAsynchronously {
                switch session.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: session.error ?? RecordingError.fileError)
                case .cancelled:
                    continuation.resume(throwing: RecordingError.fileError)
                default:
                    break
                }
            }
        }
    }
}
