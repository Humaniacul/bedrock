import SwiftUI

// MARK: - Theme namespace
// The single source of truth for Bedrock styling. Screens never reference raw
// colors/fonts — they go through `Theme` and `GlassKit`. (Brief §6)

enum Theme {}

// MARK: - Raw palette (§6.1, grounded in real geology)

// `BedrockColor` and `Color(hex:opacity:)` are declared in
// BedrockShared/Design/BedrockTokens.swift (the onboarding token set, shared
// with the monitor and shield). These are the pre-onboarding names the rest of
// the app still uses, kept at their existing values. `ember` and `emberGlow`
// come straight from the shared set (same values).
extension BedrockColor {
    static let obsidian = Color(hex: 0x0E0D0C) // deepest base / app background (warm near-black, never pure)
    static let basalt   = Color(hex: 0x1A1917) // raised surfaces, sheets
    static let slate    = Color(hex: 0x242220) // cards, strata lines
    static let ash      = Color(hex: 0x7D7770) // secondary text, dividers, inactive
    static let quartz   = Color(hex: 0xF4F1EC) // primary text (bone white — never clinical #FFF)
    static let bronze   = Color(hex: 0xB5652E) // pressed/secondary states, milestone metal
    static let mineral  = Color(hex: 0x5E8A8F) // cool counterpoint — calm/clarity states ONLY
}

// MARK: - Semantic roles

extension Theme {
    static let background    = BedrockColor.obsidian
    static let surface       = BedrockColor.basalt   // solid surface (also the Reduce-Transparency glass fallback)
    static let surfaceRaised = BedrockColor.slate
    static let textPrimary   = BedrockColor.quartz
    /// Limestone, as onboarding's supporting text. (The old Ash, #7D7770, failed AA.)
    static let textSecondary = BedrockColor.inkSecondary
    static let hairline      = Color(hex: 0x2A2724)
    static let accent        = BedrockColor.ember
    static let accentPressed = BedrockColor.bronze
    static let onAccent      = BedrockColor.obsidian // text/icon sitting on an ember fill
    /// Calm/clarity register — used only in Intercept / urge-surf moments (§6.1).
    static let calm          = BedrockColor.mineral
}
