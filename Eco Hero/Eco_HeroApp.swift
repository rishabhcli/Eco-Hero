//
//  Eco_HeroApp.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct Eco_HeroApp: App {
    // Connect AppDelegate for Firebase initialization
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var authManager = AuthenticationManager()
    @State private var firestoreService = FirestoreService()

    var sharedModelContainer: ModelContainer = {
        print("🔄 App: Creating SwiftData ModelContainer...")

        let schema = Schema([
            EcoActivity.self,
            UserProfile.self,
            Challenge.self,
            Achievement.self
        ])

        print("✅ App: Schema created with \(schema.entities.count) entities")

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ App: ModelContainer created successfully")
            return container
        } catch {
            print("❌ App: FATAL ERROR - Could not create ModelContainer")
            print("❌ App: Error: \(error)")
            print("❌ App: Error details: \(error.localizedDescription)")

            if let nsError = error as NSError? {
                print("❌ App: Error domain: \(nsError.domain)")
                print("❌ App: Error code: \(nsError.code)")
                print("❌ App: Error userInfo: \(nsError.userInfo)")
            }

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environment(authManager)
                        .environment(firestoreService)
                } else {
                    AuthenticationView()
                        .environment(authManager)
                        .environment(firestoreService)
                }
            }
            .onAppear {
                print("🔄 App: View appeared, setting up auth listener...")
                // Setup auth listener after Firebase is configured
                authManager.setupAuthListener()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
