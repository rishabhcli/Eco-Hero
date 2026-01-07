//
//  AuthenticationView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var showingSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppConstants.Layout.sectionSpacing) {
                        heroSection
                        segmentedControl

                        Group {
                            if showingSignUp {
                                SignUpView(showingSignUp: $showingSignUp)
                            } else {
                                SignInView(showingSignUp: $showingSignUp)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showingSignUp)

                        benefitsSection
                        privacySection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            AppConstants.Gradients.hero
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.12))
                .blur(radius: 120)
                .frame(width: 340, height: 340)
                .offset(x: -180, y: -240)

            Circle()
                .fill(Color.white.opacity(0.08))
                .blur(radius: 140)
                .frame(width: 280, height: 280)
                .offset(x: 160, y: -180)

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Welcome to Eco Hero")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Log mindful actions, earn badges, and get climate-positive guidance every day.")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(highlightCards) { highlight in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(highlight.title, systemImage: highlight.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(highlight.value)
                            .font(.title2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            }
        }
        .glassCardStyle()
    }

    private var segmentedControl: some View {
        HStack(spacing: 6) {
            segmentButton(title: "Sign In", isActive: !showingSignUp) {
                showingSignUp = false
            }

            segmentButton(title: "Create Account", isActive: showingSignUp) {
                showingSignUp = true
            }
        }
        .padding(6)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func segmentButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isActive ? .white : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(isActive ? AnyShapeStyle(AppConstants.Gradients.accent) : AnyShapeStyle(Color.clear))
                )
        }
        .buttonStyle(.plain)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Eco Hero")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(authBenefits) { benefit in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: benefit.icon)
                            .font(.title2)
                            .foregroundStyle(Color.ecoGreen)
                        Text(benefit.title)
                            .font(.headline)
                        Text(benefit.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .secondaryCardStyle()
                }
            }
        }
        .glassCardStyle()
    }

    private var privacySection: some View {
        VStack(spacing: 6) {
            Text("Your data stays on device. Optionally connect to the cloud when you're ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("By continuing you agree to our privacy policy and terms of use.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

private struct AuthHighlight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}

private let highlightCards: [AuthHighlight] = [
    AuthHighlight(title: "Impact Logged", value: "1.2M+", icon: "leaf.fill"),
    AuthHighlight(title: "Tips Shared", value: "150+", icon: "sparkles"),
    AuthHighlight(title: "Badges Earned", value: "4.8K", icon: "trophy.fill")
]

private struct AuthBenefit: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

private let authBenefits: [AuthBenefit] = [
    AuthBenefit(icon: "chart.bar.doc.horizontal", title: "Live Progress", description: "Beautiful dashboards and streaks keep you inspired."),
    AuthBenefit(icon: "bolt.fill", title: "Smart Coaching", description: "AI-powered nudges suggest the highest-impact actions."),
    AuthBenefit(icon: "lock.shield", title: "Private By Design", description: "Offline-first storage keeps your data safe."),
    AuthBenefit(icon: "gamecontroller.fill", title: "Gamified Challenges", description: "Earn XP, unlock badges, and climb eco tiers.")
]

struct SignInView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Binding var showingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back")
                    .font(.title2.bold())
                Text("Sign in to continue building sustainable habits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                inputField(icon: "at", placeholder: "Email", text: $email) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                inputField(icon: "lock.fill", placeholder: "Password", text: $password) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
            }

            Button("Forgot password?") {
                // TODO: implement password reset flow
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button(action: signIn) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius)
                        .fill(AppConstants.Gradients.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            HStack(spacing: 4) {
                Text("New to Eco Hero?")
                    .foregroundStyle(.secondary)
                Button("Create an account") {
                    showingSignUp = true
                }
                .font(.subheadline.bold())
            }
        }
        .glassCardStyle()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred")
        }
    }

    @ViewBuilder
    private func inputField<Content: View>(icon: String, placeholder: String, text: Binding<String>, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            content()
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder)
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
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
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Set up your profile")
                    .font(.title2.bold())
                Text("We use your name to personalize badges and the leaderboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                inputField(icon: "person.crop.circle", placeholder: "Display Name", text: $displayName) {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                }

                inputField(icon: "at", placeholder: "Email", text: $email) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                inputField(icon: "lock.fill", placeholder: "Password", text: $password) {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                }

                inputField(icon: "lock.circle", placeholder: "Confirm Password", text: $confirmPassword) {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Minimum 6 characters", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Password must match", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(password == confirmPassword && !password.isEmpty ? .green : .secondary)
            }

            Button(action: signUp) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius)
                        .fill(AppConstants.Gradients.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isLoading)

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(.secondary)
                Button("Sign in") {
                    showingSignUp = false
                }
                .font(.subheadline.bold())
            }
        }
        .glassCardStyle()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    private func inputField<Content: View>(icon: String, placeholder: String, text: Binding<String>, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            content()
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder)
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
