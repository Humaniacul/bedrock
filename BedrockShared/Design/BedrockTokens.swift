//  BedrockTokens.swift
//  Bedrock onboarding · design tokens (Phase 5 V1, revised in Phase 7)
//
//  Suggested home: BedrockShared/, so the app and the DeviceActivity monitor share one palette.
//  The shield extension (BedrockShield) doesn't compile BedrockShared; copy `BedrockColor` there
//  or add BedrockShared to its sources in project.yml.
//
//  Fonts: Instrument Serif (SIL Open Font License 1.1, free to bundle) for emotional lines.
//  SF Pro and SF Mono come from the system. If the bundled serif fails to load, `BedrockFont`
//  falls back to the system serif (New York), so nothing breaks.

import SwiftUI

// MARK: - Colour

public enum BedrockColor {
    // Backgrounds
    /// Obsidian · app and shield background
    public static let bgBase = Color(hex: 0x0E0D0C)
    /// Basalt · cards, sheets, list groups
    public static let bgSurface = Color(hex: 0x1A1917)
    /// Slate · inputs, inner panels, solid secondary buttons, Reduce Transparency fill for glass
    public static let bgRaised = Color(hex: 0x242220)

    // Lines
    /// Seam · dividers, card borders
    public static let lineSubtle = Color(hex: 0x2A2724)
    /// Fault · unselected chip borders, empty nodes
    public static let lineStrong = Color(hex: 0x3A3530)

    // Ink
    /// Chalk · headlines, body, primary labels (17.1:1 on bgBase)
    public static let inkPrimary = Color(hex: 0xF4F1EC)
    /// Limestone · supporting text (11.1:1)
    public static let inkSecondary = Color(hex: 0xC9C3BA)
    /// Ash · eyebrows, captions, legal, placeholders (5.9:1). Replaces the old #7D7770, which failed AA.
    public static let inkTertiary = Color(hex: 0x948D85)
    /// Dust · disabled labels only. Never meaning, never placeholders (3.4:1).
    public static let inkDisabled = Color(hex: 0x6B655F)

    // Ember
    /// Ember · primary buttons, selection, the one key thing
    public static let ember = Color(hex: 0xC8743C)
    /// Glow · ember text, icons, highlights (8.9:1)
    public static let emberGlow = Color(hex: 0xE8A05C)
    /// Kiln · fills behind Chalk text, tags, selected card fill tint
    public static let emberDeep = Color(hex: 0x8A5530)
    /// Molten · the carve flash, 300ms at most
    public static let emberHot = Color(hex: 0xF6BE84)
    /// Selected card / chip fill
    public static let emberWash = Color(hex: 0x2A1A10)

    // Stone (illustration only)
    public static let stoneLight = Color(hex: 0x46403A)
    public static let stoneMid = Color(hex: 0x2F2A26)
    public static let stoneDark = Color(hex: 0x1C1916)

    /// Primary button fill: vertical gradient, top 0.97 → bottom 0.95 alpha.
    public static let primaryFill = LinearGradient(
        colors: [Color(hex: 0xDE8C52).opacity(0.97), Color(hex: 0xC8743C).opacity(0.95)],
        startPoint: .top, endPoint: .bottom)
    /// Label colour on the primary button (5.6:1 on Ember).
    public static let onEmber = bgBase
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

// MARK: - Dawn (horizon glow opacity per screen)

/// The horizon rises one step per screen and peaks at the paywall. Animate with `BedrockMotion.dawn`.
public enum Dawn {
    public static func level(for screen: OnboardingScreen) -> Double {
        switch screen {
        case .s1: return 0
        case .s2, .s2d, .b2, .b9: return 0.10
        case .s3: return 0.18          // 0.26 once the wall is up
        case .s4: return 0.26
        case .s5: return 0.32
        case .s6: return 0.38
        case .s7: return 0.44
        case .s8: return 0.50
        case .s9: return 0.40          // the door: the story's low point
        case .s10: return 0.58
        case .s11: return 0.64
        case .s12, .s12u: return 1.0   // first light
        case .siwa, .s14: return 0.90
        case .strictSetup: return 0.85
        case .sealed: return 0.92
        case .s15: return 0.95
        case .home: return 1.0
        case .sp1: return 0.55
        case .sp2: return 0.60
        case .sp3: return 0.65
        case .sp4: return 0.75
        }
    }
}

/// Screen groups for Dawn levels. `OnboardingAnalytics.ScreenID` is the finer-grained list used for events;
/// if your router has its own screen enum, map it to both (or merge them into one).
public enum OnboardingScreen: String, CaseIterable {
    case s1, s2, s2d = "s2_d", b2, b9, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s12u, siwa
    case strictSetup = "s13", sealed = "s13_6", s14, s15, home, sp1, sp2, sp3, sp4
}

// MARK: - Space and radius

public enum Space {
    public static let s1: CGFloat = 4    // icon to label
    public static let s2: CGFloat = 8    // chip gap, tight stacks
    public static let s3: CGFloat = 12   // eyebrow to headline
    public static let s4: CGFloat = 16   // headline to body
    public static let s5: CGFloat = 20   // card padding (compact)
    public static let s6: CGFloat = 24   // screen margins
    public static let s7: CGFloat = 32   // body to content
    public static let s8: CGFloat = 40   // section breaks
    public static let s9: CGFloat = 56   // primary button height
    public static let s10: CGFloat = 72  // hero breathing room

    /// Primary button sits this far above the home indicator.
    public static let primaryBottom: CGFloat = 46
    /// Content starts below the chapter bar (58pt) and back row (92–136pt).
    public static let contentTopWithChapter: CGFloat = 112
    public static let contentTopWithBack: CGFloat = 150
}

public enum Radius {
    public static let xs: CGFloat = 8       // tags
    public static let sm: CGFloat = 10      // stones, small chips
    public static let md: CGFloat = 14      // inputs, inner cards, chips
    public static let lg: CGFloat = 20      // cards
    public static let capsule: CGFloat = 28 // 56pt buttons
    public static let sheet: CGFloat = 34   // sheet corners
}

// MARK: - Type

public enum BedrockFont {
    /// PostScript name of the bundled serif. Add InstrumentSerif-Regular.ttf and -Italic.ttf
    /// to the app target and list them under UIAppFonts in Info.plist.
    public static let serifName = "InstrumentSerif-Regular"
    public static let serifItalicName = "InstrumentSerif-Italic"

    static func serif(_ size: CGFloat, relativeTo style: Font.TextStyle, italic: Bool = false) -> Font {
        let name = italic ? serifItalicName : serifName
        #if canImport(UIKit)
        if UIFont(name: name, size: size) == nil {
            return .system(size: size, design: .serif).italic(italic) // New York fallback
        }
        #endif
        return .custom(name, size: size, relativeTo: style)
    }

    /// Display XL · 44/46, tracking −0.5 · S1, S12, Sealed
    public static let displayXL = serif(44, relativeTo: .largeTitle)
    /// Title · 36/40 · most screen headlines
    public static let title = serif(36, relativeTo: .title)
    /// Title S · 30/34 · the S8 reflection lines, sheet titles
    public static let titleS = serif(30, relativeTo: .title2)
    /// Accent italic · 34/38 in Glow · “At 2am.”
    public static let accentItalic = serif(34, relativeTo: .title, italic: true)

    /// Headline · SF Pro Semibold 17/22
    public static let headline = Font.headline
    /// Body · SF Pro 17/24
    public static let body = Font.body
    /// Subhead · SF Pro 15/20
    public static let subhead = Font.subheadline
    /// Footnote · SF Pro 13/18 · legal, captions
    public static let footnote = Font.footnote
    /// Eyebrow · SF Mono Medium 11/14, tracking +2, uppercase
    public static let eyebrow = Font.system(.caption2, design: .monospaced).weight(.medium)
    /// Digits · SF Mono 15, tabular
    public static let digits = Font.system(.body, design: .monospaced).monospacedDigit()
}

public struct LineSpec: Sendable {
    public let tracking: CGFloat
    public let lineSpacing: CGFloat
}

public enum BedrockLine {
    public static let displayXL = LineSpec(tracking: -0.5, lineSpacing: 2)
    public static let title = LineSpec(tracking: 0, lineSpacing: 4)
    public static let titleS = LineSpec(tracking: 0, lineSpacing: 4)
    public static let body = LineSpec(tracking: 0, lineSpacing: 7)   // 17pt on a 24pt line
    public static let eyebrow = LineSpec(tracking: 2, lineSpacing: 3)
}

public extension View {
    /// Eyebrow style: mono, uppercase, wide tracking, Ash.
    func bedrockEyebrow(color: Color = BedrockColor.inkTertiary) -> some View {
        self.font(BedrockFont.eyebrow)
            .tracking(BedrockLine.eyebrow.tracking)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

// MARK: - Glass

/// Liquid Glass is used on controls only: back, close, Finish later, the hold control, the floating digit window.
/// Never on content, never glass on glass. With Reduce Transparency, fall back to a solid fill.
/// (Named `BedrockControlGlass` because the app already has a `BedrockGlass` modifier in GlassKit.)
public struct BedrockControlGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: AnyShape

    public func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(BedrockColor.bgRaised, in: shape)
                .overlay(shape.stroke(BedrockColor.lineStrong, lineWidth: 1))
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
}

public extension View {
    func bedrockGlass<S: Shape>(_ shape: S) -> some View {
        modifier(BedrockControlGlass(shape: AnyShape(shape)))
    }
}
