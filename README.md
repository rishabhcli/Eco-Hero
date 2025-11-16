# Eco Hero 🌍

**Track your environmental impact, one action at a time.**

Eco Hero is a native iOS app that helps users make sustainable choices through activity logging, AI-powered challenges, waste sorting games, and educational content. Built with SwiftUI and powered by Apple Intelligence on iOS 26+, Eco Hero makes eco-friendly living engaging and rewarding.

---

## Features

### 🎯 Activity Tracking
- Log eco-friendly actions across six categories: Meals, Transport, Plastic, Energy, Water, and Lifestyle
- Track CO₂ savings and environmental impact
- Build streaks and earn XP for consistent actions
- AI-powered activity suggestions (iOS 26+)

### 🎮 Waste Sorting Game
- Real-time ML-powered waste classification using your camera
- Learn to properly sort recyclables and compostables
- Track accuracy and build sorting streaks
- Rolling average smoothing for stable predictions

### 🏆 Challenges & Achievements
- Complete daily, weekly, and milestone challenges
- Earn badges and unlock achievements
- AI-generated personalized missions (iOS 26+)
- Track active, completed, and available challenges

### 📚 Learn & Grow
- Daily eco-facts and educational content
- Category-specific sustainability tips
- AI-powered smart tip generator with streaming responses (iOS 26+)
- Curated environmental insights

### 📊 Profile & Stats
- Track total XP, level, and streak
- View CO₂ savings and activity history
- Monitor challenge completion rates
- Personal sustainability dashboard

---

## Technical Highlights

### Platform & Requirements
- **Minimum:** iOS 18.0+
- **Optimized for:** iOS 26+ (with Apple Intelligence)
- **Devices:** iPhone and iPad
- **Architecture:** SwiftUI with modern Swift Observation

### Key Technologies
- **SwiftData** - Local data persistence for activities, challenges, and user profiles
- **Vision + CoreML** - Real-time waste classification with custom ML model
- **FoundationModels** - On-device AI for tip generation and challenge creation (iOS 26+)
- **AVFoundation** - Camera integration for waste sorting
- **Liquid Glass Effects** - Modern iOS 26 UI with Material blur fallbacks

### Backward Compatibility
Eco Hero uses runtime availability checks to provide the best experience on every iOS version:

**iOS 26+:**
- Full Liquid Glass effects with interactive tinting
- Apple Intelligence-powered features
- AI activity suggestions, challenge generation, and smart tips

**iOS 18-25:**
- Material blur effects (visually similar to Liquid Glass)
- Static fallback content and legacy CoreML models
- All core features fully functional
- AI features gracefully hidden

### Architecture
- **@Observable** macro for modern state management
- SwiftData schema for `UserProfile`, `EcoActivity`, `WasteSortingResult`, `Challenge`
- Services layer for AI, authentication, and cloud sync
- Reusable components with glass effect compatibility layer

---

## Project Structure

```
Eco-Hero/
├── Eco Hero/                           # Main source directory
│   ├── Eco_HeroApp.swift              # App entry point
│   ├── ContentView.swift              # Main tab view
│   ├── Models/                        # Data models
│   │   ├── ActivityCategory.swift
│   │   ├── EcoActivity.swift
│   │   ├── UserProfile.swift
│   │   ├── Challenge.swift
│   │   └── WasteSortingResult.swift
│   ├── Views/
│   │   ├── Dashboard/                 # Main dashboard
│   │   ├── Activities/                # Activity logging
│   │   ├── WasteSorting/              # ML waste classifier
│   │   ├── Challenges/                # Challenges & achievements
│   │   ├── Profile/                   # User profile
│   │   └── LearnView.swift            # Educational content
│   ├── Services/
│   │   └── AI/
│   │       ├── WasteClassifierService.swift
│   │       ├── FoundationContentService.swift
│   │       └── TipModelService.swift
│   ├── Utilities/
│   │   ├── Constants.swift
│   │   ├── Extensions.swift
│   │   └── LiquidGlassCompatibility.swift
│   └── Resources/
│       └── Models/
│           └── WasteClassifier.mlmodel
├── Eco Hero.xcodeproj/
├── Info.plist
└── CLAUDE.md                          # Development documentation
```

---

## Build Guide

### Prerequisites
- **macOS 15.0+** (Sequoia or later)
- **Xcode 16.0+**
- An iPhone or iPad running **iOS 18.0+** (or use the iOS Simulator)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/risban933/Eco-Hero.git
   cd Eco-Hero
   ```

2. **Open in Xcode**
   ```bash
   open "Eco Hero.xcodeproj"
   ```
   Or use **Cmd + O** in Xcode and select `Eco Hero.xcodeproj`

3. **Select a destination**
   - At the top of Xcode, click the device menu
   - Choose an iOS Simulator (e.g., "iPhone 16") or your connected device

4. **Build and run**
   - Press **Cmd + R** or click the Play button
   - The app will build and launch on your selected device

### Running on a Physical Device
1. Connect your iPhone/iPad via USB
2. Select it from the device menu in Xcode
3. You may need to trust the developer certificate on your device:
   - Settings → General → VPN & Device Management → Trust

### Testing Apple Intelligence Features
To test AI-powered features (activity suggestions, challenge generation, smart tips):
- Use a device or simulator running **iOS 26.0+**
- These features are automatically hidden on iOS 18-25

---

## Key Features by iOS Version

| Feature | iOS 18-25 | iOS 26+ |
|---------|-----------|---------|
| Activity Tracking | ✅ Full | ✅ Full + AI Suggestions |
| Waste Sorting Game | ✅ Full | ✅ Full |
| Challenges | ✅ Full | ✅ Full + AI Generation |
| Learn Section | ✅ Static Tips | ✅ AI Smart Tips |
| Glass UI Effects | ✅ Material Blur | ✅ Liquid Glass |
| Profile & Stats | ✅ Full | ✅ Full |

---

## Development

### Recent Updates (November 2025)
- ✅ **iOS 18.0+ Compatibility** - Full backward compatibility with graceful feature degradation
- ✅ **Liquid Glass Compatibility Layer** - Seamless UI across all iOS versions
- ✅ **Apple Intelligence Integration** - On-device AI for iOS 26+ with smart fallbacks
- ✅ **Rolling Average Smoothing** - Stable ML predictions in waste classifier
- ✅ **Color System Fix** - Eliminated asset catalog warnings

### Configuration Notes
- **Info.plist** must remain at project root (not inside `Eco Hero/` folder)
- Project uses `PBXFileSystemSynchronizedRootGroup` for auto-syncing
- No storyboards - pure SwiftUI architecture

### Testing Checklist
- [x] Build succeeds with iOS 18.0 deployment target
- [ ] App runs on iOS 18 simulator (Material blur fallbacks)
- [ ] App runs on iOS 26 simulator (full Liquid Glass + Apple Intelligence)
- [ ] No visual regressions across versions
- [ ] All features functional on both versions

---

## Contributing

This is a personal project, but feedback and suggestions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Share ideas for new eco-friendly activities or challenges
- Suggest improvements to the waste classification model

---

## License

This project is available for educational and personal use. See repository for license details.

---

## Acknowledgments

Built with:
- SwiftUI and modern Swift concurrency
- Apple's Vision and CoreML frameworks
- FoundationModels for on-device AI (iOS 26+)
- Claude Code for development assistance

---

**Made with 💚 for a more sustainable future**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
