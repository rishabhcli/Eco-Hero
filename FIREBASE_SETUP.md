# Firebase Setup Guide for Eco Hero

This guide will help you integrate Firebase into the Eco Hero app to enable real authentication and cloud data sync.

## Prerequisites

- Google account
- Xcode project already open
- Bundle identifier: `com.rishabh.Eco-Hero`

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: **Eco Hero**
4. Disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon
2. Enter bundle ID: `com.rishabh.Eco-Hero`
3. Enter app nickname: **Eco Hero iOS**
4. Leave App Store ID blank for now
5. Click "Register app"

## Step 3: Download Configuration File

1. Download `GoogleService-Info.plist`
2. Drag it into Xcode project (next to `Eco_HeroApp.swift`)
3. ✅ Check "Copy items if needed"
4. ✅ Select "Eco Hero" target
5. Click "Finish"

## Step 4: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select **Dependency Rule:** "Up to Next Major Version" `12.5.0`
4. Click "Add Package"
5. When prompted, select the following products:
   - ✅ **FirebaseAuth** (for authentication)
   - ✅ **FirebaseFirestore** (for cloud database)
   - ✅ **FirebaseStorage** (optional, for images)
6. Click "Add Package"

## Step 5: Initialize Firebase in App

Open `Eco_HeroApp.swift` and update it:

```swift
//
//  Eco_HeroApp.swift
//  Eco Hero
//

import SwiftUI
import SwiftData
import FirebaseCore  // ADD THIS

@main
struct Eco_HeroApp: App {
    @State private var authManager = AuthenticationManager()

    // ADD THIS INITIALIZER
    init() {
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        // ... existing code ...
    }()

    var body: some Scene {
        // ... existing code ...
    }
}
```

## Step 6: Update AuthenticationManager

Open `Services/Firebase/AuthenticationManager.swift` and update the imports:

```swift
import Foundation
import SwiftUI
import FirebaseAuth  // ADD THIS
```

Then replace the sign-in method:

```swift
func signIn(email: String, password: String) async throws {
    // REPLACE placeholder with real Firebase call
    let result = try await Auth.auth().signIn(withEmail: email, password: password)

    self.isAuthenticated = true
    self.currentUserEmail = result.user.email
    self.currentUserID = result.user.uid
}
```

Replace the sign-up method:

```swift
func signUp(email: String, password: String, displayName: String) async throws {
    // Create user with Firebase
    let result = try await Auth.auth().createUser(withEmail: email, password: password)

    // Update display name
    let changeRequest = result.user.createProfileChangeRequest()
    changeRequest.displayName = displayName
    try await changeRequest.commitChanges()

    self.isAuthenticated = true
    self.currentUserEmail = result.user.email
    self.currentUserID = result.user.uid
}
```

Replace the sign-out method:

```swift
func signOut() throws {
    try Auth.auth().signOut()
    self.isAuthenticated = false
    self.currentUserEmail = nil
    self.currentUserID = nil
}
```

Replace the reset password method:

```swift
func resetPassword(email: String) async throws {
    try await Auth.auth().sendPasswordReset(withEmail: email)
}
```

Add authentication state listener in `init()`:

```swift
init() {
    // Listen for auth state changes
    Auth.auth().addStateDidChangeListener { [weak self] _, user in
        self?.isAuthenticated = user != nil
        self?.currentUserEmail = user?.email
        self?.currentUserID = user?.uid
    }
}
```

## Step 7: Enable Authentication in Firebase Console

1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Click "Sign-in method" tab
4. Click "Email/Password"
5. Enable "Email/Password"
6. Click "Save"

## Step 8: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Select **Start in production mode** (we'll add rules next)
4. Choose a location (e.g., `us-central1`)
5. Click "Enable"

## Step 9: Configure Firestore Security Rules

In Firestore → Rules tab, add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // User's activities subcollection
      match /activities/{activityId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // User's challenges subcollection
      match /challenges/{challengeId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // User's achievements subcollection
      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Public challenges (read-only)
    match /public_challenges/{challengeId} {
      allow read: if true;
      allow write: if false; // Only admins can write (via console)
    }
  }
}
```

Click "Publish"

## Step 10: Test Authentication

1. Build and run the app (Cmd + R)
2. Try signing up with a real email and password
3. Check Firebase Console → Authentication → Users
4. You should see the new user listed!

## Step 11: Set Up Cloud Sync (Optional)

Create a new service file: `Services/Firebase/FirestoreService.swift`

```swift
import Foundation
import FirebaseFirestore
import SwiftData

class FirestoreService {
    private let db = Firestore.firestore()

    // Sync activity to Firestore
    func syncActivity(_ activity: EcoActivity, userId: String) async throws {
        let activityData: [String: Any] = [
            "timestamp": activity.timestamp,
            "category": activity.category.rawValue,
            "description": activity.activityDescription,
            "carbonSavedKg": activity.carbonSavedKg,
            "waterSavedLiters": activity.waterSavedLiters,
            "landSavedSqMeters": activity.landSavedSqMeters,
            "plasticSavedItems": activity.plasticSavedItems,
            "distance": activity.distance as Any,
            "notes": activity.notes as Any
        ]

        let docRef = try await db.collection("users")
            .document(userId)
            .collection("activities")
            .addDocument(data: activityData)

        activity.firebaseID = docRef.documentID
        activity.isSynced = true
    }

    // Sync user profile
    func syncProfile(_ profile: UserProfile) async throws {
        let profileData: [String: Any] = [
            "email": profile.email,
            "displayName": profile.displayName,
            "joinDate": profile.joinDate,
            "totalCarbonSavedKg": profile.totalCarbonSavedKg,
            "totalWaterSavedLiters": profile.totalWaterSavedLiters,
            "totalPlasticSavedItems": profile.totalPlasticSavedItems,
            "currentLevel": profile.currentLevel,
            "experiencePoints": profile.experiencePoints,
            "streak": profile.streak,
            "longestStreak": profile.longestStreak
        ]

        try await db.collection("users")
            .document(profile.firebaseUID)
            .setData(profileData, merge: true)
    }
}
```

## Troubleshooting

### Build Errors
- Make sure `GoogleService-Info.plist` is added to the project target
- Clean build folder: Product → Clean Build Folder (Shift + Cmd + K)
- Rebuild: Cmd + B

### Authentication Errors
- Check that Email/Password is enabled in Firebase Console
- Verify email format is correct
- Password must be at least 6 characters

### Firestore Errors
- Check security rules allow the operation
- Verify user is authenticated
- Check for network connection

## Next Steps

Once Firebase is working:

1. **Add offline persistence:**
   ```swift
   let settings = Firestore.firestore().settings
   settings.isPersistenceEnabled = true
   Firestore.firestore().settings = settings
   ```

2. **Add real-time listeners** for data sync

3. **Implement profile picture upload** with Firebase Storage

4. **Add cloud functions** for server-side logic

## Resources

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firebase Auth Guide](https://firebase.google.com/docs/auth/ios/start)
- [Firestore Guide](https://firebase.google.com/docs/firestore/quickstart)
- [Firebase Swift SDK on GitHub](https://github.com/firebase/firebase-ios-sdk)

---

**Estimated Setup Time:** 30-45 minutes

**Support:** If you encounter issues, check the Firebase documentation or create an issue in the project repository.
