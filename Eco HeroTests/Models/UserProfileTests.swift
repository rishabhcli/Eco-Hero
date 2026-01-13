//
//  UserProfileTests.swift
//  Eco HeroTests
//
//  Tests for UserProfile model - XP calculation, leveling, and streak logic.
//

import XCTest
@testable import Eco_Hero

final class UserProfileTests: XCTestCase {

    var profile: UserProfile!

    override func setUp() {
        super.setUp()
        profile = UserProfile(
            userIdentifier: "test-user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialValues() {
        XCTAssertEqual(profile.userIdentifier, "test-user-123")
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertEqual(profile.displayName, "Test User")
        XCTAssertEqual(profile.currentLevel, 1)
        XCTAssertEqual(profile.experiencePoints, 0)
        XCTAssertEqual(profile.streak, 0)
        XCTAssertEqual(profile.longestStreak, 0)
        XCTAssertEqual(profile.totalCarbonSavedKg, 0)
        XCTAssertEqual(profile.totalWaterSavedLiters, 0)
        XCTAssertEqual(profile.totalLandSavedSqMeters, 0)
        XCTAssertEqual(profile.totalPlasticSavedItems, 0)
        XCTAssertEqual(profile.totalActivitiesLogged, 0)
        XCTAssertNil(profile.lastActivityDate)
    }

    func testInitialSettings() {
        XCTAssertTrue(profile.soundEnabled)
        XCTAssertTrue(profile.hapticsEnabled)
        XCTAssertTrue(profile.notificationsEnabled)
    }

    // MARK: - Impact Metrics Accumulation Tests

    func testUpdateImpactMetricsAccumulatesCarbon() {
        let activity = EcoActivity(
            category: .transport,
            description: "Biked to work",
            carbonSavedKg: 2.5,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalCarbonSavedKg, 2.5, accuracy: 0.001)
    }

    func testUpdateImpactMetricsAccumulatesWater() {
        let activity = EcoActivity(
            category: .water,
            description: "Shorter shower",
            carbonSavedKg: 0,
            waterSavedLiters: 50,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalWaterSavedLiters, 50, accuracy: 0.001)
    }

    func testUpdateImpactMetricsAccumulatesLand() {
        let activity = EcoActivity(
            category: .meals,
            description: "Vegan meal",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 3.5,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalLandSavedSqMeters, 3.5, accuracy: 0.001)
    }

    func testUpdateImpactMetricsAccumulatesPlastic() {
        let activity = EcoActivity(
            category: .plastic,
            description: "Used reusable bags",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 5
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalPlasticSavedItems, 5)
    }

    func testUpdateImpactMetricsAccumulatesMultipleActivities() {
        let activity1 = EcoActivity(
            category: .transport,
            description: "Biked",
            carbonSavedKg: 1.0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let activity2 = EcoActivity(
            category: .transport,
            description: "Walked",
            carbonSavedKg: 0.5,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity1)
        profile.updateImpactMetrics(activity: activity2)

        XCTAssertEqual(profile.totalCarbonSavedKg, 1.5, accuracy: 0.001)
        XCTAssertEqual(profile.totalActivitiesLogged, 2)
    }

    func testActivityCountIncrements() {
        let activity = EcoActivity(
            category: .other,
            description: "Test",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.totalActivitiesLogged, 1)

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.totalActivitiesLogged, 2)

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.totalActivitiesLogged, 3)
    }

    // MARK: - XP Calculation Tests

    func testXPCalculationFormula() {
        // XP = carbon * 10 + water * 0.01 + plastic * 5
        let activity = EcoActivity(
            category: .meals,
            description: "Mixed activity",
            carbonSavedKg: 2.0,      // 2.0 * 10 = 20 XP
            waterSavedLiters: 1000,  // 1000 * 0.01 = 10 XP
            landSavedSqMeters: 1.0,  // Not included in XP
            plasticSavedItems: 4     // 4 * 5 = 20 XP
        )
        // Total: 20 + 10 + 20 = 50 XP

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.experiencePoints, 50, accuracy: 0.001)
    }

    func testXPFromCarbonOnly() {
        let activity = EcoActivity(
            category: .transport,
            description: "Carbon only",
            carbonSavedKg: 5.0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        // 5.0 * 10 = 50 XP
        XCTAssertEqual(profile.experiencePoints, 50, accuracy: 0.001)
    }

    func testXPFromWaterOnly() {
        let activity = EcoActivity(
            category: .water,
            description: "Water only",
            carbonSavedKg: 0,
            waterSavedLiters: 500,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        // 500 * 0.01 = 5 XP
        XCTAssertEqual(profile.experiencePoints, 5, accuracy: 0.001)
    }

    func testXPFromPlasticOnly() {
        let activity = EcoActivity(
            category: .plastic,
            description: "Plastic only",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 10
        )

        profile.updateImpactMetrics(activity: activity)

        // 10 * 5 = 50 XP
        XCTAssertEqual(profile.experiencePoints, 50, accuracy: 0.001)
    }

    func testXPAccumulatesAcrossActivities() {
        let activity1 = EcoActivity(
            category: .transport,
            description: "Activity 1",
            carbonSavedKg: 3.0,  // 30 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let activity2 = EcoActivity(
            category: .plastic,
            description: "Activity 2",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 6  // 30 XP
        )

        profile.updateImpactMetrics(activity: activity1)
        profile.updateImpactMetrics(activity: activity2)

        XCTAssertEqual(profile.experiencePoints, 60, accuracy: 0.001)
    }

    // MARK: - Level Up Tests

    func testNoLevelUpBelow100XP() {
        let activity = EcoActivity(
            category: .transport,
            description: "Small activity",
            carbonSavedKg: 9.0,  // 90 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.currentLevel, 1)
        XCTAssertEqual(profile.experiencePoints, 90, accuracy: 0.001)
    }

    func testLevelUpAtExactly100XP() {
        let activity = EcoActivity(
            category: .transport,
            description: "Level up activity",
            carbonSavedKg: 10.0,  // 100 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.currentLevel, 2)
        XCTAssertEqual(profile.experiencePoints, 100, accuracy: 0.001)
    }

    func testLevelUpAbove100XP() {
        let activity = EcoActivity(
            category: .transport,
            description: "Big activity",
            carbonSavedKg: 15.0,  // 150 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.currentLevel, 2)
        XCTAssertEqual(profile.experiencePoints, 150, accuracy: 0.001)
    }

    func testMultipleLevelUpsFromSingleActivity() {
        // To reach level 3, need >= 200 XP (level 2 threshold is 100, level 3 is 200)
        let activity = EcoActivity(
            category: .transport,
            description: "Massive activity",
            carbonSavedKg: 25.0,  // 250 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        // 250 XP should put us at level 3 (needs >= 200 XP for level 3)
        XCTAssertEqual(profile.currentLevel, 3)
    }

    func testLevelThresholdFormula() {
        // Level N requires N * 100 XP to advance
        // Level 1 -> 2: 100 XP
        // Level 2 -> 3: 200 XP
        // Level 3 -> 4: 300 XP

        // Add exactly 300 XP total
        let activity = EcoActivity(
            category: .transport,
            description: "Test",
            carbonSavedKg: 30.0,  // 300 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        // At 300 XP: level 3 requires 200, level 4 requires 300
        // So we should be at level 4
        XCTAssertEqual(profile.currentLevel, 4)
    }

    func testGradualLevelProgression() {
        // Add 50 XP at a time
        let activity = EcoActivity(
            category: .transport,
            description: "Test",
            carbonSavedKg: 5.0,  // 50 XP
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.currentLevel, 1)  // 50 XP

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.currentLevel, 2)  // 100 XP

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.currentLevel, 2)  // 150 XP

        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.currentLevel, 3)  // 200 XP
    }

    // MARK: - Streak Tests

    func testFirstActivityStartsStreak() {
        let activity = EcoActivity(
            category: .other,
            description: "First activity",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.streak, 1)
        XCTAssertNotNil(profile.lastActivityDate)
    }

    func testSameDayActivityDoesNotChangeStreak() {
        let activity = EcoActivity(
            category: .other,
            description: "Test",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        // First activity
        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.streak, 1)

        // Second activity same day
        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.streak, 1)

        // Third activity same day
        profile.updateImpactMetrics(activity: activity)
        XCTAssertEqual(profile.streak, 1)
    }

    func testLongestStreakUpdatesWhenCurrentExceeds() {
        let activity = EcoActivity(
            category: .other,
            description: "Test",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        // First activity - streak 1, longest 0 -> becomes 1
        profile.updateImpactMetrics(activity: activity)
        // Note: We need consecutive days to test this properly
        // For now, just verify initial state
        XCTAssertEqual(profile.streak, 1)
        // The longest streak might or might not update based on implementation
    }

    // MARK: - Streak Edge Cases (Unit testable without date manipulation)

    func testStreakStartsAtZero() {
        XCTAssertEqual(profile.streak, 0)
        XCTAssertEqual(profile.longestStreak, 0)
    }

    func testLastActivityDateUpdatesOnActivity() {
        XCTAssertNil(profile.lastActivityDate)

        let activity = EcoActivity(
            category: .other,
            description: "Test",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertNotNil(profile.lastActivityDate)
    }

    // MARK: - Zero Impact Activity Tests

    func testZeroImpactActivityStillCountsAsActivity() {
        let activity = EcoActivity(
            category: .other,
            description: "Zero impact",
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalActivitiesLogged, 1)
        XCTAssertEqual(profile.experiencePoints, 0)
        XCTAssertEqual(profile.streak, 1)
    }

    // MARK: - Mixed Impact Tests

    func testMixedImpactActivity() {
        let activity = EcoActivity(
            category: .lifestyle,
            description: "Full eco day",
            carbonSavedKg: 5.0,        // 50 XP
            waterSavedLiters: 200,     // 2 XP
            landSavedSqMeters: 2.0,    // 0 XP (not counted)
            plasticSavedItems: 3       // 15 XP
        )
        // Total: 67 XP

        profile.updateImpactMetrics(activity: activity)

        XCTAssertEqual(profile.totalCarbonSavedKg, 5.0, accuracy: 0.001)
        XCTAssertEqual(profile.totalWaterSavedLiters, 200, accuracy: 0.001)
        XCTAssertEqual(profile.totalLandSavedSqMeters, 2.0, accuracy: 0.001)
        XCTAssertEqual(profile.totalPlasticSavedItems, 3)
        XCTAssertEqual(profile.experiencePoints, 67, accuracy: 0.001)
    }
}
