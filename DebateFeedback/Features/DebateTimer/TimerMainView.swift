//
//  TimerMainView.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import SwiftUI
import SwiftData

struct TimerMainView: View {
    let debateSession: DebateSession

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: TimerViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                timerContent(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TimerViewModel(debateSession: debateSession, modelContext: modelContext)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { if !$0 { viewModel?.showError = false } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func timerContent(viewModel: TimerViewModel) -> some View {
        VStack(spacing: 0) {
            // Motion Header
            motionHeader(viewModel: viewModel)

            // Main Timer Display
            Spacer()

            timerDisplay(viewModel: viewModel)

            Spacer()

            // Control Buttons
            controlButtons(viewModel: viewModel)

            // Navigation
            speakerNavigation(viewModel: viewModel)

            // Recordings List (if any completed)
            if !viewModel.recordings.isEmpty {
                recordingsList(viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isRecording)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isDebateComplete {
                    Button("View Feedback") {
                        coordinator.finishDebate()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Motion Header

    private func motionHeader(viewModel: TimerViewModel) -> some View {
        VStack(spacing: 12) {
            Text("Motion")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(debateSession.motion)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            // Current Speaker Info
            VStack(spacing: 4) {
                Text(viewModel.currentSpeaker.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(viewModel.currentSpeaker.position)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Timer Display

    private func timerDisplay(viewModel: TimerViewModel) -> some View {
        VStack(spacing: 24) {
            // Timer with Bell Icon
            HStack(spacing: 16) {
                Spacer()

                Text(viewModel.formattedTime)
                    .font(.system(size: Constants.timerFontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.isOvertime ? Constants.Colors.error : .primary)

                // Bell Icon (only show when timer is running)
                if viewModel.isRecording {
                    Button {
                        viewModel.ringBell()
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Constants.Colors.primaryAction)
                            .symbolEffect(.bounce, value: viewModel.elapsedTime)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(viewModel.isOvertime ?
                              Constants.Colors.error :
                              Constants.Colors.primaryAction)
                        .frame(width: geometry.size.width * viewModel.progressPercentage)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
            .padding(.horizontal, 40)

            // Recording Indicator
            if viewModel.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Constants.Colors.recordingActive)
                        .frame(width: 12, height: 12)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isRecording)

                    Text("REC")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.recordingActive)
                }
            }
        }
    }

    // MARK: - Control Buttons

    private func controlButtons(viewModel: TimerViewModel) -> some View {
        HStack(spacing: 20) {
            if viewModel.isRecording {
                Button {
                    viewModel.stopTimer()
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("STOP")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.Sizing.minimumTapTarget * 1.5)
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.Colors.recordingActive)
            } else {
                Button {
                    viewModel.startTimer()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("START")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.Sizing.minimumTapTarget * 1.5)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }

    // MARK: - Speaker Navigation

    private func speakerNavigation(viewModel: TimerViewModel) -> some View {
        HStack {
            Button {
                viewModel.previousSpeaker()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(!viewModel.canGoBack || viewModel.isRecording)

            Spacer()

            Text("Speaker \(viewModel.speakerProgress)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                viewModel.nextSpeaker()
            } label: {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .disabled(!viewModel.canGoForward || viewModel.isRecording)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Recordings List

    private func recordingsList(viewModel: TimerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Completed Speeches (\(viewModel.completedSpeeches))")
                    .font(.headline)

                Spacer()

                Text("Double-tap to play")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recordings, id: \.id) { recording in
                        RecordingCard(recording: recording, viewModel: viewModel)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .tertiarySystemBackground))
    }
}

// MARK: - Recording Card

struct RecordingCard: View {
    let recording: SpeechRecording
    @Bindable var viewModel: TimerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.speakerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Playback indicator
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                }
            }

            Text(recording.speakerPosition)
                .font(.caption)
                .foregroundColor(.secondary)

            // Duration/Playback time
            Text(viewModel.getPlaybackTime(for: recording))
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                statusIndicator

                if recording.uploadStatus == .uploading,
                   let progress = viewModel.uploadProgress[recording.id] {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 60)
                }
            }

            // Playback progress bar
            if isPlaying {
                ProgressView(value: viewModel.getPlaybackProgress(for: recording))
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
        }
        .padding(12)
        .frame(width: 170)
        .background(isPlaying ? Color.blue.opacity(0.1) : Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPlaying ? Color.blue : statusColor, lineWidth: isPlaying ? 3 : 2)
        )
        .onTapGesture(count: 2) {
            viewModel.togglePlayback(for: recording)
        }
    }

    private var isPlaying: Bool {
        viewModel.playingRecordingId == recording.id && viewModel.isPlaying
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption2)
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        if recording.processingStatus == .complete {
            return Constants.Colors.complete
        } else if recording.uploadStatus == .failed || recording.processingStatus == .failed {
            return Constants.Colors.failed
        } else if recording.uploadStatus == .uploading {
            return Constants.Colors.uploading
        } else if recording.processingStatus == .processing {
            return Constants.Colors.processing
        }
        return Constants.Colors.pending
    }

    private var statusText: String {
        if recording.processingStatus == .complete {
            return "Ready"
        } else if recording.uploadStatus == .failed {
            return "Failed"
        } else if recording.uploadStatus == .uploading {
            return "Uploading"
        } else if recording.processingStatus == .processing {
            return "Processing"
        }
        return "Pending"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DebateSession.self, configurations: config)

    let session = DebateSession(
        motion: "This house believes that social media does more harm than good",
        format: .wsdc,
        studentLevel: .secondary,
        speechTimeSeconds: 300
    )

    var composition = TeamComposition()
    composition.prop = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    composition.opp = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    session.teamComposition = composition

    return NavigationStack {
        TimerMainView(debateSession: session)
            .environment(AppCoordinator())
            .modelContainer(container)
    }
}
