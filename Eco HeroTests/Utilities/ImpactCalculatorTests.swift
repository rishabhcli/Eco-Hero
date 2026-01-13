//
//  ImpactCalculatorTests.swift
//  Eco HeroTests
//
//  Tests for ImpactCalculator - environmental impact calculation logic.
//

import XCTest
@testable import Eco_Hero

final class ImpactCalculatorTests: XCTestCase {

    // MARK: - Meal Impact Tests

    func testVegetarianMealImpact() {
        let impact = ImpactCalculator.vegetarianMealImpact()

        XCTAssertEqual(impact.carbonSavedKg, 2.5, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 3000, accuracy: 0.001)
        XCTAssertEqual(impact.landSavedSqMeters, 2.8, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 0)
    }

    func testVeganMealImpact() {
        let impact = ImpactCalculator.veganMealImpact()

        XCTAssertEqual(impact.carbonSavedKg, 3.2, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 4000, accuracy: 0.001)
        XCTAssertEqual(impact.landSavedSqMeters, 3.5, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 0)
    }

    func testVeganMealHasHigherImpactThanVegetarian() {
        let vegan = ImpactCalculator.veganMealImpact()
        let vegetarian = ImpactCalculator.vegetarianMealImpact()

        XCTAssertGreaterThan(vegan.carbonSavedKg, vegetarian.carbonSavedKg)
        XCTAssertGreaterThan(vegan.waterSavedLiters, vegetarian.waterSavedLiters)
        XCTAssertGreaterThan(vegan.landSavedSqMeters, vegetarian.landSavedSqMeters)
    }

    func testLocalFoodImpact() {
        let impact = ImpactCalculator.localFoodImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0.5, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 100, accuracy: 0.001)
        XCTAssertEqual(impact.landSavedSqMeters, 0.1, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 0)
    }

    // MARK: - Transport Impact Tests

    func testBikingImpactScalesWithDistance() {
        let impact1km = ImpactCalculator.bikingImpact(distanceKm: 1)
        let impact5km = ImpactCalculator.bikingImpact(distanceKm: 5)
        let impact10km = ImpactCalculator.bikingImpact(distanceKm: 10)

        // Should scale linearly
        XCTAssertEqual(impact5km.carbonSavedKg, impact1km.carbonSavedKg * 5, accuracy: 0.001)
        XCTAssertEqual(impact10km.carbonSavedKg, impact1km.carbonSavedKg * 10, accuracy: 0.001)
        XCTAssertEqual(impact10km.carbonSavedKg, impact5km.carbonSavedKg * 2, accuracy: 0.001)
    }

    func testBikingImpactValues() {
        let impact = ImpactCalculator.bikingImpact(distanceKm: 10)

        // 0.12 kg CO2 per km * 10 km = 1.2 kg
        XCTAssertEqual(impact.carbonSavedKg, 1.2, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 0)
        XCTAssertEqual(impact.landSavedSqMeters, 0)
        XCTAssertEqual(impact.plasticSavedItems, 0)
    }

    func testBikingImpactZeroDistance() {
        let impact = ImpactCalculator.bikingImpact(distanceKm: 0)

        XCTAssertEqual(impact.carbonSavedKg, 0)
    }

    func testWalkingImpactSameAsBiking() {
        let biking = ImpactCalculator.bikingImpact(distanceKm: 5)
        let walking = ImpactCalculator.walkingImpact(distanceKm: 5)

        XCTAssertEqual(biking.carbonSavedKg, walking.carbonSavedKg, accuracy: 0.001)
    }

    func testPublicTransportImpact() {
        let impact = ImpactCalculator.publicTransportImpact(distanceKm: 10)

        // 0.08 kg CO2 per km * 10 km = 0.8 kg
        XCTAssertEqual(impact.carbonSavedKg, 0.8, accuracy: 0.001)
    }

    func testPublicTransportLessImpactThanBiking() {
        let biking = ImpactCalculator.bikingImpact(distanceKm: 10)
        let publicTransport = ImpactCalculator.publicTransportImpact(distanceKm: 10)

        // Biking saves more CO2 than public transport
        XCTAssertGreaterThan(biking.carbonSavedKg, publicTransport.carbonSavedKg)
    }

    func testCarpoolingImpact() {
        let impact = ImpactCalculator.carpoolingImpact(distanceKm: 10)

        // 0.06 kg CO2 per km * 10 km = 0.6 kg
        XCTAssertEqual(impact.carbonSavedKg, 0.6, accuracy: 0.001)
    }

    func testTransportImpactHierarchy() {
        let distance = 10.0
        let biking = ImpactCalculator.bikingImpact(distanceKm: distance)
        let publicTransport = ImpactCalculator.publicTransportImpact(distanceKm: distance)
        let carpooling = ImpactCalculator.carpoolingImpact(distanceKm: distance)

        // Biking > Public Transport > Carpooling
        XCTAssertGreaterThan(biking.carbonSavedKg, publicTransport.carbonSavedKg)
        XCTAssertGreaterThan(publicTransport.carbonSavedKg, carpooling.carbonSavedKg)
    }

    // MARK: - Plastic Impact Tests

    func testReusableBottleImpact() {
        let impact = ImpactCalculator.reusableBottleImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0.082, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 3, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 1)
    }

    func testReusableBagImpactScalesWithCount() {
        let impact1 = ImpactCalculator.reusableBagImpact(count: 1)
        let impact5 = ImpactCalculator.reusableBagImpact(count: 5)
        let impact10 = ImpactCalculator.reusableBagImpact(count: 10)

        // Carbon should scale linearly
        XCTAssertEqual(impact5.carbonSavedKg, impact1.carbonSavedKg * 5, accuracy: 0.001)
        XCTAssertEqual(impact10.carbonSavedKg, impact1.carbonSavedKg * 10, accuracy: 0.001)

        // Plastic items should scale linearly
        XCTAssertEqual(impact5.plasticSavedItems, 5)
        XCTAssertEqual(impact10.plasticSavedItems, 10)
    }

    func testReusableBagImpactValues() {
        let impact = ImpactCalculator.reusableBagImpact(count: 1)

        XCTAssertEqual(impact.carbonSavedKg, 0.04, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 1)
    }

    func testReusableBagDefaultCount() {
        let impactDefault = ImpactCalculator.reusableBagImpact()
        let impactOne = ImpactCalculator.reusableBagImpact(count: 1)

        XCTAssertEqual(impactDefault.carbonSavedKg, impactOne.carbonSavedKg)
        XCTAssertEqual(impactDefault.plasticSavedItems, impactOne.plasticSavedItems)
    }

    func testReusableCupImpact() {
        let impact = ImpactCalculator.reusableCupImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0.011, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 0.5, accuracy: 0.001)
        XCTAssertEqual(impact.plasticSavedItems, 1)
    }

    func testAvoidPlasticUtensilsImpact() {
        let impact = ImpactCalculator.avoidPlasticUtensilsImpact(count: 5)

        XCTAssertEqual(impact.carbonSavedKg, 0.1, accuracy: 0.001)  // 0.02 * 5
        XCTAssertEqual(impact.plasticSavedItems, 5)
    }

    // MARK: - Energy Impact Tests

    func testLedBulbImpactScalesWithHours() {
        let impact4h = ImpactCalculator.ledBulbImpact(hoursPerDay: 4)
        let impact8h = ImpactCalculator.ledBulbImpact(hoursPerDay: 8)

        // Should scale linearly
        XCTAssertEqual(impact8h.carbonSavedKg, impact4h.carbonSavedKg * 2, accuracy: 0.001)
    }

    func testLedBulbImpactValues() {
        let impact = ImpactCalculator.ledBulbImpact(hoursPerDay: 10)

        // 0.045 kg CO2 per hour * 10 hours = 0.45 kg
        XCTAssertEqual(impact.carbonSavedKg, 0.45, accuracy: 0.001)
    }

    func testUnplugDevicesImpact() {
        let impact = ImpactCalculator.unplugDevicesImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0.5, accuracy: 0.001)
    }

    func testColdWaterLaundryImpact() {
        let impact = ImpactCalculator.coldWaterLaundryImpact()

        XCTAssertEqual(impact.carbonSavedKg, 2.2, accuracy: 0.001)
    }

    // MARK: - Water Impact Tests

    func testShorterShowerImpact() {
        let impact = ImpactCalculator.shorterShowerImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0.3, accuracy: 0.001)
        XCTAssertEqual(impact.waterSavedLiters, 50, accuracy: 0.001)
    }

    func testFixLeakyFaucetImpact() {
        let impact = ImpactCalculator.fixLeakyFaucetImpact()

        XCTAssertEqual(impact.carbonSavedKg, 0)
        XCTAssertEqual(impact.waterSavedLiters, 90, accuracy: 0.001)
    }

    // MARK: - Other Impact Tests

    func testRecyclingImpactScalesWithWeight() {
        let impact1kg = ImpactCalculator.recyclingImpact(weightKg: 1)
        let impact5kg = ImpactCalculator.recyclingImpact(weightKg: 5)

        XCTAssertEqual(impact5kg.carbonSavedKg, impact1kg.carbonSavedKg * 5, accuracy: 0.001)
    }

    func testRecyclingImpactValues() {
        let impact = ImpactCalculator.recyclingImpact(weightKg: 2)

        // 0.7 kg CO2 per kg * 2 kg = 1.4 kg
        XCTAssertEqual(impact.carbonSavedKg, 1.4, accuracy: 0.001)
    }

    func testCompostingImpactScalesWithWeight() {
        let impact1kg = ImpactCalculator.compostingImpact(weightKg: 1)
        let impact5kg = ImpactCalculator.compostingImpact(weightKg: 5)

        XCTAssertEqual(impact5kg.carbonSavedKg, impact1kg.carbonSavedKg * 5, accuracy: 0.001)
        XCTAssertEqual(impact5kg.landSavedSqMeters, impact1kg.landSavedSqMeters * 5, accuracy: 0.001)
    }

    func testCompostingImpactValues() {
        let impact = ImpactCalculator.compostingImpact(weightKg: 2)

        // 0.5 kg CO2 per kg * 2 kg = 1.0 kg
        XCTAssertEqual(impact.carbonSavedKg, 1.0, accuracy: 0.001)
        // 0.1 m² per kg * 2 kg = 0.2 m²
        XCTAssertEqual(impact.landSavedSqMeters, 0.2, accuracy: 0.001)
    }

    func testPlantTreeImpact() {
        let impact = ImpactCalculator.plantTreeImpact()

        XCTAssertEqual(impact.carbonSavedKg, 21.0, accuracy: 0.001)
    }

    // MARK: - Equivalents Tests

    func testGetEquivalentsForCarbon() {
        // 21 kg CO2 = 1 tree equivalent
        let impact = ActivityImpact(
            carbonSavedKg: 21.0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.treesPlanted, 1.0, accuracy: 0.001)
    }

    func testGetEquivalentsForWater() {
        // 1 liter = 2 bottles (0.5L each)
        let impact = ActivityImpact(
            carbonSavedKg: 0,
            waterSavedLiters: 10,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.bottlesOfWater, 20.0, accuracy: 0.001)
    }

    func testGetEquivalentsForPlastic() {
        let impact = ActivityImpact(
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 5
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.plasticBags, 5.0, accuracy: 0.001)
    }

    func testGetEquivalentsCarMilesSaved() {
        // 0.12 kg CO2 per mile
        let impact = ActivityImpact(
            carbonSavedKg: 1.2,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.carMilesSaved, 10.0, accuracy: 0.001)
    }

    func testGetEquivalentsComplexImpact() {
        let impact = ActivityImpact(
            carbonSavedKg: 42.0,  // 2 trees
            waterSavedLiters: 5.0,  // 10 bottles
            landSavedSqMeters: 1.0,
            plasticSavedItems: 3  // 3 bags
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.treesPlanted, 2.0, accuracy: 0.001)
        XCTAssertEqual(equivalents.bottlesOfWater, 10.0, accuracy: 0.001)
        XCTAssertEqual(equivalents.plasticBags, 3.0, accuracy: 0.001)
    }

    // MARK: - Edge Cases

    func testZeroDistanceTransport() {
        let biking = ImpactCalculator.bikingImpact(distanceKm: 0)
        let walking = ImpactCalculator.walkingImpact(distanceKm: 0)
        let publicTransport = ImpactCalculator.publicTransportImpact(distanceKm: 0)
        let carpooling = ImpactCalculator.carpoolingImpact(distanceKm: 0)

        XCTAssertEqual(biking.carbonSavedKg, 0)
        XCTAssertEqual(walking.carbonSavedKg, 0)
        XCTAssertEqual(publicTransport.carbonSavedKg, 0)
        XCTAssertEqual(carpooling.carbonSavedKg, 0)
    }

    func testZeroWeightRecycling() {
        let recycling = ImpactCalculator.recyclingImpact(weightKg: 0)
        let composting = ImpactCalculator.compostingImpact(weightKg: 0)

        XCTAssertEqual(recycling.carbonSavedKg, 0)
        XCTAssertEqual(composting.carbonSavedKg, 0)
        XCTAssertEqual(composting.landSavedSqMeters, 0)
    }

    func testZeroHoursLedBulb() {
        let impact = ImpactCalculator.ledBulbImpact(hoursPerDay: 0)

        XCTAssertEqual(impact.carbonSavedKg, 0)
    }

    func testLargeDistanceValues() {
        // Test with large but realistic values
        let impact = ImpactCalculator.bikingImpact(distanceKm: 1000)

        XCTAssertEqual(impact.carbonSavedKg, 120.0, accuracy: 0.001)
    }

    func testEquivalentsWithZeroImpact() {
        let impact = ActivityImpact(
            carbonSavedKg: 0,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )

        let equivalents = ImpactCalculator.getEquivalents(for: impact)

        XCTAssertEqual(equivalents.treesPlanted, 0)
        XCTAssertEqual(equivalents.bottlesOfWater, 0)
        XCTAssertEqual(equivalents.plasticBags, 0)
        XCTAssertEqual(equivalents.carMilesSaved, 0)
    }
}
