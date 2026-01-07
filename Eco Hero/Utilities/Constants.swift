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

        // Refreshed palette
        static let evergreen = Color(hex: "0E5E4B")
        static let forest = Color(hex: "012D26")
        static let meadow = Color(hex: "6DD3A6")
        static let ocean = Color(hex: "1B8EF2")
        static let sunrise = Color(hex: "FFB347")
        static let dusk = Color(hex: "433878")
        static let slate = Color(hex: "152E2E")
        static let sand = Color(hex: "F5F2EA")

        static let cardSurface = Color(.secondarySystemGroupedBackground)
        static let elevatedSurface = Color(.systemBackground)

        // Category colors
        static let mealColor = Color.green
        static let transportColor = Color.blue
        static let plasticColor = Color.orange
        static let energyColor = Color.yellow
        static let waterColor = Color.cyan
        static let lifestyleColor = Color.mint
    }

    struct Layout {
        static let cardCornerRadius: CGFloat = 22
        static let compactCornerRadius: CGFloat = 14
        static let gridSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }

    struct Gradients {
        // Primary hero gradient for main headers
        static let hero = LinearGradient(
            colors: [Colors.evergreen, Colors.forest],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Accent gradient for interactive elements
        static let accent = LinearGradient(
            colors: [Colors.ocean, Colors.dusk],
            startPoint: .top,
            endPoint: .bottomTrailing
        )

        // Subtle mellow gradient for card backgrounds
        static let mellow = LinearGradient(
            colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Success gradient for positive feedback
        static let success = LinearGradient(
            colors: [Color.green, Color.green.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Warning gradient for streaks and alerts
        static let warning = LinearGradient(
            colors: [Color.orange, Color.yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Glass tint gradient for liquid glass effects
        static let glassTint = LinearGradient(
            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Category-specific gradients
        static func categoryGradient(for category: ActivityCategory) -> LinearGradient {
            let baseColor = category.color
            return LinearGradient(
                colors: [baseColor, baseColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Glass tint for specific category
        static func glassTint(for category: ActivityCategory) -> Color {
            category.color.opacity(0.3)
        }

        // Shimmer gradient for progress bars
        static let shimmer = LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.5),
                Color.white.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Celebration gradient for level up
        static let celebration = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF6B6B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Achievement gradient
        static let achievement = LinearGradient(
            colors: [Color(hex: "A855F7"), Color(hex: "EC4899")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Impact card gradients
        static let carbonGradient = [Color(hex: "16A34A"), Color(hex: "22C55E")]
        static let waterGradient = [Color(hex: "0EA5E9"), Color(hex: "38BDF8")]
        static let landGradient = [Color(hex: "84CC16"), Color(hex: "A3E635")]
        static let plasticGradient = [Color(hex: "F97316"), Color(hex: "FB923C")]

        // Streak flame gradient
        static let flameGradient = [Color(hex: "F97316"), Color(hex: "FBBF24"), Color(hex: "FCD34D")]
    }

    // MARK: - Animation Timing

    struct Animation {
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
        static let quickDuration: Double = 0.2
        static let standardDuration: Double = 0.35
        static let longDuration: Double = 0.5

        // Particle and effect timing
        static let particleLifetime: Double = 2.0
        static let particleEmissionRate: Double = 0.15
        static let shimmerDuration: Double = 1.5
        static let celebrationDuration: Double = 3.0
        static let confettiBurstDuration: Double = 1.5

        // Micro-interaction timing
        static let cascadeDelay: Double = 0.05
        static let microInteractionDuration: Double = 0.15
        static let parallaxMultiplier: CGFloat = 0.3

        static var spring: SwiftUI.Animation {
            .spring(response: springResponse, dampingFraction: springDamping)
        }

        static var bouncy: SwiftUI.Animation {
            .spring(response: 0.35, dampingFraction: 0.6)
        }

        static var gentle: SwiftUI.Animation {
            .easeInOut(duration: standardDuration)
        }

        static var snappy: SwiftUI.Animation {
            .spring(response: 0.25, dampingFraction: 0.7)
        }

        static var elastic: SwiftUI.Animation {
            .spring(response: 0.5, dampingFraction: 0.5)
        }
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
