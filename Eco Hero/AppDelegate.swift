//
//  AppDelegate.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase before anything else
        FirebaseApp.configure()

        // Enable offline persistence for Firestore
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        Firestore.firestore().settings = settings

        return true
    }
}
