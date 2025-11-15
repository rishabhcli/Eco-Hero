//
//  ImpactCalculator.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation

/// Calculates environmental impact metrics based on eco-friendly activities
/// All values are based on scientific research and environmental studies
struct ImpactCalculator {

    // MARK: - Meal Impact Calculations

    /// Impact of eating vegetarian vs meat-based meal
    static func vegetarianMealImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 2.5,        // 2.5 kg CO₂ saved per vegetarian meal
            waterSavedLiters: 3000,     // 3000 liters water saved
            landSavedSqMeters: 2.8,     // 2.8 m² land saved
            plasticSavedItems: 0
        )
    }

    /// Impact of eating vegan vs meat-based meal
    static func veganMealImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 3.2,        // 3.2 kg CO₂ saved per vegan meal
            waterSavedLiters: 4000,     // 4000 liters water saved
            landSavedSqMeters: 3.5,     // 3.5 m² land saved
            plasticSavedItems: 0
        )
    }

    /// Impact of eating locally sourced food
    static func localFoodImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.5,
            waterSavedLiters: 100,
            landSavedSqMeters: 0.1,
            plasticSavedItems: 0
        )
    }

    // MARK: - Transport Impact Calculations

    /// Impact of biking instead of driving (per km)
    static func bikingImpact(distanceKm: Double) -> ActivityImpact {
        let carbonPerKm = 0.12  // 120g CO₂ saved per km
        return ActivityImpact(
            carbonSavedKg: carbonPerKm * distanceKm,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of walking instead of driving (per km)
    static func walkingImpact(distanceKm: Double) -> ActivityImpact {
        let carbonPerKm = 0.12  // Same as biking
        return ActivityImpact(
            carbonSavedKg: carbonPerKm * distanceKm,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of using public transport instead of driving (per km)
    static func publicTransportImpact(distanceKm: Double) -> ActivityImpact {
        let carbonPerKm = 0.08  // 80g CO₂ saved per km
        return ActivityImpact(
            carbonSavedKg: carbonPerKm * distanceKm,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of carpooling (per km, assuming 2+ people)
    static func carpoolingImpact(distanceKm: Double) -> ActivityImpact {
        let carbonPerKm = 0.06  // 60g CO₂ saved per km
        return ActivityImpact(
            carbonSavedKg: carbonPerKm * distanceKm,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    // MARK: - Plastic Impact Calculations

    /// Impact of using reusable water bottle instead of plastic
    static func reusableBottleImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.082,      // 82g CO₂ per plastic bottle avoided
            waterSavedLiters: 3,        // 3 liters water saved
            landSavedSqMeters: 0,
            plasticSavedItems: 1
        )
    }

    /// Impact of using reusable shopping bag
    static func reusableBagImpact(count: Int = 1) -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.04 * Double(count),   // 40g CO₂ per bag
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: count
        )
    }

    /// Impact of using reusable coffee cup
    static func reusableCupImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.011,      // 11g CO₂ per disposable cup avoided
            waterSavedLiters: 0.5,
            landSavedSqMeters: 0,
            plasticSavedItems: 1
        )
    }

    /// Impact of avoiding plastic utensils
    static func avoidPlasticUtensilsImpact(count: Int = 1) -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.02 * Double(count),
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: count
        )
    }

    // MARK: - Energy Impact Calculations

    /// Impact of using LED bulb instead of incandescent (per day)
    static func ledBulbImpact(hoursPerDay: Double) -> ActivityImpact {
        let carbonPerHour = 0.045  // 45g CO₂ saved per hour
        return ActivityImpact(
            carbonSavedKg: carbonPerHour * hoursPerDay,
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of unplugging devices (per day)
    static func unplugDevicesImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.5,        // Average phantom load savings
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of using cold water for laundry
    static func coldWaterLaundryImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 2.2,        // 2.2 kg CO₂ per load
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    // MARK: - Water Impact Calculations

    /// Impact of shorter shower (5 minutes saved)
    static func shorterShowerImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.3,
            waterSavedLiters: 50,       // ~10 liters per minute saved
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of fixing a leaky faucet (per day)
    static func fixLeakyFaucetImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0,
            waterSavedLiters: 90,       // Average leak waste per day
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    // MARK: - Other Impact Calculations

    /// Impact of recycling (per kg of material)
    static func recyclingImpact(weightKg: Double) -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.7 * weightKg,  // ~700g CO₂ saved per kg recycled
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    /// Impact of composting (per kg of organic waste)
    static func compostingImpact(weightKg: Double) -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 0.5 * weightKg,  // ~500g CO₂ saved per kg composted
            waterSavedLiters: 0,
            landSavedSqMeters: 0.1 * weightKg,
            plasticSavedItems: 0
        )
    }

    /// Impact of planting a tree
    static func plantTreeImpact() -> ActivityImpact {
        return ActivityImpact(
            carbonSavedKg: 21.0,       // Annual CO₂ absorption by one tree
            waterSavedLiters: 0,
            landSavedSqMeters: 0,
            plasticSavedItems: 0
        )
    }

    // MARK: - Helper Methods

    /// Get equivalent representations for impact metrics
    static func getEquivalents(for impact: ActivityImpact) -> ImpactEquivalents {
        ImpactEquivalents(
            treesPlanted: impact.carbonSavedKg / 21.0,
            bottlesOfWater: impact.waterSavedLiters / 0.5,
            plasticBags: Double(impact.plasticSavedItems),
            carMilesSaved: impact.carbonSavedKg / 0.12
        )
    }
}

// MARK: - Supporting Types

struct ActivityImpact {
    let carbonSavedKg: Double
    let waterSavedLiters: Double
    let landSavedSqMeters: Double
    let plasticSavedItems: Int
}

struct ImpactEquivalents {
    let treesPlanted: Double           // Equivalent trees' annual CO₂ absorption
    let bottlesOfWater: Double         // 500ml bottles equivalent
    let plasticBags: Double            // Plastic bags avoided
    let carMilesSaved: Double          // Miles of car travel avoided
}
