import SwiftUI

// Typography (§6.2). Body/labels use system text styles so they scale with
// Dynamic Type automatically. Hero numerals (the carved day count) use the
// `Size` constants together with `@ScaledMetric(relativeTo:)` at the call site,
// so they scale too — see `FoundationView`.
//
// TODO §6.2: swap the display face to Geist / Inter Tight once the font files
// are bundled. Centralize the swap here — change `display*` only.

extension Theme {
    enum Typography {
        // Display — confident, grounded. (System heavy as a placeholder for Geist.)
        // Display and titles share onboarding's serif (Instrument Serif), so the
        // app reads as the same world as First Light.
        static let display  = BedrockFont.serif(36, relativeTo: .largeTitle)
        static let title    = BedrockFont.serif(26, relativeTo: .title2)
        static let headline = Font.system(.headline)
        static let body     = Font.system(.body)
        static let callout  = Font.system(.callout)
        static let caption  = Font.system(.caption)

        // Counter / data — carved and measured (§6.2).
        static let mono        = Font.system(.body, design: .monospaced)
        static let monoCaption = Font.system(.caption, design: .monospaced).weight(.medium)

        /// Base point sizes for hero numerals. Use with
        /// `@ScaledMetric(relativeTo: .largeTitle)` so they honor Dynamic Type.
        enum Size {
            static let counter: CGFloat   = 76 // the Foundation day count
            static let displayXL: CGFloat = 56 // onboarding "DAY 47" moments
            static let display: CGFloat   = 36
        }
    }
}
