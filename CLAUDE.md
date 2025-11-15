# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Eco Hero** is an iOS environmental impact tracking app built with SwiftUI and SwiftData. Users log eco-friendly activities (meals, transport, plastic reduction, energy/water conservation) and the app calculates their environmental impact (CO₂, water, land saved). Features include gamification (levels, streaks, challenges, badges), educational content, and Firebase authentication.

**Architecture:** MVVM with SwiftUI
**Deployment Target:** iOS 18.0 (backward compatible)
**Target SDK:** iOS 26.1
**Bundle ID:** `com.rishabh.Eco-Hero`

## Build Commands

### Basic Build & Run
```bash
# Open project
open "Eco Hero.xcodeproj"

# Build from command line (requires specific simulator)
xcodebuild -project "Eco Hero.xcodeproj" -scheme "Eco Hero" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1' build

# Clean build
xcodebuild -project "Eco Hero.xcodeproj" -scheme "Eco Hero" clean
```

**Note:** The project name contains a space. Always quote: `"Eco Hero.xcodeproj"`

### In Xcode
- **Build:** Cmd + B
- **Run:** Cmd + R
- **Clean:** Shift + Cmd + K
- **Test:** Cmd + U

### Simulator Requirements
- iOS 18.0+ simulator required
- Available simulators: iPhone 17, iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air, iPad models
- Firebase requires network connectivity in simulator

## Critical Architecture Details

### SwiftData Models & Relationships

The app uses **4 core SwiftData models** with specific interdependencies:

**EcoActivity** (Activities/Eco Hero/Models/EcoActivity.swift)
- Primary data model for logged eco-friendly actions
- Contains impact calculations (CO₂, water, land, plastic) computed at creation time
- **Must include `userID` field** for multi-user support (links to UserProfile.firebaseUID)
- Firebase sync fields: `firebaseID`, `isSynced` (for cloud backup)
- Distance field is optional but required for transport activities

**UserProfile** (Activities/Eco Hero/Models/UserProfile.swift)
- Singleton per user (keyed by `firebaseUID`)
- Aggregates total impact from all EcoActivity records
- **Critical:** The `updateImpactMetrics(activity:)` method must be called when logging activities to maintain cumulative totals
- Streak logic automatically updates on activity logging (checks date continuity)
- XP formula: `CO₂ * 10 + Water * 0.01 + Plastic * 5`
- Level progression: `100 XP × current level`

**Challenge & Achievement**
- Pre-populated challenges are created in `ChallengesView.initializeChallenges()`
- User participation tracked via `userID` field
- Achievement unlocking is based on profile metrics reaching thresholds

### Impact Calculation System

**ImpactCalculator** (Utilities/ImpactCalculator.swift) is the source of truth for environmental metrics:
- All calculation methods return `ActivityImpact` struct
- Values are scientifically-backed (see README for sources)
- **Must use `return` statements** (Swift 5.0 doesn't infer return in multi-line expressions)
- Transport activities calculate impact based on distance (km)
- Adding new activity types requires updating both `ImpactCalculator` and `LogActivityView.activityOptions(for:)`

### State Management Pattern

The app uses SwiftUI's `@Observable` macro (not `ObservableObject`):
- `AuthenticationManager` is `@Observable` and injected via `.environment()`
- SwiftData models use `@Query` property wrapper for reactive fetching
- Firebase auth state is synchronized to `AuthenticationManager` properties via listener
- **Important:** Profile updates must call `try modelContext.save()` to persist changes

### View Hierarchy & Navigation

**Tab Structure:**
```
MainTabView (5 tabs)
├── DashboardView (Home)
├── LogActivityView (Log Activity)
├── ChallengesView (3 sub-tabs: Active/Available/Completed)
├── LearnView (Educational content)
└── ProfileView (User stats & settings)
```

**Authentication Flow:**
- `Eco_HeroApp` checks `authManager.isAuthenticated`
- If false → `AuthenticationView` (Sign In/Sign Up)
- If true → `MainTabView`
- AuthenticationManager maintains Firebase auth state automatically

### Firebase Integration Status

**Current State:**
- Firebase SDK added (v12.6.0+) with GoogleService-Info.plist
- `FirebaseCore` initialized in `Eco_HeroApp.init()`
- `AuthenticationManager` fully implements Firebase Auth
- **Missing packages:** Must add `FirebaseAuth` and `FirebaseFirestore` to target

**To Complete Setup:**
1. In Xcode: Select "Eco Hero" target → General → Frameworks
2. Add `FirebaseAuth` and `FirebaseFirestore` from firebase-ios-sdk package
3. Enable Email/Password in Firebase Console → Authentication
4. See `FIREBASE_SETUP.md` for complete instructions

**Auth State Handling:**
- AuthenticationManager listens to `Auth.auth().addStateDidChangeListener`
- Automatically syncs `isAuthenticated`, `currentUserEmail`, `currentUserID`
- Error handling converts Firebase NSError codes to custom `AuthError` enum

## Key Implementation Patterns

### Adding New Activity Types

1. Update `ActivityCategory` enum in `Models/ActivityCategory.swift` with icon and color
2. Add calculation method to `ImpactCalculator.swift` returning `ActivityImpact`
3. Update `LogActivityView.activityOptions(for:)` with new options
4. Update `LogActivityView.calculateImpact()` switch statement
5. Add educational content to `Constants.EcoTips` if desired

### Logging Activities Properly

**Required steps** when logging activity (see `LogActivityView.logActivity()`):
```swift
// 1. Create activity with calculated impact
let activity = EcoActivity(category: category, description: desc, ...)

// 2. Insert into SwiftData
modelContext.insert(activity)

// 3. Update user profile (critical!)
if let profile = userProfile {
    profile.updateImpactMetrics(activity: activity)
}

// 4. Save context
try modelContext.save()
```

Skipping step 3 will break cumulative metrics and XP/level progression.

### Challenge Progress Tracking

Challenges don't auto-update from activities. To implement auto-tracking:
1. Query active challenges in `LogActivityView`
2. After logging activity, check if activity matches challenge criteria
3. Call `challenge.updateProgress()` if criteria met
4. Save modelContext

Currently challenges are manually joined but progress is not automatically tracked from activities.

### Working with SwiftData

**Querying:**
```swift
@Query private var activities: [EcoActivity]  // All activities
@Query(sort: \.timestamp, order: .reverse) private var activities: [EcoActivity]  // Sorted
```

**Filtering by user:**
```swift
let userActivities = activities.filter { $0.userID == authManager.currentUserID }
```

**Updating models:**
SwiftData models are classes (reference types). Direct property assignment works, but must save context:
```swift
profile.currentLevel = 5  // Change is tracked
try modelContext.save()   // Persist to disk
```

### Educational Content Management

All facts and tips stored in `Constants.swift`:
- `EducationalFacts.facts` - Array of 15+ environmental facts
- `EcoTips.tips` - Array of tip objects with title/description/category
- Functions: `randomFact()`, `tip(for: category)`, `randomTip()`

To add content, simply append to these arrays. No database updates needed.

## Common Development Patterns

### Haptic Feedback
```swift
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)
```
Used on: activity logging, badge unlocks, challenge completion

### SwiftUI Card Style
```swift
VStack { ... }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
```
Or use `.cardStyle()` extension

### Formatting Numbers
```swift
value.abbreviated       // "1.2K", "3.4M" (from Extensions.swift)
value.formattedWithCommas  // "1,234.5"
value.rounded(toPlaces: 2)  // 1.23
```

## Firebase Integration Checklist

When adding Firebase features:

**Authentication:**
- ✅ FirebaseCore initialized in app
- ✅ AuthenticationManager uses Firebase Auth
- ⚠️ Must add FirebaseAuth package to target
- ⚠️ Must enable Email/Password in Firebase Console

**Firestore (for cloud sync):**
- ⚠️ Must add FirebaseFirestore package to target
- Create `FirestoreService.swift` in Services/Firebase/
- Implement sync methods for each model
- Set up security rules (see FIREBASE_SETUP.md)
- Call sync after local SwiftData saves

**Storage (for photos):**
- Future feature (not yet implemented)
- Will require FirebaseStorage package
- Photos stored locally by default (photoPath in EcoActivity)

## Testing Notes

**Current Auth State:**
- Firebase Auth is implemented but SDK may not be linked
- If auth fails, check that FirebaseAuth package is added to target
- Test accounts can be created via sign-up flow or Firebase Console

**Data Persistence:**
- All data stored locally in SwiftData
- Database path: App's documents directory
- Data persists between app launches
- Deleting app = deletes all local data

**Offline Mode:**
- App fully functional offline (SwiftData only)
- Firebase operations will fail without network
- No automatic retry logic implemented

## Important Files Reference

**Entry Point:**
- `Eco_HeroApp.swift` - App lifecycle, Firebase initialization, ModelContainer setup

**Core Services:**
- `AuthenticationManager.swift` - Firebase Auth wrapper, auth state management
- `ImpactCalculator.swift` - Environmental impact calculations (source of truth)

**Main Views:**
- `MainTabView.swift` - Tab navigation structure
- `DashboardView.swift` - Home screen with metrics
- `LogActivityView.swift` - Activity logging form (critical logic here)

**Configuration:**
- `Constants.swift` - App-wide constants, educational content, XP formulas
- `Extensions.swift` - Helper functions for formatting, date math, View modifiers

**Documentation:**
- `README.md` - User-facing documentation
- `IMPLEMENTATION_SUMMARY.md` - Technical status, what's done vs pending
- `FIREBASE_SETUP.md` - Step-by-step Firebase integration guide

## Known Issues & Workarounds

**Firebase Auth Build Error:**
"Unable to find module dependency: 'FirebaseAuth'"
- **Cause:** FirebaseAuth not added to app target
- **Fix:** Xcode → Eco Hero target → General → Frameworks → Add FirebaseAuth

**SwiftData Query Not Updating:**
- SwiftUI view may not be observing model changes
- Ensure using `@Query` property wrapper, not manual fetch
- If updating existing model, call `try modelContext.save()`

**Impact Metrics Not Updating:**
- Likely `profile.updateImpactMetrics(activity)` not called after logging
- See "Logging Activities Properly" section above

**Streak Reset Unexpectedly:**
- Streak logic in `UserProfile.updateStreak()` checks date continuity
- Logs must be on consecutive days (ignores time of day)
- Check `lastActivityDate` is being set correctly

## Level & Gamification Constants

**Level Titles:** (see `Constants.Levels.levelTitle(for:)`)
- 1: Eco Beginner
- 2-4: Green Starter
- 5-9: Earth Friend
- 10-14: Eco Warrior
- 15-19: Planet Protector
- 20-29: Sustainability Champion
- 30-39: Eco Hero
- 40-49: Environmental Legend
- 50+: Earth Guardian

**XP Calculation:**
```swift
let points = activity.carbonSavedKg * 10 +
             activity.waterSavedLiters * 0.01 +
             Double(activity.plasticSavedItems) * 5
```

**Level Up Logic:**
```swift
while experiencePoints >= Double(currentLevel * 100) {
    currentLevel += 1
}
```

## Future Enhancements (Pending)

These features are planned but not yet implemented:

1. **Vision Framework** - Image recognition for waste classification
2. **AVFoundation** - Sound effects for success feedback
3. **UserNotifications** - Daily reminders, streak alerts
4. **AI Assistant** - Natural language activity logging via LLM
5. **Swift Charts** - Data visualization graphs
6. **Social Features** - Activity feed, leaderboards (requires Firestore)

When implementing these, see `IMPLEMENTATION_SUMMARY.md` for detailed requirements and estimated time.

## Code Style Notes

- Use SwiftUI's `.sidebarAdaptable` for TabView (iPad support)
- Prefer `@Observable` over `ObservableObject` for new code
- Always use `return` in multi-line closures (Swift 5.0 requirement)
- Impact calculations use metric units (kg, liters, m²)
- Date formatting via Extensions.swift helpers
- Error handling: throw custom AuthError, not Firebase NSError

## Project Statistics

- **20+ Swift files**
- **4 SwiftData models**
- **15+ SwiftUI views**
- **~3,500 lines of code**
- **iOS 18.0+ deployment target**
- **Clean build (0 warnings)**
