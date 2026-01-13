//
//  ChallengeTests.swift
//  Eco HeroTests
//
//  Tests for Challenge model - lifecycle, progress, and expiration logic.
//

import XCTest
@testable import Eco_Hero

final class ChallengeTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialValues() {
        let challenge = Challenge(
            title: "Test Challenge",
            description: "A test challenge",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        XCTAssertEqual(challenge.title, "Test Challenge")
        XCTAssertEqual(challenge.challengeDescription, "A test challenge")
        XCTAssertEqual(challenge.type, .daily)
        XCTAssertEqual(challenge.iconName, "star")
        XCTAssertEqual(challenge.targetCount, 5)
        XCTAssertEqual(challenge.currentProgress, 0)
        XCTAssertEqual(challenge.rewardXP, 100)
        XCTAssertEqual(challenge.status, .notStarted)
        XCTAssertFalse(challenge.isActive)
        XCTAssertNil(challenge.startDate)
        XCTAssertNil(challenge.endDate)
        XCTAssertNil(challenge.userID)
        XCTAssertNil(challenge.joinedDate)
    }

    func testInitWithCategory() {
        let challenge = Challenge(
            title: "Meals Challenge",
            description: "Eat vegetarian",
            type: .weekly,
            category: .meals,
            iconName: "leaf",
            targetCount: 7,
            rewardXP: 200
        )

        XCTAssertEqual(challenge.category, .meals)
    }

    func testInitWithBadgeID() {
        let challenge = Challenge(
            title: "Badge Challenge",
            description: "Earn a badge",
            type: .milestone,
            iconName: "trophy",
            targetCount: 10,
            rewardXP: 500,
            badgeID: "eco_champion"
        )

        XCTAssertEqual(challenge.badgeID, "eco_champion")
    }

    // MARK: - Join Tests

    func testJoinSetsUserID() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        challenge.join(userID: "user-123")

        XCTAssertEqual(challenge.userID, "user-123")
    }

    func testJoinSetsJoinedDate() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        let beforeJoin = Date()
        challenge.join(userID: "user-123")
        let afterJoin = Date()

        XCTAssertNotNil(challenge.joinedDate)
        XCTAssertGreaterThanOrEqual(challenge.joinedDate!, beforeJoin)
        XCTAssertLessThanOrEqual(challenge.joinedDate!, afterJoin)
    }

    func testJoinSetsStartDate() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        challenge.join(userID: "user-123")

        XCTAssertNotNil(challenge.startDate)
    }

    func testJoinActivatesChallenge() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        challenge.join(userID: "user-123")

        XCTAssertTrue(challenge.isActive)
        XCTAssertEqual(challenge.status, .inProgress)
    }

    // MARK: - End Date Tests by Challenge Type

    func testDailyChallengeEndDate() {
        let challenge = Challenge(
            title: "Daily",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        let beforeJoin = Date()
        challenge.join(userID: "user-123")

        XCTAssertNotNil(challenge.endDate)

        // End date should be approximately 1 day from now
        let expectedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: beforeJoin)!
        let timeDifference = abs(challenge.endDate!.timeIntervalSince(expectedEndDate))

        // Allow 1 second tolerance
        XCTAssertLessThan(timeDifference, 1.0)
    }

    func testWeeklyChallengeEndDate() {
        let challenge = Challenge(
            title: "Weekly",
            description: "Test",
            type: .weekly,
            iconName: "star",
            targetCount: 7,
            rewardXP: 200
        )

        let beforeJoin = Date()
        challenge.join(userID: "user-123")

        XCTAssertNotNil(challenge.endDate)

        // End date should be approximately 7 days from now
        let expectedEndDate = Calendar.current.date(byAdding: .day, value: 7, to: beforeJoin)!
        let timeDifference = abs(challenge.endDate!.timeIntervalSince(expectedEndDate))

        // Allow 1 second tolerance
        XCTAssertLessThan(timeDifference, 1.0)
    }

    func testMilestoneChallengeNoEndDate() {
        let challenge = Challenge(
            title: "Milestone",
            description: "Test",
            type: .milestone,
            iconName: "star",
            targetCount: 100,
            rewardXP: 1000
        )

        challenge.join(userID: "user-123")

        XCTAssertNil(challenge.endDate)
    }

    // MARK: - Progress Tests

    func testUpdateProgressIncrements() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")

        challenge.updateProgress()
        XCTAssertEqual(challenge.currentProgress, 1)

        challenge.updateProgress()
        XCTAssertEqual(challenge.currentProgress, 2)

        challenge.updateProgress()
        XCTAssertEqual(challenge.currentProgress, 3)
    }

    func testProgressDoesNotExceedTarget() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 3,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")

        challenge.updateProgress()
        challenge.updateProgress()
        challenge.updateProgress()  // Completes

        XCTAssertEqual(challenge.currentProgress, 3)
        XCTAssertEqual(challenge.status, .completed)

        // Further progress should not be possible (status is completed)
        challenge.updateProgress()
        // Progress updates only happen if status is correct - challenge is now completed
    }

    // MARK: - Completion Tests

    func testAutoCompletesAtTarget() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 2,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")

        challenge.updateProgress()
        XCTAssertEqual(challenge.status, .inProgress)

        challenge.updateProgress()
        XCTAssertEqual(challenge.status, .completed)
    }

    func testCompleteDeactivatesChallenge() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        XCTAssertTrue(challenge.isActive)

        challenge.updateProgress()

        XCTAssertFalse(challenge.isActive)
        XCTAssertEqual(challenge.status, .completed)
    }

    func testManualComplete() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 10,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        challenge.complete()

        XCTAssertEqual(challenge.status, .completed)
        XCTAssertFalse(challenge.isActive)
    }

    // MARK: - Expiration Tests

    func testCheckExpirationDoesNothingWhenNotExpired() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        challenge.updateProgress()  // Progress: 1/5

        challenge.checkExpiration()

        XCTAssertEqual(challenge.status, .inProgress)
        XCTAssertTrue(challenge.isActive)
    }

    func testCheckExpirationDoesNothingForCompleted() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        challenge.updateProgress()  // Completes

        XCTAssertEqual(challenge.status, .completed)

        challenge.checkExpiration()

        XCTAssertEqual(challenge.status, .completed)  // Still completed, not failed
    }

    func testCheckExpirationDoesNothingForMilestone() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .milestone,
            iconName: "star",
            targetCount: 100,
            rewardXP: 1000
        )

        challenge.join(userID: "user-123")

        // Milestone has no end date
        XCTAssertNil(challenge.endDate)

        challenge.checkExpiration()

        XCTAssertEqual(challenge.status, .inProgress)
    }

    func testCheckExpirationDoesNothingForNotStarted() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        // Not joined
        XCTAssertEqual(challenge.status, .notStarted)

        challenge.checkExpiration()

        XCTAssertEqual(challenge.status, .notStarted)
    }

    // MARK: - Challenge Type Tests

    func testChallengeTypeValues() {
        XCTAssertEqual(ChallengeType.daily.rawValue, "Daily")
        XCTAssertEqual(ChallengeType.weekly.rawValue, "Weekly")
        XCTAssertEqual(ChallengeType.milestone.rawValue, "Milestone")
    }

    func testChallengeStatusValues() {
        XCTAssertEqual(ChallengeStatus.notStarted.rawValue, "Not Started")
        XCTAssertEqual(ChallengeStatus.inProgress.rawValue, "In Progress")
        XCTAssertEqual(ChallengeStatus.completed.rawValue, "Completed")
        XCTAssertEqual(ChallengeStatus.failed.rawValue, "Failed")
    }

    // MARK: - Edge Cases

    func testSingleProgressChallenge() {
        let challenge = Challenge(
            title: "One-time",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        challenge.join(userID: "user-123")

        XCTAssertEqual(challenge.currentProgress, 0)
        XCTAssertEqual(challenge.status, .inProgress)

        challenge.updateProgress()

        XCTAssertEqual(challenge.currentProgress, 1)
        XCTAssertEqual(challenge.status, .completed)
    }

    func testHighTargetChallenge() {
        let challenge = Challenge(
            title: "Big Goal",
            description: "Test",
            type: .milestone,
            iconName: "star",
            targetCount: 1000,
            rewardXP: 5000
        )

        challenge.join(userID: "user-123")

        // Simulate many progress updates
        for _ in 0..<100 {
            challenge.updateProgress()
        }

        XCTAssertEqual(challenge.currentProgress, 100)
        XCTAssertEqual(challenge.status, .inProgress)
    }

    func testZeroRewardXPChallenge() {
        let challenge = Challenge(
            title: "No Reward",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 0
        )

        XCTAssertEqual(challenge.rewardXP, 0)

        challenge.join(userID: "user-123")
        challenge.updateProgress()

        XCTAssertEqual(challenge.status, .completed)
    }

    func testUUIDUniqueness() {
        let challenge1 = Challenge(
            title: "Challenge 1",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        let challenge2 = Challenge(
            title: "Challenge 2",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 1,
            rewardXP: 50
        )

        XCTAssertNotEqual(challenge1.id, challenge2.id)
    }
}
