# Eco Hero - iOS Environmental Impact Tracking App

<img src="https://img.shields.io/badge/iOS-18.0+-blue.svg" alt="iOS 18.0+">
<img src="https://img.shields.io/badge/Swift-5.0+-orange.svg" alt="Swift 5.0+">
<img src="https://img.shields.io/badge/SwiftUI-Latest-green.svg" alt="SwiftUI">
<img src="https://img.shields.io/badge/SwiftData-Latest-purple.svg" alt="SwiftData">

Eco Hero is a comprehensive iOS app that helps users track their environmental impact through daily eco-friendly activities. The app gamifies sustainability by rewarding users with badges, levels, and challenges while providing educational content about environmental conservation.

## Features

### ✅ Implemented

- **User Authentication**
  - Email/password sign in and sign up
  - Secure authentication flow (Firebase integration pending)
  - User profile management

- **Activity Tracking**
  - Log eco-friendly activities across 6 categories:
    - Meals (vegetarian, vegan, local food)
    - Transport (biking, walking, public transit, carpooling)
    - Plastic reduction (reusable bottles, bags, cups)
    - Energy conservation (LED bulbs, unplugging devices, cold water laundry)
    - Water conservation (shorter showers, fixing leaks)
    - Lifestyle (recycling, composting, planting trees)
  - Automatic impact calculation (CO₂, water, land, plastic saved)
  - Activity history and notes

- **Impact Dashboard**
  - Real-time cumulative impact metrics
  - Weekly progress tracking
  - Activity streak counter
  - Recent activities feed
  - Educational "Did You Know?" facts

- **Gamification System**
  - Level progression with experience points (XP)
  - 9 level titles (Eco Beginner → Earth Guardian)
  - Daily streak tracking
  - Weekly and daily challenges
  - Achievement badges
  - Challenge categories aligned with activity types

- **Educational Content**
  - 15+ eco-facts about environmental impact
  - Category-specific tips for sustainable living
  - Daily eco-fact cards
  - Detailed information for each activity category

- **User Profile**
  - Personal impact statistics
  - Level and streak display
  - Achievement gallery
  - Settings (sound, haptics, notifications)
  - Account management

- **Data Persistence**
  - SwiftData for local storage
  - Offline-first architecture
  - Models: EcoActivity, UserProfile, Challenge, Achievement

### 🚧 Pending Implementation

The following features are outlined in the implementation plan but require additional setup:

1. **Firebase Integration**
   - Authentication with Firebase Auth
   - Cloud sync with Firestore
   - User data backup and multi-device sync

2. **Vision Framework Integration**
   - Image recognition for waste classification
   - Camera integration for scanning items
   - ML model for identifying recyclables

3. **Audio & Haptics**
   - Success sound effects for logged activities
   - Badge unlock celebration sounds
   - Enhanced haptic feedback patterns
   - Sound asset files

4. **Local Notifications**
   - Daily activity reminders
   - Streak maintenance notifications
   - Challenge progress alerts
   - AI-scheduled reminders

5. **Agentic AI Assistant**
   - Natural language activity logging
   - Smart reminders and scheduling
   - Personalized eco-tips
   - Function calling for in-app actions
   - Integration with OpenAI or similar LLM

6. **Advanced Features**
   - Social feed for sharing activities
   - Friend connections and leaderboards
   - Monthly impact summaries
   - Shareable achievement graphics
   - Charts and data visualization

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI:

```
Eco Hero/
├── Models/                    # SwiftData models
│   ├── EcoActivity.swift
│   ├── UserProfile.swift
│   ├── Challenge.swift
│   ├── Achievement.swift
│   └── ActivityCategory.swift
│
├── ViewModels/               # Business logic (to be expanded)
│
├── Views/                    # SwiftUI views
│   ├── Authentication/
│   │   └── AuthenticationView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Activities/
│   │   └── LogActivityView.swift
│   ├── Challenges/
│   │   └── ChallengesView.swift
│   ├── Profile/
│   │   └── ProfileView.swift
│   ├── LearnView.swift
│   └── MainTabView.swift
│
├── Services/                 # External services
│   └── Firebase/
│       └── AuthenticationManager.swift
│
├── Utilities/               # Helpers and extensions
│   ├── ImpactCalculator.swift
│   ├── Constants.swift
│   └── Extensions.swift
│
└── Resources/              # Assets (to be populated)
    ├── Sounds/
    └── Data/
```

## Technical Stack

- **Language:** Swift 5.0+
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Minimum iOS:** 18.0
- **Target iOS:** Latest (iOS 26+)
- **Architecture:** MVVM
- **Backend (Planned):** Firebase (Auth, Firestore, Storage)
- **AI (Planned):** OpenAI GPT-4 or similar LLM
- **ML (Planned):** Vision framework + Core ML

## Setup Instructions

### Prerequisites

- macOS with Xcode 26.1.1+ (or latest)
- iOS 18.0+ device or simulator
- Apple Developer account (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rishabhbansal/Eco-Hero.git
   cd Eco-Hero
   ```

2. **Open in Xcode**
   ```bash
   open "Eco Hero.xcodeproj"
   ```

3. **Build and Run**
   - Select a target device or simulator
   - Press `Cmd + R` to build and run
   - The app will launch with the authentication screen

### Firebase Setup (Required for Production)

Currently, the app uses placeholder authentication. To enable full Firebase integration:

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "Eco Hero"
   - Enable iOS app and download `GoogleService-Info.plist`

2. **Add Firebase to Xcode**
   - Add Firebase iOS SDK via Swift Package Manager:
     - In Xcode: File → Add Package Dependencies
     - Enter: `https://github.com/firebase/firebase-ios-sdk`
     - Select version 12.5.0 or later
     - Add packages: FirebaseAuth, FirebaseFirestore, FirebaseStorage

3. **Configure Firebase**
   - Drag `GoogleService-Info.plist` into your Xcode project
   - Update `AuthenticationManager.swift` to use actual Firebase calls:
     ```swift
     import FirebaseAuth

     func signIn(email: String, password: String) async throws {
         let result = try await Auth.auth().signIn(withEmail: email, password: password)
         self.isAuthenticated = true
         self.currentUserEmail = result.user.email
         self.currentUserID = result.user.uid
     }
     ```

4. **Enable Authentication Methods**
   - In Firebase Console, go to Authentication
   - Enable Email/Password sign-in method

5. **Set up Firestore**
   - In Firebase Console, create a Firestore database
   - Start in production mode
   - Set up security rules for user data

## Impact Calculation Methodology

The app uses scientifically-backed data to calculate environmental impact:

### Carbon Emissions (CO₂)
- **Vegetarian meal:** 2.5 kg CO₂ saved (vs. meat-based)
- **Vegan meal:** 3.2 kg CO₂ saved
- **Biking/Walking:** 120g CO₂ saved per km (vs. car)
- **Public transport:** 80g CO₂ saved per km
- **LED bulb:** 45g CO₂ saved per hour

### Water Conservation
- **Vegetarian meal:** 3,000 liters saved
- **Vegan meal:** 4,000 liters saved
- **Reusable bottle:** 3 liters saved
- **Shorter shower (5 min):** 50 liters saved

### Plastic Reduction
- Tracked by number of items avoided
- Categories: bottles, bags, cups, utensils

### Land Preservation
- Measured in square meters (m²)
- Primarily from diet changes

*All values are based on peer-reviewed environmental studies and industry standards.*

## Gamification System

### Experience Points (XP)
- CO₂ saved: 10 XP per kg
- Water saved: 0.01 XP per liter
- Plastic avoided: 5 XP per item
- Level up: Every 100 XP × current level

### Level Progression
| Level | Title | XP Required |
|-------|-------|-------------|
| 1 | Eco Beginner | 0 |
| 2-4 | Green Starter | 100-400 |
| 5-9 | Earth Friend | 500-900 |
| 10-14 | Eco Warrior | 1,000-1,400 |
| 15-19 | Planet Protector | 1,500-1,900 |
| 20-29 | Sustainability Champion | 2,000-2,900 |
| 30-39 | Eco Hero | 3,000-3,900 |
| 40-49 | Environmental Legend | 4,000-4,900 |
| 50+ | Earth Guardian | 5,000+ |

### Challenges
- **Weekly:** 7-day commitments (e.g., Meatless Week)
- **Daily:** Single-day goals
- **Milestone:** Long-term achievements

## Development Roadmap

### Phase 1: Core Functionality ✅ COMPLETE
- [x] Project setup and architecture
- [x] SwiftData models
- [x] Authentication UI
- [x] Activity logging
- [x] Dashboard with metrics
- [x] Gamification (levels, challenges, badges)
- [x] Educational content
- [x] User profile

### Phase 2: Enhanced Features (Next Steps)
- [ ] Firebase integration
- [ ] Cloud sync
- [ ] Sound effects and enhanced haptics
- [ ] Local notifications
- [ ] Image recognition for waste classification
- [ ] Data visualization (charts)

### Phase 3: AI & Social (Future)
- [ ] Agentic AI assistant
- [ ] Natural language activity logging
- [ ] Social feed
- [ ] Friend connections
- [ ] Leaderboards
- [ ] Shareable achievements

### Phase 4: Polish & Release
- [ ] App icon and launch screen
- [ ] Onboarding flow
- [ ] Privacy policy
- [ ] App Store assets
- [ ] Beta testing
- [ ] App Store submission

## Testing

Currently using development authentication (bypassing Firebase). To test:

1. Launch the app
2. Enter any email and password on sign-in screen
3. Explore all features:
   - Log activities from different categories
   - Check dashboard for updated metrics
   - Join and complete challenges
   - Browse educational content
   - View profile and settings

## Contributing

This is a personal project, but suggestions and feedback are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Open a Pull Request

## Privacy & Data

- All user data stored locally with SwiftData
- Firebase integration (when enabled) uses secure authentication
- No data sold or shared with third parties
- Users can delete their account and all associated data
- Complies with Apple's privacy guidelines

## License

This project is for educational and portfolio purposes.

## Credits

**Developer:** Rishabh Bansal
**Design Inspiration:** Various eco-tracking apps and sustainability platforms
**Environmental Data:** Based on research from environmental organizations and scientific studies

## Contact

For questions or feedback:
- GitHub: [Your GitHub Profile]
- Email: [Your Email]

---

**Note:** This is an active development project. Some features described in the implementation plan are not yet complete. The core functionality is working and demonstrates the app's potential. Firebase integration and advanced features (AI, notifications, image recognition) are planned for future releases.

## Screenshots

*Coming soon - add screenshots once UI is finalized*

## Acknowledgments

- Apple for SwiftUI and SwiftData frameworks
- Firebase for backend services
- Environmental research organizations for impact data
- Open source community for inspiration

---

*Last Updated: November 15, 2025*
*Version: 1.0.0 (Beta)*
