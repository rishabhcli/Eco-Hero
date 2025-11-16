//
//  LogActivityView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct LogActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(CloudSyncService.self) private var syncService
    @Environment(FoundationContentService.self) private var foundationContentService
    @Query private var profiles: [UserProfile]

    @State private var selectedCategory: ActivityCategory = .meals
    @State private var selectedActivityType: String = ""
    @State private var notes: String = ""
    @State private var distance: String = ""
    @State private var showSuccess = false
    @State private var isSyncing = false
    @State private var aiSuggestion: ActivityIdea?
    @State private var isGeneratingSuggestion = false
    @State private var suggestionError: String?
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case distance
        case notes
    }

    private var userProfile: UserProfile? {
        profiles.first { $0.userIdentifier == authManager.currentUserID ?? "" }
    }

    private var categoryColor: Color {
        selectedCategory.color
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Layout.sectionSpacing) {
                    heroSection
                    categorySelector
                    activityGrid

                    if selectedCategory == .transport {
                        distanceField
                    }

                    notesSection

                    if !selectedActivityType.isEmpty {
                        impactPreview
                    }

                    primaryButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Activity")
            .alert("Success!", isPresented: $showSuccess) {
                Button("Great") {
                    resetForm()
                }
            } message: {
                Text("Your eco-friendly activity has been logged.")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedCategory.rawValue)
                        .font(.title2.bold())
                    Text(categoryDescription(for: selectedCategory))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selectedCategory.icon)
                    .font(.system(size: 36))
                    .padding(16)
                    .background(categoryColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            if let profile = userProfile {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Total impact")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(profile.totalCarbonSavedKg.rounded(toPlaces: 1)) kg CO₂")
                            .font(.headline)
                    }

                    Divider()

                    VStack(alignment: .leading) {
                        Text("Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(profile.streak) days")
                            .font(.headline)
                    }

                    Spacer()
                }
            }
        }
        .cardStyle(background: categoryColor.opacity(0.15), borderOpacity: 0.15)
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        selectedActivityType = ""
                        distance = ""
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .pillStyle(
                        background: category == selectedCategory ? category.color : Color(.secondarySystemBackground),
                        foreground: category == selectedCategory ? .white : .primary
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var activityGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose an action")
                    .font(.headline)
                Spacer()
                Button {
                    generateAISuggestion()
                } label: {
                    if isGeneratingSuggestion {
                        ProgressView()
                    } else {
                        Label("Suggest", systemImage: "wand.and.stars")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGeneratingSuggestion)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Layout.gridSpacing) {
                ForEach(activityOptions(for: selectedCategory), id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedActivityType = option
                        }
                    } label: {
                        ActivityOptionCard(title: option, isSelected: selectedActivityType == option, color: selectedCategory.color)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let aiSuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    Text(aiSuggestion.actionTitle)
                        .font(.headline)
                    Text(aiSuggestion.activityDescription)
                        .font(.subheadline)
                    Text(aiSuggestion.motivation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .onTapGesture {
                    selectedActivityType = aiSuggestion.actionTitle
                    notes = aiSuggestion.motivation
                }
            } else if let suggestionError {
                Text(suggestionError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .cardStyle()
    }

    private var distanceField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance")
                .font(.headline)
            HStack {
                Image(systemName: "ruler")
                    .foregroundStyle(.secondary)
                TextField("Distance in km", text: $distance)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .distance)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .cardStyle()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (optional)")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                TextEditor(text: $notes)
                    .padding(12)
                    .frame(minHeight: 120)
                    .background(Color.clear)
                    .focused($focusedField, equals: .notes)
                if notes.isEmpty {
                    Text("Add context, like who you were with or what inspired you.")
                        .foregroundStyle(.secondary)
                        .padding(18)
                        .allowsHitTesting(false)
                }
            }
        }
        .cardStyle()
    }

    private var impactPreview: some View {
        let impact = calculateImpact()
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Estimated impact")
                    .font(.headline)
                Spacer()
                Text(selectedActivityType)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                if impact.carbonSavedKg > 0 {
                    ImpactMetricRow(title: "CO₂ Saved", value: "\(impact.carbonSavedKg.rounded(toPlaces: 2)) kg", icon: "cloud.fill", tint: .green)
                }
                if impact.waterSavedLiters > 0 {
                    ImpactMetricRow(title: "Water Saved", value: "\(impact.waterSavedLiters.rounded(toPlaces: 0)) L", icon: "drop.fill", tint: .blue)
                }
                if impact.plasticSavedItems > 0 {
                    ImpactMetricRow(title: "Plastic Avoided", value: "\(impact.plasticSavedItems) items", icon: "bag.fill", tint: .orange)
                }
                if impact.landSavedSqMeters > 0 {
                    ImpactMetricRow(title: "Land Preserved", value: "\(impact.landSavedSqMeters.rounded(toPlaces: 1)) m²", icon: "leaf.fill", tint: .green)
                }
            }
        }
        .cardStyle()
    }

    private var primaryButton: some View {
        Button(action: logActivity) {
            HStack {
                Spacer()
                if isSyncing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Save activity", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
            .background(AppConstants.Gradients.accent)
            .cornerRadius(AppConstants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(selectedActivityType.isEmpty || isSyncing)
    }

    private func categoryDescription(for category: ActivityCategory) -> String {
        switch category {
        case .meals:
            return "Track plant-forward meals and low-impact dining."
        case .transport:
            return "Swap carbon-heavy trips for movement-powered ones."
        case .plastic:
            return "Celebrate reusables and low-waste swaps."
        case .energy:
            return "Capture moments of home energy mindfulness."
        case .water:
            return "Record water-wise choices."
        case .lifestyle:
            return "Log green habits that don't fit elsewhere."
        case .other:
            return "Anything else that helped the planet today."
        }
    }

    private func activityOptions(for category: ActivityCategory) -> [String] {
        switch category {
        case .meals:
            return ["Vegetarian Meal", "Vegan Meal", "Local/Organic Food"]
        case .transport:
            return ["Biked Instead of Driving", "Walked Instead of Driving", "Used Public Transport", "Carpooled"]
        case .plastic:
            return ["Used Reusable Bottle", "Used Reusable Bag", "Used Reusable Cup", "Avoided Plastic Utensils"]
        case .energy:
            return ["Used LED Bulb", "Unplugged Devices", "Cold Water Laundry"]
        case .water:
            return ["Shorter Shower", "Fixed Leaky Faucet"]
        case .lifestyle:
            return ["Recycled", "Composted", "Planted a Tree"]
        case .other:
            return ["Other Eco-Friendly Action"]
        }
    }

    private func calculateImpact() -> ActivityImpact {
        let distanceValue = Double(distance) ?? 0

        switch (selectedCategory, selectedActivityType) {
        case (.meals, "Vegetarian Meal"):
            return ImpactCalculator.vegetarianMealImpact()
        case (.meals, "Vegan Meal"):
            return ImpactCalculator.veganMealImpact()
        case (.meals, "Local/Organic Food"):
            return ImpactCalculator.localFoodImpact()
        case (.transport, "Biked Instead of Driving"):
            return ImpactCalculator.bikingImpact(distanceKm: distanceValue)
        case (.transport, "Walked Instead of Driving"):
            return ImpactCalculator.walkingImpact(distanceKm: distanceValue)
        case (.transport, "Used Public Transport"):
            return ImpactCalculator.publicTransportImpact(distanceKm: distanceValue)
        case (.transport, "Carpooled"):
            return ImpactCalculator.carpoolingImpact(distanceKm: distanceValue)
        case (.plastic, "Used Reusable Bottle"):
            return ImpactCalculator.reusableBottleImpact()
        case (.plastic, "Used Reusable Bag"):
            return ImpactCalculator.reusableBagImpact()
        case (.plastic, "Used Reusable Cup"):
            return ImpactCalculator.reusableCupImpact()
        case (.plastic, "Avoided Plastic Utensils"):
            return ImpactCalculator.avoidPlasticUtensilsImpact()
        case (.energy, "Used LED Bulb"):
            return ImpactCalculator.ledBulbImpact(hoursPerDay: 3)
        case (.energy, "Unplugged Devices"):
            return ImpactCalculator.unplugDevicesImpact()
        case (.energy, "Cold Water Laundry"):
            return ImpactCalculator.coldWaterLaundryImpact()
        case (.water, "Shorter Shower"):
            return ImpactCalculator.shorterShowerImpact()
        case (.water, "Fixed Leaky Faucet"):
            return ImpactCalculator.fixLeakyFaucetImpact()
        case (.lifestyle, "Recycled"):
            return ImpactCalculator.recyclingImpact(weightKg: 1)
        case (.lifestyle, "Composted"):
            return ImpactCalculator.compostingImpact(weightKg: 1)
        case (.lifestyle, "Planted a Tree"):
            return ImpactCalculator.plantTreeImpact()
        default:
            return ActivityImpact(carbonSavedKg: 0, waterSavedLiters: 0, landSavedSqMeters: 0, plasticSavedItems: 0)
        }
    }

    private func generateAISuggestion() {
        guard !isGeneratingSuggestion else { return }
        isGeneratingSuggestion = true
        suggestionError = nil

        Task {
            do {
                let suggestion = try await foundationContentService.suggestActivity(for: selectedCategory)
                await MainActor.run {
                    self.aiSuggestion = suggestion
                    self.selectedActivityType = suggestion.actionTitle
                    self.notes = suggestion.motivation
                    self.isGeneratingSuggestion = false
                }
            } catch {
                await MainActor.run {
                    self.suggestionError = error.localizedDescription
                    self.isGeneratingSuggestion = false
                }
            }
        }
    }

    private func logActivity() {
        isSyncing = true
        let impact = calculateImpact()
        let distanceValue = selectedCategory == .transport ? Double(distance) : nil

        let activity = EcoActivity(
            category: selectedCategory,
            description: selectedActivityType,
            notes: notes.isEmpty ? nil : notes,
            carbonSavedKg: impact.carbonSavedKg,
            waterSavedLiters: impact.waterSavedLiters,
            landSavedSqMeters: impact.landSavedSqMeters,
            plasticSavedItems: impact.plasticSavedItems,
            distance: distanceValue,
            userID: authManager.currentUserID
        )

        modelContext.insert(activity)

        var currentProfile: UserProfile?
        if let profile = userProfile {
            profile.updateImpactMetrics(activity: activity)
            currentProfile = profile
        } else if let userID = authManager.currentUserID, let email = authManager.currentUserEmail {
            let newProfile = UserProfile(
                userIdentifier: userID,
                email: email,
                displayName: email.components(separatedBy: "@").first ?? "User"
            )
            modelContext.insert(newProfile)
            newProfile.updateImpactMetrics(activity: activity)
            currentProfile = newProfile
        }

        do {
            try modelContext.save()
            showSuccess = true
            playSuccessFeedback()

            if let userID = authManager.currentUserID {
                Task {
                    defer { isSyncing = false }
                    do {
                        try await syncService.syncActivity(activity, userId: userID)
                        if let profile = currentProfile {
                            try await syncService.syncProfile(profile)
                        }
                    } catch {
                        print("Error syncing to Firestore: \(error)")
                    }
                }
            } else {
                isSyncing = false
            }
        } catch {
            isSyncing = false
            print("Error saving activity: \(error)")
        }
    }

    private func playSuccessFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func resetForm() {
        selectedCategory = .meals
        selectedActivityType = ""
        notes = ""
        distance = ""
    }
}

private struct ActivityOptionCard: View {
    let title: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(isSelected ? "Selected" : "Tap to choose")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                .fill(isSelected ? color.opacity(0.25) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.compactCornerRadius, style: .continuous)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        )
    }
}

private struct ImpactMetricRow: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .padding(8)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
    }
}

#Preview {
    LogActivityView()
        .environment(AuthenticationManager())
        .environment(CloudSyncService())
        .environment(FoundationContentService())
        .modelContainer(for: [EcoActivity.self, UserProfile.self], inMemory: true)
}
