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
    @State private var scrollOffset: CGFloat = 0
    @State private var showCelebration = false
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
                        .offset(y: scrollOffset * 0.3)
                        .bounceIn(delay: 0.1)

                    tabPicker
                        .bounceIn(delay: 0.2)

                    switch selectedTab {
                    case .active:
                        challengesSection(title: "In progress", subtitle: "Stay on top of your commitments", items: activeChallenges) { challenge in
                            EnhancedChallengeCardView(challenge: challenge)
                        }
                    case .available:
                        challengesSection(title: "New missions", subtitle: "Join a challenge to boost your XP", items: availableChallenges) { challenge in
                            EnhancedAvailableChallengeCardView(challenge: challenge) {
                                joinChallenge(challenge)
                            }
                        }
                    case .completed:
                        challengesSection(title: "Victories", subtitle: "Celebrate everything you've finished", items: completedChallenges) { challenge in
                            EnhancedCompletedChallengeCardView(challenge: challenge)
                        }
                    }

                    achievementsSection
                        .bounceIn(delay: 0.4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
                .readScrollOffset(into: $scrollOffset)
            }
            .coordinateSpace(name: "scroll")
            .background(
                ZStack {
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.green.opacity(0.3), Color.black]
                            : [Color.green.opacity(0.15), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Fire effect for challenges
                    FireEffectView(intensity: 12)
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Challenges")
            .onAppear(perform: initializeChallenges)
            .overlay {
                if showCelebration {
                    CelebrationOverlay(
                        type: .achievement(name: "Challenge Joined!", icon: "checkmark.seal.fill"),
                        onDismiss: {
                            withAnimation {
                                showCelebration = false
                            }
                        }
                    )
                }
            }
        }
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Level up your eco journey")
                        .font(.title2.bold())
                    Text("Complete themed missions for streaks, XP, and badges.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.15))
                    )
            }

            HStack(spacing: 10) {
                CompactHeroStatView(title: "Active", value: "\(activeChallenges.count)", icon: "flame.fill", color: .orange)
                CompactHeroStatView(title: "Done", value: "\(completedChallenges.count)", icon: "checkmark.seal.fill", color: .green)
                CompactHeroStatView(title: "Badges", value: "\(unlockedAchievements.count)", icon: "star.fill", color: .yellow)
            }

            // Apple Intelligence feature - only available on iOS 26+
            if #available(iOS 26, *) {
                Button {
                    requestFoundationChallenge()
                } label: {
                    HStack {
                        if isGeneratingChallenge {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate new mission")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingChallenge)

                if let generationMessage {
                    Text(generationMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .padding(20)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "16A34A"),
                            Color(hex: "15803D"),
                            Color(hex: "166534")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color(hex: "16A34A").opacity(0.4), radius: 16, x: 0, y: 8)
    }

    private var tabPicker: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(ChallengeTab.allCases) { tab in
                    if #available(iOS 26, *) {
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
                    } else {
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
                        .buttonStyle(.compatibleGlass(
                            tintColor: selectedTab == tab ? AppConstants.Colors.ocean.opacity(0.5) : nil,
                            cornerRadius: 16,
                            interactive: true
                        ))
                    }
                }
            }
        }
        .padding(6)
        .compatibleGlassEffect(
            tintColor: Color.primary.opacity(0.05),
            cornerRadius: 24,
            interactive: false
        )
        .compatibleGlassEffectID("tab-picker", in: glassNamespace)
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
            // Trigger celebration
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCelebration = true
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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
    @Environment(\.colorScheme) private var colorScheme

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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(challenge.type.rawValue, systemImage: challenge.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if let endDate = challenge.endDate {
                    Text("Ends \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                CircularProgressView(progress: progress, tint: tint)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(challenge.currentProgress) / \(challenge.targetCount)")
                        .font(.subheadline.weight(.semibold))
                    ProgressView(value: Double(challenge.currentProgress), total: Double(challenge.targetCount))
                        .tint(tint)
                }

                Spacer(minLength: 8)

                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.caption.bold())
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(tint.opacity(colorScheme == .dark ? 0.25 : 0.15), in: Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .stroke(tint.opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: 1)
        )
    }
}

// MARK: - Enhanced Challenge Cards

struct EnhancedChallengeCardView: View {
    let challenge: Challenge
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false
    @State private var isPressed = false
    @State private var gradientRotation: Double = 0

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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 6)

                    Image(systemName: challenge.iconName)
                        .font(.title3)
                        .foregroundStyle(tint)
                        .symbolEffect(.bounce, value: isVisible)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label(challenge.type.rawValue, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if let endDate = challenge.endDate {
                    Text("Ends \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                EnhancedCircularProgress(progress: progress, tint: tint)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(challenge.currentProgress) / \(challenge.targetCount)")
                        .font(.subheadline.weight(.semibold))
                        .contentTransition(.numericText())
                    EnhancedLinearProgress(progress: progress, tint: tint)
                        .frame(height: 6)
                }

                Spacer(minLength: 8)

                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.caption.bold())
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(tint.opacity(colorScheme == .dark ? 0.25 : 0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.08 : 0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.4), tint.opacity(0.1), tint.opacity(0.4)],
                        center: .center,
                        angle: .degrees(gradientRotation)
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: tint.opacity(isPressed ? 0.3 : 0.1), radius: isPressed ? 12 : 6, x: 0, y: isPressed ? 6 : 3)
        .scaleEffect(isPressed ? 0.98 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
}

struct EnhancedCircularProgress: View {
    let progress: Double
    let tint: Color
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(tint.opacity(0.1))
                .blur(radius: 8)

            // Track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 5)

            // Progress with gradient
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.6), tint, tint.opacity(0.6)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Percentage
            Text("\(Int(animatedProgress * 100))%")
                .font(.caption.bold())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

struct EnhancedLinearProgress: View {
    let progress: Double
    let tint: Color
    @State private var animatedProgress: Double = 0
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.08))

                // Fill with shimmer
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(animatedProgress))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                        .offset(x: shimmerOffset * geometry.size.width * CGFloat(animatedProgress))
                        .mask(RoundedRectangle(cornerRadius: 3))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: tint.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = progress
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 2
            }
        }
    }
}

struct AvailableChallengeCardView: View {
    let challenge: Challenge
    let onJoin: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color {
        if let category = challenge.category {
            return category.color
        }
        return Color.ecoGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(challenge.challengeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.caption.bold())
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(tint.opacity(colorScheme == .dark ? 0.25 : 0.15), in: Capsule())
            }

            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Text("Join challenge")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .background(tint)
                .foregroundStyle(.white)
                .cornerRadius(AppConstants.Layout.compactCornerRadius)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .elevationShadow(.subtle)
    }
}

struct EnhancedAvailableChallengeCardView: View {
    let challenge: Challenge
    let onJoin: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false
    @State private var isButtonPressed = false
    @State private var pulseScale: CGFloat = 1.0

    private var tint: Color {
        if let category = challenge.category {
            return category.color
        }
        return Color.ecoGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 6)
                        .scaleEffect(pulseScale)

                    Image(systemName: challenge.iconName)
                        .font(.title3)
                        .foregroundStyle(tint)
                        .symbolEffect(.bounce, value: isVisible)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(challenge.challengeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)

                // XP badge with glow
                ZStack {
                    Capsule()
                        .fill(tint.opacity(0.2))
                        .blur(radius: 4)
                        .frame(width: 70, height: 28)

                    Text("+\(Int(challenge.rewardXP)) XP")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(tint.opacity(colorScheme == .dark ? 0.25 : 0.15), in: Capsule())
                }
            }

            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Join challenge")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous))
                .shadow(color: tint.opacity(0.4), radius: isButtonPressed ? 2 : 6, x: 0, y: isButtonPressed ? 1 : 3)
                .scaleEffect(isButtonPressed ? 0.97 : 1)
            }
            .buttonStyle(.plain)
            .pressEffect()
        }
        .padding(16)
        .popCard(cornerRadius: AppConstants.Layout.cardCornerRadius, background: Color(.secondarySystemBackground))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

struct CompletedChallengeCardView: View {
    let challenge: Challenge
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(Color.ecoGreen)
                .padding(10)
                .background(Color.ecoGreen.opacity(colorScheme == .dark ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("+\(Int(challenge.rewardXP)) XP")
                .font(.caption.bold())
                .foregroundStyle(Color.ecoGreen)
                .lineLimit(1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .elevationShadow(.subtle)
    }
}

struct EnhancedCompletedChallengeCardView: View {
    let challenge: Challenge
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false
    @State private var showSparkle = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Glow behind checkmark
                Circle()
                    .fill(Color.ecoGreen.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)
                    .scaleEffect(showSparkle ? 1.2 : 1.0)

                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ecoGreen)
                    .padding(10)
                    .background(Color.ecoGreen.opacity(colorScheme == .dark ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .symbolEffect(.bounce, value: showSparkle)

                // Sparkle particles
                if showSparkle {
                    SparkleParticleView(colors: [Color.ecoGreen, Color.ecoGreen.opacity(0.7), .white])
                        .frame(width: 60, height: 60)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // XP with glow
            ZStack {
                Capsule()
                    .fill(Color.ecoGreen.opacity(0.15))
                    .blur(radius: 4)
                    .frame(width: 70, height: 24)

                Text("+\(Int(challenge.rewardXP)) XP")
                    .font(.caption.bold())
                    .foregroundStyle(Color.ecoGreen)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .popCard(cornerRadius: AppConstants.Layout.cardCornerRadius, background: Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .stroke(Color.ecoGreen.opacity(0.2), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSparkle = true
            }
        }
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer ring with gradient
                Circle()
                    .stroke(
                        achievement.isUnlocked
                            ? LinearGradient(colors: [Color.ecoGreen, Color.ecoGreen.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(isVisible ? 1.0 : 0.8)

                // Inner fill
                Circle()
                    .fill(achievement.isUnlocked ? Color.ecoGreen.opacity(colorScheme == .dark ? 0.25 : 0.15) : Color.gray.opacity(0.1))
                    .frame(width: 68, height: 68)

                // Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 26))
                    .foregroundStyle(achievement.isUnlocked ? Color.ecoGreen : Color.gray)
                    .symbolEffect(.bounce, value: isVisible && achievement.isUnlocked)
            }
            .shadow(color: achievement.isUnlocked ? Color.ecoGreen.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)

            Text(achievement.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 100)
        .opacity(achievement.isUnlocked ? 1 : 0.5)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

struct HeroStatView: View {
    let title: String
    let value: String
    let icon: String
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .symbolEffect(.bounce, value: isVisible)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .compatibleGlassEffect(
            variant: .thin,
            tintColor: Color.white.opacity(0.15),
            cornerRadius: 16,
            interactive: false
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isVisible = true
            }
        }
    }
}

struct CompactHeroStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CircularProgressView: View {
    let progress: Double
    let tint: Color
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.6), tint],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
            Text("\(Int(animatedProgress * 100))%")
                .font(.caption.bold())
                .contentTransition(.numericText())
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), value: isAnimating)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ChallengesView()
        .environment(AuthenticationManager())
        .environment(FoundationContentService())
        .modelContainer(for: [Challenge.self, Achievement.self], inMemory: true)
}
