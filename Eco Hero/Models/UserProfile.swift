//
//  UserProfile.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var firebaseUID: String
    var email: String
    var displayName: String
    var joinDate: Date
    var avatarPath: String?

    // Cumulative impact metrics
    var totalCarbonSavedKg: Double
    var totalWaterSavedLiters: Double
    var totalLandSavedSqMeters: Double
    var totalPlasticSavedItems: Int

    // Gamification
    var currentLevel: Int
    var experiencePoints: Double
    var streak: Int // Current daily streak
    var longestStreak: Int

    // Settings
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool

    // Last activity date for streak tracking
    var lastActivityDate: Date?

    init(
        firebaseUID: String,
        email: String,
        displayName: String
    ) {
        self.id = UUID()
        self.firebaseUID = firebaseUID
        self.email = email
        self.displayName = displayName
        self.joinDate = Date()
        self.avatarPath = nil

        // Initialize metrics to zero
        self.totalCarbonSavedKg = 0
        self.totalWaterSavedLiters = 0
        self.totalLandSavedSqMeters = 0
        self.totalPlasticSavedItems = 0

        // Initialize gamification
        self.currentLevel = 1
        self.experiencePoints = 0
        self.streak = 0
        self.longestStreak = 0

        // Initialize settings
        self.soundEnabled = true
        self.hapticsEnabled = true
        self.notificationsEnabled = true

        self.lastActivityDate = nil
    }

    func updateImpactMetrics(activity: EcoActivity) {
        totalCarbonSavedKg += activity.carbonSavedKg
        totalWaterSavedLiters += activity.waterSavedLiters
        totalLandSavedSqMeters += activity.landSavedSqMeters
        totalPlasticSavedItems += activity.plasticSavedItems

        // Add experience points
        let points = activity.carbonSavedKg * 10 +
                     activity.waterSavedLiters * 0.01 +
                     Double(activity.plasticSavedItems) * 5
        experiencePoints += points

        // Level up logic (100 XP per level)
        while experiencePoints >= Double(currentLevel * 100) {
            currentLevel += 1
        }

        // Update streak
        updateStreak()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 0 {
                // Same day, no change to streak
                return
            } else if daysDifference == 1 {
                // Consecutive day, increment streak
                streak += 1
                if streak > longestStreak {
                    longestStreak = streak
                }
            } else {
                // Streak broken, reset
                streak = 1
            }
        } else {
            // First activity
            streak = 1
        }

        lastActivityDate = Date()
    }
}
