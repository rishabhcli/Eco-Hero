//
//  DashboardView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthenticationManager.self) private var authManager
    @Query(sort: [SortDescriptor(\EcoActivity.timestamp, order: .reverse)])
    private var activities: [EcoActivity]
    @Query private var profiles: [UserProfile]

    @State private var highlightFact = AppConstants.EducationalFacts.randomFact()
    @State private var selectedImpactCard: String?
    @State private var showingImpactDetail: ImpactType?
    @State private var animateStreak = false
    @State private var animateLevel = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showCelebration: CelebrationOverlay.CelebrationType?
    @State private var hasAppeared = false

    private var userProfile: UserProfile? {
        profiles.first { $0.userIdentifier == authManager.currentUserID ?? "" }
    }

    private var weeklyActivityCounts: [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = activities.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
            return DailyActivity(date: date, count: count)
        }
        .reversed()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Water effect background with gyroscope
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                WaterEffectView(baseColor: Color(hex: "0EA5E9"))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroHeader
                            .offset(y: scrollOffset > 0 ? -scrollOffset * 0.3 : 0)

                        impactGrid
                        weeklyChart
                        recentActivity
                        ecoTip
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

                // Celebration overlay
                if let celebration = showCelebration {
                    CelebrationOverlay(type: celebration) {
                        showCelebration = nil
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !hasAppeared {
                    seedDataIfNeeded()
                    hasAppeared = true
                }
            }
            .sheet(item: $showingImpactDetail, onDismiss: {
                // Clear the selected card highlight when sheet is dismissed
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedImpactCard = nil
                }
            }) { type in
                ImpactDetailSheet(type: type, profile: userProfile)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Seed Data
    private func seedDataIfNeeded() {
        guard profiles.isEmpty else { return }

        let userID = authManager.currentUserID ?? "demo-user"

        let profile = UserProfile(
            userIdentifier: userID,
            email: authManager.currentUserEmail ?? "hero@eco.app",
            displayName: "Eco Hero"
        )
        profile.experiencePoints = 75
        profile.currentLevel = 1
        profile.streak = 5
        profile.longestStreak = 7
        profile.totalCarbonSavedKg = 12.4
        profile.totalWaterSavedLiters = 450
        profile.totalLandSavedSqMeters = 2.3
        profile.totalPlasticSavedItems = 28
        modelContext.insert(profile)

        let sampleActivities: [(String, ActivityCategory, Double, Double, Int)] = [
            ("Biked to work", .transport, 2.1, 0, 0),
            ("Plant-based lunch", .meals, 1.8, 120, 0),
            ("Refused plastic bag", .plastic, 0.1, 0, 1),
            ("5-minute shower", .water, 0.3, 45, 0),
            ("LED bulbs installed", .energy, 0.8, 0, 0),
            ("Composted food scraps", .lifestyle, 0.5, 15, 0),
            ("Carpooled with friends", .transport, 1.5, 0, 0),
            ("Reusable water bottle", .plastic, 0.2, 0, 2),
        ]

        for (index, activity) in sampleActivities.enumerated() {
            let eco = EcoActivity(
                category: activity.1,
                description: activity.0,
                carbonSavedKg: activity.2,
                waterSavedLiters: activity.3,
                plasticSavedItems: activity.4,
                userID: userID
            )
            eco.timestamp = Calendar.current.date(byAdding: .hour, value: -index * 8, to: Date()) ?? Date()
            modelContext.insert(eco)
        }

        try? modelContext.save()
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .scaleOnAppear(delay: 0.1)

                    if let profile = userProfile {
                        Text(AppConstants.Levels.levelTitle(for: profile.currentLevel))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .scaleOnAppear(delay: 0.15)
                    }
                }

                Spacer()

                if let profile = userProfile, profile.streak > 0 {
                    StreakBadge(
                        streak: profile.streak,
                        animateStreak: $animateStreak
                    )
                    .scaleOnAppear(delay: 0.2)
                }
            }

            if let profile = userProfile {
                XPProgressCard(
                    profile: profile,
                    animateLevel: $animateLevel,
                    onLevelUp: { newLevel in
                        showCelebration = .levelUp(newLevel: newLevel)
                    }
                )
                .bounceIn(delay: 0.25)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Impact Grid
    private var impactGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Impact")
                .font(.title3.weight(.semibold))
                .scaleOnAppear(delay: 0.3)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                EnhancedImpactCard(
                    icon: "leaf.fill",
                    value: (userProfile?.totalCarbonSavedKg ?? 12.4).abbreviated,
                    label: "CO₂ Saved",
                    unit: "kg",
                    gradient: AppConstants.Gradients.carbonGradient,
                    isSelected: selectedImpactCard == "co2",
                    index: 0
                ) {
                    selectedImpactCard = "co2"
                    haptic(.medium)
                    showingImpactDetail = .carbon
                }

                EnhancedImpactCard(
                    icon: "drop.fill",
                    value: (userProfile?.totalWaterSavedLiters ?? 450).abbreviated,
                    label: "Water Saved",
                    unit: "liters",
                    gradient: AppConstants.Gradients.waterGradient,
                    isSelected: selectedImpactCard == "water",
                    index: 1
                ) {
                    selectedImpactCard = "water"
                    haptic(.medium)
                    showingImpactDetail = .water
                }

                EnhancedImpactCard(
                    icon: "tree.fill",
                    value: (userProfile?.totalLandSavedSqMeters ?? 2.3).abbreviated,
                    label: "Land Preserved",
                    unit: "m²",
                    gradient: AppConstants.Gradients.landGradient,
                    isSelected: selectedImpactCard == "land",
                    index: 2
                ) {
                    selectedImpactCard = "land"
                    haptic(.medium)
                    showingImpactDetail = .land
                }

                EnhancedImpactCard(
                    icon: "bag.fill",
                    value: "\(userProfile?.totalPlasticSavedItems ?? 28)",
                    label: "Plastic Avoided",
                    unit: "items",
                    gradient: AppConstants.Gradients.plasticGradient,
                    isSelected: selectedImpactCard == "plastic",
                    index: 3
                ) {
                    selectedImpactCard = "plastic"
                    haptic(.medium)
                    showingImpactDetail = .plastic
                }
            }
        }
    }

    // MARK: - Weekly Chart
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("This Week")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(activitiesThisWeek.count) activities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 0) {
                let maxCount = max(weeklyActivityCounts.map { $0.count }.max() ?? 1, 1)
                ForEach(Array(weeklyActivityCounts.enumerated()), id: \.element.id) { index, day in
                    EnhancedWeekBar(
                        count: day.count,
                        maxCount: maxCount,
                        label: day.shortLabel,
                        isToday: Calendar.current.isDateInToday(day.date),
                        index: index
                    )
                }
            }
            .frame(height: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
        .bounceIn(delay: 0.5)
    }

    // MARK: - Recent Activity
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Activity")
                    .font(.title3.weight(.semibold))
                Spacer()
                if !activities.isEmpty {
                    if #available(iOS 26, *) {
                        NavigationLink {
                            ActivitiesListView()
                        } label: {
                            Text("See all")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color(hex: "16A34A"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.glass(.regular.tint(Color(hex: "16A34A").opacity(0.2)).interactive()))
                    } else {
                        NavigationLink {
                            ActivitiesListView()
                        } label: {
                            Text("See all")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color(hex: "16A34A"))
                        }
                    }
                }
            }

            if activities.isEmpty {
                EmptyActivityCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.prefix(4).enumerated()), id: \.element.id) { index, activity in
                        EnhancedActivityItem(activity: activity, index: index)

                        if index < min(activities.count - 1, 3) {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
            }
        }
        .bounceIn(delay: 0.6)
    }

    // MARK: - Eco Tip
    private var ecoTip: some View {
        Group {
            if #available(iOS 26, *) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        highlightFact = AppConstants.EducationalFacts.randomFact()
                    }
                    haptic(.light)
                } label: {
                    EcoFactContent(
                        highlightFact: highlightFact,
                        animateStreak: animateStreak,
                        colorScheme: colorScheme
                    )
                }
                .buttonStyle(.glass(.regular.tint(Color(hex: "F59E0B").opacity(0.35)).interactive()))
            } else {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        highlightFact = AppConstants.EducationalFacts.randomFact()
                    }
                    haptic(.light)
                } label: {
                    EcoFactContent(
                        highlightFact: highlightFact,
                        animateStreak: animateStreak,
                        colorScheme: colorScheme
                    )
                }
                .buttonStyle(EnhancedBounceButtonStyle())
            }
        }
        .bounceIn(delay: 0.7)
    }

    private var activitiesThisWeek: [EcoActivity] {
        activities.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Eco Fact Content (Dark Mode Aware)

private struct EcoFactContent: View {
    let highlightFact: String
    let animateStreak: Bool
    let colorScheme: ColorScheme

    private var titleColor: Color {
        colorScheme == .dark ? Color(hex: "FCD34D") : Color(hex: "92400E")
    }

    private var textColor: Color {
        colorScheme == .dark ? Color(hex: "FEF3C7") : Color(hex: "78350F")
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "78350F").opacity(0.4) : Color(hex: "FEF3C7")
    }

    private var gradientColor: Color {
        colorScheme == .dark ? Color(hex: "F59E0B").opacity(0.2) : Color(hex: "FDE68A").opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "F59E0B"))
                Text("Did you know?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(titleColor)
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(titleColor.opacity(0.6))
                    .rotationEffect(.degrees(animateStreak ? 360 : 0))
            }

            Text(highlightFact)
                .font(.subheadline)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Text("Tap for another fact")
                .font(.caption)
                .foregroundStyle(titleColor.opacity(0.5))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gradientColor, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: Color(hex: "F59E0B").opacity(colorScheme == .dark ? 0.25 : 0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Streak Badge with Flame Particles

private struct StreakBadge: View {
    let streak: Int
    @Binding var animateStreak: Bool
    @State private var showParticles = false
    @Namespace private var glassNamespace

    var body: some View {
        Button {
            animateStreak.toggle()
            showParticles = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showParticles = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: AppConstants.Gradients.flameGradient,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .symbolEffect(.bounce, value: animateStreak)

                Text("\(streak)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .modifier(StreakBadgeStyleModifier(glassNamespace: glassNamespace))
        .overlay(alignment: .top) {
            // Flame particles as overlay - doesn't affect layout
            if showParticles {
                FlameParticleView(particleCount: min(streak, 5), baseColor: .orange)
                    .frame(width: 80, height: 60)
                    .offset(y: -40)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct StreakBadgeStyleModifier: ViewModifier {
    let glassNamespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glass(.regular.tint(Color.orange.opacity(0.3)).interactive()))
                .glassEffectID("streak", in: glassNamespace)
        } else {
            content
                .buttonStyle(EnhancedBounceButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

private struct ImpactCardStyleModifier: ViewModifier {
    let isSelected: Bool
    let gradient: [Color]
    let label: String
    let glassNamespace: Namespace.ID
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(EnhancedBounceButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? gradient[0].opacity(0.1) : Color(.systemBackground).opacity(colorScheme == .dark ? 0.4 : 0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.clear, lineWidth: 1)
                )
                .glassEffect(
                    .regular.tint(isSelected ? gradient[0].opacity(colorScheme == .dark ? 0.25 : 0.15) : .clear).interactive(),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .glassEffectID("impact-\(label)", in: glassNamespace)
        } else {
            content
                .buttonStyle(EnhancedBounceButtonStyle())
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))

                        // Subtle gradient overlay when selected
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(gradient[0].opacity(0.05))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                .shadow(color: isSelected ? gradient[0].opacity(0.2) : .clear, radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - XP Progress Card with Shimmer

private struct XPProgressCard: View {
    let profile: UserProfile
    @Binding var animateLevel: Bool
    var onLevelUp: (Int) -> Void

    @State private var shimmerActive = false
    @State private var glowPulse = false

    private var progress: CGFloat {
        min(CGFloat(profile.experiencePoints / Double(max(profile.currentLevel * 100, 1))), 1.0)
    }

    var body: some View {
        Button {
            animateLevel.toggle()
            // Trigger shimmer animation on tap
            shimmerActive = true
            glowPulse.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            // Stop shimmer after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                shimmerActive = false
            }
        } label: {
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "F59E0B"))
                            .symbolEffect(.bounce, value: animateLevel)
                        Text("Level \(profile.currentLevel)")
                            .font(.caption.weight(.semibold))
                    }

                    Spacer()

                    Text("\(Int(profile.experiencePoints)) / \(profile.currentLevel * 100) XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))

                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "16A34A"), Color(hex: "22C55E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                            .shimmerEffect(isActive: shimmerActive)
                            .animation(.spring(response: 0.6), value: profile.experiencePoints)

                        // Glowing edge indicator
                        if progress > 0.05 {
                            Circle()
                                .fill(.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: Color(hex: "16A34A").opacity(0.8), radius: glowPulse ? 8 : 4)
                                .offset(x: geometry.size.width * progress - 7)
                                .animation(.easeInOut(duration: 0.5), value: glowPulse)
                        }
                    }
                }
                .frame(height: 12)
            }
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            .shadow(color: Color(hex: "16A34A").opacity(0.1), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(EnhancedBounceButtonStyle())
        .onAppear {
            glowPulse = true
        }
    }
}

// MARK: - Enhanced Impact Card

private struct EnhancedImpactCard: View {
    let icon: String
    let value: String
    let label: String
    let unit: String
    let gradient: [Color]
    var isSelected: Bool = false
    let index: Int
    var onTap: () -> Void
    @Namespace private var glassNamespace

    @State private var iconBounce = false
    @State private var isHovered = false
    @State private var gradientRotation: Double = 0

    var body: some View {
        Button {
            iconBounce.toggle()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    // Animated gradient background for icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: UnitPoint(x: 0.5 + cos(gradientRotation) * 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5 - cos(gradientRotation) * 0.5, y: 1)
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: iconBounce)
                }
                .shadow(color: gradient[0].opacity(0.4), radius: isSelected ? 12 : 6, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .modifier(ImpactCardStyleModifier(isSelected: isSelected, gradient: gradient, label: label, glassNamespace: glassNamespace))
        .cascadeEntrance(index: index, delay: 0.08)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = .pi * 2
            }
        }
    }
}

// MARK: - Enhanced Week Bar

private struct EnhancedWeekBar: View {
    let count: Int
    let maxCount: Int
    let label: String
    let isToday: Bool
    let index: Int

    @State private var animatedHeight: CGFloat = 0
    @State private var isTapped = false
    @State private var glowActive = false

    private var targetHeight: CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 70
        guard maxCount > 0 else { return minHeight }
        return max(minHeight, CGFloat(count) / CGFloat(maxCount) * maxHeight)
    }

    var body: some View {
        Button {
            isTapped.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Spacer()

                ZStack(alignment: .top) {
                    // Bar with gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isToday
                                ? LinearGradient(colors: [Color(hex: "16A34A"), Color(hex: "22C55E"), Color(hex: "86EFAC")], startPoint: .bottom, endPoint: .top)
                                : LinearGradient(colors: [Color(hex: "16A34A").opacity(0.25), Color(hex: "22C55E").opacity(0.25)], startPoint: .bottom, endPoint: .top)
                        )
                        .frame(width: 32, height: animatedHeight)
                        .shadow(color: isToday ? Color(hex: "16A34A").opacity(0.4) : .clear, radius: glowActive ? 8 : 4, x: 0, y: 0)

                    // Count tooltip
                    if isTapped && count > 0 {
                        Text("\(count)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "16A34A"), in: Capsule())
                            .offset(y: -24)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: isTapped)

                Text(label)
                    .font(.caption2.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? Color(hex: "16A34A") : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.08)) {
                animatedHeight = targetHeight
            }
            if isToday {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowActive = true
                }
            }
        }
    }
}

// MARK: - Enhanced Activity Item

private struct EnhancedActivityItem: View {
    let activity: EcoActivity
    let index: Int
    @State private var isTapped = false

    var body: some View {
        Button {
            isTapped.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                // Icon with gradient background
                Image(systemName: activity.category.icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [activity.category.color, activity.category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .shadow(color: activity.category.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    .symbolEffect(.bounce, value: isTapped)

                VStack(alignment: .leading, spacing: 3) {
                    Text(activity.activityDescription)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if activity.carbonSavedKg > 0 {
                    Text("-\(activity.carbonSavedKg.rounded(toPlaces: 1))kg")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "16A34A"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "16A34A").opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isTapped ? Color(.systemGray6) : .clear)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isTapped)
        .onChange(of: isTapped) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isTapped = false
                }
            }
        }
    }
}

// MARK: - Empty Activity Card

private struct EmptyActivityCard: View {
    @State private var leafFloat = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "16A34A").opacity(0.4), Color(hex: "22C55E").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(y: leafFloat ? -5 : 5)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: leafFloat)

            VStack(spacing: 4) {
                Text("No activities yet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("Start logging your eco-friendly actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        .onAppear {
            leafFloat = true
        }
    }
}

// MARK: - Impact Types

enum ImpactType: String, Identifiable {
    case carbon, water, land, plastic
    var id: String { rawValue }
}

struct ImpactDetailSheet: View {
    let type: ImpactType
    let profile: UserProfile?

    @State private var iconScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0

    var body: some View {
        mainContent
            .padding(.top, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                // Gradient tint overlay
                LinearGradient(
                    colors: [
                        gradientColors[0].opacity(0.15),
                        gradientColors[0].opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .presentationBackground {
                if #available(iOS 26, *) {
                    // Liquid glass background for iOS 26+
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .glassEffect()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    gradientColors[0].opacity(0.2),
                                    gradientColors[0].opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    // Fallback for earlier iOS versions
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    gradientColors[0].opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    iconScale = 1
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    contentOpacity = 1
                }
            }
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            // Icon with animation
            ZStack {
                // Animated glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(gradientColors[0].opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                        .scaleEffect(iconScale)
                }

                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .shadow(color: gradientColors[0].opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(iconScale)
            }

            VStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(title)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(contentOpacity)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(contentOpacity)

            Spacer()
        }
    }

    private var iconName: String {
        switch type {
        case .carbon: return "leaf.fill"
        case .water: return "drop.fill"
        case .land: return "tree.fill"
        case .plastic: return "bag.fill"
        }
    }

    private var gradientColors: [Color] {
        switch type {
        case .carbon: return AppConstants.Gradients.carbonGradient
        case .water: return AppConstants.Gradients.waterGradient
        case .land: return AppConstants.Gradients.landGradient
        case .plastic: return AppConstants.Gradients.plasticGradient
        }
    }

    private var value: String {
        switch type {
        case .carbon: return "\((profile?.totalCarbonSavedKg ?? 12.4).rounded(toPlaces: 1)) kg"
        case .water: return "\(Int(profile?.totalWaterSavedLiters ?? 450)) L"
        case .land: return "\((profile?.totalLandSavedSqMeters ?? 2.3).rounded(toPlaces: 1)) m²"
        case .plastic: return "\(profile?.totalPlasticSavedItems ?? 28)"
        }
    }

    private var title: String {
        switch type {
        case .carbon: return "CO₂ Emissions Saved"
        case .water: return "Water Conserved"
        case .land: return "Land Preserved"
        case .plastic: return "Plastic Items Avoided"
        }
    }

    private var description: String {
        switch type {
        case .carbon: return "That's equivalent to driving \(Int((profile?.totalCarbonSavedKg ?? 12.4) * 4)) fewer kilometers in a car!"
        case .water: return "You've saved enough water for \(Int((profile?.totalWaterSavedLiters ?? 450) / 50)) showers!"
        case .land: return "You've helped preserve land area equal to \(Int((profile?.totalLandSavedSqMeters ?? 2.3) * 10)) houseplants!"
        case .plastic: return "That's \(profile?.totalPlasticSavedItems ?? 28) pieces of plastic kept out of our oceans!"
        }
    }
}

// MARK: - Supporting Views

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ActivitiesListView: View {
    @Query(sort: [SortDescriptor(\EcoActivity.timestamp, order: .reverse)])
    private var activities: [EcoActivity]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    EnhancedActivityItem(activity: activity, index: index)
                    if index < activities.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .padding(20)
        }
        .navigationTitle("All Activities")
        .background(Color(.systemGroupedBackground))
    }
}

private struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    var shortLabel: String {
        date.formatted(.dateTime.weekday(.narrow))
    }
}

#Preview {
    DashboardView()
        .environment(AuthenticationManager())
        .modelContainer(for: [EcoActivity.self, UserProfile.self], inMemory: true)
}
