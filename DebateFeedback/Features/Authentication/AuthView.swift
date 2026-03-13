//
//  AuthView.swift
//  DebateFeedback
//
//

import SwiftUI
import SwiftData

struct AuthView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AuthViewModel()
    @State private var animateMascot = false
    @State private var showTeacherTools = false

    var body: some View {
        ZStack {
            // Light background with subtle glitters
            Constants.Colors.backgroundLight
                .ignoresSafeArea()

            SubtleGlitterView()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 34) {
                Spacer()

                // App Logo/Title with Mascot
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.softPink.opacity(0.16))
                            .frame(width: 210, height: 210)
                            .blur(radius: animateMascot ? 10 : 18)
                            .scaleEffect(animateMascot ? 1.02 : 0.94)

                        Image("mascot")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 225, height: 225)
                            .offset(y: animateMascot ? -6 : 4)
                    }
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateMascot)

                    Text("DebateMate")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.Colors.textPrimary)

                    Text("Intelligent feedback for modern debate")
                        .font(.body)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Login Section
                VStack(spacing: 20) {
                    // Teacher Login
                    VStack(spacing: 16) {
                        TextField("Teacher Name", text: $viewModel.teacherName)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .disabled(viewModel.isLoading)
                            .padding()
                            .background(Constants.Colors.backgroundSecondary)
                            .foregroundColor(Constants.Colors.textPrimary)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Constants.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                            )

                        Button {
                            HapticManager.shared.light()
                            Task {
                                await viewModel.loginAsTeacher()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Login as Teacher")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.Sizing.minimumTapTarget)
                        }
                        .gradientButtonStyle(isEnabled: !viewModel.teacherName.isEmpty && !viewModel.isLoading)
                        .disabled(viewModel.teacherName.isEmpty || viewModel.isLoading)
                        .accessibilityLabel("Login as teacher button")
                        .accessibilityHint("Sign in with your teacher account to access full features")
                    }

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Constants.Colors.textTertiary.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Constants.Colors.textTertiary.opacity(0.3))
                    }

                    // Guest Login
                    Button {
                        HapticManager.shared.light()
                        viewModel.loginAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.Sizing.minimumTapTarget)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Constants.Colors.softPink, Constants.Colors.softPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Constants.Colors.softPink.opacity(0.35), radius: 16, x: 0, y: 8)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Continue as guest button")
                    .accessibilityHint("Use the app with limited features and no history")

                    teacherToolsCard
                }
                .padding(.horizontal, 32)

                Spacer()

                // Footer
                Text("Capstone Debate ©")
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            }
        }
        .preferredColorScheme(ThemeManager.shared.preferredColorScheme)
        .onAppear {
            animateMascot = true
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated {
                HapticManager.shared.success()
                if let teacher = viewModel.authenticatedTeacher {
                    coordinator.loginAsTeacher(persistTeacher(teacher))
                } else {
                    coordinator.loginAsGuest()
                }
            }
        }
    }

    private var teacherToolsCard: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showTeacherTools.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Teacher?")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: showTeacherTools ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundColor(Constants.Colors.primaryBlue)
            }

            if showTeacherTools {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Import from Google Classroom", systemImage: "person.2.wave.2")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Constants.Colors.textPrimary)

                    Text("Roster sync is the next teacher shortcut we should add. For now, teacher login still unlocks saved sessions and the full feedback workflow.")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Constants.Colors.backgroundSecondary)
                .cornerRadius(16)
            }
        }
    }

    private func persistTeacher(_ teacher: Teacher) -> Teacher {
        let descriptor = FetchDescriptor<Teacher>()
        let existingTeachers = (try? modelContext.fetch(descriptor)) ?? []

        let storedTeacher: Teacher
        if let match = existingTeachers.first(where: {
            $0.id == teacher.id ||
            $0.name.compare(
                teacher.name,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }) {
            match.name = teacher.name
            match.deviceId = teacher.deviceId
            match.authToken = teacher.authToken
            match.isAdmin = teacher.isAdmin
            storedTeacher = match
        } else {
            let newTeacher = Teacher(
                id: teacher.id,
                name: teacher.name,
                deviceId: teacher.deviceId,
                authToken: teacher.authToken,
                isAdmin: teacher.isAdmin
            )
            modelContext.insert(newTeacher)
            storedTeacher = newTeacher
        }

        claimUnownedTeacherSessions(for: storedTeacher)
        try? modelContext.save()
        return storedTeacher
    }

    private func claimUnownedTeacherSessions(for teacher: Teacher) {
        let descriptor = FetchDescriptor<DebateSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []

        for session in sessions {
            if session.matches(teacher: teacher) {
                session.teacher = teacher
                session.isGuestMode = false
                continue
            }

            guard session.isRecoverableTeacherSession else {
                continue
            }

            session.teacher = teacher
            session.isGuestMode = false
        }
    }
}

#Preview {
    AuthView()
        .environment(AppCoordinator())
}
