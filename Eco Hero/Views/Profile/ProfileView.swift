//
//  ProfileView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    var embedInNavigation: Bool = true
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthenticationManager.self) private var authManager
    @Query private var profiles: [UserProfile]
    @Query private var activities: [EcoActivity]
    @Query private var achievements: [Achievement]

    @State private var showingSettings = false
    @State private var showingLogoutAlert = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showSparkles = false

    private var userProfile: UserProfile? {
        profiles.first { $0.userIdentifier == authManager.currentUserID ?? "" }
    }

    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.userID == authManager.currentUserID && $0.isUnlocked }
    }

    var body: some View {
        Group {
            if embedInNavigation {
                NavigationStack {
                    content
                        .navigationTitle("Profile")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .font(.body.weight(.medium))
                                        .symbolEffect(.bounce, value: showingSettings)
                                }
                            }
                        }
                }
            } else {
                content
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
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                profileHeader
                    .bounceIn(delay: 0.1)
                statsGrid
                achievementsSummary
                activityBreakdown
                accountSection
                    .bounceIn(delay: 0.4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                Color(.systemGroupedBackground)

                // Animated floating orbs background
                FloatingOrbsBackground(
                    orbCount: 4,
                    colors: [
                        Color(hex: "16A34A").opacity(0.15),
                        Color(hex: "0EA5E9").opacity(0.1),
                        Color(hex: "22C55E").opacity(0.12)
                    ]
                )
            }
            .ignoresSafeArea()
        )
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Animated Avatar with glow ring
            EnhancedAvatarView(
                initial: userProfile?.displayName.prefix(1).uppercased() ?? "E",
                level: userProfile?.currentLevel ?? 1,
                xpProgress: userProfile.map {
                    $0.experiencePoints / Double(max($0.currentLevel * 100, 1))
                } ?? 0
            )

            // Name and Level
            VStack(spacing: 4) {
                Text(userProfile?.displayName ?? "Eco Hero")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                if let profile = userProfile {
                    Text(AppConstants.Levels.levelTitle(for: profile.currentLevel))
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "16A34A"))
                }

                if let email = authManager.currentUserEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Enhanced Level Progress with shimmer
            if let profile = userProfile {
                VStack(spacing: 8) {
                    HStack {
                        Text("Level \(profile.currentLevel)")
                            .font(.caption.weight(.semibold))
                            .contentTransition(.numericText())
                        Spacer()
                        Text("\(Int(profile.experiencePoints)) / \(profile.currentLevel * 100) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }

                    EnhancedProfileXPBar(
                        progress: min(profile.experiencePoints / Double(max(profile.currentLevel * 100, 1)), 1.0)
                    )
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .popCard(cornerRadius: 24, background: Color(.systemBackground))
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                EnhancedProfileStatCard(
                    title: "Current Streak",
                    value: Double(userProfile?.streak ?? 0),
                    unit: "days",
                    icon: "flame.fill",
                    color: Color(hex: "F97316"),
                    index: 0
                )

                EnhancedProfileStatCard(
                    title: "Total Activities",
                    value: Double(activities.count),
                    unit: "logged",
                    icon: "checkmark.circle.fill",
                    color: Color(hex: "16A34A"),
                    index: 1
                )

                EnhancedProfileStatCard(
                    title: "CO₂ Saved",
                    value: userProfile?.totalCarbonSavedKg ?? 0,
                    unit: "kg",
                    icon: "cloud.fill",
                    color: Color(hex: "22C55E"),
                    index: 2
                )

                EnhancedProfileStatCard(
                    title: "Water Saved",
                    value: userProfile?.totalWaterSavedLiters ?? 0,
                    unit: "liters",
                    icon: "drop.fill",
                    color: Color(hex: "0EA5E9"),
                    index: 3
                )
            }
        }
    }

    // MARK: - Achievements
    private var achievementsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    AchievementsListView()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "16A34A"))
            }

            if unlockedAchievements.isEmpty {
                VStack(spacing: 8) {
                    ZStack {
                        // Glow ring
                        Circle()
                            .fill(Color.yellow.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .blur(radius: 12)

                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5), value: true)
                    }

                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Complete challenges to earn badges")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .popCard(cornerRadius: 16, background: Color(.systemBackground))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(unlockedAchievements.prefix(6).enumerated()), id: \.element.id) { index, achievement in
                            EnhancedAchievementBadge(achievement: achievement, index: index)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .bounceIn(delay: 0.2)
    }

    // MARK: - Activity Breakdown
    private var activityBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Breakdown")
                .font(.headline)

            let categoryCounts = Dictionary(grouping: activities, by: { $0.category })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if categoryCounts.isEmpty {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .blur(radius: 12)

                        Image(systemName: "chart.pie")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5), value: true)
                    }

                    Text("Log activities to see breakdown")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .popCard(cornerRadius: 16, background: Color(.systemBackground))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(categoryCounts.prefix(5).enumerated()), id: \.element.key) { index, element in
                        EnhancedCategoryRow(
                            category: element.key,
                            count: element.value,
                            total: activities.count,
                            index: index
                        )
                        if element.key != categoryCounts.prefix(5).last?.key {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .popCard(cornerRadius: 16, background: Color(.systemBackground))
            }
        }
        .bounceIn(delay: 0.3)
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 0) {
            Button {
                showingSettings = true
            } label: {
                HStack {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                showingLogoutAlert = true
            } label: {
                HStack {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// MARK: - Enhanced Supporting Views

private struct EnhancedAvatarView: View {
    let initial: String
    let level: Int
    let xpProgress: Double

    @State private var isAnimating = false
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color(hex: "16A34A").opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 15)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

            // Animated progress ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
                .frame(width: 92, height: 92)

            Circle()
                .trim(from: 0, to: CGFloat(min(xpProgress, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "16A34A"), Color(hex: "22C55E"), Color(hex: "16A34A")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 92, height: 92)
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(ringRotation))

            // Inner avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "16A34A"), Color(hex: "15803D")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: Color(hex: "16A34A").opacity(0.3), radius: 8, x: 0, y: 4)

            Text(initial)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Level badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Lv.\(level)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "16A34A"))
                                .shadow(color: Color(hex: "16A34A").opacity(0.4), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .frame(width: 92, height: 92)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

private struct EnhancedProfileXPBar: View {
    let progress: Double

    @State private var animatedProgress: Double = 0
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray5))

                // Filled progress
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "16A34A"), Color(hex: "22C55E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(animatedProgress))
                    .overlay(
                        // Shimmer effect
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)
                        .offset(x: shimmerOffset * geometry.size.width * CGFloat(animatedProgress))
                        .mask(
                            RoundedRectangle(cornerRadius: 5)
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                // Glowing edge
                if animatedProgress > 0 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .blur(radius: 2)
                        .offset(x: geometry.size.width * CGFloat(animatedProgress) - 5)
                }
            }
        }
        .frame(height: 10)
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

private struct EnhancedProfileStatCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    let index: Int

    @State private var isVisible = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                // Glow behind icon
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .padding(10)
                    .background(color.opacity(0.15), in: Circle())
                    .symbolEffect(.bounce, value: isVisible)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value.abbreviated)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glowCard(color: color, cornerRadius: 14, isActive: isPressed)
        .scaleEffect(isPressed ? 0.97 : (isVisible ? 1.0 : 0.9))
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                isVisible = true
            }
        }
    }
}

private struct EnhancedCategoryRow: View {
    let category: ActivityCategory
    let count: Int
    let total: Int
    let index: Int

    @State private var animatedProgress: Double = 0
    @State private var isVisible = false

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .blur(radius: 4)

                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundStyle(category.color)
                    .frame(width: 32, height: 32)
                    .background(category.color.opacity(0.12), in: Circle())
                    .symbolEffect(.bounce, value: isVisible)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress)
                            .shadow(color: category.color.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08)) {
                isVisible = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.08 + 0.2)) {
                animatedProgress = percentage
            }
        }
    }
}

private struct EnhancedAchievementBadge: View {
    let achievement: Achievement
    let index: Int

    @State private var isVisible = false
    @State private var showSparkle = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Glow effect for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(Color.ecoGreen.opacity(0.25))
                        .frame(width: 90, height: 90)
                        .blur(radius: 15)
                        .scaleEffect(showSparkle ? 1.2 : 1.0)
                }

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
                    .fill(achievement.isUnlocked ? Color.ecoGreen.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 68, height: 68)

                // Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 26))
                    .foregroundStyle(achievement.isUnlocked ? Color.ecoGreen : Color.gray)
                    .symbolEffect(.bounce, value: showSparkle)

                // Sparkle particles
                if achievement.isUnlocked && showSparkle {
                    SparkleParticleView(colors: [Color.ecoGreen, Color.ecoGreen.opacity(0.7), .white])
                        .frame(width: 100, height: 100)
                }
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
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                isVisible = true
            }
            if achievement.isUnlocked {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 0.3) {
                    showSparkle = true
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(AuthenticationManager.self) private var authManager

    private var userProfile: UserProfile? {
        profiles.first { $0.userIdentifier == authManager.currentUserID ?? "" }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Toggle("Notifications", isOn: Binding(
                        get: { userProfile?.notificationsEnabled ?? true },
                        set: { newValue in
                            if let profile = userProfile {
                                profile.notificationsEnabled = newValue
                            }
                        }
                    ))

                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { userProfile?.hapticsEnabled ?? true },
                        set: { newValue in
                            if let profile = userProfile {
                                profile.hapticsEnabled = newValue
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
                        Text("1.0.0")
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
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
        .modelContainer(for: [UserProfile.self, EcoActivity.self, Achievement.self], inMemory: true)
}
