//
//  LearnView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct LearnView: View {
    @State private var selectedCategory: ActivityCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily fact card
                    dailyFactCard

                    // Tips by category
                    tipsSection

                    // All facts section
                    allFactsSection
                }
                .padding()
            }
            .navigationTitle("Learn")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var dailyFactCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                Text("Eco Fact of the Day")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text(AppConstants.EducationalFacts.randomFact())
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Tap to learn more eco tips below")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.ecoGreen.opacity(0.1), Color.ecoBlue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Eco Tips by Category")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ActivityCategory.allCases, id: \.self) { category in
                    CategoryTipCard(category: category)
                }
            }
        }
    }

    private var allFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Eco Facts")
                .font(.headline)

            ForEach(Array(AppConstants.EducationalFacts.facts.enumerated()), id: \.offset) { index, fact in
                FactCard(fact: fact, number: index + 1)
            }
        }
    }
}

struct CategoryTipCard: View {
    let category: ActivityCategory

    var body: some View {
        NavigationLink(destination: CategoryTipsDetailView(category: category)) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color(category.color))
                    .frame(height: 44)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct FactCard: View {
    let fact: String
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ecoGreen.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.ecoGreen)
            }

            Text(fact)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CategoryTipsDetailView: View {
    let category: ActivityCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(Color(category.color))

                    Text(category.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tips and information about \(category.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(category.color).opacity(0.1))
                .cornerRadius(16)

                // Tips
                if let tip = AppConstants.EcoTips.tip(for: category) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tip.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(tip.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Related facts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Did You Know?")
                        .font(.headline)

                    ForEach(Array(AppConstants.EducationalFacts.facts.prefix(3).enumerated()), id: \.offset) { index, fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)

                            Text(fact)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    LearnView()
}

#Preview("Category Detail") {
    NavigationStack {
        CategoryTipsDetailView(category: .meals)
    }
}
