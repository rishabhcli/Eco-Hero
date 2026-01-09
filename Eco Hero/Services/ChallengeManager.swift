//
//  ChallengeManager.swift
//  Eco Hero
//
//  Manages challenge lifecycle including expiration checks, progress updates,
//  and integration with the notification system.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class ChallengeManager {
    private var modelContext: ModelContext?
    private var notificationService: NotificationService?

    /// Challenges expiring within the next 24 hours
    private(set) var expiringChallenges: [Challenge] = []

    /// Recently failed challenges (for UI feedback)
    private(set) var recentlyFailedChallenges: [Challenge] = []

    init() {}

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func setNotificationService(_ service: NotificationService) {
        self.notificationService = service
    }

    // MARK: - Expiration Management

    /// Check all active challenges for expiration
    func checkAllExpirations() {
        guard let context = modelContext else {
            print("⚠️ ChallengeManager: No model context set")
            return
        }

        let inProgressStatus = ChallengeStatus.inProgress
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate<Challenge> { challenge in
                challenge.status == inProgressStatus
            }
        )

        do {
            let activeChallenges = try context.fetch(descriptor)

            var expired: [Challenge] = []
            var expiringSoon: [Challenge] = []

            for challenge in activeChallenges {
                // Check if expired
                challenge.checkExpiration()

                if challenge.status == .failed {
                    expired.append(challenge)
                    notificationService?.notifyChallengeExpired(
                        challengeID: challenge.id.uuidString,
                        title: challenge.title
                    )
                } else if let endDate = challenge.endDate {
                    // Check if expiring within 24 hours
                    let hoursUntilExpiration = endDate.timeIntervalSinceNow / 3600
                    if hoursUntilExpiration > 0 && hoursUntilExpiration <= 24 {
                        expiringSoon.append(challenge)

                        // Schedule expiration warning if not already scheduled
                        notificationService?.scheduleChallengeExpiringNotification(
                            challengeID: challenge.id.uuidString,
                            title: challenge.title,
                            deadline: endDate,
                            hoursBefore: max(1, Int(hoursUntilExpiration))
                        )
                    }
                }
            }

            // Update state
            recentlyFailedChallenges = expired
            expiringChallenges = expiringSoon

            // Save changes
            try context.save()

            print("✅ ChallengeManager: Checked \(activeChallenges.count) challenges, \(expired.count) expired, \(expiringSoon.count) expiring soon")

        } catch {
            print("❌ ChallengeManager: Failed to check expirations: \(error.localizedDescription)")
        }
    }

    /// Get challenges expiring within a specified number of hours
    func getExpiringChallenges(within hours: Int) -> [Challenge] {
        guard let context = modelContext else { return [] }

        let cutoffDate = Date().addingTimeInterval(Double(hours * 3600))
        let inProgressStatus = ChallengeStatus.inProgress

        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate<Challenge> { challenge in
                challenge.status == inProgressStatus
            }
        )

        do {
            let challenges = try context.fetch(descriptor)
            return challenges.filter { challenge in
                guard let endDate = challenge.endDate else { return false }
                return endDate <= cutoffDate && endDate > Date()
            }
        } catch {
            print("❌ ChallengeManager: Failed to fetch expiring challenges: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Challenge Actions

    /// Join a challenge for the current user
    func joinChallenge(_ challenge: Challenge, userID: String) {
        guard challenge.status == .notStarted else {
            print("⚠️ ChallengeManager: Cannot join challenge that's already started")
            return
        }

        challenge.join(userID: userID)

        // Schedule expiration notification if challenge has a deadline
        if let endDate = challenge.endDate {
            notificationService?.scheduleChallengeExpiringNotification(
                challengeID: challenge.id.uuidString,
                title: challenge.title,
                deadline: endDate,
                hoursBefore: 24
            )
        }

        saveContext()
        print("✅ ChallengeManager: Joined challenge '\(challenge.title)'")
    }

    /// Update progress on a challenge
    func updateProgress(for challenge: Challenge, increment: Int = 1) {
        guard challenge.status == .inProgress else { return }

        for _ in 0..<increment {
            challenge.updateProgress()
        }

        if challenge.status == .completed {
            // Cancel any pending notifications
            notificationService?.cancelChallengeNotifications(challengeID: challenge.id.uuidString)
            print("🎉 ChallengeManager: Challenge '\(challenge.title)' completed!")
        }

        saveContext()
    }

    /// Abandon a challenge
    func abandonChallenge(_ challenge: Challenge) {
        challenge.status = .failed
        challenge.isActive = false

        notificationService?.cancelChallengeNotifications(challengeID: challenge.id.uuidString)

        saveContext()
        print("❌ ChallengeManager: Challenge '\(challenge.title)' abandoned")
    }

    /// Retry a failed challenge
    func retryChallenge(_ challenge: Challenge, userID: String) {
        // Reset challenge state
        challenge.currentProgress = 0
        challenge.status = .notStarted
        challenge.isActive = false
        challenge.startDate = nil
        challenge.endDate = nil
        challenge.joinedDate = nil

        // Re-join
        joinChallenge(challenge, userID: userID)
    }

    // MARK: - Challenge Queries

    /// Get all active challenges for a user
    func getActiveChallenges(for userID: String) -> [Challenge] {
        guard let context = modelContext else { return [] }

        let inProgressStatus = ChallengeStatus.inProgress
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate<Challenge> { challenge in
                challenge.status == inProgressStatus && challenge.userID == userID
            },
            sortBy: [SortDescriptor(\.endDate)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ ChallengeManager: Failed to fetch active challenges: \(error.localizedDescription)")
            return []
        }
    }

    /// Get available (not started) challenges
    func getAvailableChallenges() -> [Challenge] {
        guard let context = modelContext else { return [] }

        let notStartedStatus = ChallengeStatus.notStarted
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate<Challenge> { challenge in
                challenge.status == notStartedStatus
            }
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ ChallengeManager: Failed to fetch available challenges: \(error.localizedDescription)")
            return []
        }
    }

    /// Get completed challenges for a user
    func getCompletedChallenges(for userID: String) -> [Challenge] {
        guard let context = modelContext else { return [] }

        let completedStatus = ChallengeStatus.completed
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate<Challenge> { challenge in
                challenge.status == completedStatus && challenge.userID == userID
            },
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ ChallengeManager: Failed to fetch completed challenges: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Time Remaining

    /// Get human-readable time remaining for a challenge
    func timeRemaining(for challenge: Challenge) -> String? {
        guard let endDate = challenge.endDate, challenge.status == .inProgress else {
            return nil
        }

        let remaining = endDate.timeIntervalSinceNow

        if remaining <= 0 {
            return "Expired"
        }

        let hours = Int(remaining / 3600)
        let days = hours / 24

        if days > 0 {
            return "\(days)d \(hours % 24)h left"
        } else if hours > 0 {
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m left"
        } else {
            let minutes = Int(remaining / 60)
            return "\(minutes)m left"
        }
    }

    // MARK: - Private Helpers

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("❌ ChallengeManager: Failed to save context: \(error.localizedDescription)")
        }
    }

    /// Clear the recently failed challenges list (after user has seen them)
    func clearRecentlyFailed() {
        recentlyFailedChallenges = []
    }
}
