import SwiftUI

// MARK: - Theme namespace
// The single source of truth for Bedrock styling. Screens never reference raw
// colors/fonts — they go through `Theme` and `GlassKit`. (Brief §6)

enum Theme {}

// MARK: - Raw palette (§6.1, grounded in real geology)

extension Color {
    /// Hex literal initializer, e.g. `Color(hex: 0xE2683B)`.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// The raw geology palette. Prefer the semantic roles in `Theme` below; reach
/// for these only when a role doesn't exist yet.
enum BedrockColor {
    static let obsidian = Color(hex: 0x0E0D0C) // deepest base / app background (warm near-black, never pure)
    static let basalt   = Color(hex: 0x1A1917) // raised surfaces, sheets
    static let slate    = Color(hex: 0x242220) // cards, strata lines
    static let ash      = Color(hex: 0x7D7770) // secondary text, dividers, inactive
    static let quartz   = Color(hex: 0xF4F1EC) // primary text (bone white — never clinical #FFF)
    static let ember    = Color(hex: 0xC8743C) // primary accent: molten core / progress
    static let emberGlow = Color(hex: 0xE8A05C) // accent glow — highlights, warmed words
    static let bronze   = Color(hex: 0xB5652E) // pressed/secondary states, milestone metal
    static let mineral  = Color(hex: 0x5E8A8F) // cool counterpoint — calm/clarity states ONLY
}

// MARK: - Semantic roles

extension Theme {
    static let background    = BedrockColor.obsidian
    static let surface       = BedrockColor.basalt   // solid surface (also the Reduce-Transparency glass fallback)
    static let surfaceRaised = BedrockColor.slate
    static let textPrimary   = BedrockColor.quartz
    static let textSecondary = BedrockColor.ash
    static let hairline      = Color(hex: 0x2A2724)
    static let accent        = BedrockColor.ember
    static let accentPressed = BedrockColor.bronze
    static let onAccent      = BedrockColor.obsidian // text/icon sitting on an ember fill
    /// Calm/clarity register — used only in Intercept / urge-surf moments (§6.1).
    static let calm          = BedrockColor.mineral
}
