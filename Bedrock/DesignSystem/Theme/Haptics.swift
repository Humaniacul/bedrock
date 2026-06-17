import UIKit
import CoreHaptics

// Haptics (§6.5). "Stone is weighty" — laying a stratum should *feel* like
// something solid locking in. Hero moments use bespoke Core Haptics patterns
// (a fine chisel tick, a forging ramp, a stone-set thud); light ticks stay on
// the cheaper feedback generators. Everything routes through here — screens
// never touch generators or the engine directly. Falls back gracefully where
// haptics are unsupported (e.g. the Simulator).
@MainActor
enum BedrockHaptics {
    // MARK: - Light feedback (generators)

    /// Light tick for option selection during the quiz / pickers.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Soft pulse for calm states (Intercept breathing).
    static func calm() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    // MARK: - Hero patterns (Core Haptics, with fallback)

    /// A fine chisel tick — sharp, low intensity. One per carved glyph.
    static func chiselTick() {
        guard let engine = sharedEngine else {
            UISelectionFeedbackGenerator().selectionChanged()
            return
        }
        play(on: engine, events: [transientEvent(intensity: 0.45, sharpness: 0.85, at: 0)])
    }

    /// A stratum settling into the Foundation — a deep, solid "set."
    static func set() {
        guard let engine = sharedEngine else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
            return
        }
        play(on: engine, events: [transientEvent(intensity: 0.9, sharpness: 0.5, at: 0)])
    }

    /// A milestone layer / stone locking home — heavy thud + low rumble (§6.5).
    static func milestone() { stoneSet() }

    /// The oath stone locking into the monolith — the heaviest moment in the app.
    static func stoneSet() {
        guard let engine = sharedEngine else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        play(on: engine, events: [
            transientEvent(intensity: 1.0, sharpness: 0.6, at: 0),
            continuousEvent(intensity: 0.7, sharpness: 0.1, at: 0, duration: 0.28),
        ])
    }

    /// A rising "forging" rumble over `duration`, for the press-and-hold oath.
    /// Climax with `stoneSet()` when the hold completes; call `stopRamp()` if
    /// the user releases early.
    static func oathRamp(duration: Double) {
        guard let engine = sharedEngine else { return }
        let event = continuousEvent(intensity: 0.35, sharpness: 0.2, at: 0, duration: duration)
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.15),
                .init(relativeTime: duration * 0.7, value: 0.6),
                .init(relativeTime: duration, value: 1.0),
            ],
            relativeTime: 0)
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            activeRampPlayer = player
        } catch { /* best-effort */ }
    }

    static func stopRamp() {
        try? activeRampPlayer?.stop(atTime: CHHapticTimeImmediate)
        activeRampPlayer = nil
    }

    // MARK: - Engine

    private static var activeRampPlayer: CHHapticPatternPlayer?

    private static let sharedEngine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        let engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = true
        engine?.resetHandler = { [weak engine] in try? engine?.start() }
        try? engine?.start()
        return engine
    }()

    private static func transientEvent(intensity: Float, sharpness: Float, at time: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }

    private static func continuousEvent(intensity: Float, sharpness: Float, at time: TimeInterval, duration: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time, duration: duration)
    }

    private static func play(on engine: CHHapticEngine, events: [CHHapticEvent]) {
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { /* best-effort */ }
    }
}
