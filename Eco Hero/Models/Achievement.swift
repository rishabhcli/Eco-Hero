//
//  Achievement.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftData

enum AchievementTier: String, Codable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
}

@Model
final class Achievement {
    var id: UUID
    var badgeID: String // Unique identifier for the badge type
    var title: String
    var badgeDescription: String
    var tier: AchievementTier
    var iconName: String
    var category: ActivityCategory?

    // Unlock criteria
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progressCurrent: Double
    var progressRequired: Double

    // User reference
    var userID: String?

    init(
        badgeID: String,
        title: String,
        description: String,
        tier: AchievementTier,
        iconName: String,
        category: ActivityCategory? = nil,
        progressRequired: Double,
        userID: String? = nil
    ) {
        self.id = UUID()
        self.badgeID = badgeID
        self.title = title
        self.badgeDescription = description
        self.tier = tier
        self.iconName = iconName
        self.category = category
        self.isUnlocked = false
        self.unlockedDate = nil
        self.progressCurrent = 0
        self.progressRequired = progressRequired
        self.userID = userID
    }

    func updateProgress(by amount: Double) {
        guard !isUnlocked else { return }

        progressCurrent += amount

        if progressCurrent >= progressRequired {
            unlock()
        }
    }

    func unlock() {
        isUnlocked = true
        unlockedDate = Date()
    }

    var progressPercentage: Double {
        guard progressRequired > 0 else { return 0 }
        return min((progressCurrent / progressRequired) * 100, 100)
    }
}
