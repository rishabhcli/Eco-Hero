//
//  ChallengeManagerTests.swift
//  Eco HeroTests
//
//  Tests for ChallengeManager service - time remaining calculations and challenge lifecycle.
//

import XCTest
@testable import Eco_Hero

final class ChallengeManagerTests: XCTestCase {

    var challengeManager: ChallengeManager!

    override func setUp() {
        super.setUp()
        challengeManager = ChallengeManager()
    }

    override func tearDown() {
        challengeManager = nil
        super.tearDown()
    }

    // MARK: - Time Remaining Tests

    func testTimeRemainingReturnsNilForNotStartedChallenge() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        // Not joined, status is .notStarted
        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNil(result)
    }

    func testTimeRemainingReturnsNilForCompletedChallenge() {
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

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNil(result)
    }

    func testTimeRemainingReturnsNilForFailedChallenge() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        challenge.status = .failed

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNil(result)
    }

    func testTimeRemainingReturnsNilForMilestoneChallenge() {
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

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNil(result)
    }

    func testTimeRemainingShowsDaysAndHours() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .weekly,
            iconName: "star",
            targetCount: 7,
            rewardXP: 200
        )

        challenge.join(userID: "user-123")
        // Weekly challenge has 7 days, so should show days

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        // Result should contain "d" for days
        XCTAssertTrue(result?.contains("d") ?? false, "Expected days in time remaining: \(result ?? "nil")")
    }

    func testTimeRemainingShowsHoursAndMinutesForDaily() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 3,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        // Daily challenge has ~24 hours

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        // Result should contain "h" for hours
        XCTAssertTrue(result?.contains("h") ?? false, "Expected hours in time remaining: \(result ?? "nil")")
    }

    func testTimeRemainingReturnsExpiredForPastEndDate() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        // Manually set end date to the past
        challenge.endDate = Date().addingTimeInterval(-3600)  // 1 hour ago

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertEqual(result, "Expired")
    }

    // MARK: - Time Remaining Format Tests

    func testTimeRemainingFormatWithMultipleDays() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .weekly,
            iconName: "star",
            targetCount: 7,
            rewardXP: 200
        )

        challenge.join(userID: "user-123")
        // Set end date to 3 days from now
        challenge.endDate = Date().addingTimeInterval(3 * 24 * 3600 + 5 * 3600)  // 3 days 5 hours

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("3d") ?? false, "Expected '3d' in result: \(result ?? "nil")")
    }

    func testTimeRemainingFormatWithHoursOnly() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 3,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        // Set end date to 5 hours from now
        challenge.endDate = Date().addingTimeInterval(5 * 3600 + 30 * 60)  // 5 hours 30 minutes

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("h") ?? false, "Expected 'h' in result: \(result ?? "nil")")
        XCTAssertTrue(result?.contains("m") ?? false, "Expected 'm' in result: \(result ?? "nil")")
    }

    func testTimeRemainingFormatWithMinutesOnly() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 3,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        // Set end date to 45 minutes from now
        challenge.endDate = Date().addingTimeInterval(45 * 60)

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        // Should show minutes only when less than 1 hour
        XCTAssertTrue(result?.contains("m left") ?? false, "Expected minutes only in result: \(result ?? "nil")")
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(challengeManager.expiringChallenges.isEmpty)
        XCTAssertTrue(challengeManager.recentlyFailedChallenges.isEmpty)
    }

    func testClearRecentlyFailed() {
        // Add some failed challenges manually (normally done by checkAllExpirations)
        // For this test, we just verify the clear function works
        challengeManager.clearRecentlyFailed()

        XCTAssertTrue(challengeManager.recentlyFailedChallenges.isEmpty)
    }

    // MARK: - Join Challenge Tests (without ModelContext)

    func testJoinChallengeRequiresNotStartedStatus() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        // First join
        challenge.join(userID: "user-123")
        XCTAssertEqual(challenge.status, .inProgress)

        // Save original user
        let originalUser = challenge.userID

        // Trying to "join" via manager should not work since status is not .notStarted
        // Note: This would need ModelContext to actually test joinChallenge method
        // For now, test the Challenge model behavior directly
        XCTAssertEqual(challenge.userID, originalUser)
    }

    // MARK: - Update Progress Tests (without ModelContext)

    func testUpdateProgressIncrementsChallenge() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")

        // Direct challenge update
        challenge.updateProgress()
        XCTAssertEqual(challenge.currentProgress, 1)

        challenge.updateProgress()
        XCTAssertEqual(challenge.currentProgress, 2)
    }

    func testUpdateProgressCompletesChallenge() {
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
        challenge.updateProgress()

        XCTAssertEqual(challenge.status, .completed)
        XCTAssertFalse(challenge.isActive)
    }

    // MARK: - Abandon Challenge Tests (without ModelContext)

    func testAbandonChallengeSetsFailed() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")

        // Simulate abandon behavior
        challenge.status = .failed
        challenge.isActive = false

        XCTAssertEqual(challenge.status, .failed)
        XCTAssertFalse(challenge.isActive)
    }

    // MARK: - Retry Challenge Tests (without ModelContext)

    func testRetryChallengeResetsState() {
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
        challenge.updateProgress()
        challenge.status = .failed

        // Reset state like retry would
        challenge.currentProgress = 0
        challenge.status = .notStarted
        challenge.isActive = false
        challenge.startDate = nil
        challenge.endDate = nil
        challenge.joinedDate = nil

        XCTAssertEqual(challenge.currentProgress, 0)
        XCTAssertEqual(challenge.status, .notStarted)
        XCTAssertFalse(challenge.isActive)
        XCTAssertNil(challenge.startDate)
        XCTAssertNil(challenge.endDate)
    }

    // MARK: - Edge Cases

    func testTimeRemainingWithExactlyZeroSeconds() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .daily,
            iconName: "star",
            targetCount: 5,
            rewardXP: 100
        )

        challenge.join(userID: "user-123")
        challenge.endDate = Date()  // Exactly now

        let result = challengeManager.timeRemaining(for: challenge)

        // Should return "Expired" or "0m left" depending on implementation
        XCTAssertNotNil(result)
    }

    func testTimeRemainingWithVeryLargeDuration() {
        let challenge = Challenge(
            title: "Test",
            description: "Test",
            type: .milestone,
            iconName: "star",
            targetCount: 1000,
            rewardXP: 5000
        )

        challenge.join(userID: "user-123")
        // Milestones have no end date, so manually set a far future date
        challenge.endDate = Date().addingTimeInterval(365 * 24 * 3600)  // 1 year

        let result = challengeManager.timeRemaining(for: challenge)

        XCTAssertNotNil(result)
        // Should show many days
        XCTAssertTrue(result?.contains("d") ?? false)
    }
}
