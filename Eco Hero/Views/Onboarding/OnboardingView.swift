//
//  OnboardingView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var classifierService = WasteClassifierService()
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var showConfetti = false
    @State private var buttonGlow = false
    @State private var dragOffset: CGFloat = 0
    @Namespace private var glassNamespace

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "leaf.fill",
            iconColors: [Color(hex: "16A34A"), Color(hex: "22C55E")],
            title: "Welcome to\nEco Hero",
            subtitle: "Your personal sustainability companion",
            description: "Track your environmental impact, earn rewards, and join millions making a difference for our planet.",
            particleType: .leaf
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            iconColors: [Color(hex: "0EA5E9"), Color(hex: "38BDF8")],
            title: "Smart Waste\nSorting",
            subtitle: "AI-powered recycling assistant",
            description: "Point your camera at any item and instantly know if it's recyclable or compostable. Powered by Apple Intelligence.",
            particleType: .scan
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColors: [Color(hex: "F97316"), Color(hex: "FB923C")],
            title: "Track Your\nImpact",
            subtitle: "See your progress grow",
            description: "Log eco-friendly activities and watch your CO₂ savings, water conservation, and plastic avoidance add up over time.",
            particleType: .chart
        ),
        OnboardingPage(
            icon: "trophy.fill",
            iconColors: [Color(hex: "A855F7"), Color(hex: "C084FC")],
            title: "Earn Rewards\n& Badges",
            subtitle: "Gamified sustainability",
            description: "Complete challenges, unlock achievements, level up your eco profile, and compete with friends on the leaderboard.",
            particleType: .sparkle
        )
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedOnboardingBackground(
                colors: pages[currentPage].iconColors,
                currentPage: currentPage
            )

            // Confetti overlay
            if showConfetti {
                ConfettiView(colors: [.green, .blue, .orange, .purple, .yellow, .white])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.opacity)
                    }
                }
                .frame(height: 50)

                // Page content with 3D rotation
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            EnhancedOnboardingPageView(
                                page: page,
                                namespace: glassNamespace,
                                isActive: currentPage == index,
                                pageIndex: index
                            )
                            .frame(width: geometry.size.width)
                            .rotation3DEffect(
                                .degrees(Double(index - currentPage) * 15 + Double(dragOffset / 20)),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.5
                            )
                        }
                    }
                    .offset(x: -CGFloat(currentPage) * geometry.size.width + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if value.translation.width < -threshold && currentPage < pages.count - 1 {
                                        currentPage += 1
                                    } else if value.translation.width > threshold && currentPage > 0 {
                                        currentPage -= 1
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                }

                // Bottom section
                VStack(spacing: 24) {
                    // Custom page indicator
                    HStack(spacing: 10) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index
                                    ? LinearGradient(colors: pages[index].iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                                .shadow(color: currentPage == index ? pages[index].iconColors[0].opacity(0.5) : .clear, radius: 4)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Action button with glow
                    actionButton
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
            if currentPage == pages.count - 1 {
                startButtonGlow()
            }
        }
        .onChange(of: currentPage) { _, newValue in
            if newValue == pages.count - 1 {
                startButtonGlow()
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        let isLastPage = currentPage == pages.count - 1

        if #available(iOS 26, *) {
            Button(action: handleNext) {
                buttonContent(isLastPage: isLastPage)
            }
            .buttonStyle(.glass(.regular.tint(pages[currentPage].iconColors.first?.opacity(0.5)).interactive()))
            .glassEffectID("continue-button", in: glassNamespace)
            .padding(.horizontal, 32)
            .shadow(color: isLastPage && buttonGlow ? pages[currentPage].iconColors[0].opacity(0.6) : .clear, radius: buttonGlow ? 20 : 10)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: buttonGlow)
        } else {
            Button(action: handleNext) {
                buttonContent(isLastPage: isLastPage)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(pages[currentPage].iconColors.first?.opacity(0.5) ?? .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .shadow(color: isLastPage && buttonGlow ? pages[currentPage].iconColors[0].opacity(0.6) : .clear, radius: buttonGlow ? 20 : 10)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: buttonGlow)
        }
    }

    private func buttonContent(isLastPage: Bool) -> some View {
        HStack(spacing: 12) {
            Text(isLastPage ? "Get Started" : "Continue")
                .font(.headline)
            Image(systemName: isLastPage ? "sparkles" : "arrow.right")
                .font(.title3)
                .symbolEffect(.bounce, value: isLastPage && buttonGlow)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func startButtonGlow() {
        buttonGlow = true
    }

    private func handleNext() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            // Final page - show confetti and complete
            showConfetti = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            Task {
                await classifierService.requestAuthorization()
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds for confetti
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

// MARK: - Animated Background

private struct AnimatedOnboardingBackground: View {
    let colors: [Color]
    let currentPage: Int

    @State private var phase: CGFloat = 0
    @State private var orbOffsets: [CGSize] = [
        CGSize(width: -100, height: -200),
        CGSize(width: 150, height: 100),
        CGSize(width: -50, height: 300)
    ]

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    colors.first ?? .green,
                    colors.last?.opacity(0.8) ?? .green.opacity(0.8),
                    Color.black.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.6), value: currentPage)

            // Floating orbs with parallax
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [colors.first?.opacity(0.4 - Double(i) * 0.1) ?? .white.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .blur(radius: 60 + CGFloat(i) * 20)
                    .frame(width: 300 - CGFloat(i) * 50, height: 300 - CGFloat(i) * 50)
                    .offset(orbOffsets[i])
                    .animation(.easeInOut(duration: 0.8 + Double(i) * 0.2), value: currentPage)
            }

            // Subtle moving mesh
            MeshGradientBackground(colors: colors, phase: phase)
                .opacity(0.3)
        }
        .ignoresSafeArea()
        .onAppear {
            animateOrbs()
        }
        .onChange(of: currentPage) { _, _ in
            animateOrbs()
        }
    }

    private func animateOrbs() {
        withAnimation(.easeInOut(duration: 2)) {
            orbOffsets = [
                CGSize(width: CGFloat.random(in: -150...(-50)), height: CGFloat.random(in: -250...(-150))),
                CGSize(width: CGFloat.random(in: 100...200), height: CGFloat.random(in: 50...150)),
                CGSize(width: CGFloat.random(in: -100...0), height: CGFloat.random(in: 250...350))
            ]
        }
    }
}

private struct MeshGradientBackground: View {
    let colors: [Color]
    let phase: CGFloat

    var body: some View {
        Canvas { context, size in
            let gridSize = 4
            let cellWidth = size.width / CGFloat(gridSize)
            let cellHeight = size.height / CGFloat(gridSize)

            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let x = CGFloat(col) * cellWidth + cellWidth / 2
                    let y = CGFloat(row) * cellHeight + cellHeight / 2
                    let offset = sin(phase + CGFloat(row + col) * 0.5) * 10

                    let rect = CGRect(
                        x: x - cellWidth / 2 + offset,
                        y: y - cellHeight / 2,
                        width: cellWidth,
                        height: cellHeight
                    )

                    let opacity = 0.1 + sin(phase + CGFloat(row * col) * 0.3) * 0.05
                    context.fill(
                        RoundedRectangle(cornerRadius: 20).path(in: rect),
                        with: .color(colors.first?.opacity(opacity) ?? .white.opacity(opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Onboarding Page Model

private struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let description: String
    let particleType: ParticleType

    enum ParticleType {
        case leaf
        case scan
        case chart
        case sparkle
    }
}

// MARK: - Enhanced Onboarding Page View

private struct EnhancedOnboardingPageView: View {
    let page: OnboardingPage
    let namespace: Namespace.ID
    let isActive: Bool
    let pageIndex: Int

    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -20
    @State private var contentOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOffset: CGFloat = 20
    @State private var descriptionOffset: CGFloat = 15
    @State private var showParticles = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon with particles
            ZStack {
                // Particle effects behind icon
                if showParticles {
                    particleView
                        .frame(width: 200, height: 200)
                }

                // Glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            page.iconColors[0].opacity(0.2 - Double(i) * 0.05),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(160 + i * 40), height: CGFloat(160 + i * 40))
                        .scaleEffect(isActive ? 1 : 0.8)
                        .opacity(isActive ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.1), value: isActive)
                }

                // Icon
                if #available(iOS 26, *) {
                    iconContent
                        .glassEffect(.regular.tint(page.iconColors.first?.opacity(0.3)).interactive(), in: .circle)
                } else {
                    iconContent
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [page.iconColors[0].opacity(0.4), page.iconColors[1].opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
            }

            // Text content with staggered animations
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .offset(y: titleOffset)
                    .opacity(contentOpacity)

                Text(page.subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: subtitleOffset)
                    .opacity(contentOpacity)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .offset(y: descriptionOffset)
                    .opacity(contentOpacity)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { _, active in
            if active {
                animateIn()
            } else {
                resetAnimations()
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateIn()
                }
            }
        }
    }

    private var iconContent: some View {
        Image(systemName: page.icon)
            .font(.system(size: 64, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .padding(44)
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))
            .shadow(color: page.iconColors.first?.opacity(0.6) ?? .clear, radius: 30, x: 0, y: 15)
    }

    @ViewBuilder
    private var particleView: some View {
        switch page.particleType {
        case .leaf:
            FloatingLeafView(leafCount: 5, colors: page.iconColors)
        case .scan:
            ScanLineView(color: page.iconColors[0])
        case .chart:
            RisingBarsView(colors: page.iconColors)
        case .sparkle:
            SparkleParticleView(particleCount: 10, colors: page.iconColors + [.white])
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconRotation = 0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            titleOffset = 0
            contentOpacity = 1
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
            subtitleOffset = 0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            descriptionOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showParticles = true
        }
    }

    private func resetAnimations() {
        iconScale = 0.5
        iconRotation = -20
        contentOpacity = 0
        titleOffset = 30
        subtitleOffset = 20
        descriptionOffset = 15
        showParticles = false
    }
}

// MARK: - Scan Line Animation

private struct ScanLineView: View {
    let color: Color
    @State private var offset: CGFloat = -100

    var body: some View {
        ZStack {
            // Scan line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, color.opacity(0.8), color, color.opacity(0.8), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 150, height: 3)
                .blur(radius: 2)
                .offset(y: offset)

            // Corner markers
            ForEach(0..<4, id: \.self) { i in
                ScanCorner(color: color)
                    .rotationEffect(.degrees(Double(i) * 90))
                    .offset(
                        x: (i == 0 || i == 3) ? -60 : 60,
                        y: (i == 0 || i == 1) ? -60 : 60
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                offset = 100
            }
        }
    }
}

private struct ScanCorner: View {
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 15))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 15, y: 0))
        }
        .stroke(color, lineWidth: 3)
    }
}

// MARK: - Rising Bars Animation

private struct RisingBarsView: View {
    let colors: [Color]
    @State private var heights: [CGFloat] = [0.3, 0.5, 0.7, 0.4, 0.8]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 16, height: 80 * heights[i])
                    .opacity(0.7)
            }
        }
        .onAppear {
            animateBars()
        }
    }

    private func animateBars() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            heights = [0.6, 0.8, 0.4, 0.9, 0.5]
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
