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
    @Environment(FirestoreService.self) private var firestoreService
    @Query private var profiles: [UserProfile]

    @State private var selectedCategory: ActivityCategory = .meals
    @State private var selectedActivityType: String = ""
    @State private var notes: String = ""
    @State private var distance: String = ""
    @State private var showSuccess = false
    @State private var isSyncing = false

    private var userProfile: UserProfile? {
        profiles.first { $0.firebaseUID == authManager.currentUserID ?? "" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Activity") {
                    Picker("What did you do?", selection: $selectedActivityType) {
                        ForEach(activityOptions(for: selectedCategory), id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(.menu)

                    // Show distance field for transport activities
                    if selectedCategory == .transport && !selectedActivityType.isEmpty {
                        TextField("Distance (km)", text: $distance)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                // Impact preview
                if !selectedActivityType.isEmpty {
                    Section("Estimated Impact") {
                        let impact = calculateImpact()

                        if impact.carbonSavedKg > 0 {
                            HStack {
                                Label("CO₂ Saved", systemImage: "cloud.fill")
                                Spacer()
                                Text("\(impact.carbonSavedKg.rounded(toPlaces: 2)) kg")
                                    .fontWeight(.semibold)
                            }
                        }

                        if impact.waterSavedLiters > 0 {
                            HStack {
                                Label("Water Saved", systemImage: "drop.fill")
                                Spacer()
                                Text("\(impact.waterSavedLiters.rounded(toPlaces: 0)) L")
                                    .fontWeight(.semibold)
                            }
                        }

                        if impact.plasticSavedItems > 0 {
                            HStack {
                                Label("Plastic Avoided", systemImage: "bag.fill")
                                Spacer()
                                Text("\(impact.plasticSavedItems) items")
                                    .fontWeight(.semibold)
                            }
                        }

                        if impact.landSavedSqMeters > 0 {
                            HStack {
                                Label("Land Preserved", systemImage: "leaf.fill")
                                Spacer()
                                Text("\(impact.landSavedSqMeters.rounded(toPlaces: 1)) m²")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                Section {
                    Button(action: logActivity) {
                        HStack {
                            Spacer()
                            Label("Log Activity", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(selectedActivityType.isEmpty)
                }
            }
            .navigationTitle("Log Activity")
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Your eco-friendly activity has been logged!")
            }
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
        // Meals
        case (.meals, "Vegetarian Meal"):
            return ImpactCalculator.vegetarianMealImpact()
        case (.meals, "Vegan Meal"):
            return ImpactCalculator.veganMealImpact()
        case (.meals, "Local/Organic Food"):
            return ImpactCalculator.localFoodImpact()

        // Transport
        case (.transport, "Biked Instead of Driving"):
            return ImpactCalculator.bikingImpact(distanceKm: distanceValue)
        case (.transport, "Walked Instead of Driving"):
            return ImpactCalculator.walkingImpact(distanceKm: distanceValue)
        case (.transport, "Used Public Transport"):
            return ImpactCalculator.publicTransportImpact(distanceKm: distanceValue)
        case (.transport, "Carpooled"):
            return ImpactCalculator.carpoolingImpact(distanceKm: distanceValue)

        // Plastic
        case (.plastic, "Used Reusable Bottle"):
            return ImpactCalculator.reusableBottleImpact()
        case (.plastic, "Used Reusable Bag"):
            return ImpactCalculator.reusableBagImpact()
        case (.plastic, "Used Reusable Cup"):
            return ImpactCalculator.reusableCupImpact()
        case (.plastic, "Avoided Plastic Utensils"):
            return ImpactCalculator.avoidPlasticUtensilsImpact()

        // Energy
        case (.energy, "Used LED Bulb"):
            return ImpactCalculator.ledBulbImpact(hoursPerDay: 3)
        case (.energy, "Unplugged Devices"):
            return ImpactCalculator.unplugDevicesImpact()
        case (.energy, "Cold Water Laundry"):
            return ImpactCalculator.coldWaterLaundryImpact()

        // Water
        case (.water, "Shorter Shower"):
            return ImpactCalculator.shorterShowerImpact()
        case (.water, "Fixed Leaky Faucet"):
            return ImpactCalculator.fixLeakyFaucetImpact()

        // Lifestyle
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

    private func logActivity() {
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

        // Update user profile
        var currentProfile: UserProfile?
        if let profile = userProfile {
            profile.updateImpactMetrics(activity: activity)
            currentProfile = profile
        } else if let userID = authManager.currentUserID, let email = authManager.currentUserEmail {
            // Create profile if it doesn't exist
            let newProfile = UserProfile(
                firebaseUID: userID,
                email: email,
                displayName: email.components(separatedBy: "@").first ?? "User"
            )
            modelContext.insert(newProfile)
            newProfile.updateImpactMetrics(activity: activity)
            currentProfile = newProfile
        }

        // Save context
        do {
            try modelContext.save()
            showSuccess = true

            // Play success sound and haptic feedback
            playSuccessFeedback()

            // Sync to Firestore in background
            if let userID = authManager.currentUserID {
                Task {
                    do {
                        // Sync activity
                        try await firestoreService.syncActivity(activity, userId: userID)

                        // Sync profile
                        if let profile = currentProfile {
                            try await firestoreService.syncProfile(profile)
                        }
                    } catch {
                        print("Error syncing to Firestore: \(error)")
                    }
                }
            }
        } catch {
            print("Error saving activity: \(error)")
        }
    }

    private func playSuccessFeedback() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // TODO: Play success sound when audio is implemented
    }

    private func resetForm() {
        selectedCategory = .meals
        selectedActivityType = ""
        notes = ""
        distance = ""
    }
}

#Preview {
    LogActivityView()
        .environment(AuthenticationManager())
        .environment(FirestoreService())
        .modelContainer(for: [EcoActivity.self, UserProfile.self], inMemory: true)
}
