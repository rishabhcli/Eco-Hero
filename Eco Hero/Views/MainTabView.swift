//
//  MainTabView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case log = "Log"
    case challenges = "Challenges"
    case learn = "Learn"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .log: return "plus.circle.fill"
        case .challenges: return "trophy.fill"
        case .learn: return "book.fill"
        case .profile: return "person.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.rawValue, systemImage: AppTab.home.icon, value: .home) {
                DashboardView()
            }

            Tab(AppTab.log.rawValue, systemImage: AppTab.log.icon, value: .log) {
                LogActivityView()
            }

            Tab(AppTab.challenges.rawValue, systemImage: AppTab.challenges.icon, value: .challenges) {
                ChallengesView()
            }

            Tab(AppTab.learn.rawValue, systemImage: AppTab.learn.icon, value: .learn) {
                LearnView()
            }

            Tab(AppTab.profile.rawValue, systemImage: AppTab.profile.icon, value: .profile) {
                ProfileView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    MainTabView()
        .environment(AuthenticationManager())
}
