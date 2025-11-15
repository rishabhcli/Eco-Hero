//
//  TestFirebase.swift
//  Test Firebase initialization
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TestFirebaseApp: App {
    init() {
        print("🔥 Step 1: Configuring Firebase...")
        FirebaseApp.configure()
        print("✅ Step 2: Firebase configured")

        print("🔥 Step 3: Accessing Auth...")
        let auth = Auth.auth()
        print("✅ Step 4: Auth instance created: \(auth)")

        print("🔥 Step 5: Checking current user...")
        let user = auth.currentUser
        print("✅ Step 6: Current user: \(user?.uid ?? "nil")")

        print("🎉 All Firebase checks passed!")
    }

    var body: some Scene {
        WindowGroup {
            Text("Firebase Test - Check Console for Results")
                .padding()
        }
    }
}
