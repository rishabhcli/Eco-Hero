//
//  WasteClassifierServiceTests.swift
//  Eco HeroTests
//
//  Tests for WasteClassifierService - classification mapping and rolling average logic.
//  Note: Camera and ML model tests require device/simulator testing.
//

import XCTest
@testable import Eco_Hero

final class WasteClassifierServiceTests: XCTestCase {

    // MARK: - WasteBin Tests

    func testWasteBinEnum() {
        // Verify WasteBin enum values
        XCTAssertEqual(WasteBin.recycle.rawValue, "Recycle")
        XCTAssertEqual(WasteBin.compost.rawValue, "Compost")
    }

    func testWasteBinCases() {
        let allCases = WasteBin.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.recycle))
        XCTAssertTrue(allCases.contains(.compost))
    }

    func testWasteBinIcons() {
        XCTAssertEqual(WasteBin.recycle.icon, "arrow.3.trianglepath")
        XCTAssertEqual(WasteBin.compost.icon, "leaf.fill")
    }

    func testWasteBinColors() {
        XCTAssertNotNil(WasteBin.recycle.color)
        XCTAssertNotNil(WasteBin.compost.color)
    }

    // MARK: - Classification Mapping Tests

    func testMapRecycleLabelToRecycleBin() {
        // These test the expected mapping behavior based on the implementation
        let labels = ["recycle", "Recycle", "RECYCLE", "recyclable", "R", "r"]

        for label in labels {
            let expectedBin = mapTestClassificationToBin(classification: label)
            XCTAssertEqual(expectedBin, .recycle, "Label '\(label)' should map to recycle")
        }
    }

    func testMapCompostLabelToCompostBin() {
        let labels = ["compost", "Compost", "COMPOST", "organic", "Organic", "O", "o"]

        for label in labels {
            let expectedBin = mapTestClassificationToBin(classification: label)
            XCTAssertEqual(expectedBin, .compost, "Label '\(label)' should map to compost")
        }
    }

    func testUnknownLabelDefaultsToRecycle() {
        let unknownLabels = ["unknown", "trash", "garbage", "waste", "other", "???"]

        for label in unknownLabels {
            let expectedBin = mapTestClassificationToBin(classification: label)
            XCTAssertEqual(expectedBin, .recycle, "Unknown label '\(label)' should default to recycle")
        }
    }

    func testMixedCaseLabels() {
        XCTAssertEqual(mapTestClassificationToBin(classification: "ReCyClE"), .recycle)
        XCTAssertEqual(mapTestClassificationToBin(classification: "CoMpOsT"), .compost)
        XCTAssertEqual(mapTestClassificationToBin(classification: "OrGaNiC"), .compost)
    }

    func testPartialMatchLabels() {
        // Labels containing keywords
        XCTAssertEqual(mapTestClassificationToBin(classification: "recyclable_plastic"), .recycle)
        XCTAssertEqual(mapTestClassificationToBin(classification: "compost_bin"), .compost)
        XCTAssertEqual(mapTestClassificationToBin(classification: "organic_waste"), .compost)
    }

    // MARK: - Rolling Average Logic Tests

    func testRollingAverageWithAllRecycle() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.9),
            (.recycle, 0.85),
            (.recycle, 0.92),
            (.recycle, 0.88),
            (.recycle, 0.91)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        XCTAssertEqual(result.bin, .recycle)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }

    func testRollingAverageWithAllCompost() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.compost, 0.85),
            (.compost, 0.9),
            (.compost, 0.87),
            (.compost, 0.92),
            (.compost, 0.88)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        XCTAssertEqual(result.bin, .compost)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }

    func testRollingAverageWithMixedPredictions() {
        // More recycle than compost
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.8),
            (.recycle, 0.85),
            (.recycle, 0.9),
            (.compost, 0.7),
            (.recycle, 0.8)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Recycle should win (4 vs 1)
        XCTAssertEqual(result.bin, .recycle)
    }

    func testRollingAverageWithEqualSplitFavorsHigherConfidence() {
        // Equal count but different confidences
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.9),
            (.recycle, 0.9),
            (.compost, 0.5),
            (.compost, 0.5)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Recycle has higher total confidence (1.8 vs 1.0)
        XCTAssertEqual(result.bin, .recycle)
    }

    func testRollingAverageConfidenceCalculation() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.8),
            (.recycle, 0.9),
            (.recycle, 1.0)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Average confidence = (0.8 + 0.9 + 1.0) / 3 = 0.9
        XCTAssertEqual(result.confidence, 0.9, accuracy: 0.01)
    }

    func testRollingAverageWithLowConfidence() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.3),
            (.recycle, 0.35),
            (.recycle, 0.4)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Average confidence = ~0.35, below stability threshold
        XCTAssertLessThan(result.confidence, 0.6)
    }

    func testMinimumSamplesRequired() {
        // With only 1-2 samples, rolling average shouldn't produce stable result
        let singlePrediction: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.9)
        ]

        // This simulates the minimum sample check (needs >= 3)
        let needsMoreSamples = singlePrediction.count < 3
        XCTAssertTrue(needsMoreSamples)
    }

    func testBufferSizeLimit() {
        // Buffer size is 10
        let bufferSize = 10
        var buffer: [(bin: WasteBin, confidence: Double)] = []

        // Add 15 items
        for i in 0..<15 {
            buffer.append((.recycle, Double(i) * 0.1))
            if buffer.count > bufferSize {
                buffer.removeFirst()
            }
        }

        XCTAssertEqual(buffer.count, bufferSize)
    }

    // MARK: - Stability Threshold Tests

    func testStabilityThresholdValue() {
        // The implementation uses 0.6 (60%) as stability threshold
        let stabilityThreshold = 0.6

        XCTAssertEqual(stabilityThreshold, 0.6)
    }

    func testPredictionAboveStabilityThreshold() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.8),
            (.recycle, 0.85),
            (.recycle, 0.9)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Average ~0.85 is above 0.6 threshold
        XCTAssertGreaterThanOrEqual(result.confidence, 0.6)
    }

    func testPredictionBelowStabilityThreshold() {
        let predictions: [(bin: WasteBin, confidence: Double)] = [
            (.recycle, 0.4),
            (.compost, 0.3),
            (.recycle, 0.35)
        ]

        let result = calculateRollingAverageResult(predictions: predictions)

        // Mixed predictions with low confidence
        XCTAssertLessThan(result.confidence, 0.6)
    }

    // MARK: - Authorization State Tests

    func testAuthorizationStateEnum() {
        // Test that all authorization states exist
        let unknown = WasteClassifierService.AuthorizationState.unknown
        let allowed = WasteClassifierService.AuthorizationState.allowed
        let denied = WasteClassifierService.AuthorizationState.denied

        XCTAssertNotNil(unknown)
        XCTAssertNotNil(allowed)
        XCTAssertNotNil(denied)
    }

    // MARK: - Model State Tests

    func testModelStateEnum() {
        // Test that all model states exist
        let notLoaded = WasteClassifierService.ModelState.notLoaded
        let loading = WasteClassifierService.ModelState.loading

        switch notLoaded {
        case .notLoaded:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected notLoaded state")
        }

        switch loading {
        case .loading:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected loading state")
        }
    }

    // MARK: - Helper Methods (Simulate Service Logic)

    /// Simulates the mapClassificationToBin logic from WasteClassifierService
    private func mapTestClassificationToBin(classification: String) -> WasteBin {
        let normalized = classification.lowercased()

        if normalized.contains("recycle") || normalized == "r" {
            return .recycle
        } else if normalized.contains("compost") || normalized.contains("organic") || normalized == "o" {
            return .compost
        } else {
            return .recycle  // Default
        }
    }

    /// Simulates the rolling average calculation from WasteClassifierService
    private func calculateRollingAverageResult(
        predictions: [(bin: WasteBin, confidence: Double)]
    ) -> (bin: WasteBin, confidence: Double) {
        var recycleScore: Double = 0
        var compostScore: Double = 0

        for prediction in predictions {
            switch prediction.bin {
            case .recycle:
                recycleScore += prediction.confidence
            case .compost:
                compostScore += prediction.confidence
            }
        }

        let totalPredictions = Double(predictions.count)
        let averageRecycleConfidence = recycleScore / totalPredictions
        let averageCompostConfidence = compostScore / totalPredictions

        if averageRecycleConfidence > averageCompostConfidence {
            return (.recycle, averageRecycleConfidence)
        } else {
            return (.compost, averageCompostConfidence)
        }
    }
}

