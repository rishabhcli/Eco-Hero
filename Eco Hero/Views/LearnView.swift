//
//  LearnView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct LearnView: View {
    var embedInNavigation: Bool = true
    @Environment(TipModelService.self) private var tipModel
    @State private var selectedCategory: ActivityCategory = .meals
    @State private var smartTip: String?
    @State private var factOfDay: String = AppConstants.EducationalFacts.randomFact()

    var body: some View {
        Group {
            if embedInNavigation {
                NavigationStack {
                    content
                        .navigationTitle("Learn")
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppConstants.Layout.sectionSpacing) {
                dailyFactCard
                tipsSection
                smartTipSection
                allFactsSection
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
    }

    private var dailyFactCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Eco fact of the day", systemImage: "globe.asia.australia.fill")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring) {
                        factOfDay = AppConstants.EducationalFacts.randomFact()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.white.opacity(0.2), in: Circle())
            }

            Text(factOfDay)
                .font(.body)
                .foregroundStyle(.white)

            Text("Share this insight with a friend today.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.ecoGreen, AppConstants.Colors.ocean],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Guided topics")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                ForEach(ActivityCategory.allCases, id: \.self) { category in
                    CategoryTipCard(category: category)
                }
            }
        }
    }

    private var smartTipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart tip generator")
                .font(.headline)

            Picker("Focus Area", selection: $selectedCategory) {
                ForEach(ActivityCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)

            Text(smartTip ?? "Request an AI-guided suggestion tailored to your current focus.")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: generateSmartTip) {
                Label("Generate Smart Tip", systemImage: "bolt.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConstants.Gradients.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(AppConstants.Layout.cardCornerRadius)
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
        .onAppear {
            if smartTip == nil {
                smartTip = tipModel.generateTip(for: selectedCategory)
            }
        }
    }

    private var allFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Eco knowledge library")
                .font(.headline)
            LazyVStack(spacing: 12) {
                ForEach(Array(AppConstants.EducationalFacts.facts.enumerated()), id: \.offset) { index, fact in
                    FactCard(fact: fact, number: index + 1)
                }
            }
        }
    }

    private func generateSmartTip() {
        smartTip = tipModel.generateTip(for: selectedCategory)
    }
}

struct CategoryTipCard: View {
    let category: ActivityCategory

    var body: some View {
        NavigationLink(destination: CategoryTipsDetailView(category: category)) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .padding(12)
                    .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(category.rawValue)
                    .font(.headline)
                Text("Explore tips and actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(AppConstants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct FactCard: View {
    let fact: String
    let number: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(number)")
                .font(.caption.bold())
                .padding(10)
                .background(Color.ecoGreen.opacity(0.15), in: Circle())
            Text(fact)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct CategoryTipsDetailView: View {
    let category: ActivityCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(category.color)
                    Text(category.rawValue)
                        .font(.largeTitle.bold())
                    Text("Tips and information about \(category.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(category.color.opacity(0.12))
                .cornerRadius(24)

                if let tip = AppConstants.EcoTips.tip(for: category) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tip.title)
                            .font(.title2.bold())
                        Text(tip.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Did you know?")
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
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LearnView()
        .environment(TipModelService())
}

#Preview("Category Detail") {
    NavigationStack {
        CategoryTipsDetailView(category: .meals)
    }
}
