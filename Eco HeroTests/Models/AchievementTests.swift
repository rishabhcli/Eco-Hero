//
//  AchievementTests.swift
//  Eco HeroTests
//
//  Tests for Achievement model - progress tracking and unlock logic.
//

import XCTest
@testable import Eco_Hero

final class AchievementTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialValues() {
        let achievement = Achievement(
            badgeID: "test_badge",
            title: "Test Achievement",
            description: "A test achievement",
            tier: .bronze,
            iconName: "star.fill",
            progressRequired: 10
        )

        XCTAssertEqual(achievement.badgeID, "test_badge")
        XCTAssertEqual(achievement.title, "Test Achievement")
        XCTAssertEqual(achievement.badgeDescription, "A test achievement")
        XCTAssertEqual(achievement.tier, .bronze)
        XCTAssertEqual(achievement.iconName, "star.fill")
        XCTAssertEqual(achievement.progressRequired, 10)
        XCTAssertEqual(achievement.progressCurrent, 0)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedDate)
        XCTAssertNil(achievement.category)
        XCTAssertNil(achievement.userID)
    }

    func testInitWithCategory() {
        let achievement = Achievement(
            badgeID: "meals_badge",
            title: "Meals Master",
            description: "Log many meals",
            tier: .silver,
            iconName: "fork.knife",
            category: .meals,
            progressRequired: 50
        )

        XCTAssertEqual(achievement.category, .meals)
    }

    func testInitWithUserID() {
        let achievement = Achievement(
            badgeID: "user_badge",
            title: "User Badge",
            description: "User specific",
            tier: .gold,
            iconName: "person.fill",
            progressRequired: 100,
            userID: "user-123"
        )

        XCTAssertEqual(achievement.userID, "user-123")
    }

    // MARK: - Tier Tests

    func testAchievementTierValues() {
        XCTAssertEqual(AchievementTier.bronze.rawValue, "Bronze")
        XCTAssertEqual(AchievementTier.silver.rawValue, "Silver")
        XCTAssertEqual(AchievementTier.gold.rawValue, "Gold")
        XCTAssertEqual(AchievementTier.platinum.rawValue, "Platinum")
    }

    func testAllTiersCanBeCreated() {
        let bronze = Achievement(
            badgeID: "bronze",
            title: "Bronze",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        let silver = Achievement(
            badgeID: "silver",
            title: "Silver",
            description: "Test",
            tier: .silver,
            iconName: "star",
            progressRequired: 25
        )

        let gold = Achievement(
            badgeID: "gold",
            title: "Gold",
            description: "Test",
            tier: .gold,
            iconName: "star",
            progressRequired: 50
        )

        let platinum = Achievement(
            badgeID: "platinum",
            title: "Platinum",
            description: "Test",
            tier: .platinum,
            iconName: "star",
            progressRequired: 100
        )

        XCTAssertEqual(bronze.tier, .bronze)
        XCTAssertEqual(silver.tier, .silver)
        XCTAssertEqual(gold.tier, .gold)
        XCTAssertEqual(platinum.tier, .platinum)
    }

    // MARK: - Progress Update Tests

    func testUpdateProgressIncrementsCorrectly() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 3)
        XCTAssertEqual(achievement.progressCurrent, 3)

        achievement.updateProgress(by: 2)
        XCTAssertEqual(achievement.progressCurrent, 5)

        achievement.updateProgress(by: 1.5)
        XCTAssertEqual(achievement.progressCurrent, 6.5)
    }

    func testUpdateProgressAccumulatesCorrectly() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        for _ in 0..<10 {
            achievement.updateProgress(by: 5)
        }

        XCTAssertEqual(achievement.progressCurrent, 50)
    }

    func testUpdateProgressWithFractionalValues() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 0.5)
        achievement.updateProgress(by: 0.25)
        achievement.updateProgress(by: 0.25)

        XCTAssertEqual(achievement.progressCurrent, 1.0, accuracy: 0.001)
    }

    // MARK: - Auto-Unlock Tests

    func testAutoUnlocksAtThreshold() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 10)

        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedDate)
    }

    func testAutoUnlocksWhenExceedingThreshold() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 15)

        XCTAssertTrue(achievement.isUnlocked)
    }

    func testDoesNotUnlockBelowThreshold() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 9.99)

        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedDate)
    }

    func testUnlockDateIsSetOnUnlock() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 5
        )

        let beforeUnlock = Date()
        achievement.updateProgress(by: 5)
        let afterUnlock = Date()

        XCTAssertNotNil(achievement.unlockedDate)
        XCTAssertGreaterThanOrEqual(achievement.unlockedDate!, beforeUnlock)
        XCTAssertLessThanOrEqual(achievement.unlockedDate!, afterUnlock)
    }

    // MARK: - Already Unlocked Tests

    func testCannotUpdateProgressAfterUnlock() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 10)  // Unlocks
        XCTAssertTrue(achievement.isUnlocked)

        let progressAtUnlock = achievement.progressCurrent
        achievement.updateProgress(by: 5)  // Should not change

        XCTAssertEqual(achievement.progressCurrent, progressAtUnlock)
    }

    func testUnlockDateDoesNotChangeOnSubsequentUpdates() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        achievement.updateProgress(by: 10)
        let originalUnlockDate = achievement.unlockedDate

        // Try to update again
        achievement.updateProgress(by: 5)

        XCTAssertEqual(achievement.unlockedDate, originalUnlockDate)
    }

    // MARK: - Manual Unlock Tests

    func testManualUnlock() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        achievement.unlock()

        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedDate)
    }

    func testManualUnlockDoesNotChangeProgress() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        achievement.updateProgress(by: 25)
        achievement.unlock()

        XCTAssertEqual(achievement.progressCurrent, 25)
        XCTAssertTrue(achievement.isUnlocked)
    }

    // MARK: - Progress Percentage Tests

    func testProgressPercentageAtZero() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        XCTAssertEqual(achievement.progressPercentage, 0)
    }

    func testProgressPercentageAtHalf() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        achievement.updateProgress(by: 50)

        XCTAssertEqual(achievement.progressPercentage, 50, accuracy: 0.001)
    }

    func testProgressPercentageAt100() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 100
        )

        achievement.updateProgress(by: 100)

        XCTAssertEqual(achievement.progressPercentage, 100, accuracy: 0.001)
    }

    func testProgressPercentageCapsAt100() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        // Manually set progress above required (shouldn't happen normally but testing the cap)
        achievement.progressCurrent = 15

        XCTAssertEqual(achievement.progressPercentage, 100, accuracy: 0.001)
    }

    func testProgressPercentageWithFractionalValues() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 3
        )

        achievement.updateProgress(by: 1)

        XCTAssertEqual(achievement.progressPercentage, 33.333, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testProgressRequiredZero() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 0
        )

        // progressPercentage should handle division by zero
        XCTAssertEqual(achievement.progressPercentage, 0)
    }

    func testProgressRequiredOne() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 1
        )

        achievement.updateProgress(by: 1)

        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertEqual(achievement.progressPercentage, 100)
    }

    func testLargeProgressRequired() {
        let achievement = Achievement(
            badgeID: "test",
            title: "Test",
            description: "Test",
            tier: .platinum,
            iconName: "star",
            progressRequired: 10000
        )

        achievement.updateProgress(by: 100)

        XCTAssertEqual(achievement.progressPercentage, 1, accuracy: 0.001)
        XCTAssertFalse(achievement.isUnlocked)
    }

    func testUUIDUniqueness() {
        let achievement1 = Achievement(
            badgeID: "test1",
            title: "Test 1",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        let achievement2 = Achievement(
            badgeID: "test2",
            title: "Test 2",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        XCTAssertNotEqual(achievement1.id, achievement2.id)
    }

    func testSameBadgeIDDifferentInstances() {
        let achievement1 = Achievement(
            badgeID: "same_badge",
            title: "Same Badge",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        let achievement2 = Achievement(
            badgeID: "same_badge",
            title: "Same Badge",
            description: "Test",
            tier: .bronze,
            iconName: "star",
            progressRequired: 10
        )

        // Different instances with same badge ID should have different UUIDs
        XCTAssertNotEqual(achievement1.id, achievement2.id)
        XCTAssertEqual(achievement1.badgeID, achievement2.badgeID)
    }
}
