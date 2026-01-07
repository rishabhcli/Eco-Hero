//
//  Extensions.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - Double Extensions

extension Double {
    /// Format as decimal with specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// Format as string with comma separators
    var formattedWithCommas: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format for display (e.g., "1.2K", "3.4M")
    var abbreviated: String {
        let thousand = 1000.0
        let million = 1_000_000.0

        if self >= million {
            return String(format: "%.2fM", self / million)
        } else if self >= thousand {
            return String(format: "%.2fK", self / thousand)
        } else if self == floor(self) {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.2f", self)
        }
    }

    /// Format to exactly 2 decimal places
    var twoDecimalPlaces: String {
        String(format: "%.2f", self)
    }
}


// MARK: - Shadow Level System

/// Standardized shadow levels for consistent elevation hierarchy
enum ShadowLevel {
    case none
    case subtle      // Small cards, list items
    case medium      // Standard cards
    case elevated    // Hero sections, modals
    case floating    // FABs, tooltips, overlays

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 8
        case .medium: return 16
        case .elevated: return 24
        case .floating: return 32
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 4
        case .medium: return 8
        case .elevated: return 12
        case .floating: return 16
        }
    }

    var opacity: Double {
        switch self {
        case .none: return 0
        case .subtle: return 0.04
        case .medium: return 0.08
        case .elevated: return 0.12
        case .floating: return 0.16
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standardized shadow with elevation level
    func elevationShadow(_ level: ShadowLevel, color: Color = .black) -> some View {
        self.shadow(
            color: color.opacity(level.opacity),
            radius: level.radius,
            x: 0,
            y: level.yOffset
        )
    }

    /// Apply colored shadow that matches element tint
    func coloredShadow(_ color: Color, level: ShadowLevel = .medium) -> some View {
        self.shadow(
            color: color.opacity(level.opacity * 2),
            radius: level.radius,
            x: 0,
            y: level.yOffset
        )
    }

    /// Apply a reusable elevated card appearance - uses iOS 26 liquid glass when available
    func cardStyle(
        cornerRadius: CGFloat = AppConstants.Layout.cardCornerRadius,
        shadowLevel: ShadowLevel = .subtle
    ) -> some View {
        Group {
            if #available(iOS 26, *) {
                self
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .glassEffect(.regular.tint(Color.primary.opacity(0.03)))
            } else {
                self
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .elevationShadow(shadowLevel)
            }
        }
    }

    /// Secondary card style with subtle background
    func secondaryCardStyle(
        cornerRadius: CGFloat = AppConstants.Layout.cardCornerRadius
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    /// Hero card style for prominent sections
    func heroCardStyle(
        gradient: LinearGradient = AppConstants.Gradients.hero,
        cornerRadius: CGFloat = 28
    ) -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(gradient)
            )
            .foregroundStyle(.white)
            .elevationShadow(.elevated)
    }

    /// Glassmorphic variant for hero cards and authentication panels
    func glassCardStyle(
        cornerRadius: CGFloat = AppConstants.Layout.cardCornerRadius,
        shadowLevel: ShadowLevel = .elevated
    ) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(AppConstants.Gradients.mellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
            )
            .elevationShadow(shadowLevel)
    }

    /// Style for pill shaped filter chips
    func pillStyle(
        background: Color,
        foreground: Color = .white,
        isSelected: Bool = false
    ) -> some View {
        self
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(background)
            )
            .foregroundStyle(foreground)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    /// Tinted card with category color accent
    func tintedCardStyle(
        tint: Color,
        cornerRadius: CGFloat = AppConstants.Layout.cardCornerRadius
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(tint.opacity(0.3), lineWidth: 1)
                    )
            )
            .elevationShadow(.subtle)
    }

    /// Add haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    /// Interactive scale effect on press (for buttons and cards)
    func interactiveScale(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }

    /// Shimmer loading effect (uses shimmerEffect from VisualEffects)
    func shimmer(isActive: Bool) -> some View {
        self
            .redacted(reason: isActive ? .placeholder : [])
            .shimmerEffect(isActive: isActive)
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let ecoGreen = Color(hex: "4CAF50")
    static let ecoBlue = Color(hex: "2196F3")
    static let ecoOrange = Color(hex: "FF9800")
}

// MARK: - Enhanced Card Styles

extension View {
    /// Card with multi-layer shadows for enhanced depth
    func popCard(
        cornerRadius: CGFloat = 20,
        background: Color = Color(.systemBackground)
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
            // Close shadow - sharp definition
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            // Far shadow - soft depth
            .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 8)
    }

    /// Card with colored glow effect
    func glowCard(
        color: Color,
        cornerRadius: CGFloat = 20,
        isActive: Bool = true
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: 12, x: 0, y: 4)
            .shadow(color: isActive ? color.opacity(0.15) : .clear, radius: 24, x: 0, y: 8)
    }

    /// Card with animated gradient border
    func animatedBorderCard(
        colors: [Color],
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .animatedGradientBorder(colors: colors, lineWidth: lineWidth, cornerRadius: cornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    /// Gradient background card
    func gradientCard(
        colors: [Color],
        cornerRadius: CGFloat = 20
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Enhanced Button Style

struct EnhancedBounceButtonStyle: ButtonStyle {
    var hapticEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// MARK: - Scroll Offset Reader

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Read scroll offset for parallax effects
    func readScrollOffset(into binding: Binding<CGFloat>) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            binding.wrappedValue = value
        }
    }
}

// MARK: - Visual Feedback Modifiers

extension View {
    /// Add press-down visual feedback
    func pressEffect() -> some View {
        self.buttonStyle(EnhancedBounceButtonStyle())
    }

    /// Add scale-on-appear animation
    func scaleOnAppear(delay: Double = 0) -> some View {
        self.modifier(ScaleOnAppearModifier(delay: delay))
    }

    /// Add bounce-in animation
    func bounceIn(delay: Double = 0) -> some View {
        self.modifier(BounceInModifier(delay: delay))
    }
}

private struct ScaleOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

private struct BounceInModifier: ViewModifier {
    let delay: Double
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - iOS Version Conditional Modifier

extension View {
    /// Apply different modifiers based on iOS version availability
    @ViewBuilder
    func if_iOS26<T: View, F: View>(
        @ViewBuilder _ iOS26Transform: (Self) -> T,
        @ViewBuilder fallback: (Self) -> F
    ) -> some View {
        if #available(iOS 26, *) {
            iOS26Transform(self)
        } else {
            fallback(self)
        }
    }
}
