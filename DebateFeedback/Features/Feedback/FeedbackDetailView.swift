//
//  FeedbackDetailView.swift
//  DebateFeedback
//
//  Created by Claude on 10/28/25.
//

import SwiftUI

struct FeedbackDetailView: View {
    let recording: SpeechRecording

    @State private var feedbackContent: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Speaker Header
                speakerHeader

                // Feedback Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    feedbackContentView
                }
            }
            .padding()
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        if let urlString = recording.feedbackUrl,
                           let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open in Google Docs", systemImage: "doc.text")
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = recording.feedbackUrl {
                ShareSheet(items: [feedbackContent, URL(string: url)!])
            }
        }
        .task {
            await loadFeedback()
        }
    }

    // MARK: - Speaker Header

    private var speakerHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.speakerName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(recording.speakerPosition)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(recording.durationSeconds / 60):\(String(format: "%02d", recording.durationSeconds % 60))")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.primaryAction)
                }
            }

            Divider()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading feedback...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Unable to Load Feedback")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let urlString = recording.feedbackUrl {
                Button {
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open in Google Docs", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - Feedback Content View

    private var feedbackContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Parse and display feedback sections
            ForEach(parseFeedbackSections(), id: \.title) { section in
                FeedbackSection(title: section.title, content: section.content)
            }
        }
    }

    // MARK: - Load Feedback

    private func loadFeedback() async {
        // Check if we have cached feedback content
        if let cached = recording.feedbackContent, !cached.isEmpty {
            feedbackContent = cached
            isLoading = false
            return
        }

        guard let speechId = recording.speechId else {
            errorMessage = "Feedback is processing. Please check back soon."
            isLoading = false
            return
        }

        // Fetch feedback from the backend
        do {
            let response: FeedbackContentResponse = try await APIClient.shared.request(
                endpoint: .getFeedbackContent(speechId: speechId)
            )

            feedbackContent = response.feedbackText

            // Cache the feedback content
            recording.feedbackContent = feedbackContent
            try? await MainActor.run {
                // Save to database if we have access to context
                // Note: This would require passing ModelContext to this view
            }

            isLoading = false
        } catch {
            // If API call fails, fall back to showing message to open Google Docs
            errorMessage = "Feedback is ready in Google Docs. Tap the menu to open it."
            isLoading = false
        }
    }

    // MARK: - Parse Feedback

    private func parseFeedbackSections() -> [FeedbackSectionData] {
        // For now, display the raw content as a single section
        // You can enhance this to parse structured feedback
        if feedbackContent.isEmpty {
            return [FeedbackSectionData(
                title: "Feedback",
                content: "Feedback will appear here once processing is complete."
            )]
        }

        // Simple parsing - split by common headers
        var sections: [FeedbackSectionData] = []

        if feedbackContent.contains("Overall Performance") || feedbackContent.contains("Summary") {
            sections.append(FeedbackSectionData(
                title: "Overall Assessment",
                content: feedbackContent
            ))
        } else {
            sections.append(FeedbackSectionData(
                title: "AI Feedback",
                content: feedbackContent
            ))
        }

        return sections
    }
}

// MARK: - Feedback Section

struct FeedbackSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.primaryAction)

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct FeedbackSectionData {
    let title: String
    let content: String
}

#Preview {
    let recording = SpeechRecording(
        speakerName: "Alice Smith",
        speakerPosition: "Prop 1",
        localFilePath: "/path/to/file.m4a",
        durationSeconds: 300,
        debateSession: nil
    )
    recording.feedbackUrl = "https://docs.google.com/document/d/mock_id"
    recording.processingStatus = .complete

    return NavigationStack {
        FeedbackDetailView(recording: recording)
    }
}
