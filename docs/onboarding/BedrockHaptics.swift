//  BedrockHaptics.swift
//  Bedrock onboarding · haptic map (Phase 5 V2)
//
//  A haptic always pairs with a visible change. Never on: a declined permission, the paywall
//  appearing, back navigation, routine primary taps. Onboarding ships no sounds.
//  If the device has no haptic engine or the user turned System Haptics off, every call is a no-op.

import UIKit
import CoreHaptics

@MainActor
public enum BedrockHaptics {

    // MARK: The map

    /// Chip or option selected (S5–S7 chips, S11 cards, S12 plan cards).
    public static func select() { UISelectionFeedbackGenerator().selectionChanged() }

    /// A check appears (S3 rows as each write returns).
    public static func check() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }

    /// A stone lands (S3 courses, S13.6 keystone).
    public static func stoneLands() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4) }

    /// S10 path: each node lights.
    public static func pathNode() { UISelectionFeedbackGenerator().selectionChanged() }

    /// Lock: wall up (S3), Held (S4), stone set (S8), Sealed (S13.6). Heavy, then success 80ms later.
    public static func lock() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Urge button pressed (S15, Home).
    public static func urge() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }

    /// Breath phase changes (S15, Intercept): a soft transient 0.25 / 0.1.
    public static func breathPhase() { HoldRamp.shared.transient(intensity: 0.25, sharpness: 0.1) }

    /// Wrong digit in the practice run (S13.3B).
    public static func wrongDigit() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5) }

    /// Purchase succeeds (S12 → “You’re in.”).
    public static func purchased() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

    /// A step fails and needs action (S3 write failed, S13.7A, S13.7B).
    public static func needsAction() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    // None: the wall test opening Safari, a declined permission, the paywall appearing, back.
}

// MARK: - S8 HoldRamp (Core Haptics)

/// Continuous haptic over the 1.4s hold: intensity 0.2 → 0.8, sharpness 0.3 → 0.6.
/// On completion: transient 1.0 / 0.4 (then `BedrockHaptics.lock()` handles the success tap).
/// On early release: stop, transient 0.3 / 0.2.
/// Start the engine when S8 appears; stop it when S8 disappears.
@MainActor
public final class HoldRamp {
    public static let shared = HoldRamp()

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    public func prepare() {
        guard supportsHaptics, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in try? self?.engine?.start() }
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    public func stopEngine() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop()
        engine = nil
    }

    /// Call on press-down.
    public func begin(duration: TimeInterval = BedrockTiming.holdToSet) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0, duration: duration)
        let intensity = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [.init(relativeTime: 0, value: 0.2), .init(relativeTime: duration, value: 0.8)],
            relativeTime: 0)
        let sharpness = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [.init(relativeTime: 0, value: 0.3), .init(relativeTime: duration, value: 0.6)],
            relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [intensity, sharpness])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            player = nil
        }
    }

    /// Call when the ring completes.
    public func complete() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        transient(intensity: 1.0, sharpness: 0.4)
    }

    /// Call on early release.
    public func cancel() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        transient(intensity: 0.3, sharpness: 0.2)
    }

    public func transient(intensity: Float, sharpness: Float) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let one = try? engine.makePlayer(with: pattern) {
            try? one.start(atTime: CHHapticTimeImmediate)
        }
    }
}
