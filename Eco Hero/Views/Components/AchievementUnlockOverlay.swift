//
//  AchievementUnlockOverlay.swift
//  Eco Hero
//
//  Full-screen celebration overlay shown when an achievement is unlocked.
//  Enhanced with iOS 26 phaseAnimator for coordinated celebration sequences.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

// MARK: - Animation Phase Enum for iOS 26+

/// Defines the phases for the achievement unlock celebration animation
enum AchievementAnimationPhase: CaseIterable {
    case initial
    case ringAppear
    case iconBounce
    case confettiBurst
    case textReveal
    case pulseGlow

    var ringScale: CGFloat {
        switch self {
        case .initial: return 0.3
        case .ringAppear: return 1.05
        case .iconBounce: return 1.0
        case .confettiBurst, .textReveal, .pulseGlow: return 1.0
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .initial, .ringAppear: return 0.1
        case .iconBounce: return 1.15
        case .confettiBurst: return 1.0
        case .textReveal: return 1.0
        case .pulseGlow: return 1.05
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .initial: return 0
        case .ringAppear: return 20
        case .iconBounce: return 35
        case .confettiBurst: return 50
        case .textReveal: return 40
        case .pulseGlow: return 55
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .initial: return 0
        case .ringAppear, .iconBounce, .confettiBurst, .textReveal, .pulseGlow: return 0.85
        }
    }

    var showConfetti: Bool {
        switch self {
        case .initial, .ringAppear, .iconBounce: return false
        case .confettiBurst, .textReveal, .pulseGlow: return true
        }
    }

    var showText: Bool {
        switch self {
        case .initial, .ringAppear, .iconBounce, .confettiBurst: return false
        case .textReveal, .pulseGlow: return true
        }
    }
}

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showBadge = false
    @State private var showText = false
    @State private var showConfetti = false
    @State private var ringScale: CGFloat = 0.3
    @State private var iconScale: CGFloat = 0.1
    @State private var backgroundOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var animationTrigger = false
    @Namespace private var glassNamespace

    private var tierColor: Color {
        switch achievement.tier {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.4, blue: 0.9)
        }
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                iOS26Content
            } else {
                legacyContent
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - iOS 26+ Content with PhaseAnimator

    @available(iOS 26, *)
    private var iOS26Content: some View {
        ZStack {
            // Background with glass blur
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }

            VStack(spacing: 24) {
                Spacer()

                // Confetti with phase animation
                if showConfetti {
                    AchievementConfettiView(colors: [tierColor, tierColor.opacity(0.7), .white, .yellow])
                        .frame(height: 300)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Achievement badge with phaseAnimator
                achievementBadge
                    .phaseAnimator(
                        AchievementAnimationPhase.allCases,
                        trigger: animationTrigger
                    ) { content, phase in
                        content
                            .scaleEffect(phase == .pulseGlow ? 1.02 : 1.0)
                    } animation: { phase in
                        switch phase {
                        case .initial: .easeOut(duration: 0.1)
                        case .ringAppear: .spring(response: 0.4, dampingFraction: 0.6)
                        case .iconBounce: .spring(response: 0.5, dampingFraction: 0.5)
                        case .confettiBurst: .easeOut(duration: 0.2)
                        case .textReveal: .easeOut(duration: 0.3)
                        case .pulseGlow: .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        }
                    }

                // Text content with glass effect
                if showText {
                    textContent
                        .padding(24)
                        .glassEffect(.regular.tint(tierColor.opacity(0.2)).interactive(), in: RoundedRectangle(cornerRadius: 20))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Dismiss hint
                if showText {
                    dismissHint
                }
            }
        }
    }

    // MARK: - Legacy Content (iOS 18-25)

    private var legacyContent: some View {
        ZStack {
            // Background blur
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }

            VStack(spacing: 24) {
                Spacer()

                // Confetti
                if showConfetti {
                    AchievementConfettiView(colors: [tierColor, tierColor.opacity(0.7), .white, .yellow])
                        .frame(height: 300)
                }

                // Achievement badge
                achievementBadge

                // Text content
                if showText {
                    textContent
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Dismiss hint
                if showText {
                    dismissHint
                }
            }
        }
    }

    // MARK: - Shared Components

    private var achievementBadge: some View {
        ZStack {
            // Animated glow
            if showBadge {
                Circle()
                    .fill(tierColor.opacity(0.4))
                    .frame(width: 200, height: 200)
                    .blur(radius: glowRadius)
            }

            // Outer ring with gradient
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [tierColor, tierColor.opacity(0.5), tierColor.opacity(0.8), tierColor],
                        center: .center
                    ),
                    lineWidth: 6
                )
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)

            // Inner fill with radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColor.opacity(0.3), tierColor.opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .scaleEffect(ringScale)

            // Icon with symbol effect
            Image(systemName: achievement.iconName)
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(tierColor)
                .scaleEffect(iconScale)
                .shadow(color: tierColor.opacity(0.5), radius: 10)
                .symbolEffect(.bounce, value: showBadge)
        }
        .frame(height: 200)
    }

    private var textContent: some View {
        VStack(spacing: 12) {
            Text("Achievement Unlocked!")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            Text(achievement.title)
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(achievement.badgeDescription)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Tier badge with glass effect
            tierBadge
        }
    }

    @ViewBuilder
    private var tierBadge: some View {
        if #available(iOS 26, *) {
            Text(achievement.tier.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(tierColor.opacity(0.6)).interactive(), in: Capsule())
        } else {
            Text(achievement.tier.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(tierColor.opacity(0.8), in: Capsule())
        }
    }

    private var dismissHint: some View {
        Text("Tap anywhere to continue")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.bottom, 40)
            .transition(.opacity)
    }

    // MARK: - Animation Methods

    private func startAnimation() {
        // Trigger phase animator on iOS 26+
        animationTrigger.toggle()

        // Background fade in
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.85
        }

        // Badge scale in with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            showBadge = true
            ringScale = 1.0
            glowRadius = 40
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            iconScale = 1.0
        }

        // Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showConfetti = true
            }
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        // Text fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            showText = true
        }

        // Start pulsing glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowRadius = 55
            }
        }

        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            dismissOverlay()
        }
    }

    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0
            showBadge = false
            showText = false
            showConfetti = false
            ringScale = 0.3
            iconScale = 0.1
            glowRadius = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Confetti View

private struct AchievementConfettiView: View {
    let colors: [Color]

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        for i in 0..<50 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = Double.random(in: 50...200)
            let targetX = centerX + CGFloat(cos(angle) * distance)
            let targetY = centerY + CGFloat(sin(angle) * distance) - 100

            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: centerX, y: centerY),
                opacity: 1,
                rotation: 0
            )

            particles.append(particle)

            let index = particles.count - 1

            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5))) {
                particles[index].position = CGPoint(x: targetX, y: targetY)
                particles[index].rotation = Double.random(in: 180...720)
            }

            withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
                particles[index].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    var rotation: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        AchievementUnlockOverlay(
            achievement: Achievement(
                badgeID: "test",
                title: "Carbon Crusher",
                description: "Save 100 kg of CO₂",
                tier: .gold,
                iconName: "sun.max.fill",
                progressRequired: 100
            ),
            onDismiss: {}
        )
    }
}
