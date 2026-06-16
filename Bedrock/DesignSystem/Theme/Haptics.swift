import UIKit

// Haptics (§6.5). "Stone is weighty" — laying a stratum should *feel* like
// something solid locking in.
//
// TODO: upgrade the `set`/`milestone` events to bespoke CoreHaptics patterns
// (sharp attack + low rumble) for the hero moments. Impact generators are the
// Phase 0 placeholder. All haptics route through here — never call generators
// directly from a screen.

@MainActor
enum BedrockHaptics {
    /// A stratum settling into the Foundation — a deep, solid "set."
    static func set() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.9)
    }

    /// A milestone layer sliding home — heavier thud (§6.5).
    static func milestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft pulse for calm states (Intercept breathing).
    static func calm() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.5)
    }

    /// Light tick for option selection during the quiz / pickers.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
