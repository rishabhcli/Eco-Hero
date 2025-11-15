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

    private var userProfile: UserProfile? {
        profiles.first { $0.firebaseUID == authManager.currentUserID ?? "" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    welcomeHeader

                    // Impact summary cards
                    impactSummarySection

                    // Weekly progress
                    weeklyProgressSection

                    // Recent activities
                    recentActivitiesSection

                    // Did you know fact
                    didYouKnowCard
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.semibold)

            if let profile = userProfile {
                HStack {
                    Text("Level \(profile.currentLevel)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(AppConstants.Levels.levelTitle(for: profile.currentLevel))
                        .font(.subheadline)
                        .foregroundStyle(Color.ecoGreen)
                        .fontWeight(.medium)
                }

                // XP Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(profile.experiencePoints)) / \(profile.currentLevel * 100)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: profile.experiencePoints, total: Double(profile.currentLevel * 100))
                        .tint(Color.ecoGreen)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var impactSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Impact")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
                    color: .green
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
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            let weekActivities = activities.filter { activity in
                Calendar.current.isDate(activity.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("\(weekActivities.count)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.ecoGreen)

                    Text("Activities Logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let profile = userProfile {
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(profile.streak)")
                                .font(.system(size: 24, weight: .bold))
                        }

                        Text("Day Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
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

                    Text("Start logging your eco-friendly actions!")
                        .font(.caption)
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

    private var didYouKnowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Did You Know?")
                    .font(.headline)
            }

            Text(AppConstants.EducationalFacts.randomFact())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ImpactCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value.abbreviated)
                .font(.system(size: 28, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivityRowView: View {
    let activity: EcoActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.category.icon)
                .font(.title2)
                .foregroundStyle(Color(activity.category.color))
                .frame(width: 40, height: 40)
                .background(Color(activity.category.color).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.timestamp.formatted())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if activity.carbonSavedKg > 0 {
                    Text("\(activity.carbonSavedKg.rounded(toPlaces: 1)) kg CO₂")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Placeholder views for navigation
struct ActivitiesListView: View {
    @Query private var activities: [EcoActivity]

    var body: some View {
        List(activities) { activity in
            ActivityRowView(activity: activity)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("All Activities")
    }
}

#Preview {
    DashboardView()
        .environment(AuthenticationManager())
        .modelContainer(for: [EcoActivity.self, UserProfile.self], inMemory: true)
}
