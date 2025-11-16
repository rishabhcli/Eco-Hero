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
    @Environment(AuthenticationManager.self) private var authManager
    @Query private var activities: [EcoActivity]
    @Query private var profiles: [UserProfile]

    @State private var highlightFact = AppConstants.EducationalFacts.randomFact()
    @State private var activeSheet: DashboardSheet?

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
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Layout.sectionSpacing) {
                    heroHeader
                    quickActionsSection
                    impactSummarySection
                    weeklyProgressSection
                    recentActivitiesSection
                    didYouKnowCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [AppConstants.Colors.sand, Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Dashboard")
            .sheet(item: $activeSheet) { sheet in
                sheetDestination(for: sheet)
                    .presentationDetents([.large])
            }
        }
    }

    @ViewBuilder
    private func sheetDestination(for sheet: DashboardSheet) -> some View {
        switch sheet {
        case .log:
            LogActivityView()
        case .learn:
            LearnView()
        case .challenges:
            ChallengesView()
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(userProfile?.displayName ?? "Hey Eco Hero")
                .font(.largeTitle.bold())
            Text("You're on an \(userProfile?.streak ?? 0)-day streak. Keep the planet loving you back.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let profile = userProfile {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Level \(profile.currentLevel)", systemImage: "star.fill")
                            .font(.footnote)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.15), in: Capsule())
                        Spacer()
                        Text(AppConstants.Levels.levelTitle(for: profile.currentLevel))
                            .font(.footnote.bold())
                            .foregroundStyle(Color.ecoGreen)
                    }

                    ProgressView(value: profile.experiencePoints, total: Double(max(profile.currentLevel * 100, 1)))
                        .tint(Color.ecoGreen)

                    HStack {
                        Text("XP \(Int(profile.experiencePoints)) / \(profile.currentLevel * 100)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label("\(profile.totalCarbonSavedKg.rounded(toPlaces: 1)) kg CO₂", systemImage: "cloud.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AppConstants.Gradients.hero)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 25, x: 0, y: 10)
        .foregroundStyle(.white)
    }

    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            ForEach(DashboardQuickAction.actions) { action in
                Button {
                    activeSheet = action.sheet
                } label: {
                    QuickActionCard(action: action)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var impactSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Impact pulse")
                    .font(.title3.bold())
                Spacer()
                Text("All time")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Layout.gridSpacing) {
                ImpactCard(
                    title: "CO₂ Saved",
                    value: userProfile?.totalCarbonSavedKg ?? 0,
                    unit: "kg",
                    icon: "cloud.fill",
                    color: .green
                )

                ImpactCard(
                    title: "Water Saved",
                    value: userProfile?.totalWaterSavedLiters ?? 0,
                    unit: "L",
                    icon: "drop.fill",
                    color: .blue
                )

                ImpactCard(
                    title: "Land Preserved",
                    value: userProfile?.totalLandSavedSqMeters ?? 0,
                    unit: "m²",
                    icon: "leaf.fill",
                    color: .mint
                )

                ImpactCard(
                    title: "Plastic Avoided",
                    value: Double(userProfile?.totalPlasticSavedItems ?? 0),
                    unit: "items",
                    icon: "bag.fill",
                    color: .orange
                )
            }
        }
        .cardStyle()
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This week")
                    .font(.title3.bold())
                Spacer()
                Label("\(activitiesThisWeek.count) activities", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activitiesThisWeek.count)")
                        .font(.system(size: 34, weight: .bold))
                    Text("Logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(userProfile?.streak ?? 0)")
                        .font(.system(size: 34, weight: .bold))
                    Text("Day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(alignment: .bottom, spacing: 12) {
                let maxCount = max(weeklyActivityCounts.map { $0.count }.max() ?? 1, 1)
                ForEach(weeklyActivityCounts) { day in
                    VStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.ecoGreen.opacity(0.8))
                            .frame(height: max(12, CGFloat(day.count) / CGFloat(maxCount) * 80))
                        Text(day.shortLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent activity")
                    .font(.title3.bold())
                Spacer()
                NavigationLink("See all") {
                    ActivitiesListView()
                }
                .font(.footnote.bold())
            }

            if activities.isEmpty {
                EmptyStateView(
                    icon: "leaf.circle",
                    title: "No activities yet",
                    message: "Tap Log Activity to record your first eco win."
                )
                .cardStyle()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(activities.prefix(5))) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
        }
    }

    private var didYouKnowCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Did you know?", systemImage: "lightbulb.fill")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    highlightFact = AppConstants.EducationalFacts.randomFact()
                }
                .font(.footnote.bold())
            }
            Text(highlightFact)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .cardStyle(background: Color.white, borderOpacity: 0.05)
    }

    private var activitiesThisWeek: [EcoActivity] {
        activities.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }
    }
}

struct ImpactCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .padding(10)
                    .background(color.opacity(0.2), in: Circle())
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value.abbreviated)
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ActivityRowView: View {
    let activity: EcoActivity

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(activity.category.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: activity.category.icon)
                    .foregroundStyle(activity.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityDescription)
                    .font(.headline)
                Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if activity.carbonSavedKg > 0 {
                Text("−\(activity.carbonSavedKg.rounded(toPlaces: 1)) kg CO₂")
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(activity.category.color.opacity(0.15), in: Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

private struct QuickActionCard: View {
    let action: DashboardQuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: action.icon)
                .font(.title2)
                .padding(10)
                .background(Color.white.opacity(0.2), in: Circle())
            Spacer(minLength: 0)
            Text(action.title)
                .font(.headline)
            Text(action.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            LinearGradient(
                colors: action.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(AppConstants.Layout.compactCornerRadius)
        )
        .shadow(color: action.colors.last?.opacity(0.4) ?? .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

struct ActivitiesListView: View {
    @Query private var activities: [EcoActivity]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(activities) { activity in
                    ActivityRowView(activity: activity)
                }
            }
            .padding()
        }
        .navigationTitle("All Activities")
        .background(Color(.systemGroupedBackground))
    }
}

private enum DashboardSheet: Identifiable {
    case log, learn, challenges

    var id: Int { hashValue }
}

private struct DashboardQuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let sheet: DashboardSheet

    static let actions: [DashboardQuickAction] = [
        DashboardQuickAction(
            title: "Log Activity",
            subtitle: "Capture eco wins",
            icon: "plus.circle.fill",
            colors: [Color(hex: "2A9D8F"), Color(hex: "136F63")],
            sheet: .log
        ),
        DashboardQuickAction(
            title: "Smart Tips",
            subtitle: "AI-powered guidance",
            icon: "sparkles",
            colors: [Color(hex: "2196F3"), Color(hex: "3A7BD5")],
            sheet: .learn
        ),
        DashboardQuickAction(
            title: "Challenges",
            subtitle: "Boost your streak",
            icon: "trophy.fill",
            colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
            sheet: .challenges
        )
    ]
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
