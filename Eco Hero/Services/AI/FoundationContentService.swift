//
//  FoundationContentService.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable
struct iOS26ActivityIdea {
    @Guide(description: "A punchy, action-oriented label (2-5 words) that feels fresh and specific. Examples: 'Morning bike commute', 'Zero-waste grocery run', 'Plant-based dinner party'. Avoid generic phrases.")
    var actionTitle: String

    @Guide(description: "A vivid one-sentence description that paints a picture of the eco-action. Be specific about the context and make it feel achievable today.")
    var activityDescription: String

    @Guide(description: "An inspiring fact or motivating note that connects the action to real environmental impact. Include a specific stat when possible (e.g., 'saves 2kg CO₂' or 'conserves 50L water').")
    var motivation: String
}

@available(iOS 26, *)
@Generable
struct iOS26ChallengeBlueprint {
    @Guide(description: "A catchy, memorable mission title (2-5 words) that sounds exciting and game-like. Examples: 'Plastic Detox Sprint', 'Green Commuter Quest', 'Veggie Victory Week'.")
    var title: String

    @Guide(description: "An engaging one-sentence description that makes the challenge feel fun and achievable. Include the specific goal and timeframe.")
    var summary: String

    @Guide(description: "Challenge duration: 'daily' for single-day focus, 'weekly' for 7-day streaks, or 'milestone' for cumulative achievements.")
    var cadence: String

    @Guide(description: "Primary eco category: Meals (food choices), Transport (commuting), Plastic (waste reduction), Energy (power saving), Water (conservation), or Lifestyle (general eco-habits).")
    var category: String

    @Guide(description: "An SF Symbol name that visually represents the challenge theme. Examples: 'leaf.fill', 'bicycle', 'drop.fill', 'bolt.fill', 'bag.fill', 'tram.fill'.")
    var symbolName: String

    @Guide(description: "Number of actions required to complete the challenge (1-14). Make it ambitious but achievable.", .range(1...14))
    var targetCount: Int

    @Guide(description: "XP reward reflecting difficulty and duration. Daily: 50-100, Weekly: 150-250, Milestone: 100-200.", .range(10...250))
    var rewardXP: Int
}

struct ActivityIdea {
    var actionTitle: String
    var activityDescription: String
    var motivation: String
}

struct ChallengeBlueprint {
    var title: String
    var summary: String
    var cadence: String
    var category: String
    var symbolName: String
    var targetCount: Int
    var rewardXP: Int
}

@Observable
final class FoundationContentService {
    init() {}

    func suggestActivity(for category: ActivityCategory) async throws -> ActivityIdea {
        if #available(iOS 26, *) {
            let session = LanguageModelSession(
                instructions: """
                You are the creative eco-coach inside Eco Hero, a fun sustainability app. Your personality is:
                - Enthusiastic but not preachy
                - Specific and actionable (not vague)
                - Focused on small wins that feel achievable TODAY
                - Aware of real environmental impact stats

                When suggesting activities:
                - Make them feel fresh and creative, not obvious
                - Reference seasons, time of day, or social context when relevant
                - Include specific impact numbers when motivating users
                - Vary your suggestions - don't always suggest the same things
                """
            )

            let categoryContext = categoryContextDescription(for: category)
            let prompt = """
            Create an inspiring \(category.rawValue) activity idea for someone looking to make a positive environmental impact today.

            Context: \(categoryContext)

            Make it creative, specific, and motivating!
            """
            let ios26Idea = try await session.respond(
                to: prompt,
                generating: iOS26ActivityIdea.self
            ).content

            // Convert to regular ActivityIdea
            return ActivityIdea(
                actionTitle: ios26Idea.actionTitle,
                activityDescription: ios26Idea.activityDescription,
                motivation: ios26Idea.motivation
            )
        } else {
            throw NSError(domain: "FoundationContent", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available"])
        }
    }

    func generateChallenge() async throws -> ChallengeBlueprint {
        if #available(iOS 26, *) {
            let session = LanguageModelSession(
                instructions: """
                You are the mission designer for Eco Hero, a gamified sustainability app. Your role is to create exciting eco-challenges that feel like quests in a game.

                Design principles:
                - Titles should be catchy and memorable (think video game quest names)
                - Challenges should feel achievable but meaningful
                - Vary difficulty: some easy daily wins, some ambitious weekly goals
                - Include creative themes: streaks, detox challenges, exploration quests
                - Balance across categories: food, transport, plastic, energy, water, lifestyle

                SF Symbols to consider: leaf.fill, bicycle, tram.fill, drop.fill, bolt.fill, bag.fill, flame.fill, star.fill, trophy.fill, target
                """
            )

            let themes = ["eco streak", "sustainability sprint", "green challenge", "planet-friendly quest", "environmental adventure"]
            let randomTheme = themes.randomElement() ?? "eco challenge"

            let prompt = """
            Design an exciting new Eco Hero mission! Think of it as a \(randomTheme) that will engage users and make sustainability fun.

            Mix up the cadence (daily for quick wins, weekly for sustained effort, milestone for big achievements).
            Make the title memorable and the goal clear!
            """
            let ios26Blueprint = try await session.respond(
                to: prompt,
                generating: iOS26ChallengeBlueprint.self
            ).content

            // Convert to regular ChallengeBlueprint
            return ChallengeBlueprint(
                title: ios26Blueprint.title,
                summary: ios26Blueprint.summary,
                cadence: ios26Blueprint.cadence,
                category: ios26Blueprint.category,
                symbolName: ios26Blueprint.symbolName,
                targetCount: ios26Blueprint.targetCount,
                rewardXP: ios26Blueprint.rewardXP
            )
        } else {
            throw NSError(domain: "FoundationContent", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available"])
        }
    }

    private func categoryContextDescription(for category: ActivityCategory) -> String {
        switch category {
        case .meals:
            return "Food choices - plant-based meals, local produce, reducing food waste, sustainable cooking"
        case .transport:
            return "Getting around - biking, walking, public transit, carpooling, reducing car trips"
        case .plastic:
            return "Reducing plastic - reusables, avoiding single-use items, package-free shopping"
        case .energy:
            return "Saving power - LED bulbs, unplugging devices, energy-efficient habits"
        case .water:
            return "Water conservation - shorter showers, fixing leaks, efficient appliances"
        case .lifestyle:
            return "General eco-habits - recycling, composting, mindful consumption, nature connection"
        case .other:
            return "Any eco-friendly action that helps the planet"
        }
    }
}

#else

struct ActivityIdea {
    var actionTitle: String
    var activityDescription: String
    var motivation: String
}

struct ChallengeBlueprint {
    var title: String
    var summary: String
    var cadence: String
    var category: String
    var symbolName: String
    var targetCount: Int
    var rewardXP: Int
}

@Observable
final class FoundationContentService {
    private let fallbackIdeas: [ActivityCategory: ActivityIdea] = [
        .meals: ActivityIdea(
            actionTitle: "Prep Veggie Bowl",
            activityDescription: "Make a plant-heavy lunch with local produce.",
            motivation: "Plant-forward meals cut CO₂ and save thousands of liters of water."
        ),
        .transport: ActivityIdea(
            actionTitle: "Bike Errand",
            activityDescription: "Swap one short errand with a bike ride.",
            motivation: "Skipping a 5 km car ride saves ~600g CO₂."
        ),
        .plastic: ActivityIdea(
            actionTitle: "Refill Kit",
            activityDescription: "Take jars or totes to a refill shop.",
            motivation: "Every reuse avoids single-use plastics heading to landfills."
        ),
        .energy: ActivityIdea(
            actionTitle: "Lights-Off Sweep",
            activityDescription: "Unplug idle chargers and switch to LEDs.",
            motivation: "LEDs use 75% less power than incandescents."
        ),
        .water: ActivityIdea(
            actionTitle: "5-Minute Showers",
            activityDescription: "Set a timer and keep showers short.",
            motivation: "Quick showers save more than 10 liters each session."
        ),
        .lifestyle: ActivityIdea(
            actionTitle: "Sort & Compost",
            activityDescription: "Organize bins for recycle, compost, and trash.",
            motivation: "Separation keeps organic matter out of landfills."
        )
    ]

    private let fallbackChallenges: [ChallengeBlueprint] = [
        ChallengeBlueprint(
            title: "Transit Streak",
            summary: "Use public transport three times this week.",
            cadence: "weekly",
            category: "Transport",
            symbolName: "tram.fill",
            targetCount: 3,
            rewardXP: 120
        ),
        ChallengeBlueprint(
            title: "Hydro Hero",
            summary: "Log five water-saving actions in seven days.",
            cadence: "weekly",
            category: "Water",
            symbolName: "drop.circle.fill",
            targetCount: 5,
            rewardXP: 150
        ),
        ChallengeBlueprint(
            title: "Zero Plastic Day",
            summary: "Avoid single-use plastics for one full day.",
            cadence: "daily",
            category: "Plastic",
            symbolName: "bag.fill",
            targetCount: 1,
            rewardXP: 80
        )
    ]

    private var challengeIndex = 0

    init() {}

    func suggestActivity(for category: ActivityCategory) async throws -> ActivityIdea {
        if let idea = fallbackIdeas[category] {
            return idea
        }
        return ActivityIdea(
            actionTitle: "Eco Action",
            activityDescription: "Pick any small sustainable habit.",
            motivation: "Stacking small wins keeps your eco momentum going."
        )
    }

    func generateChallenge() async throws -> ChallengeBlueprint {
        guard !fallbackChallenges.isEmpty else {
            return ChallengeBlueprint(
                title: "Daily Habit",
                summary: "Complete any eco-friendly action today.",
                cadence: "daily",
                category: "Lifestyle",
                symbolName: "leaf.fill",
                targetCount: 1,
                rewardXP: 50
            )
        }

        let challenge = fallbackChallenges[challengeIndex % fallbackChallenges.count]
        challengeIndex += 1
        return challenge
    }
}

#endif
