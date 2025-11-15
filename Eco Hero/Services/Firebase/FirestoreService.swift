//
//  FirestoreService.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import FirebaseFirestore
import SwiftData

/// Manages cloud data synchronization with Firebase Firestore
@Observable
class FirestoreService {
    private let db = Firestore.firestore()
    var isSyncing: Bool = false
    var lastSyncError: Error?

    // MARK: - Activity Sync

    /// Syncs a single activity to Firestore
    func syncActivity(_ activity: EcoActivity, userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let activityData: [String: Any] = [
            "timestamp": Timestamp(date: activity.timestamp),
            "category": activity.category.rawValue,
            "description": activity.activityDescription,
            "carbonSavedKg": activity.carbonSavedKg,
            "waterSavedLiters": activity.waterSavedLiters,
            "landSavedSqMeters": activity.landSavedSqMeters,
            "plasticSavedItems": activity.plasticSavedItems,
            "distance": activity.distance as Any,
            "duration": activity.duration as Any,
            "notes": activity.notes as Any,
            "photoPath": activity.photoPath as Any,
            "userID": userId,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            if let firebaseID = activity.firebaseID {
                // Update existing document
                try await db.collection("users")
                    .document(userId)
                    .collection("activities")
                    .document(firebaseID)
                    .setData(activityData, merge: true)
            } else {
                // Create new document
                let docRef = try await db.collection("users")
                    .document(userId)
                    .collection("activities")
                    .addDocument(data: activityData)

                // Update local model with Firebase ID
                activity.firebaseID = docRef.documentID
            }

            activity.isSynced = true
            lastSyncError = nil
        } catch {
            lastSyncError = error
            activity.isSynced = false
            throw FirestoreError.syncFailed(error.localizedDescription)
        }
    }

    /// Syncs multiple activities to Firestore (batch operation)
    func syncActivities(_ activities: [EcoActivity], userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let batch = db.batch()

        for activity in activities where !activity.isSynced {
            let activityData: [String: Any] = [
                "timestamp": Timestamp(date: activity.timestamp),
                "category": activity.category.rawValue,
                "description": activity.activityDescription,
                "carbonSavedKg": activity.carbonSavedKg,
                "waterSavedLiters": activity.waterSavedLiters,
                "landSavedSqMeters": activity.landSavedSqMeters,
                "plasticSavedItems": activity.plasticSavedItems,
                "distance": activity.distance as Any,
                "notes": activity.notes as Any,
                "userID": userId,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            if let firebaseID = activity.firebaseID {
                let docRef = db.collection("users")
                    .document(userId)
                    .collection("activities")
                    .document(firebaseID)
                batch.setData(activityData, forDocument: docRef, merge: true)
            } else {
                let docRef = db.collection("users")
                    .document(userId)
                    .collection("activities")
                    .document()
                batch.setData(activityData, forDocument: docRef)
                activity.firebaseID = docRef.documentID
            }
        }

        do {
            try await batch.commit()
            activities.forEach { $0.isSynced = true }
            lastSyncError = nil
        } catch {
            lastSyncError = error
            throw FirestoreError.syncFailed(error.localizedDescription)
        }
    }

    /// Fetches all activities for a user from Firestore
    func fetchActivities(userId: String) async throws -> [[String: Any]] {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("activities")
                .order(by: "timestamp", descending: true)
                .getDocuments()

            lastSyncError = nil
            return snapshot.documents.map { doc in
                var data = doc.data()
                data["id"] = doc.documentID
                return data
            }
        } catch {
            lastSyncError = error
            throw FirestoreError.fetchFailed(error.localizedDescription)
        }
    }

    /// Listens for real-time activity updates
    func listenToActivities(userId: String, onChange: @escaping ([DocumentChange]) -> Void) -> ListenerRegistration {
        return db.collection("users")
            .document(userId)
            .collection("activities")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.lastSyncError = error
                    return
                }

                guard let snapshot = snapshot else { return }
                onChange(snapshot.documentChanges)
            }
    }

    // MARK: - User Profile Sync

    /// Syncs user profile to Firestore
    func syncProfile(_ profile: UserProfile) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let profileData: [String: Any] = [
            "email": profile.email,
            "displayName": profile.displayName,
            "joinDate": Timestamp(date: profile.joinDate),
            "totalCarbonSavedKg": profile.totalCarbonSavedKg,
            "totalWaterSavedLiters": profile.totalWaterSavedLiters,
            "totalLandSavedSqMeters": profile.totalLandSavedSqMeters,
            "totalPlasticSavedItems": profile.totalPlasticSavedItems,
            "currentLevel": profile.currentLevel,
            "experiencePoints": profile.experiencePoints,
            "streak": profile.streak,
            "longestStreak": profile.longestStreak,
            "lastActivityDate": profile.lastActivityDate.map { Timestamp(date: $0) } as Any,
            "soundEnabled": profile.soundEnabled,
            "hapticsEnabled": profile.hapticsEnabled,
            "notificationsEnabled": profile.notificationsEnabled,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users")
                .document(profile.firebaseUID)
                .setData(profileData, merge: true)

            lastSyncError = nil
        } catch {
            lastSyncError = error
            throw FirestoreError.syncFailed(error.localizedDescription)
        }
    }

    /// Fetches user profile from Firestore
    func fetchProfile(userId: String) async throws -> [String: Any]? {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let document = try await db.collection("users")
                .document(userId)
                .getDocument()

            lastSyncError = nil
            return document.data()
        } catch {
            lastSyncError = error
            throw FirestoreError.fetchFailed(error.localizedDescription)
        }
    }

    /// Listens for real-time profile updates
    func listenToProfile(userId: String, onChange: @escaping ([String: Any]?) -> Void) -> ListenerRegistration {
        return db.collection("users")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.lastSyncError = error
                    return
                }

                onChange(snapshot?.data())
            }
    }

    // MARK: - Challenge Sync

    /// Syncs a challenge to Firestore
    func syncChallenge(_ challenge: Challenge, userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let challengeData: [String: Any] = [
            "challengeID": challenge.id.uuidString,
            "title": challenge.title,
            "challengeDescription": challenge.challengeDescription,
            "type": challenge.type.rawValue,
            "category": challenge.category?.rawValue as Any,
            "targetCount": challenge.targetCount,
            "currentProgress": challenge.currentProgress,
            "status": challenge.status.rawValue,
            "startDate": challenge.startDate.map { Timestamp(date: $0) } as Any,
            "endDate": challenge.endDate.map { Timestamp(date: $0) } as Any,
            "rewardXP": challenge.rewardXP,
            "badgeID": challenge.badgeID as Any,
            "userID": userId,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users")
                .document(userId)
                .collection("challenges")
                .document(challenge.id.uuidString)
                .setData(challengeData, merge: true)

            lastSyncError = nil
        } catch {
            lastSyncError = error
            throw FirestoreError.syncFailed(error.localizedDescription)
        }
    }

    // MARK: - Achievement Sync

    /// Syncs an achievement to Firestore
    func syncAchievement(_ achievement: Achievement, userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let achievementData: [String: Any] = [
            "badgeID": achievement.badgeID,
            "title": achievement.title,
            "badgeDescription": achievement.badgeDescription,
            "tier": achievement.tier.rawValue,
            "category": achievement.category?.rawValue as Any,
            "isUnlocked": achievement.isUnlocked,
            "unlockedDate": achievement.unlockedDate.map { Timestamp(date: $0) } as Any,
            "progressCurrent": achievement.progressCurrent,
            "progressRequired": achievement.progressRequired,
            "userID": userId,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users")
                .document(userId)
                .collection("achievements")
                .document(achievement.badgeID)
                .setData(achievementData, merge: true)

            lastSyncError = nil
        } catch {
            lastSyncError = error
            throw FirestoreError.syncFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete Operations

    /// Deletes an activity from Firestore
    func deleteActivity(firebaseID: String, userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await db.collection("users")
                .document(userId)
                .collection("activities")
                .document(firebaseID)
                .delete()

            lastSyncError = nil
        } catch {
            lastSyncError = error
            throw FirestoreError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Offline Persistence

    /// Enables offline persistence for Firestore
    static func enableOfflinePersistence() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        Firestore.firestore().settings = settings
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case syncFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case invalidData
    case userNotAuthenticated

    var errorDescription: String? {
        switch self {
        case .syncFailed(let message):
            return "Failed to sync data: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .invalidData:
            return "Invalid data format"
        case .userNotAuthenticated:
            return "User must be authenticated to sync data"
        }
    }
}
