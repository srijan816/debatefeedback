//
//  AuthView.swift
//  DebateFeedback
//
//  Created by Claude on 10/24/25.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo/Title
            VStack(spacing: 16) {
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Constants.Colors.primaryAction)

                Text("Debate Feedback")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Record, Transcribe & Provide Feedback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Login Options
            VStack(spacing: 20) {
                // Teacher Login
                VStack(spacing: 12) {
                    TextField("Teacher Name", text: $viewModel.teacherName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disabled(viewModel.isLoading)

                    Button {
                        Task {
                            await viewModel.loginAsTeacher()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Login as Teacher")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Sizing.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.teacherName.isEmpty || viewModel.isLoading)
                }

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }

                // Guest Login
                Button {
                    viewModel.loginAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Sizing.minimumTapTarget)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)

                // Guest Mode Info
                Text("Guest mode: No history, feedback available until next session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated {
                if let teacher = viewModel.authenticatedTeacher {
                    coordinator.loginAsTeacher(teacher)
                } else {
                    coordinator.loginAsGuest()
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AppCoordinator())
}
