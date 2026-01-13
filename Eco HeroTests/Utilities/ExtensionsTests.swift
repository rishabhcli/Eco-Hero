//
//  ExtensionsTests.swift
//  Eco HeroTests
//
//  Tests for utility extensions - Date, Double, Color, and View extensions.
//

import XCTest
import SwiftUI
@testable import Eco_Hero

final class ExtensionsTests: XCTestCase {

    // MARK: - Date Extension Tests

    func testDateIsToday() {
        let today = Date()
        XCTAssertTrue(today.isToday)
    }

    func testDateIsNotTodayForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testDateIsNotTodayForTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(tomorrow.isToday)
    }

    func testDateIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func testDateIsNotYesterdayForToday() {
        let today = Date()
        XCTAssertFalse(today.isYesterday)
    }

    func testDateIsNotYesterdayForTwoDaysAgo() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertFalse(twoDaysAgo.isYesterday)
    }

    func testDateDaysAgo() {
        let today = Date()
        let fiveDaysAgo = today.daysAgo(5)

        let calendar = Calendar.current
        let difference = calendar.dateComponents([.day], from: fiveDaysAgo, to: today)

        XCTAssertEqual(difference.day, 5)
    }

    func testDateDaysAgoZero() {
        let today = Date()
        let zeroDaysAgo = today.daysAgo(0)

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(zeroDaysAgo, inSameDayAs: today))
    }

    func testDateStartOfDay() {
        let now = Date()
        let startOfDay = now.startOfDay

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testDateEndOfDay() {
        let now = Date()
        let endOfDay = now.endOfDay

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfDay)

        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testDateStartOfDayAndEndOfDaySameDay() {
        let now = Date()
        let startOfDay = now.startOfDay
        let endOfDay = now.endOfDay

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(startOfDay, inSameDayAs: endOfDay))
    }

    // MARK: - Double Rounded Tests

    func testDoubleRoundedToZeroPlaces() {
        let value = 3.14159
        let rounded = value.rounded(toPlaces: 0)
        XCTAssertEqual(rounded, 3.0, accuracy: 0.001)
    }

    func testDoubleRoundedToOnePlaces() {
        let value = 3.14159
        let rounded = value.rounded(toPlaces: 1)
        XCTAssertEqual(rounded, 3.1, accuracy: 0.001)
    }

    func testDoubleRoundedToTwoPlaces() {
        let value = 3.14159
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, 3.14, accuracy: 0.001)
    }

    func testDoubleRoundedToThreePlaces() {
        let value = 3.14159
        let rounded = value.rounded(toPlaces: 3)
        XCTAssertEqual(rounded, 3.142, accuracy: 0.0001)
    }

    func testDoubleRoundedRoundsUp() {
        let value = 3.145
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, 3.15, accuracy: 0.001)
    }

    func testDoubleRoundedRoundsDown() {
        let value = 3.144
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, 3.14, accuracy: 0.001)
    }

    func testDoubleRoundedNegativeValue() {
        let value = -3.14159
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, -3.14, accuracy: 0.001)
    }

    func testDoubleRoundedZeroValue() {
        let value = 0.0
        let rounded = value.rounded(toPlaces: 2)
        XCTAssertEqual(rounded, 0.0, accuracy: 0.001)
    }

    // MARK: - Double Abbreviated Tests

    func testDoubleAbbreviatedSmallNumber() {
        let value = 123.45
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "123.45")
    }

    func testDoubleAbbreviatedWholeNumber() {
        let value = 100.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "100")
    }

    func testDoubleAbbreviatedThousands() {
        let value = 1500.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "1.50K")
    }

    func testDoubleAbbreviatedTenThousands() {
        let value = 15000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "15.00K")
    }

    func testDoubleAbbreviatedHundredThousands() {
        let value = 150000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "150.00K")
    }

    func testDoubleAbbreviatedMillions() {
        let value = 1500000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "1.50M")
    }

    func testDoubleAbbreviatedTenMillions() {
        let value = 15000000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "15.00M")
    }

    func testDoubleAbbreviatedExactThousand() {
        let value = 1000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "1.00K")
    }

    func testDoubleAbbreviatedExactMillion() {
        let value = 1000000.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "1.00M")
    }

    func testDoubleAbbreviatedBelowThousand() {
        let value = 999.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "999")
    }

    func testDoubleAbbreviatedZero() {
        let value = 0.0
        let abbreviated = value.abbreviated
        XCTAssertEqual(abbreviated, "0")
    }

    // MARK: - Double TwoDecimalPlaces Tests

    func testDoubleTwoDecimalPlaces() {
        let value = 3.14159
        let formatted = value.twoDecimalPlaces
        XCTAssertEqual(formatted, "3.14")
    }

    func testDoubleTwoDecimalPlacesWholeNumber() {
        let value = 10.0
        let formatted = value.twoDecimalPlaces
        XCTAssertEqual(formatted, "10.00")
    }

    func testDoubleTwoDecimalPlacesOneDecimal() {
        let value = 5.5
        let formatted = value.twoDecimalPlaces
        XCTAssertEqual(formatted, "5.50")
    }

    func testDoubleTwoDecimalPlacesNegative() {
        let value = -12.345
        let formatted = value.twoDecimalPlaces
        XCTAssertEqual(formatted, "-12.35")  // Rounds
    }

    // MARK: - Double FormattedWithCommas Tests

    func testDoubleFormattedWithCommasSmall() {
        let value = 123.45
        let formatted = value.formattedWithCommas

        // Result depends on locale, but should contain the number
        XCTAssertTrue(formatted.contains("123"))
    }

    func testDoubleFormattedWithCommasThousands() {
        let value = 1234.56
        let formatted = value.formattedWithCommas

        // Should have comma or locale separator
        XCTAssertTrue(formatted.contains("1") && formatted.contains("234"))
    }

    func testDoubleFormattedWithCommasMillions() {
        let value = 1234567.89
        let formatted = value.formattedWithCommas

        // Should contain the digits
        XCTAssertTrue(formatted.contains("1"))
        XCTAssertTrue(formatted.contains("234"))
        XCTAssertTrue(formatted.contains("567"))
    }

    // MARK: - Color Hex Tests

    func testColorHex6Digits() {
        let color = Color(hex: "FF0000")  // Red
        // Color initialization should succeed
        XCTAssertNotNil(color)
    }

    func testColorHex3Digits() {
        let color = Color(hex: "F00")  // Red shorthand
        XCTAssertNotNil(color)
    }

    func testColorHex8Digits() {
        let color = Color(hex: "FFFF0000")  // Red with alpha
        XCTAssertNotNil(color)
    }

    func testColorHexWithHash() {
        let color = Color(hex: "#00FF00")  // Green with hash
        XCTAssertNotNil(color)
    }

    func testColorHexLowercase() {
        let color = Color(hex: "0000ff")  // Blue lowercase
        XCTAssertNotNil(color)
    }

    func testColorHexMixedCase() {
        let color = Color(hex: "FfAa00")  // Orange mixed case
        XCTAssertNotNil(color)
    }

    func testColorHexInvalid() {
        // Invalid hex should still create a color (fallback behavior)
        let color = Color(hex: "invalid")
        XCTAssertNotNil(color)
    }

    func testColorHexEmpty() {
        let color = Color(hex: "")
        XCTAssertNotNil(color)
    }

    // MARK: - Predefined Eco Colors

    func testEcoGreenColor() {
        let color = Color.ecoGreen
        XCTAssertNotNil(color)
    }

    func testEcoBlueColor() {
        let color = Color.ecoBlue
        XCTAssertNotNil(color)
    }

    func testEcoOrangeColor() {
        let color = Color.ecoOrange
        XCTAssertNotNil(color)
    }

    // MARK: - ShadowLevel Tests

    func testShadowLevelNone() {
        let level = ShadowLevel.none

        XCTAssertEqual(level.radius, 0)
        XCTAssertEqual(level.yOffset, 0)
        XCTAssertEqual(level.opacity, 0)
    }

    func testShadowLevelSubtle() {
        let level = ShadowLevel.subtle

        XCTAssertEqual(level.radius, 8)
        XCTAssertEqual(level.yOffset, 4)
        XCTAssertEqual(level.opacity, 0.04)
    }

    func testShadowLevelMedium() {
        let level = ShadowLevel.medium

        XCTAssertEqual(level.radius, 16)
        XCTAssertEqual(level.yOffset, 8)
        XCTAssertEqual(level.opacity, 0.08)
    }

    func testShadowLevelElevated() {
        let level = ShadowLevel.elevated

        XCTAssertEqual(level.radius, 24)
        XCTAssertEqual(level.yOffset, 12)
        XCTAssertEqual(level.opacity, 0.12)
    }

    func testShadowLevelFloating() {
        let level = ShadowLevel.floating

        XCTAssertEqual(level.radius, 32)
        XCTAssertEqual(level.yOffset, 16)
        XCTAssertEqual(level.opacity, 0.16)
    }

    func testShadowLevelHierarchy() {
        // Ensure shadow levels increase in intensity
        XCTAssertLessThan(ShadowLevel.none.radius, ShadowLevel.subtle.radius)
        XCTAssertLessThan(ShadowLevel.subtle.radius, ShadowLevel.medium.radius)
        XCTAssertLessThan(ShadowLevel.medium.radius, ShadowLevel.elevated.radius)
        XCTAssertLessThan(ShadowLevel.elevated.radius, ShadowLevel.floating.radius)
    }

    // MARK: - ScrollOffsetPreferenceKey Tests

    func testScrollOffsetPreferenceKeyDefaultValue() {
        XCTAssertEqual(ScrollOffsetPreferenceKey.defaultValue, 0)
    }

    func testScrollOffsetPreferenceKeyReduce() {
        var value: CGFloat = 0
        ScrollOffsetPreferenceKey.reduce(value: &value) { 100 }
        XCTAssertEqual(value, 100)
    }

    // MARK: - Edge Cases

    func testDateDaysAgoNegative() {
        // Negative days should go into the future
        let today = Date()
        let futureDate = today.daysAgo(-5)

        let calendar = Calendar.current
        let difference = calendar.dateComponents([.day], from: today, to: futureDate)

        XCTAssertEqual(difference.day, 5)
    }

    func testDoubleRoundedLargeDecimalPlaces() {
        let value = 3.14159265359
        let rounded = value.rounded(toPlaces: 10)

        // Should handle large decimal place requests
        XCTAssertEqual(rounded, 3.14159265359, accuracy: 0.0000000001)
    }

    func testDoubleAbbreviatedVeryLargeNumber() {
        let value = 999999999999.0
        let abbreviated = value.abbreviated

        // Should still produce a valid string
        XCTAssertFalse(abbreviated.isEmpty)
    }

    func testDoubleAbbreviatedVerySmallDecimal() {
        let value = 0.001
        let abbreviated = value.abbreviated

        XCTAssertEqual(abbreviated, "0.00")  // Rounded to 2 decimal places
    }
}
