import SwiftUI

// Motion tokens (§6.5). Stone is weighty (ease-out + slight overshoot); glass is
// fluid; calm states slow down. Every animated surface must degrade under
// Reduce Motion — use `reduced(_:when:)` rather than applying these raw.

extension Theme {
    enum Motion {
        /// A stratum settling into place — solid, with a small overshoot.
        static let stoneSet = Animation.spring(response: 0.45, dampingFraction: 0.7)
        /// Heavier "thud" for milestones (§6.5).
        static let milestone = Animation.spring(response: 0.62, dampingFraction: 0.6)
        /// Liquid Glass controls morphing/refracting.
        static let glassMorph = Animation.smooth(duration: 0.32)
        /// Intercept / urge-surf — everything slows down.
        static let calm = Animation.easeInOut(duration: 0.9)

        /// Returns `animation`, or `nil` when Reduce Motion is on so the change
        /// applies instantly. Pass `@Environment(\.accessibilityReduceMotion)`.
        static func reduced(_ animation: Animation, when reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : animation
        }
    }
}
