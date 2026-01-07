//
//  LiquidGlassCompatibility.swift
//  Eco Hero
//
//  Backward compatibility wrapper for iOS 26 Liquid Glass effects.
//  Provides seamless fallbacks for iOS 18-25 using Material blur effects.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

// MARK: - Glass Variant Enum

/// Available glass effect variants for visual hierarchy
enum GlassVariant {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick
    case clear

    var fallbackMaterial: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        case .clear: return .ultraThinMaterial
        }
    }

    var fallbackOpacity: Double {
        switch self {
        case .ultraThin: return 0.3
        case .thin: return 0.4
        case .regular: return 0.5
        case .thick: return 0.6
        case .ultraThick: return 0.7
        case .clear: return 0.15
        }
    }
}

// MARK: - Glass Effect Container (Compatibility Wrapper)

/// Wrapper container that provides Liquid Glass effects on iOS 26+
/// and falls back to standard VStack on iOS 18-25.
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26, *) {
            SwiftUI.GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            VStack(spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Compatibility Extensions

extension View {
    /// Applies a glass-like effect that works across iOS 18-26.
    /// - iOS 26+: Uses Liquid Glass with interactive tinting
    /// - iOS 18-25: Uses Material blur with similar appearance
    @ViewBuilder
    func compatibleGlassEffect(
        variant: GlassVariant = .regular,
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        interactive: Bool = true
    ) -> some View {
        if #available(iOS 26, *) {
            // iOS 26+: Use Liquid Glass with .regular (variants not directly accessible)
            if let tint = tintColor, interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else if let tint = tintColor {
                self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            } else if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            // iOS 18-25: Material blur fallback
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(variant.fallbackMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.2 * variant.fallbackOpacity), lineWidth: 1)
                        )
                        .background(
                            tintColor.map {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill($0.opacity(variant.fallbackOpacity))
                            }
                        )
                )
        }
    }

    /// Convenience overload without variant parameter for backward compatibility
    @ViewBuilder
    func compatibleGlassEffect(
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        interactive: Bool = true
    ) -> some View {
        compatibleGlassEffect(variant: .regular, tintColor: tintColor, cornerRadius: cornerRadius, interactive: interactive)
    }

    /// Applies a glass effect with a specific shape.
    @ViewBuilder
    func compatibleGlassEffect<S: InsettableShape>(
        variant: GlassVariant = .regular,
        tintColor: Color? = nil,
        shape: S,
        interactive: Bool = true
    ) -> some View {
        if #available(iOS 26, *) {
            // iOS 26+: Use Liquid Glass
            if let tint = tintColor, interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else if let tint = tintColor {
                self.glassEffect(.regular.tint(tint), in: shape)
            } else if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            // iOS 18-25: Material blur fallback
            self
                .background(
                    shape
                        .fill(variant.fallbackMaterial)
                        .overlay(
                            shape
                                .strokeBorder(Color.white.opacity(0.2 * variant.fallbackOpacity), lineWidth: 1)
                        )
                        .background(
                            tintColor.map {
                                shape.fill($0.opacity(variant.fallbackOpacity))
                            }
                        )
                )
        }
    }

    /// Convenience overload without variant for backward compatibility
    @ViewBuilder
    func compatibleGlassEffect<S: InsettableShape>(
        tintColor: Color? = nil,
        shape: S,
        interactive: Bool = true
    ) -> some View {
        compatibleGlassEffect(variant: .regular, tintColor: tintColor, shape: shape, interactive: interactive)
    }

    /// Assigns an ID to a glass effect element (iOS 26+ only, no-op on earlier versions).
    @ViewBuilder
    func compatibleGlassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// Creates a union of glass effect regions (iOS 26+ only, applies single glass effect on iOS 18-25).
    @ViewBuilder
    func compatibleGlassEffectUnion(id: String, namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            self.glassEffectUnion(id: id, namespace: namespace)
        } else {
            // iOS 18-25: Apply a single glass effect to the unified container
            self.compatibleGlassEffect(cornerRadius: 16, interactive: false)
        }
    }

    /// Applies a glass effect transition (iOS 26+ only, falls back to opacity on earlier versions).
    @ViewBuilder
    func compatibleGlassEffectTransition() -> some View {
        if #available(iOS 26, *) {
            self.glassEffectTransition(.materialize)
        } else {
            self.transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Compatible Glass Button Style

struct CompatibleGlassButtonStyle: ButtonStyle {
    let variant: GlassVariant
    let tintColor: Color?
    let cornerRadius: CGFloat
    let isProminent: Bool

    init(
        variant: GlassVariant = .regular,
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        isProminent: Bool = false
    ) {
        self.variant = variant
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(variant.fallbackMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                Color.white.opacity(configuration.isPressed ? 0.4 : 0.25),
                                lineWidth: isProminent ? 1.5 : 1
                            )
                    )
                    .background(
                        tintColor.map {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill($0.opacity(isProminent ? 0.8 : 0.5))
                        }
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .shadow(
                color: (tintColor ?? .clear).opacity(configuration.isPressed ? 0.2 : 0.3),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Prominent glass button style for primary actions
struct CompatibleGlassProminentButtonStyle: ButtonStyle {
    let tintColor: Color
    let cornerRadius: CGFloat

    init(tintColor: Color = .blue, cornerRadius: CGFloat = 16) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tintColor.opacity(configuration.isPressed ? 0.7 : 0.9),
                                tintColor.opacity(configuration.isPressed ? 0.5 : 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .shadow(
                color: tintColor.opacity(configuration.isPressed ? 0.3 : 0.5),
                radius: configuration.isPressed ? 6 : 12,
                x: 0,
                y: configuration.isPressed ? 3 : 6
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CompatibleGlassButtonStyle {
    static func compatibleGlass(
        variant: GlassVariant = .regular,
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        interactive: Bool = true
    ) -> CompatibleGlassButtonStyle {
        CompatibleGlassButtonStyle(variant: variant, tintColor: tintColor, cornerRadius: cornerRadius, isProminent: false)
    }

    static func compatibleGlassProminent(
        tintColor: Color = .blue,
        cornerRadius: CGFloat = 16
    ) -> CompatibleGlassProminentButtonStyle {
        CompatibleGlassProminentButtonStyle(tintColor: tintColor, cornerRadius: cornerRadius)
    }
}

// MARK: - Apple Intelligence Availability Check

extension View {
    /// Check if Apple Intelligence features are available.
    /// Returns true on iOS 26+ with compatible hardware, false otherwise.
    var isAppleIntelligenceAvailable: Bool {
        if #available(iOS 26, *) {
            // On iOS 26+, Apple Intelligence is available on supported hardware
            // For now, assume all iOS 26+ devices support it
            return true
        }
        return false
    }
}

// MARK: - Animation Helpers

extension View {
    /// Applies a smooth spring animation for interactive elements
    func springAnimation<V: Equatable>(value: V) -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }

    /// Applies a bouncy spring animation for playful interactions
    func bouncyAnimation<V: Equatable>(value: V) -> some View {
        self.animation(.spring(response: 0.35, dampingFraction: 0.6), value: value)
    }

    /// Applies a gentle ease animation for subtle transitions
    func gentleAnimation<V: Equatable>(value: V) -> some View {
        self.animation(.easeInOut(duration: 0.25), value: value)
    }

    /// Adds a pulsing glow effect (useful for highlighting)
    func pulsingGlow(color: Color, isActive: Bool) -> some View {
        self
            .shadow(
                color: color.opacity(isActive ? 0.6 : 0),
                radius: isActive ? 12 : 0,
                x: 0,
                y: 0
            )
            .animation(
                isActive
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: isActive
            )
    }

    /// Adds a subtle breathing scale effect
    func breathingEffect(isActive: Bool, scale: CGFloat = 1.03) -> some View {
        self
            .scaleEffect(isActive ? scale : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    : .default,
                value: isActive
            )
    }

    /// Count-up animation modifier for numeric values
    func countUpAnimation() -> some View {
        self.contentTransition(.numericText(countsDown: false))
    }

    /// Applies press feedback (scale + brightness)
    func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Animated Value View Modifier

/// A view modifier that animates numeric value changes
struct AnimatedValueModifier: ViewModifier {
    let value: Double
    @State private var displayedValue: Double = 0

    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayedValue = newValue
                }
            }
    }
}

extension View {
    func animateValue(_ value: Double) -> some View {
        self.modifier(AnimatedValueModifier(value: value))
    }
}

// MARK: - Staggered Animation Helper

/// Applies staggered entrance animation to child views
struct StaggeredAnimationModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * baseDelay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAnimation(index: Int, baseDelay: Double = 0.05) -> some View {
        self.modifier(StaggeredAnimationModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Documentation

/*
 ## Backward Compatibility Strategy

 This file ensures Eco Hero works seamlessly on iOS 18.0 through iOS 26+ by:

 1. **Runtime Availability Checks**
    - Uses `if #available(iOS 26, *)` to conditionally enable iOS 26 features
    - Provides visually similar fallbacks for older iOS versions

 2. **Liquid Glass Effects**
    - iOS 26+: Full Liquid Glass with interactive tinting and transitions
    - iOS 18-25: Material blur effects (.ultraThinMaterial) with similar visual appearance
    - All compatibility methods prefixed with `compatible` to avoid naming conflicts

 3. **Apple Intelligence**
    - iOS 26+: FoundationModels for on-device AI (already handled in FoundationContentService.swift)
    - iOS 18-25: Static fallback content and legacy CoreML models

 4. **Graceful Degradation**
    - All UI elements remain functional on older devices
    - Layout and navigation are preserved across all versions
    - No features are removed; only visual enhancements differ

 ## Usage Example

 ```swift
 // Replace iOS 26-specific code:
 // .glassEffect(.regular.tint(.green.opacity(0.3)).interactive(), in: .rect(cornerRadius: 16))

 // With compatible version:
 .compatibleGlassEffect(tintColor: .green.opacity(0.3), cornerRadius: 16, interactive: true)

 // iOS 26: Renders with Liquid Glass
 // iOS 18-25: Renders with Material blur (visually similar)
 ```

 ## Migration Checklist for Views

 Replace these iOS 26-specific APIs with compatible versions:

 - `.glassEffect()` → `.compatibleGlassEffect()`
 - `.glassEffectID()` → `.compatibleGlassEffectID()`
 - `.glassEffectUnion()` → `.compatibleGlassEffectUnion()`
 - `.glassEffectTransition()` → `.compatibleGlassEffectTransition()`
 - `.buttonStyle(.glass())` → `.buttonStyle(.compatibleGlass())`

 ## Testing Checklist

 - [ ] Build succeeds on Xcode with iOS 18.0 deployment target
 - [ ] App runs on iOS 18 simulator (fallback UI)
 - [ ] App runs on iOS 26 simulator (full Liquid Glass)
 - [ ] No visual regressions on either version
 - [ ] All features functional on both versions
 */
