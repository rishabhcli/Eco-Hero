//
//  ActivityCategory.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation

enum ActivityCategory: String, Codable, CaseIterable {
    case meals = "Meals"
    case transport = "Transport"
    case plastic = "Plastic"
    case energy = "Energy"
    case water = "Water"
    case lifestyle = "Lifestyle"
    case other = "Other"

    var icon: String {
        switch self {
        case .meals: return "fork.knife"
        case .transport: return "bicycle"
        case .plastic: return "bag"
        case .energy: return "bolt.fill"
        case .water: return "drop.fill"
        case .lifestyle: return "leaf.fill"
        case .other: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .meals: return "green"
        case .transport: return "blue"
        case .plastic: return "orange"
        case .energy: return "yellow"
        case .water: return "cyan"
        case .lifestyle: return "mint"
        case .other: return "purple"
        }
    }
}
