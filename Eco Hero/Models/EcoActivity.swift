//
//  EcoActivity.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftData

@Model
final class EcoActivity {
    var id: UUID
    var timestamp: Date
    var category: ActivityCategory
    var activityDescription: String
    var notes: String?

    // Impact metrics
    var carbonSavedKg: Double
    var waterSavedLiters: Double
    var landSavedSqMeters: Double
    var plasticSavedItems: Int

    // Optional data
    var distance: Double? // For transport activities
    var duration: Int? // Duration in minutes
    var photoPath: String? // Path to local photo

    // User reference (Firebase UID)
    var userID: String?

    // Sync status
    var isSynced: Bool
    var firebaseID: String?

    init(
        category: ActivityCategory,
        description: String,
        notes: String? = nil,
        carbonSavedKg: Double = 0,
        waterSavedLiters: Double = 0,
        landSavedSqMeters: Double = 0,
        plasticSavedItems: Int = 0,
        distance: Double? = nil,
        duration: Int? = nil,
        photoPath: String? = nil,
        userID: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.category = category
        self.activityDescription = description
        self.notes = notes
        self.carbonSavedKg = carbonSavedKg
        self.waterSavedLiters = waterSavedLiters
        self.landSavedSqMeters = landSavedSqMeters
        self.plasticSavedItems = plasticSavedItems
        self.distance = distance
        self.duration = duration
        self.photoPath = photoPath
        self.userID = userID
        self.isSynced = false
        self.firebaseID = nil
    }
}
