//
//  Challenge.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftData

enum ChallengeType: String, Codable {
    case weekly = "Weekly"
    case daily = "Daily"
    case milestone = "Milestone"
}

enum ChallengeStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
}

@Model
final class Challenge {
    var id: UUID
    var title: String
    var challengeDescription: String
    var type: ChallengeType
    var category: ActivityCategory?
    var iconName: String

    // Challenge criteria
    var targetCount: Int // Number of activities or days
    var currentProgress: Int

    // Timing
    var startDate: Date?
    var endDate: Date?
    var isActive: Bool
    var status: ChallengeStatus

    // Rewards
    var rewardXP: Double
    var badgeID: String?

    // User participation
    var userID: String?
    var joinedDate: Date?

    init(
        title: String,
        description: String,
        type: ChallengeType,
        category: ActivityCategory? = nil,
        iconName: String,
        targetCount: Int,
        rewardXP: Double,
        badgeID: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = description
        self.type = type
        self.category = category
        self.iconName = iconName
        self.targetCount = targetCount
        self.currentProgress = 0
        self.isActive = false
        self.status = .notStarted
        self.rewardXP = rewardXP
        self.badgeID = badgeID
    }

    func join(userID: String) {
        self.userID = userID
        self.joinedDate = Date()
        self.startDate = Date()
        self.isActive = true
        self.status = .inProgress

        // Set end date based on type
        switch type {
        case .weekly:
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        case .daily:
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .milestone:
            endDate = nil // No time limit
        }
    }

    func updateProgress() {
        currentProgress += 1

        if currentProgress >= targetCount {
            complete()
        }
    }

    func complete() {
        status = .completed
        isActive = false
    }

    func checkExpiration() {
        guard let end = endDate, status == .inProgress else { return }

        if Date() > end && currentProgress < targetCount {
            status = .failed
            isActive = false
        }
    }
}
