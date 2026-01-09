//
//  VisualEffects.swift
//  Eco Hero
//
//  Created by Claude on 1/6/26.
//

import SwiftUI

// MARK: - Safe Random Helper

/// Safe random CGFloat that handles invalid ranges (when containerSize is 0 or too small)
private func safeRandom(in range: ClosedRange<CGFloat>) -> CGFloat {
    guard range.lowerBound <= range.upperBound else {
        return range.lowerBound
    }
    return CGFloat.random(in: range)
}

/// Safe random to avoid crashes when container size is zero or smaller than min value
private func safeRandomPosition(min: CGFloat, max: CGFloat, fallback: CGFloat = 0) -> CGFloat {
    if max <= min { return fallback }
    return CGFloat.random(in: min...max)
}

// MARK: - Particle Systems


/// Rising flame particles for streak counter
struct FlameParticleView: View {
    let particleCount: Int
    let baseColor: Color

    @State private var particles: [FlameParticle] = []

    init(particleCount: Int = 5, baseColor: Color = .orange) {
        self.particleCount = particleCount
        self.baseColor = baseColor
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let age = now - particle.creationTime
                    let progress = age / particle.lifetime

                    guard progress < 1 else { continue }

                    let opacity = 1 - progress
                    let scale = 1 - (progress * 0.5)
                    let yOffset = -CGFloat(progress) * 60
                    let xWobble = sin(progress * .pi * 3 + particle.phase) * 8

                    let x = size.width / 2 + particle.xOffset + xWobble
                    let y = size.height / 2 + yOffset

                    let particleSize = particle.size * scale
                    let rect = CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )

                    let gradient = Gradient(colors: [
                        baseColor.opacity(opacity),
                        baseColor.opacity(opacity * 0.5),
                        .clear
                    ])

                    context.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            gradient,
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: particleSize / 2
                        )
                    )
                }
            }
        }
        .onAppear {
            startEmitting()
        }
    }

    private func startEmitting() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            let newParticle = FlameParticle(
                xOffset: CGFloat.random(in: -15...15),
                size: CGFloat.random(in: 6...14),
                lifetime: Double.random(in: 0.8...1.5),
                phase: Double.random(in: 0...(.pi * 2)),
                creationTime: Date().timeIntervalSinceReferenceDate
            )
            particles.append(newParticle)
            particles = particles.filter {
                Date().timeIntervalSinceReferenceDate - $0.creationTime < $0.lifetime
            }
            if particles.count > 15 {
                particles.removeFirst()
            }
        }
    }
}

private struct FlameParticle: Identifiable {
    let id = UUID()
    let xOffset: CGFloat
    let size: CGFloat
    let lifetime: Double
    let phase: Double
    let creationTime: TimeInterval
}

/// Sparkle particles for achievements and celebrations
struct SparkleParticleView: View {
    let particleCount: Int
    let colors: [Color]
    @State private var isAnimating = false

    init(particleCount: Int = 12, colors: [Color] = [.yellow, .orange, .white]) {
        self.particleCount = particleCount
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                SparklePoint(
                    color: colors[index % colors.count],
                    angle: Double(index) * (360.0 / Double(particleCount)),
                    delay: Double(index) * 0.05,
                    isAnimating: isAnimating
                )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

private struct SparklePoint: View {
    let color: Color
    let angle: Double
    let delay: Double
    let isAnimating: Bool

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.3
    @State private var distance: CGFloat = 20

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .blur(radius: 1)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(
                x: cos(angle * .pi / 180) * distance,
                y: sin(angle * .pi / 180) * distance
            )
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                        opacity = 1
                        scale = 1
                        distance = 40
                    }
                    withAnimation(.easeIn(duration: 0.3).delay(delay + 0.4)) {
                        opacity = 0
                        scale = 0.5
                        distance = 50
                    }
                }
            }
    }
}

/// Confetti burst for celebrations
struct ConfettiView: View {
    let colors: [Color]
    let particleCount: Int
    @State private var particles: [ConfettiParticle] = []
    @State private var isActive = false

    init(colors: [Color] = [.green, .blue, .orange, .pink, .yellow, .purple], particleCount: Int = 50) {
        self.colors = colors
        self.particleCount = particleCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let age = now - particle.creationTime
                    guard age < 3.0 else { continue }

                    let gravity: CGFloat = 400
                    let x = particle.startX + particle.velocityX * CGFloat(age)
                    let y = particle.startY + particle.velocityY * CGFloat(age) + 0.5 * gravity * CGFloat(age * age)

                    let rotation = particle.rotation + particle.rotationSpeed * CGFloat(age)
                    let opacity = max(0, 1 - (age / 3.0))

                    var contextCopy = context
                    contextCopy.opacity = opacity
                    contextCopy.translateBy(x: x, y: y)
                    contextCopy.rotate(by: .radians(rotation))

                    let rect = CGRect(x: -particle.width/2, y: -particle.height/2, width: particle.width, height: particle.height)
                    contextCopy.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            burst()
        }
    }

    func burst() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 3

        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                startX: centerX,
                startY: centerY,
                velocityX: CGFloat.random(in: -300...300),
                velocityY: CGFloat.random(in: -500...(-200)),
                width: CGFloat.random(in: 8...14),
                height: CGFloat.random(in: 6...10),
                color: colors.randomElement() ?? .green,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotationSpeed: CGFloat.random(in: -10...10),
                creationTime: Date().timeIntervalSinceReferenceDate
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let rotation: CGFloat
    let rotationSpeed: CGFloat
    let creationTime: TimeInterval
}

/// Floating leaf particles for eco-themed ambient effects with gyroscope response
/// Leaves drift with tilt direction and flutter on shake
struct FloatingLeafView: View {
    let leafCount: Int
    let colors: [Color]
    
    private let motion = MotionManager.shared

    init(leafCount: Int = 6, colors: [Color] = [Color(hex: "16A34A"), Color(hex: "22C55E"), Color(hex: "86EFAC")]) {
        self.leafCount = leafCount
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<leafCount, id: \.self) { index in
                    GyroLeafParticle(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 10...18),
                        containerSize: geometry.size,
                        delay: Double(index) * 0.4,
                        tiltX: motion.tiltX,
                        tiltY: motion.tiltY,
                        isShaking: motion.isShaking,
                        layerIndex: index % 3
                    )
                }
            }
        }
        .motionAware()
    }
}

private struct GyroLeafParticle: View {
    let color: Color
    let size: CGFloat
    let containerSize: CGSize
    let delay: Double
    let tiltX: CGFloat
    let tiltY: CGFloat
    let isShaking: Bool
    let layerIndex: Int

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    @State private var flutterRotation: Double = 0
    @State private var flutterTimer: Timer?

    // Parallax offset - closer leaves move more
    private var parallaxOffset: CGPoint {
        let multiplier = CGFloat(layerIndex + 1) * 12
        return CGPoint(
            x: tiltX * multiplier,
            y: tiltY * multiplier * 0.5
        )
    }

    // Flutter intensity on shake
    private var flutterIntensity: Double {
        Double.random(in: 20...40)
    }

    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size))
            .foregroundStyle(color)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation + flutterRotation))
            .rotation3DEffect(
                .degrees(Double(tiltX) * 15),
                axis: (x: 0, y: 1, z: 0)
            )
            .position(
                x: position.x + parallaxOffset.x,
                y: position.y + parallaxOffset.y
            )
            .blur(radius: CGFloat(layerIndex) * 0.3)
            .onAppear {
                position = CGPoint(
                    x: safeRandomPosition(min: 0, max: containerSize.width, fallback: containerSize.width / 2),
                    y: containerSize.height + 30
                )
                startAnimation()
            }
            .onChange(of: isShaking) { _, shaking in
                if shaking {
                    // Start flutter animation with Timer for proper state-driven control
                    flutterTimer?.invalidate()
                    let intensity = flutterIntensity
                    flutterTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            flutterRotation = flutterRotation > 0 ? -intensity : intensity
                        }
                    }
                    flutterTimer?.fire() // Start immediately
                } else {
                    flutterTimer?.invalidate()
                    flutterTimer = nil
                    withAnimation(.easeOut(duration: 0.3)) {
                        flutterRotation = 0
                    }
                }
            }
            .onDisappear {
                flutterTimer?.invalidate()
            }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.5).delay(delay)) {
            opacity = 0.8
        }

        withAnimation(
            .easeInOut(duration: Double.random(in: 5...8))
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            position = CGPoint(
                x: safeRandomPosition(min: 0, max: containerSize.width, fallback: containerSize.width / 2),
                y: -30
            )
        }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            rotation = Double.random(in: -35...35)
        }
    }
}


// MARK: - Water Effect with Gyroscope

import CoreMotion

/// Interactive water ripple effect that responds to device motion
/// Enhanced with bolder effects, parallax bubbles, and shimmer reflections
struct WaterEffectView: View {
    @State private var ripples: [WaterRipple] = []
    @State private var shimmerPhase: CGFloat = 0
    @State private var bubbleSeeds: [BubbleSeed] = (0..<12).map { _ in BubbleSeed() }
    @Environment(\.colorScheme) private var colorScheme
    
    private let motion = MotionManager.shared
    let baseColor: Color

    init(baseColor: Color = Color(hex: "0EA5E9")) {
        self.baseColor = baseColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic water gradient that shifts with tilt
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [baseColor.opacity(0.25), baseColor.opacity(0.08)]
                        : [baseColor.opacity(0.18), baseColor.opacity(0.05)],
                    startPoint: UnitPoint(x: 0.5 + motion.tiltX * 0.4, y: 0 + motion.tiltY * 0.2),
                    endPoint: UnitPoint(x: 0.5 - motion.tiltX * 0.4, y: 1 - motion.tiltY * 0.2)
                )

                // Bold animated wave layers with enhanced motion response
                WaveLayer(phase: 0, amplitude: 25 + motion.tiltY * 20, color: baseColor.opacity(0.2))
                    .offset(y: geometry.size.height * 0.55)

                WaveLayer(phase: .pi / 3, amplitude: 18 + motion.tiltY * 15, color: baseColor.opacity(0.15))
                    .offset(y: geometry.size.height * 0.65)

                WaveLayer(phase: .pi / 1.5, amplitude: 12 + motion.tiltY * 10, color: baseColor.opacity(0.1))
                    .offset(y: geometry.size.height * 0.75)

                // Shimmer/light reflection that responds to tilt
                WaterShimmerLayer(
                    baseColor: baseColor,
                    phase: shimmerPhase,
                    tiltX: motion.tiltX
                )
                .opacity(colorScheme == .dark ? 0.4 : 0.6)

                // Ripples from motion
                ForEach(ripples) { ripple in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [baseColor.opacity(ripple.opacity), baseColor.opacity(ripple.opacity * 0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: ripple.size, height: ripple.size)
                        .position(ripple.position)
                }

                // Parallax floating bubbles that move opposite to tilt
                ForEach(Array(bubbleSeeds.enumerated()), id: \.offset) { index, seed in
                    WaterBubble(
                        seed: seed,
                        containerSize: geometry.size,
                        tiltX: motion.tiltX,
                        tiltY: motion.tiltY,
                        baseColor: baseColor,
                        layerIndex: index % 3
                    )
                }
            }
        }
        .motionAware()
        .onAppear {
            startShimmerAnimation()
            startContinuousRipples()
        }
    }

    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
    }
    
    private func startContinuousRipples() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // Create subtle ambient ripples
            let centerX = UIScreen.main.bounds.width / 2
            let centerY = UIScreen.main.bounds.height / 2
            createRipple(at: CGPoint(
                x: centerX + CGFloat.random(in: -100...100) + motion.tiltX * 50,
                y: centerY + CGFloat.random(in: -50...50) + motion.tiltY * 50
            ))
            
            // Extra ripples on shake
            if motion.isShaking {
                for _ in 0..<3 {
                    createRipple(at: CGPoint(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                        y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
                    ))
                }
            }
        }
    }

    private func createRipple(at position: CGPoint) {
        guard ripples.count < 8 else { return }
        let ripple = WaterRipple(position: position)
        ripples.append(ripple)

        withAnimation(.easeOut(duration: 2.0)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].size = 180
                ripples[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

private struct BubbleSeed {
    let xRatio: CGFloat = CGFloat.random(in: 0.1...0.9)
    let yRatio: CGFloat = CGFloat.random(in: 0.2...0.8)
    let size: CGFloat = CGFloat.random(in: 4...12)
    let parallaxMultiplier: CGFloat = CGFloat.random(in: 0.5...1.5)
    let phaseOffset: Double = Double.random(in: 0...(.pi * 2))
}

private struct WaterBubble: View {
    let seed: BubbleSeed
    let containerSize: CGSize
    let tiltX: CGFloat
    let tiltY: CGFloat
    let baseColor: Color
    let layerIndex: Int
    
    @State private var floatOffset: CGFloat = 0
    
    private var parallaxOffset: CGPoint {
        // Bubbles move opposite to tilt for depth effect
        let multiplier = seed.parallaxMultiplier * CGFloat(layerIndex + 1) * 15
        return CGPoint(
            x: -tiltX * multiplier,
            y: -tiltY * multiplier
        )
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        baseColor.opacity(0.5),
                        baseColor.opacity(0.2),
                        baseColor.opacity(0.05)
                    ],
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 0,
                    endRadius: seed.size
                )
            )
            .frame(width: seed.size, height: seed.size)
            .blur(radius: CGFloat(layerIndex) * 0.5)
            .position(
                x: containerSize.width * seed.xRatio + parallaxOffset.x,
                y: containerSize.height * seed.yRatio + parallaxOffset.y + floatOffset
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(seed.phaseOffset / 2)
                ) {
                    floatOffset = CGFloat.random(in: -15...15)
                }
            }
    }
}

private struct WaterShimmerLayer: View {
    let baseColor: Color
    let phase: CGFloat
    let tiltX: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.15),
                    .white.opacity(0.3),
                    .white.opacity(0.15),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.4)
            .rotationEffect(.degrees(-15 + Double(tiltX) * 10))
            .offset(
                x: (phase * 2 - 0.5) * geometry.size.width + tiltX * 30,
                y: geometry.size.height * 0.3
            )
            .blur(radius: 20)
        }
    }
}

private struct WaterRipple: Identifiable {
    let id = UUID()
    let position: CGPoint
    var size: CGFloat = 20
    var opacity: Double = 0.6
}

private struct WaveLayer: View {
    let phase: Double
    let amplitude: CGFloat
    let color: Color

    @State private var animationPhase: Double = 0

    var body: some View {
        WaveShape(phase: animationPhase + phase, amplitude: amplitude)
            .fill(color)
            .onAppear {
                withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            }
    }
}

private struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height))

        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * 2.5 + phase) * amplitude + height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height * 2))
        path.addLine(to: CGPoint(x: 0, y: height * 2))
        path.closeSubpath()

        return path
    }
}

// MARK: - Rain Effect

/// Falling rain particles effect with gyroscope response
/// Rain angle and intensity respond to device motion
struct RainEffectView: View {
    let intensity: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private let motion = MotionManager.shared

    init(intensity: Int = 40) {
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic rain gradient that shifts with tilt
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.blue.opacity(0.12), Color.clear]
                        : [Color.blue.opacity(0.08), Color.clear],
                    startPoint: UnitPoint(x: 0.5 + motion.tiltX * 0.3, y: 0),
                    endPoint: UnitPoint(x: 0.5 - motion.tiltX * 0.2, y: 1)
                )

                // Rain drops with gyroscope response
                ForEach(0..<intensity, id: \.self) { index in
                    GyroRainDrop(
                        containerSize: geometry.size,
                        delay: Double(index) * 0.05,
                        colorScheme: colorScheme,
                        tiltX: motion.tiltX,
                        isShaking: motion.isShaking
                    )
                }
                
                // Splash particles at bottom when shaking
                if motion.accelerationMagnitude > 0.5 {
                    ForEach(0..<8, id: \.self) { index in
                        RainSplash(
                            containerSize: geometry.size,
                            index: index,
                            intensity: motion.accelerationMagnitude
                        )
                    }
                }
            }
        }
        .motionAware()
    }
}

private struct GyroRainDrop: View {
    let containerSize: CGSize
    let delay: Double
    let colorScheme: ColorScheme
    let tiltX: CGFloat
    let isShaking: Bool

    @State private var yPosition: CGFloat = -50
    @State private var opacity: Double = 0

    private let xPosition: CGFloat
    private let dropLength: CGFloat
    private let duration: Double
    private let startY: CGFloat

    init(containerSize: CGSize, delay: Double, colorScheme: ColorScheme, tiltX: CGFloat, isShaking: Bool) {
        self.containerSize = containerSize
        self.delay = delay
        self.colorScheme = colorScheme
        self.tiltX = tiltX
        self.isShaking = isShaking
        self.xPosition = safeRandomPosition(min: 0, max: containerSize.width, fallback: containerSize.width / 2)
        self.dropLength = CGFloat.random(in: 15...35)
        self.duration = Double.random(in: 0.6...1.2)
        self.startY = -CGFloat.random(in: 30...80) // Stagger start positions
    }

    // Rain angle based on tilt
    private var rainAngle: Double {
        Double(tiltX) * 25 // Max 25 degree angle
    }
    
    // X position with wind drift
    private var xPositionWithWind: CGFloat {
        xPosition + tiltX * 80 // Drift based on tilt
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(colorScheme == .dark ? 0.5 : 0.35),
                        Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: isShaking ? 3 : 2, height: dropLength * (isShaking ? 1.3 : 1))
            .opacity(opacity)
            .rotationEffect(.degrees(rainAngle))
            .position(x: xPositionWithWind, y: yPosition)
            .onAppear {
                yPosition = startY
                startAnimation()
            }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 0.1).delay(delay)) {
            opacity = 1
        }

        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            yPosition = containerSize.height + 50
        }
    }
}

private struct RainSplash: View {
    let containerSize: CGSize
    let index: Int
    let intensity: CGFloat
    
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(
                x: safeRandomPosition(min: 20, max: containerSize.width - 20, fallback: containerSize.width / 2),
                y: containerSize.height - 30 + yOffset
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(Double(index) * 0.05)) {
                    scale = 1.0 + intensity * 0.3
                    opacity = 0.6
                    yOffset = -CGFloat.random(in: 10...25)
                }
                withAnimation(.easeIn(duration: 0.4).delay(Double(index) * 0.05 + 0.3)) {
                    opacity = 0
                    scale = 0.5
                }
            }
    }
}


// MARK: - Fire Effect

/// Animated fire effect for challenges with gyroscope response
/// Flames lean toward tilt direction and intensify on shake
struct FireEffectView: View {
    let intensity: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private let motion = MotionManager.shared

    init(intensity: Int = 15) {
        self.intensity = intensity
    }
    
    // Dynamic intensity based on shake
    private var dynamicIntensity: Int {
        motion.isShaking ? intensity + 8 : intensity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic fire glow that shifts with tilt
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color.orange.opacity(motion.isShaking ? 0.35 : 0.25), Color.red.opacity(0.15), Color.clear]
                        : [Color.orange.opacity(motion.isShaking ? 0.2 : 0.15), Color.red.opacity(0.08), Color.clear],
                    center: UnitPoint(x: 0.5 + motion.tiltX * 0.3, y: 1.0),
                    startRadius: motion.isShaking ? 80 : 50,
                    endRadius: geometry.size.height * 0.75
                )
                
                // Heat distortion overlay
                HeatDistortionLayer(tiltX: motion.tiltX, tiltY: motion.tiltY)
                    .opacity(colorScheme == .dark ? 0.15 : 0.08)

                // Fire particles with tilt response
                ForEach(0..<dynamicIntensity, id: \.self) { index in
                    GyroFireParticle(
                        containerSize: geometry.size,
                        delay: Double(index) * 0.08,
                        colorScheme: colorScheme,
                        tiltX: motion.tiltX,
                        isShaking: motion.isShaking
                    )
                }

                // Ember particles with motion scatter
                ForEach(0..<(dynamicIntensity / 2), id: \.self) { index in
                    GyroEmberParticle(
                        containerSize: geometry.size,
                        delay: Double(index) * 0.15,
                        tiltX: motion.tiltX,
                        accelerationMagnitude: motion.accelerationMagnitude
                    )
                }
            }
        }
        .motionAware()
    }
}

private struct HeatDistortionLayer: View {
    let tiltX: CGFloat
    let tiltY: CGFloat
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for i in 0..<8 {
                    let yPos = size.height * 0.5 + CGFloat(i) * 30
                    let xWobble = sin(phase + Double(i) * 0.5 + Double(tiltX)) * 20
                    
                    context.opacity = 0.3 - Double(i) * 0.03
                    context.fill(
                        Ellipse().path(in: CGRect(
                            x: size.width / 2 - 100 + xWobble + tiltX * 30,
                            y: yPos,
                            width: 200,
                            height: 15
                        )),
                        with: .color(.orange.opacity(0.2))
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

private struct GyroFireParticle: View {
    let containerSize: CGSize
    let delay: Double
    let colorScheme: ColorScheme
    let tiltX: CGFloat
    let isShaking: Bool

    @State private var yOffset: CGFloat = 0
    @State private var xWobble: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1

    private let xPosition: CGFloat
    private let particleColor: Color
    private let size: CGFloat

    init(containerSize: CGSize, delay: Double, colorScheme: ColorScheme, tiltX: CGFloat, isShaking: Bool) {
        self.containerSize = containerSize
        self.delay = delay
        self.colorScheme = colorScheme
        self.tiltX = tiltX
        self.isShaking = isShaking
        self.xPosition = containerSize.width * CGFloat.random(in: 0.25...0.75)
        self.particleColor = [Color.orange, Color.red, Color.yellow, Color(hex: "FF6B00")].randomElement()!
        self.size = CGFloat.random(in: 25...50)
    }
    
    // Flames lean toward lower side of device
    private var flameLean: CGFloat {
        tiltX * 60 // Lean up to 60 points based on tilt
    }
    
    // Size boost when shaking
    private var sizeMultiplier: CGFloat {
        isShaking ? 1.4 : 1.0
    }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        particleColor.opacity(colorScheme == .dark ? 0.7 : 0.5),
                        particleColor.opacity(colorScheme == .dark ? 0.3 : 0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * sizeMultiplier / 2
                )
            )
            .frame(width: size * sizeMultiplier, height: size * sizeMultiplier)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(
                x: xPosition - containerSize.width / 2 + xWobble + flameLean,
                y: yOffset
            )
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        yOffset = containerSize.height * 0.8

        withAnimation(.easeIn(duration: 0.25).delay(delay)) {
            opacity = 1
        }

        withAnimation(
            .easeOut(duration: Double.random(in: 1.2...2.0))
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            yOffset = -60
            scale = 0.2
            opacity = 0
        }

        withAnimation(
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            xWobble = CGFloat.random(in: -25...25)
        }
    }
}

private struct GyroEmberParticle: View {
    let containerSize: CGSize
    let delay: Double
    let tiltX: CGFloat
    let accelerationMagnitude: CGFloat

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    private let emberColor: Color
    private let emberSize: CGFloat

    init(containerSize: CGSize, delay: Double, tiltX: CGFloat, accelerationMagnitude: CGFloat) {
        self.containerSize = containerSize
        self.delay = delay
        self.tiltX = tiltX
        self.accelerationMagnitude = accelerationMagnitude
        self.emberColor = [Color.orange, Color.yellow, Color.red, Color(hex: "FFD700")].randomElement()!
        self.emberSize = CGFloat.random(in: 3...6)
    }
    
    // Embers scatter more with acceleration
    private var scatterAmount: CGFloat {
        min(accelerationMagnitude * 40, 80)
    }

    var body: some View {
        Circle()
            .fill(emberColor)
            .frame(width: emberSize, height: emberSize)
            .blur(radius: 1)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .position(
                x: position.x + tiltX * 30 + (accelerationMagnitude > 0.5 ? CGFloat.random(in: -scatterAmount...scatterAmount) : 0),
                y: position.y
            )
            .onAppear {
                position = CGPoint(
                    x: containerSize.width * CGFloat.random(in: 0.25...0.75),
                    y: containerSize.height * 0.85
                )
                startAnimation()
            }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 0.15).delay(delay)) {
            opacity = 1
        }

        withAnimation(
            .easeOut(duration: Double.random(in: 1.5...3.0))
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            position = CGPoint(
                x: containerSize.width * CGFloat.random(in: 0.1...0.9),
                y: -30
            )
            opacity = 0
            rotation = Double.random(in: -180...180)
        }
    }
}


// MARK: - Animated Backgrounds

/// Slowly shifting gradient background
struct AnimatedGradientBackground: View {
    let colors: [Color]
    let animationDuration: Double

    @State private var start = UnitPoint.topLeading
    @State private var end = UnitPoint.bottomTrailing

    init(colors: [Color], animationDuration: Double = 6.0) {
        self.colors = colors
        self.animationDuration = animationDuration
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    start = UnitPoint.bottomLeading
                    end = UnitPoint.topTrailing
                }
            }
    }
}

/// Floating orbs background with blur and gyroscope parallax
/// Orbs shift with device tilt for 3D depth effect
struct FloatingOrbsBackground: View {
    let orbCount: Int
    let colors: [Color]
    
    private let motion = MotionManager.shared

    init(orbCount: Int = 4, colors: [Color] = [.green.opacity(0.3), .blue.opacity(0.2), .purple.opacity(0.2)]) {
        self.orbCount = orbCount
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<orbCount, id: \.self) { index in
                    GyroFloatingOrb(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 120...220),
                        containerSize: geometry.size,
                        animationDuration: Double.random(in: 6...12),
                        tiltX: motion.tiltX,
                        tiltY: motion.tiltY,
                        layerIndex: index
                    )
                }
            }
        }
        .blur(radius: 55)
        .motionAware()
    }
}

private struct GyroFloatingOrb: View {
    let color: Color
    let size: CGFloat
    let containerSize: CGSize
    let animationDuration: Double
    let tiltX: CGFloat
    let tiltY: CGFloat
    let layerIndex: Int

    @State private var basePosition: CGPoint = .zero
    @State private var scale: CGFloat = 1.0
    
    // Parallax - different layers move at different speeds for depth
    private var parallaxOffset: CGPoint {
        let depthMultiplier = CGFloat(layerIndex + 1) * 25
        return CGPoint(
            x: -tiltX * depthMultiplier, // Move opposite to tilt for parallax
            y: -tiltY * depthMultiplier
        )
    }
    
    // Scale based on Y tilt - simulates closer/further
    private var depthScale: CGFloat {
        1.0 + tiltY * 0.1 * CGFloat(layerIndex + 1) / 4
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size * depthScale, height: size * depthScale)
            .scaleEffect(scale)
            .position(
                x: basePosition.x + parallaxOffset.x,
                y: basePosition.y + parallaxOffset.y
            )
            .onAppear {
                basePosition = CGPoint(
                    x: safeRandomPosition(min: size/2, max: containerSize.width - size/2, fallback: containerSize.width / 2),
                    y: safeRandomPosition(min: size/2, max: containerSize.height - size/2, fallback: containerSize.height / 2)
                )
                startAnimation()
            }
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
        ) {
            basePosition = CGPoint(
                x: safeRandomPosition(min: size/2, max: containerSize.width - size/2, fallback: containerSize.width / 2),
                y: safeRandomPosition(min: size/2, max: containerSize.height - size/2, fallback: containerSize.height / 2)
            )
        }
        
        withAnimation(
            .easeInOut(duration: animationDuration * 0.7)
            .repeatForever(autoreverses: true)
        ) {
            scale = CGFloat.random(in: 0.9...1.1)
        }
    }
}

// MARK: - Shimmer Effect

/// Liquid shimmer overlay for progress bars
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .white.opacity(0.6),
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * geometry.size.width * 1.6 - geometry.size.width * 0.3)
                        .mask(content)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Glow Effect

/// Color-matched glow for interactive elements
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool

    @State private var pulseScale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: radius * pulseScale)
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: radius * 1.5 * pulseScale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(
                        .easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseScale = 1.2
                    }
                } else {
                    pulseScale = 1
                }
            }
    }
}

// MARK: - Pulse Effect

/// Breathing scale animation
struct PulseModifier: ViewModifier {
    let isActive: Bool
    let scale: CGFloat

    @State private var currentScale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        currentScale = scale
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentScale = 1
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        currentScale = scale
                    }
                }
            }
    }
}

// MARK: - Animated Border

/// Rotating gradient border
struct AnimatedGradientBorderModifier: ViewModifier {
    let colors: [Color]
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: colors + [colors.first ?? .clear],
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 3)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Cascade Entrance

/// Staggered list entrance animation
struct CascadeEntranceModifier: ViewModifier {
    let index: Int
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * delay)
                ) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Floating Animation

/// Gentle up/down floating motion
struct FloatingModifier: ViewModifier {
    let amount: CGFloat
    let duration: Double

    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = amount
                }
            }
    }
}

// MARK: - Parallax Effect

/// Scroll-responsive parallax offset
struct ParallaxModifier: ViewModifier {
    let multiplier: CGFloat
    @Binding var scrollOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: scrollOffset > 0 ? -scrollOffset * multiplier : 0)
    }
}

// MARK: - Celebration Overlay

/// Full-screen celebration for milestones
struct CelebrationOverlay: View {
    let type: CelebrationType
    let onDismiss: () -> Void

    @State private var isShowing = false
    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0

    enum CelebrationType {
        case levelUp(newLevel: Int)
        case achievement(name: String, icon: String)
        case milestone(count: Int, label: String)
        case streak(days: Int)

        var title: String {
            switch self {
            case .levelUp(_): return "Level Up!"
            case .achievement(let name, _): return name
            case .milestone(let count, let label): return "\(count) \(label)!"
            case .streak(let days): return "\(days) Day Streak!"
            }
        }

        var subtitle: String {
            switch self {
            case .levelUp(let level): return "You reached Level \(level)"
            case .achievement: return "Achievement Unlocked"
            case .milestone: return "Milestone Reached"
            case .streak: return "Keep it going!"
            }
        }

        var icon: String {
            switch self {
            case .levelUp: return "star.fill"
            case .achievement(_, let icon): return icon
            case .milestone: return "trophy.fill"
            case .streak: return "flame.fill"
            }
        }

        var colors: [Color] {
            switch self {
            case .levelUp: return [.yellow, .orange]
            case .achievement: return [.purple, .pink]
            case .milestone: return [.green, .mint]
            case .streak: return [.orange, .red]
            }
        }
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(isShowing ? 0.6 : 0)
                .ignoresSafeArea()

            // Confetti
            if isShowing {
                ConfettiView(colors: type.colors + [.white, .yellow])
                    .ignoresSafeArea()
            }

            // Content
            VStack(spacing: 24) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: type.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(iconScale)
                    .shadow(color: type.colors.first?.opacity(0.5) ?? .clear, radius: 20)

                // Text
                VStack(spacing: 8) {
                    Text(type.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(type.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(textOpacity)
            }
            .padding(40)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isShowing = true
                iconScale = 1.2
            }

            withAnimation(.spring(response: 0.5).delay(0.2)) {
                iconScale = 1
            }

            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                textOpacity = 1
            }

            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            isShowing = false
            iconScale = 0.5
            textOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - View Extensions

extension View {
    func shimmerEffect(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }

    func glowEffect(color: Color, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowModifier(color: color, radius: radius, isActive: isActive))
    }

    func pulsingScale(isActive: Bool = true, scale: CGFloat = 1.05) -> some View {
        modifier(PulseModifier(isActive: isActive, scale: scale))
    }

    func animatedGradientBorder(colors: [Color], lineWidth: CGFloat = 2, cornerRadius: CGFloat = 16) -> some View {
        modifier(AnimatedGradientBorderModifier(colors: colors, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }

    func cascadeEntrance(index: Int, delay: Double = 0.05) -> some View {
        modifier(CascadeEntranceModifier(index: index, delay: delay))
    }

    func floatingAnimation(amount: CGFloat = 5, duration: Double = 3) -> some View {
        modifier(FloatingModifier(amount: amount, duration: duration))
    }

    func parallaxEffect(multiplier: CGFloat = 0.3, scrollOffset: Binding<CGFloat>) -> some View {
        modifier(ParallaxModifier(multiplier: multiplier, scrollOffset: scrollOffset))
    }
}
