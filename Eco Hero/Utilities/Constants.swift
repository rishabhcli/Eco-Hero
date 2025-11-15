//
//  Constants.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftUI

struct AppConstants {

    // MARK: - Colors

    struct Colors {
        static let primaryGreen = Color("PrimaryGreen")
        static let secondaryGreen = Color("SecondaryGreen")
        static let accentBlue = Color("AccentBlue")
        static let backgroundColor = Color("Background")
        static let cardBackground = Color("CardBackground")

        // Category colors
        static let mealColor = Color.green
        static let transportColor = Color.blue
        static let plasticColor = Color.orange
        static let energyColor = Color.yellow
        static let waterColor = Color.cyan
        static let lifestyleColor = Color.mint
    }

    // MARK: - Level System

    struct Levels {
        static let xpPerLevel = 100.0
        static let maxLevel = 50

        static func levelTitle(for level: Int) -> String {
            switch level {
            case 1: return "Eco Beginner"
            case 2...4: return "Green Starter"
            case 5...9: return "Earth Friend"
            case 10...14: return "Eco Warrior"
            case 15...19: return "Planet Protector"
            case 20...29: return "Sustainability Champion"
            case 30...39: return "Eco Hero"
            case 40...49: return "Environmental Legend"
            case 50...: return "Earth Guardian"
            default: return "Eco Beginner"
            }
        }
    }

    // MARK: - Notifications

    struct Notifications {
        static let dailyReminderHour = 20  // 8 PM
        static let dailyReminderMinute = 0
        static let streakReminderIdentifier = "streak-reminder"
        static let challengeReminderIdentifier = "challenge-reminder"
    }

    // MARK: - Educational Content

    struct EducationalFacts {
        static let facts = [
            "Did you know? Eating one vegetarian meal can save up to 3,000 liters of water!",
            "A single tree can absorb about 21 kg of CO₂ per year.",
            "Biking just 5 km instead of driving saves about 600g of CO₂.",
            "Plastic bags can take up to 1,000 years to decompose.",
            "Using a reusable water bottle for one year can save over 160 plastic bottles from landfills.",
            "Turning off lights when leaving a room can save up to 10% on your electricity bill.",
            "Composting reduces methane emissions from landfills.",
            "One beef burger requires 2,500 liters of water to produce.",
            "Public transportation can reduce your carbon footprint by 45%.",
            "LED bulbs use 75% less energy than incandescent bulbs.",
            "Fixing a leaky faucet can save 90 liters of water per day.",
            "Recycling one aluminum can saves enough energy to run a TV for 3 hours.",
            "The fashion industry is the 2nd largest polluter of water globally.",
            "A cold water wash cycle can cut energy use by 90%.",
            "Carpooling with one other person can cut your carbon emissions in half."
        ]

        static func randomFact() -> String {
            facts.randomElement() ?? facts[0]
        }
    }

    // MARK: - Tips

    struct EcoTips {
        static let tips = [
            Tip(
                title: "Start with Meatless Mondays",
                description: "Going vegetarian just one day a week can make a huge impact on your carbon footprint.",
                category: .meals
            ),
            Tip(
                title: "Carry a Reusable Water Bottle",
                description: "Invest in a good reusable bottle and avoid single-use plastics.",
                category: .plastic
            ),
            Tip(
                title: "Bike for Short Trips",
                description: "For trips under 3 km, consider biking or walking instead of driving.",
                category: .transport
            ),
            Tip(
                title: "Switch to LED Bulbs",
                description: "LED bulbs use 75% less energy and last 25 times longer than incandescent bulbs.",
                category: .energy
            ),
            Tip(
                title: "Take Shorter Showers",
                description: "Reducing shower time by just 2 minutes can save up to 20 liters of water.",
                category: .water
            ),
            Tip(
                title: "Bring Your Own Bags",
                description: "Keep reusable bags in your car or backpack for spontaneous shopping trips.",
                category: .plastic
            ),
            Tip(
                title: "Unplug Devices",
                description: "Electronics consume energy even when turned off. Unplug them or use a power strip.",
                category: .energy
            ),
            Tip(
                title: "Start Composting",
                description: "Turn food scraps into nutrient-rich soil and reduce landfill waste.",
                category: .lifestyle
            ),
            Tip(
                title: "Buy Local Produce",
                description: "Locally grown food requires less transportation, reducing carbon emissions.",
                category: .meals
            ),
            Tip(
                title: "Use Public Transportation",
                description: "Taking the bus or train just twice a week can reduce carbon emissions significantly.",
                category: .transport
            )
        ]

        static func tip(for category: ActivityCategory) -> Tip? {
            tips.first { $0.category == category }
        }

        static func randomTip() -> Tip {
            tips.randomElement() ?? tips[0]
        }
    }

    struct Tip {
        let title: String
        let description: String
        let category: ActivityCategory
    }
}
