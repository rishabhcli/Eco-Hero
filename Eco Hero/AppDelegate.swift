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
        print("🚀 AppDelegate: Starting Firebase configuration...")

        // Configure Firebase before anything else
        do {
            FirebaseApp.configure()
            print("✅ AppDelegate: Firebase configured successfully")

            // Verify Firebase app is configured
            if let app = FirebaseApp.app() {
                print("✅ AppDelegate: Firebase app name: \(app.name)")
                print("✅ AppDelegate: Firebase options: \(app.options)")
            } else {
                print("❌ AppDelegate: Firebase app is nil!")
            }

            // Enable offline persistence for Firestore
            print("🔄 AppDelegate: Configuring Firestore...")
            let settings = FirestoreSettings()
            settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
            Firestore.firestore().settings = settings
            print("✅ AppDelegate: Firestore configured successfully")

        } catch {
            print("❌ AppDelegate: Firebase configuration error: \(error)")
            print("❌ AppDelegate: Error details: \(error.localizedDescription)")
        }

        print("✅ AppDelegate: Application launch completed")
        return true
    }
}
