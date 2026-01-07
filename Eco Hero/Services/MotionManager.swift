//
//  MotionManager.swift
//  Eco Hero
//
//  Created by Claude on 1/7/26.
//

import SwiftUI
import CoreMotion

/// Shared motion manager service for gyroscope-responsive effects
/// Apple recommends using a single CMMotionManager per app
@Observable
final class MotionManager {
    static let shared = MotionManager()
    
    // MARK: - Published Motion Data
    
    /// Horizontal tilt (-1 to 1, negative = left, positive = right)
    private(set) var tiltX: CGFloat = 0
    
    /// Vertical tilt (-1 to 1, negative = back, positive = forward)
    private(set) var tiltY: CGFloat = 0
    
    /// Current rotation rate on Z axis (radians/second)
    private(set) var rotationRateZ: CGFloat = 0
    
    /// Combined acceleration magnitude (shake detection)
    private(set) var accelerationMagnitude: CGFloat = 0
    
    /// Whether device motion is available
    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }
    
    // MARK: - Private Properties
    
    private let motionManager = CMMotionManager()
    private var activeObservers = 0
    private let updateInterval: TimeInterval = 0.033 // ~30Hz for smooth animations
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start receiving motion updates. Call from onAppear.
    func startUpdates() {
        activeObservers += 1
        
        guard activeObservers == 1 else { return }
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Smooth tilt values using gravity
            withAnimation(.easeOut(duration: 0.1)) {
                self.tiltX = CGFloat(motion.gravity.x)
                self.tiltY = CGFloat(motion.gravity.y)
            }
            
            // Rotation rate for spinning effects
            self.rotationRateZ = CGFloat(motion.rotationRate.z)
            
            // Acceleration magnitude for shake detection
            let accel = motion.userAcceleration
            self.accelerationMagnitude = CGFloat(
                sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            )
        }
    }
    
    /// Stop receiving motion updates. Call from onDisappear.
    func stopUpdates() {
        activeObservers = max(0, activeObservers - 1)
        
        guard activeObservers == 0 else { return }
        motionManager.stopDeviceMotionUpdates()
        
        // Reset values when stopped
        withAnimation(.easeOut(duration: 0.3)) {
            tiltX = 0
            tiltY = 0
            rotationRateZ = 0
            accelerationMagnitude = 0
        }
    }
    
    // MARK: - Utility Computed Properties
    
    /// Normalized tilt angle (0 to 1 based on combined tilt)
    var tiltMagnitude: CGFloat {
        sqrt(tiltX * tiltX + tiltY * tiltY)
    }
    
    /// Whether device was recently shaken
    var isShaking: Bool {
        accelerationMagnitude > 1.5
    }
    
    /// Whether device is experiencing moderate motion
    var isMoving: Bool {
        accelerationMagnitude > 0.3
    }
}

// MARK: - View Modifier for Easy Integration

struct MotionAwareModifier: ViewModifier {
    let motion = MotionManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                motion.startUpdates()
            }
            .onDisappear {
                motion.stopUpdates()
            }
    }
}

extension View {
    /// Makes this view motion-aware by starting/stopping motion updates
    func motionAware() -> some View {
        modifier(MotionAwareModifier())
    }
}
