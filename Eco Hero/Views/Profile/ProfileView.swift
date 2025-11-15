//
//  ProfileView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @Query private var profiles: [UserProfile]
    @Query private var activities: [EcoActivity]

    @State private var showingSettings = false
    @State private var showingLogoutAlert = false

    private var userProfile: UserProfile? {
        profiles.first { $0.firebaseUID == authManager.currentUserID ?? "" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats overview
                    statsOverview

                    // Achievements summary
                    achievementsSummary

                    // Activity history
                    activityHistory

                    // Settings and actions
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ecoGreen, Color.ecoBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Text(userProfile?.displayName.prefix(1).uppercased() ?? "E")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Name and level
            VStack(spacing: 8) {
                Text(userProfile?.displayName ?? "Eco Hero")
                    .font(.title2)
                    .fontWeight(.bold)

                if let profile = userProfile {
                    Text(AppConstants.Levels.levelTitle(for: profile.currentLevel))
                        .font(.subheadline)
                        .foregroundStyle(Color.ecoGreen)
                        .fontWeight(.medium)

                    HStack(spacing: 16) {
                        Label("Level \(profile.currentLevel)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("\(profile.streak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Member since
            if let profile = userProfile {
                Text("Member since \(profile.joinDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Impact")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "CO₂ Saved",
                    value: userProfile?.totalCarbonSavedKg ?? 0,
                    unit: "kg",
                    icon: "cloud.fill",
                    color: .green
                )

                StatCard(
                    title: "Water Saved",
                    value: userProfile?.totalWaterSavedLiters ?? 0,
                    unit: "L",
                    icon: "drop.fill",
                    color: .blue
                )

                StatCard(
                    title: "Activities",
                    value: Double(activities.count),
                    unit: "total",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Streak",
                    value: Double(userProfile?.longestStreak ?? 0),
                    unit: "longest",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }

    private var achievementsSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    AchievementsListView()
                }
                .font(.caption)
                .foregroundStyle(Color.ecoGreen)
            }

            HStack(spacing: 12) {
                ForEach(0..<5) { index in
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "star.fill")
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private var activityHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    ActivitiesListView()
                }
                .font(.caption)
                .foregroundStyle(Color.ecoGreen)
            }

            if activities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No activities yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                ForEach(Array(activities.prefix(3))) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingSettings = true
            } label: {
                HStack {
                    Label("Settings", systemImage: "gearshape")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            Button {
                showingLogoutAlert = true
            } label: {
                HStack {
                    Label("Sign Out", systemImage: "arrow.right.square")
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value.abbreviated)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(AuthenticationManager.self) private var authManager

    private var userProfile: UserProfile? {
        profiles.first { $0.firebaseUID == authManager.currentUserID ?? "" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Sound Effects", isOn: Binding(
                        get: { userProfile?.soundEnabled ?? true },
                        set: { newValue in
                            if var profile = userProfile {
                                profile.soundEnabled = newValue
                            }
                        }
                    ))

                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { userProfile?.hapticsEnabled ?? true },
                        set: { newValue in
                            if var profile = userProfile {
                                profile.hapticsEnabled = newValue
                            }
                        }
                    ))

                    Toggle("Notifications", isOn: Binding(
                        get: { userProfile?.notificationsEnabled ?? true },
                        set: { newValue in
                            if var profile = userProfile {
                                profile.notificationsEnabled = newValue
                            }
                        }
                    ))
                }

                Section("Account") {
                    if let email = authManager.currentUserEmail {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementsListView: View {
    @Query private var achievements: [Achievement]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadgeView(achievement: achievement)
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ProfileView()
        .environment(AuthenticationManager())
        .modelContainer(for: [UserProfile.self, EcoActivity.self], inMemory: true)
}
