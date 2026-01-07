# Eco Hero - Development Documentation

> AI-assisted development guide for Claude and other AI assistants

## Overview

Eco Hero is a native iOS SwiftUI app that helps users track their environmental impact through:
- Activity logging with CO2/water/plastic savings calculations
- Real-time ML-powered waste sorting using the camera
- Gamified challenges with XP, levels, and streaks
- Educational eco-tips with Apple Intelligence integration (iOS 26+)

**Created by:** Rishabh Bansal (November 2025)

---

## Quick Reference

| Attribute | Value |
|-----------|-------|
| **Language** | Swift 5.10+ |
| **Framework** | SwiftUI with @Observable macro |
| **Minimum iOS** | 18.0 |
| **Optimized for** | iOS 26+ (Apple Intelligence features) |
| **Data Persistence** | SwiftData |
| **ML Frameworks** | Vision + CoreML |
| **Architecture** | MVVM-lite with Services layer |

---

## Project Structure

```
Eco-Hero/
├── Eco Hero/                           # Main source directory (Xcode auto-synced)
│   ├── Eco_HeroApp.swift               # App entry point, SwiftData setup
│   ├── ContentView.swift               # Legacy template (unused)
│   ├── Item.swift                      # Legacy template (unused)
│   │
│   ├── Models/
│   │   ├── ActivityCategory.swift      # Enum with icon/color properties
│   │   ├── EcoActivity.swift           # SwiftData model - logged activities
│   │   ├── UserProfile.swift           # SwiftData model - user stats/XP/streaks
│   │   ├── Challenge.swift             # SwiftData model - challenges system
│   │   ├── Achievement.swift           # SwiftData model - badges/achievements
│   │   ├── WasteBin.swift              # Enum: .recycle, .compost
│   │   └── WasteSortingResult.swift    # SwiftData model - sorting game results
│   │
│   ├── Views/
│   │   ├── MainTabView.swift           # Root TabView with 5 tabs
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift     # Home screen with stats/charts
│   │   ├── Activities/
│   │   │   └── LogActivityView.swift   # Activity logging form
│   │   ├── WasteSorting/
│   │   │   └── WasteSortingView.swift  # ML camera classifier
│   │   ├── Challenges/
│   │   │   └── ChallengesView.swift    # Challenge management
│   │   ├── Profile/
│   │   │   └── ProfileView.swift       # User profile & settings
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift    # First-time user flow
│   │   │   └── OnboardingCardView.swift
│   │   ├── Authentication/
│   │   │   └── AuthenticationView.swift # Sign in/up screens
│   │   ├── Components/
│   │   │   └── CameraPreviewView.swift # AVCaptureSession preview
│   │   ├── LearnView.swift             # Educational content
│   │   └── MoreView.swift              # Additional options
│   │
│   ├── Services/
│   │   ├── AI/
│   │   │   ├── WasteClassifierService.swift    # Real-time ML classification
│   │   │   ├── FoundationContentService.swift  # Apple Intelligence (iOS 26+)
│   │   │   └── TipModelService.swift           # Eco tip generation
│   │   ├── Sync/
│   │   │   ├── AuthenticationManager.swift     # Local auth state
│   │   │   └── CloudSyncService.swift          # Sync placeholder
│   │   └── MotionManager.swift                 # Device motion for effects
│   │
│   ├── Utilities/
│   │   ├── Constants.swift             # AppConstants (colors, gradients, tips)
│   │   ├── Extensions.swift            # Helper extensions
│   │   ├── ImpactCalculator.swift      # CO2/water/plastic calculations
│   │   ├── LiquidGlassCompatibility.swift  # iOS 26 glass effect fallbacks
│   │   └── VisualEffects.swift         # Custom animations/effects
│   │
│   ├── Resources/
│   │   └── Models/
│   │       ├── WasteClassifier.mlmodel     # Waste classification model
│   │       └── EcoTipRecommender.mlpackage # Tip recommendation model
│   │
│   └── Assets.xcassets/                # Images, colors, app icon
│
├── Eco Hero.xcodeproj/                 # Xcode project
├── Info.plist                          # MUST be at root (not in Eco Hero/)
├── CLAUDE.md                           # This file
├── AGENTS.md                           # Multi-agent guidelines
├── GEMINI.md                           # Gemini-specific notes
├── README.md                           # User-facing documentation
└── LICENSE                             # Proprietary license
```

---

## SwiftData Schema

All models use the `@Model` macro for SwiftData persistence:

### UserProfile
```swift
@Model
final class UserProfile {
    var userIdentifier: String      // Links to AuthenticationManager
    var email: String
    var displayName: String
    var experiencePoints: Double    // XP for leveling
    var currentLevel: Int           // Calculated from XP (100 XP/level)
    var streak: Int                 // Current daily streak
    var longestStreak: Int
    var totalCarbonSavedKg: Double
    var totalWaterSavedLiters: Double
    var totalPlasticSavedItems: Int
    var lastActivityDate: Date?     // For streak calculation
}
```

### EcoActivity
```swift
@Model
final class EcoActivity {
    var category: ActivityCategory  // Enum stored as raw value
    var activityDescription: String
    var carbonSavedKg: Double
    var waterSavedLiters: Double
    var plasticSavedItems: Int
    var timestamp: Date
    var userID: String?
}
```

### Challenge
```swift
@Model
final class Challenge {
    var type: ChallengeType         // .daily, .weekly, .milestone
    var status: ChallengeStatus     // .notStarted, .inProgress, .completed, .failed
    var targetCount: Int
    var currentProgress: Int
    var rewardXP: Double
}
```

---

## Key Services

### WasteClassifierService
**Location:** `Eco Hero/Services/AI/WasteClassifierService.swift`

Real-time camera-based waste classification using Vision + CoreML.

**Key Implementation Details:**
- Uses `@Observable` for SwiftUI integration
- Rolling average buffer of **10 frames** (~0.3s at 30fps) for stability
- Stability threshold: 60% confidence before UI update
- Falls back to color heuristics if ML model unavailable
- Outputs: `WasteBin.recycle` or `WasteBin.compost`

```swift
// Key properties
private let bufferSize: Int = 10
private let stabilityThreshold: Double = 0.6
private(set) var predictedBin: WasteBin = .recycle
private(set) var confidence: Double = 0.0
private(set) var isUsingFallback: Bool = false
```

### FoundationContentService
**Location:** `Eco Hero/Services/AI/FoundationContentService.swift`

Apple Intelligence integration for iOS 26+.

**Features:**
- Uses `#if canImport(FoundationModels)` for compile-time checks
- `@Generable` structs for structured AI responses
- Provides activity suggestions and challenge generation
- Falls back to static content on iOS 18-25

**iOS 26+ Types:**
```swift
@Generable struct iOS26ActivityIdea { ... }
@Generable struct iOS26ChallengeBlueprint { ... }
```

### TipModelService
**Location:** `Eco Hero/Services/AI/TipModelService.swift`

Eco-tip generation with streaming support.

- iOS 26+: Uses `LanguageModelSession` with streaming responses
- iOS 18-25: Uses `EcoTipRecommender.mlpackage` CoreML model or static fallbacks

### AuthenticationManager
**Location:** `Eco Hero/Services/Sync/AuthenticationManager.swift`

Local-only authentication (no Firebase/backend currently).
- Stores user ID in UserDefaults
- Auto-authenticates on launch
- Ready for backend integration

---

## ActivityCategory Colors

**IMPORTANT:** `ActivityCategory.color` returns `SwiftUI.Color` directly, not a String:

```swift
enum ActivityCategory: String, Codable, CaseIterable {
    case meals, transport, plastic, energy, water, lifestyle, other

    var color: Color {
        switch self {
        case .meals: return .green
        case .transport: return .blue
        case .plastic: return .orange
        case .energy: return .yellow
        case .water: return .cyan
        case .lifestyle: return .mint
        case .other: return .purple
        }
    }
}
```

**Usage:** `category.color` (NOT `Color(category.color)`)

---

## iOS 18-26 Backward Compatibility

### Liquid Glass Effects

iOS 26 introduces Liquid Glass effects. We provide a compatibility layer:

| iOS 26 API | Compatibility Method |
|------------|---------------------|
| `.glassEffect()` | `.compatibleGlassEffect()` |
| `.glassEffectID()` | `.compatibleGlassEffectID()` |
| `.glassEffectUnion()` | `.compatibleGlassEffectUnion()` |
| `.buttonStyle(.glass())` | `.buttonStyle(.compatibleGlass())` |

**Implementation:** `Eco Hero/Utilities/LiquidGlassCompatibility.swift`

### Apple Intelligence Features

These features are **completely hidden** on iOS 18-25:
- "Generate new mission" button in ChallengesView
- "Smart tip generator" in LearnView
- "Suggest" button in LogActivityView

**Pattern:**
```swift
if #available(iOS 26, *) {
    // Show AI-powered feature
} else {
    // Hide or show static fallback
}
```

---

## Build Configuration

### Critical Notes

1. **Info.plist Location:** Must be at project root (`/Eco-Hero/Info.plist`), NOT inside `Eco Hero/` folder
   - Project uses `PBXFileSystemSynchronizedRootGroup` for auto-syncing
   - Placing Info.plist inside causes duplicate output errors

2. **Camera Permission:** `NSCameraUsageDescription` is set in Info.plist for waste classifier

3. **No Storyboards:** Pure SwiftUI app, no `UIMainStoryboardFile` key

4. **Deployment Target:** iOS 18.0 minimum

### Build Commands

```bash
# Build for simulator
xcodebuild -scheme "Eco Hero" -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -scheme "Eco Hero" -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild clean -scheme "Eco Hero"
```

---

## Code Conventions

### State Management
- Use `@Observable` macro for services and view models
- Use `@State` for view-local state
- Use `@Environment` to pass services down the view hierarchy

### Service Injection Pattern
```swift
// In Eco_HeroApp.swift
@State private var authManager = AuthenticationManager()
@State private var wasteClassifier = WasteClassifierService()

// Inject via environment
MainTabView()
    .environment(authManager)
    .environment(wasteClassifier)

// Use in views
@Environment(AuthenticationManager.self) private var authManager
```

### Naming Conventions
- Files: `PascalCase.swift` matching the primary type
- Services: `*Service.swift` suffix
- Views: `*View.swift` suffix
- Models: Plain noun (e.g., `Challenge.swift`, `UserProfile.swift`)

### SwiftData Queries
```swift
@Query(sort: [SortDescriptor(\EcoActivity.timestamp, order: .reverse)])
private var activities: [EcoActivity]
```

---

## Constants & Theming

All constants are in `AppConstants` struct:

```swift
AppConstants.Colors.evergreen        // Primary brand color
AppConstants.Gradients.hero          // Main header gradient
AppConstants.Animation.spring        // Standard spring animation
AppConstants.Levels.levelTitle(for:) // Level name by number
AppConstants.EducationalFacts.randomFact()
AppConstants.EcoTips.tips
```

---

## Common Tasks

### Adding a New Activity Category
1. Add case to `ActivityCategory` enum in `Models/ActivityCategory.swift`
2. Add `icon` and `color` computed properties
3. Add impact calculations in `ImpactCalculator.swift`
4. Add fallback tip in `TipModelService.swift`

### Adding a New SwiftData Model
1. Create model file in `Models/` with `@Model` macro
2. Add to schema in `Eco_HeroApp.swift`:
```swift
let schema = Schema([
    EcoActivity.self,
    UserProfile.self,
    Challenge.self,
    Achievement.self,
    WasteSortingResult.self,
    NewModel.self  // Add here
])
```

### Using Liquid Glass (iOS 26+)
```swift
// Use compatibility wrapper for cross-version support
.compatibleGlassEffect(
    variant: .regular,
    tintColor: .green.opacity(0.3),
    cornerRadius: 16,
    interactive: true
)
```

---

## Testing Checklist

- [ ] Build succeeds with iOS 18.0 deployment target
- [ ] App runs on iOS 18 simulator (Material blur fallbacks)
- [ ] App runs on iOS 26 simulator (full Liquid Glass + Apple Intelligence)
- [ ] WasteClassifierService works with camera permission
- [ ] SwiftData persistence works across app launches
- [ ] Streak calculation works correctly across days
- [ ] No visual regressions across iOS versions

---

## Environment Setup

Services are injected at the app root:

```swift
// Eco_HeroApp.swift
@State private var authManager = AuthenticationManager()
@State private var syncService = CloudSyncService()
@State private var tipService = TipModelService()
@State private var wasteClassifier = WasteClassifierService()
@State private var foundationContentService = FoundationContentService()
```

---

## Known Issues & Workarounds

1. **ContentView.swift & Item.swift:** Legacy Xcode template files, not used in production. Safe to delete but left for reference.

2. **Camera on Simulator:** WasteClassifierService requires physical device for camera. Falls back to color heuristics on simulator.

3. **Apple Intelligence on Simulator:** iOS 26+ simulator may not have full FoundationModels support. Test on physical device for AI features.

---

## Recent Changes (January 2026)

- Rolling average buffer size adjusted to 10 frames (from 15)
- Visual overhaul with enhanced animations and effects
- Water effect background on Dashboard
- Celebration overlays for level ups
- Comprehensive backward compatibility layer

---

## File Change Guidelines

When modifying this codebase:

1. **Always use `if #available(iOS 26, *)`** for iOS 26-specific APIs
2. **Use compatibility wrappers** from `LiquidGlassCompatibility.swift`
3. **Test on both iOS 18 and iOS 26** simulators
4. **Follow existing patterns** for services and state management
5. **Update SwiftData schema** in `Eco_HeroApp.swift` when adding models
6. **Keep Info.plist at project root** - never move it inside `Eco Hero/`
