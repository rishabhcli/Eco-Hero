//
//  AuthenticationView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var showingSignUp = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.ecoGreen, Color.ecoBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showingSignUp {
                SignUpView(showingSignUp: $showingSignUp)
            } else {
                SignInView(showingSignUp: $showingSignUp)
            }
        }
    }
}

struct SignInView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Binding var showingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Eco Hero")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Track your impact, save the planet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.bottom, 40)

            // Sign in form
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ecoGreen.opacity(0.8))
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Button("Forgot Password?") {
                    // TODO: Implement password reset
                }
                .foregroundStyle(.white)
                .font(.footnote)
            }
            .padding(.horizontal, 40)

            Spacer()

            // Sign up link
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.white)
                Button("Sign Up") {
                    showingSignUp = true
                }
                .foregroundStyle(.white)
                .fontWeight(.bold)
            }
            .padding(.bottom, 40)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred")
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                authManager.errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

struct SignUpView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Binding var showingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Create Account")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Join the Eco Hero community")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.bottom, 40)

            // Sign up form
            VStack(spacing: 20) {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)

                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ecoGreen.opacity(0.8))
                .cornerRadius(10)
                .disabled(isLoading || !isFormValid)
            }
            .padding(.horizontal, 40)

            Spacer()

            // Sign in link
            HStack {
                Text("Already have an account?")
                    .foregroundStyle(.white)
                Button("Sign In") {
                    showingSignUp = false
                }
                .foregroundStyle(.white)
                .fontWeight(.bold)
            }
            .padding(.bottom, 40)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !displayName.isEmpty &&
        password == confirmPassword && password.count >= 6
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }

        isLoading = true
        Task {
            do {
                try await authManager.signUp(email: email, password: password, displayName: displayName)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthenticationManager())
}
