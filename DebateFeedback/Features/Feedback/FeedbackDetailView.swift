//
//  FeedbackDetailView.swift
//  DebateFeedback
//
//  Created by Claude on 10/28/25.
//

import SwiftUI
import WebKit

struct FeedbackDetailView: View {
    let recording: SpeechRecording

    @State private var feedbackContent: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var useWebView = true // Show HTML viewer by default
    @State private var webViewLoading = false
    @State private var webViewError: String?

    var body: some View {
        Group {
            if let urlString = recording.feedbackUrl, let url = URL(string: urlString), useWebView {
                // Show HTML feedback in WebView
                VStack(spacing: 0) {
                    // Speaker info bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recording.speakerName)
                                .font(.headline)
                            Text(recording.speakerPosition)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if webViewLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("\(recording.durationSeconds / 60):\(String(format: "%02d", recording.durationSeconds % 60))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))

                    // WebView with feedback or error
                    if let error = webViewError {
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
                                .padding()

                            Button {
                                UIApplication.shared.open(url)
                            } label: {
                                Label("Open in Safari", systemImage: "safari")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        WebView(url: url, isLoading: $webViewLoading, error: $webViewError)
                    }
                }
            } else {
                // Fallback to text-based viewer
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        speakerHeader

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
                .task {
                    await loadFeedback()
                }
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if let urlString = recording.feedbackUrl, URL(string: urlString) != nil {
                        Button {
                            if let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open in Safari", systemImage: "safari")
                        }

                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = recording.feedbackUrl {
                ShareSheet(items: [URL(string: url)!])
            }
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

// MARK: - WebView Component

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: String?

    init(url: URL, isLoading: Binding<Bool> = .constant(false), error: Binding<String?> = .constant(nil)) {
        self.url = url
        self._isLoading = isLoading
        self._error = error
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.isLoading = $isLoading
        context.coordinator.error = $error

        // Only load if not already loaded
        if webView.url != url {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 30

            print("📱 Loading feedback URL: \(url.absoluteString)")
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, error: $error)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var isLoading: Binding<Bool>
        var error: Binding<String?>

        init(isLoading: Binding<Bool>, error: Binding<String?>) {
            self.isLoading = isLoading
            self.error = error
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📱 WebView started loading")
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = true
                self.error.wrappedValue = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("📱 WebView finished loading successfully")
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to load: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = false
                self.error.wrappedValue = "Failed to load feedback: \(error.localizedDescription)"
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView provisional navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = false
                self.error.wrappedValue = "Could not connect to feedback server. Please check your connection."
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation
            decisionHandler(.allow)
        }
    }
}

#Preview {
    let recording = SpeechRecording(
        speakerName: "Alice Smith",
        speakerPosition: "Prop 1",
        localFilePath: "/path/to/file.m4a",
        durationSeconds: 300,
        debateSession: nil
    )
    recording.feedbackUrl = "http://144.217.164.110:12000/feedback/view/22"
    recording.processingStatus = .complete

    return NavigationStack {
        FeedbackDetailView(recording: recording)
    }
}
