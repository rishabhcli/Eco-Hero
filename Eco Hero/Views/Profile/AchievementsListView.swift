//
//  AchievementsListView.swift
//  Eco Hero
//
//  Wrapper view that displays the achievement gallery.
//  This view is referenced from ChallengesView and ProfileView.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

/// Wrapper that navigates to the full AchievementGalleryView
struct AchievementsListView: View {
    var body: some View {
        AchievementGalleryView()
    }
}

#Preview {
    NavigationStack {
        AchievementsListView()
            .environment(AuthenticationManager())
            .modelContainer(for: Achievement.self, inMemory: true)
    }
}
