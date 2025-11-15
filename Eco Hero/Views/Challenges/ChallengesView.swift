//
//  ChallengesView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @Query private var challenges: [Challenge]
    @Query private var achievements: [Achievement]

    @State private var selectedTab: ChallengeTab = .active

    enum ChallengeTab {
        case active
        case available
        case completed
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Active").tag(ChallengeTab.active)
                    Text("Available").tag(ChallengeTab.available)
                    Text("Completed").tag(ChallengeTab.completed)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .active:
                            activeChallengesSection
                        case .available:
                            availableChallengesSection
                        case .completed:
                            completedChallengesSection
                        }

                        // Achievements section
                        achievementsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Challenges & Badges")
            .background(Color(.systemGroupedBackground))
            .onAppear(perform: initializeChallenges)
        }
    }

    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let activeChallenges = challenges.filter { $0.isActive && $0.userID == authManager.currentUserID }

            if activeChallenges.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Active Challenges",
                    message: "Start a challenge to earn badges and XP!"
                )
            } else {
                ForEach(activeChallenges) { challenge in
                    ChallengeCardView(challenge: challenge)
                }
            }
        }
    }

    private var availableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let availableChallenges = challenges.filter { $0.status == .notStarted }

            if availableChallenges.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "All Caught Up!",
                    message: "You've started all available challenges."
                )
            } else {
                ForEach(availableChallenges) { challenge in
                    AvailableChallengeCardView(challenge: challenge, onJoin: {
                        joinChallenge(challenge)
                    })
                }
            }
        }
    }

    private var completedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let completedChallenges = challenges.filter {
                $0.status == .completed && $0.userID == authManager.currentUserID
            }

            if completedChallenges.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Completed Challenges",
                    message: "Complete challenges to see them here!"
                )
            } else {
                ForEach(completedChallenges) { challenge in
                    CompletedChallengeCardView(challenge: challenge)
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)

            let userAchievements = achievements.filter { $0.userID == authManager.currentUserID }

            if userAchievements.isEmpty {
                Text("No achievements yet. Complete challenges to earn badges!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(userAchievements) { achievement in
                        AchievementBadgeView(achievement: achievement)
                    }
                }
            }
        }
        .padding(.top, 24)
    }

    private func joinChallenge(_ challenge: Challenge) {
        guard let userID = authManager.currentUserID else { return }
        challenge.join(userID: userID)

        do {
            try modelContext.save()
        } catch {
            print("Error joining challenge: \(error)")
        }
    }

    private func initializeChallenges() {
        // Create default challenges if none exist
        if challenges.isEmpty {
            createDefaultChallenges()
        }
    }

    private func createDefaultChallenges() {
        let defaultChallenges = [
            Challenge(
                title: "Meatless Week",
                description: "Go vegetarian or vegan for 7 consecutive days",
                type: .weekly,
                category: .meals,
                iconName: "leaf.fill",
                targetCount: 7,
                rewardXP: 500,
                badgeID: "meatless_week"
            ),
            Challenge(
                title: "Car-Free Week",
                description: "Avoid using a car for 7 days",
                type: .weekly,
                category: .transport,
                iconName: "bicycle",
                targetCount: 7,
                rewardXP: 600,
                badgeID: "car_free_week"
            ),
            Challenge(
                title: "Plastic-Free Challenge",
                description: "Avoid single-use plastics for 7 days",
                type: .weekly,
                category: .plastic,
                iconName: "bag.fill",
                targetCount: 7,
                rewardXP: 450,
                badgeID: "plastic_free"
            ),
            Challenge(
                title: "5 Eco Actions",
                description: "Log 5 eco-friendly activities this week",
                type: .weekly,
                iconName: "star.fill",
                targetCount: 5,
                rewardXP: 250
            )
        ]

        for challenge in defaultChallenges {
            modelContext.insert(challenge)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error creating default challenges: \(error)")
        }
    }
}

struct ChallengeCardView: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.ecoGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)

                    Text(challenge.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let endDate = challenge.endDate {
                    VStack(alignment: .trailing) {
                        Text("Ends")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(endDate, style: .date)
                            .font(.caption)
                    }
                }
            }

            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(challenge.currentProgress) / \(challenge.targetCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                ProgressView(
                    value: Double(challenge.currentProgress),
                    total: Double(challenge.targetCount)
                )
                .tint(Color.ecoGreen)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AvailableChallengeCardView: View {
    let challenge: Challenge
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.ecoGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)

                    Text(challenge.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.ecoGreen)
            }

            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onJoin) {
                Text("Join Challenge")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.ecoGreen)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CompletedChallengeCardView: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(Color.ecoGreen)

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)

                Text("Completed!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(Int(challenge.rewardXP)) XP")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.ecoGreen)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.ecoGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: achievement.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(achievement.isUnlocked ? Color.ecoGreen : Color.gray)
            }

            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.5)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ChallengesView()
        .environment(AuthenticationManager())
        .modelContainer(for: [Challenge.self, Achievement.self], inMemory: true)
}
