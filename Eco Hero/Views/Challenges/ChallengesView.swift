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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(FoundationContentService.self) private var foundationContentService
    @Query private var challenges: [Challenge]
    @Query private var achievements: [Achievement]

    @State private var selectedTab: ChallengeTab = .active
    @State private var isGeneratingChallenge = false
    @State private var generationMessage: String?
    @Namespace private var glassNamespace

    enum ChallengeTab: String, CaseIterable, Identifiable {
        case active = "Active"
        case available = "Available"
        case completed = "Done"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .active: return "flame.fill"
            case .available: return "sparkles"
            case .completed: return "seal.fill"
            }
        }
    }

    private var activeChallenges: [Challenge] {
        challenges.filter { $0.isActive && $0.userID == authManager.currentUserID }
    }

    private var availableChallenges: [Challenge] {
        challenges.filter { $0.status == .notStarted }
    }

    private var completedChallenges: [Challenge] {
        challenges.filter { $0.status == .completed && $0.userID == authManager.currentUserID }
    }

    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.userID == authManager.currentUserID && $0.isUnlocked }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Layout.sectionSpacing) {
                    heroBanner
                    tabPicker

                    switch selectedTab {
                    case .active:
                        challengesSection(title: "In progress", subtitle: "Stay on top of your commitments", items: activeChallenges) { challenge in
                            ChallengeCardView(challenge: challenge)
                        }
                    case .available:
                        challengesSection(title: "New missions", subtitle: "Join a challenge to boost your XP", items: availableChallenges) { challenge in
                            AvailableChallengeCardView(challenge: challenge) {
                                joinChallenge(challenge)
                            }
                        }
                    case .completed:
                        challengesSection(title: "Victories", subtitle: "Celebrate everything you've finished", items: completedChallenges) { challenge in
                            CompletedChallengeCardView(challenge: challenge)
                        }
                    }

                    achievementsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.green.opacity(0.3), Color.black]
                        : [Color.green.opacity(0.15), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Challenges")
            .onAppear(perform: initializeChallenges)
        }
    }

    private var heroBanner: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Level up your eco journey")
                            .font(.title2.bold())
                        Text("Complete themed missions for streaks, XP, and badges.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .padding(16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                        .glassEffectID("trophy-icon", in: glassNamespace)
                }

                HStack(spacing: 12) {
                    HeroStatView(title: "Active", value: "\(activeChallenges.count)", icon: "flame.fill")
                    HeroStatView(title: "Completed", value: "\(completedChallenges.count)", icon: "checkmark.seal.fill")
                    HeroStatView(title: "Badges", value: "\(unlockedAchievements.count)", icon: "star.fill")
                }

                Button {
                    requestFoundationChallenge()
                } label: {
                    if isGeneratingChallenge {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Generate new mission", systemImage: "sparkles")
                            .font(.headline)
                    }
                }
                .buttonStyle(.glass(.regular.interactive()))
                .glassEffectID("generate-mission", in: glassNamespace)
                .disabled(isGeneratingChallenge)

                if let generationMessage {
                    Text(generationMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(24)
            .glassEffect(.regular.tint(Color.ecoGreen.opacity(0.4)), in: .rect(cornerRadius: 32))
            .glassEffectID("hero-banner", in: glassNamespace)
        }
        .foregroundStyle(.white)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    private var tabPicker: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(ChallengeTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                    }
                    .buttonStyle(.glass(selectedTab == tab
                        ? .regular.tint(AppConstants.Colors.ocean.opacity(0.5)).interactive()
                        : .regular.interactive()))
                    .glassEffectID("tab-\(tab.rawValue)", in: glassNamespace)
                }
            }
        }
        .padding(6)
        .glassEffect(.regular.tint(Color.primary.opacity(0.05)), in: .rect(cornerRadius: 24))
        .glassEffectID("tab-picker", in: glassNamespace)
    }

    private func challengesSection<Content: View>(title: String, subtitle: String, items: [Challenge], @ViewBuilder content: @escaping (Challenge) -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                EmptyStateView(
                    icon: "leaf",
                    title: "Nothing to show",
                    message: "Check back soon or try another tab."
                )
                .cardStyle()
            } else {
                VStack(spacing: 14) {
                    ForEach(items) { challenge in
                        content(challenge)
                    }
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Badges")
                    .font(.headline)
                Spacer()
                NavigationLink("View all") {
                    AchievementsListView()
                }
                .font(.footnote.bold())
            }

            if unlockedAchievements.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "No badges yet",
                    message: "Complete challenges to unlock your first badge."
                )
                .cardStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(unlockedAchievements) { achievement in
                            AchievementBadgeView(achievement: achievement)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.top, 8)
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
        if challenges.isEmpty {
            createDefaultChallenges()
        }
    }

    private func requestFoundationChallenge() {
        guard !isGeneratingChallenge else { return }
        isGeneratingChallenge = true
        generationMessage = nil

        Task {
            do {
                let blueprint = try await foundationContentService.generateChallenge()
                await MainActor.run {
                    let challenge = Challenge(
                        title: blueprint.title,
                        description: blueprint.summary,
                        type: mapCadence(blueprint.cadence),
                        category: mapCategory(blueprint.category),
                        iconName: blueprint.symbolName,
                        targetCount: blueprint.targetCount,
                        rewardXP: Double(blueprint.rewardXP)
                    )
                    modelContext.insert(challenge)
                    try? modelContext.save()
                    generationMessage = "Added '\(challenge.title)' to Available."
                    isGeneratingChallenge = false
                }
            } catch {
                await MainActor.run {
                    generationMessage = error.localizedDescription
                    isGeneratingChallenge = false
                }
            }
        }
    }

    private func mapCadence(_ cadence: String) -> ChallengeType {
        switch cadence.lowercased() {
        case "daily":
            return .daily
        case "milestone":
            return .milestone
        default:
            return .weekly
        }
    }

    private func mapCategory(_ category: String) -> ActivityCategory? {
        ActivityCategory.allCases.first { $0.rawValue.lowercased() == category.lowercased() }
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

    private var progress: Double {
        guard challenge.targetCount > 0 else { return 0 }
        return Double(challenge.currentProgress) / Double(challenge.targetCount)
    }

    private var tint: Color {
        if let category = challenge.category {
            return category.color
        }
        return Color.ecoGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(challenge.type.rawValue, systemImage: challenge.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.title)
                        .font(.headline)
                }
                Spacer()
                if let endDate = challenge.endDate {
                    Text("Ends \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                CircularProgressView(progress: progress, tint: tint)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(challenge.currentProgress) / \(challenge.targetCount)")
                        .font(.headline)
                    ProgressView(value: Double(challenge.currentProgress), total: Double(challenge.targetCount))
                        .tint(tint)
                }

                Spacer()

                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.footnote.bold())
                    .padding(8)
                    .background(tint.opacity(0.2), in: Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.35), Color(.systemBackground).opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AvailableChallengeCardView: View {
    let challenge: Challenge
    let onJoin: () -> Void

    private var tint: Color {
        if let category = challenge.category {
            return category.color
        }
        return Color.ecoGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.challengeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.footnote.bold())
                    .padding(8)
                    .background(tint.opacity(0.2), in: Capsule())
            }

            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Text("Join challenge")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(tint)
                .foregroundStyle(.white)
                .cornerRadius(AppConstants.Layout.compactCornerRadius)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
    }
}

struct CompletedChallengeCardView: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color.ecoGreen)
                .padding(10)
                .background(Color.ecoGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(Int(challenge.rewardXP)) XP")
                .font(.footnote.bold())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(achievement.isUnlocked ? Color.ecoGreen : Color.gray.opacity(0.4), lineWidth: 3)
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(achievement.isUnlocked ? Color.ecoGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 76, height: 76)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 30))
                    .foregroundStyle(achievement.isUnlocked ? Color.ecoGreen : Color.gray)
            }
            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120)
        .opacity(achievement.isUnlocked ? 1 : 0.5)
    }
}

struct HeroStatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct CircularProgressView: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ChallengesView()
        .environment(AuthenticationManager())
        .environment(FoundationContentService())
        .modelContainer(for: [Challenge.self, Achievement.self], inMemory: true)
}
