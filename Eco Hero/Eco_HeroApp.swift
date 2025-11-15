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
        let schema = Schema([
            EcoActivity.self,
            UserProfile.self,
            Challenge.self,
            Achievement.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
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
                // Setup auth listener after Firebase is configured
                authManager.setupAuthListener()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
