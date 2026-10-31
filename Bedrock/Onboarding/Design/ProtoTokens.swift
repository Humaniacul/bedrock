import SwiftUI

// The prototype's exact values (Claude Design canvas “Bedrock — Onboarding”,
// P2 · ProtoCore). The onboarding is built 1:1 against it, so every size, line
// height and colour a screen uses lives here, named, and views stay free of
// literals.

// MARK: - Type scale

/// One text style from the prototype: face, size, exact line height, weight and
/// tracking. Sizes follow Dynamic Type through `@ScaledMetric` (see `.ptype`).
struct PType: Sendable {
    enum Face: Sendable { case serif, serifItalic, sans, mono }

    let face: Face
    let size: CGFloat
    let line: CGFloat?
    var weight: Font.Weight = .regular
    var tracking: CGFloat = 0
    var relativeTo: Font.TextStyle = .body

    // Serif (Instrument Serif)
    static let held = PType(face: .serif, size: 52, line: 54, relativeTo: .largeTitle)          // Held. Sealed. You're in.
    static let display = PType(face: .serif, size: 46, line: 48, tracking: -0.5, relativeTo: .largeTitle) // S1, S12
    static let titleL = PType(face: .serif, size: 42, line: 45, tracking: -0.3, relativeTo: .largeTitle) // SP1, SP4
    static let doneTitle = PType(face: .serif, size: 40, line: 44, relativeTo: .largeTitle)     // That's all it is.
    static let title = PType(face: .serif, size: 36, line: 40, relativeTo: .title)
    static let titleM = PType(face: .serif, size: 34, line: 38, relativeTo: .title)             // S10, S13.x, S14, Home
    static let titleItalicM = PType(face: .serifItalic, size: 34, line: 38, relativeTo: .title) // At 2am.
    static let practiceTitle = PType(face: .serif, size: 32, line: 36, relativeTo: .title)
    static let sheetTitle = PType(face: .serif, size: 30, line: 34, relativeTo: .title2)
    static let reflect = PType(face: .serif, size: 28, line: 32, relativeTo: .title2)           // S8 lines, breath label
    static let option = PType(face: .serif, size: 26, line: 30, relativeTo: .title2)            // option cards, plan prices
    static let stepNumeral = PType(face: .serif, size: 26, line: 24, relativeTo: .title2)
    static let stuck = PType(face: .serif, size: 24, line: 28, relativeTo: .title3)
    static let quote = PType(face: .serif, size: 22, line: 27, relativeTo: .title3)             // S10 footer, late night
    static let letter = PType(face: .serif, size: 20, line: 27, relativeTo: .body)
    static let digitHero = PType(face: .serif, size: 56, line: 60, relativeTo: .largeTitle)
    static let pipDigit = PType(face: .serif, size: 50, line: 54, relativeTo: .largeTitle)
    static let stoneWord = PType(face: .serif, size: 26, line: nil, tracking: 3, relativeTo: .title2)
    static let homeStoneWord = PType(face: .serif, size: 23, line: nil, tracking: 3, relativeTo: .title2)

    // Sans (SF Pro)
    static let body = PType(face: .sans, size: 17, line: 24)
    static let bodyM = PType(face: .sans, size: 16, line: 22, relativeTo: .callout)
    static let after = PType(face: .sans, size: 16, line: 23, relativeTo: .callout)
    static let callout = PType(face: .sans, size: 16, line: nil, relativeTo: .callout)
    static let calloutMedium = PType(face: .sans, size: 16, line: nil, weight: .medium, relativeTo: .callout)
    static let calloutSemibold = PType(face: .sans, size: 16, line: nil, weight: .semibold, relativeTo: .callout)
    static let primary = PType(face: .sans, size: 17, line: nil, weight: .semibold, relativeTo: .headline)
    static let rowTitle = PType(face: .sans, size: 17, line: nil, weight: .semibold, relativeTo: .headline)
    static let subhead = PType(face: .sans, size: 15, line: 21, relativeTo: .subheadline)
    static let subheadPlain = PType(face: .sans, size: 15, line: nil, relativeTo: .subheadline)
    static let subheadSemibold = PType(face: .sans, size: 15, line: nil, weight: .semibold, relativeTo: .subheadline)
    static let listItem = PType(face: .sans, size: 15, line: 20, relativeTo: .subheadline)
    static let step = PType(face: .sans, size: 14.5, line: 20, relativeTo: .subheadline)
    static let note = PType(face: .sans, size: 14, line: 20, relativeTo: .footnote)
    static let notePlain = PType(face: .sans, size: 14, line: nil, relativeTo: .footnote)
    static let rowDetail = PType(face: .sans, size: 14, line: 19, relativeTo: .footnote)
    static let footnote = PType(face: .sans, size: 13, line: 18, relativeTo: .footnote)
    static let footnotePlain = PType(face: .sans, size: 13, line: nil, relativeTo: .footnote)
    static let footnoteMedium = PType(face: .sans, size: 13, line: nil, weight: .medium, relativeTo: .footnote)
    static let caption = PType(face: .sans, size: 12.5, line: 17, relativeTo: .caption)
    static let captionPlain = PType(face: .sans, size: 12.5, line: nil, relativeTo: .caption)
    static let small = PType(face: .sans, size: 12, line: nil, relativeTo: .caption)
    static let badge = PType(face: .sans, size: 11.5, line: nil, weight: .semibold, relativeTo: .caption2)
    static let legal = PType(face: .sans, size: 11.5, line: 16, relativeTo: .caption2)
    static let urgeCircle = PType(face: .sans, size: 19, line: 23, weight: .semibold, relativeTo: .title3)
    static let urgeCapsule = PType(face: .sans, size: 18, line: nil, weight: .semibold, relativeTo: .headline)
    static let keypad = PType(face: .sans, size: 28, line: nil, relativeTo: .title)
    static let lockTime = PType(face: .sans, size: 62, line: 66, weight: .semibold, tracking: -1, relativeTo: .largeTitle)
    static let lockDate = PType(face: .sans, size: 13, line: nil, weight: .semibold, relativeTo: .footnote)

    // Mono (SF Mono)
    static let eyebrow = PType(face: .mono, size: 11, line: nil, weight: .medium, tracking: 2, relativeTo: .caption2)
    static let columnHead = PType(face: .mono, size: 11, line: nil, weight: .medium, tracking: 1.6, relativeTo: .caption2)
    static let windowPhase = PType(face: .mono, size: 11, line: nil, tracking: 2, relativeTo: .caption2)
    static let pipPhase = PType(face: .mono, size: 10, line: nil, tracking: 2, relativeTo: .caption2)
    static let stoneDay = PType(face: .mono, size: 10, line: nil, tracking: 3, relativeTo: .caption2)
    static let homeStoneDay = PType(face: .mono, size: 9.5, line: nil, tracking: 3, relativeTo: .caption2)
    static let chapter = PType(face: .mono, size: 9.5, line: nil, tracking: 1.6, relativeTo: .caption2)
    static let previewTag = PType(face: .mono, size: 10, line: nil, tracking: 1.5, relativeTo: .caption2)
    static let stepNumber = PType(face: .mono, size: 14.5, line: 20, relativeTo: .subheadline)
    static let code = PType(face: .mono, size: 28, line: nil, tracking: 3, relativeTo: .title)
}

private struct PTypeModifier: ViewModifier {
    let type: PType
    @ScaledMetric private var size: CGFloat
    @ScaledMetric private var line: CGFloat

    init(_ type: PType) {
        self.type = type
        _size = ScaledMetric(wrappedValue: type.size, relativeTo: type.relativeTo)
        _line = ScaledMetric(wrappedValue: type.line ?? type.size, relativeTo: type.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .tracking(type.tracking)
            .lineHeight(type.line == nil ? nil : .exact(points: line))
    }

    private var font: Font {
        switch type.face {
        case .serif: BedrockFont.serifFixed(size, italic: false)
        case .serifItalic: BedrockFont.serifFixed(size, italic: true)
        case .sans: .system(size: size, weight: type.weight)
        case .mono: .system(size: size, weight: type.weight, design: .monospaced)
        }
    }
}

extension View {
    /// The prototype's text style: font, exact line height, tracking.
    func ptype(_ type: PType) -> some View { modifier(PTypeModifier(type)) }
}

extension BedrockFont {
    /// Instrument Serif at an already-scaled size (New York if it fails to load).
    static func serifFixed(_ size: CGFloat, italic: Bool) -> Font {
        let name = italic ? serifItalicName : serifName
        if UIFont(name: name, size: size) == nil {
            return .system(size: size, design: .serif).italic(italic)
        }
        return .custom(name, fixedSize: size)
    }
}

// MARK: - Colour

extension BedrockColor {
    /// Unselected chip ticks, the dashed “My own word”, link separators.
    static let lineMuted = Color(hex: 0x4A4540)
    /// SP2's “You'll see” card.
    static let emberNight = Color(hex: 0x1F1712)
    /// Controls' glass: a faint white fill, edge and top highlight.
    static let glassFill = Color.white.opacity(0.07)
    static let glassFillSoft = Color.white.opacity(0.06)
    static let glassEdge = Color.white.opacity(0.14)
    static let glassEdgeSoft = Color.white.opacity(0.12)
    static let glassHighlight = Color.white.opacity(0.18)
    /// Behind sheets.
    static let scrim = Color(hex: 0x080706, opacity: 0.62)

    // Primary button: inset highlight and baked drop shadow.
    static let primaryInset = Color(hex: 0xFFECD6, opacity: 0.45)
    static let primaryDrop = Color(hex: 0xC8743C, opacity: 0.22)

    // Stone (the mark, the foundation, bricks).
    static let markHi = Color(hex: 0x4A433C)
    static let markLo = Color(hex: 0x241F1B)
    static let glyphHi = Color(hex: 0x5A524A)
    static let glyphLo = Color(hex: 0x2A2622)
    static let iconStoneHi = Color(hex: 0x6A6058)
    static let iconStoneLo = Color(hex: 0x2E2925)
    static let brickHi = Color(hex: 0x3D3833)
    static let brickMid = Color(hex: 0x2B2723)
    static let brickLo = Color(hex: 0x1F1C19)
    static let homeStoneMid = Color(hex: 0x312C27)
    static let engraving = Color(hex: 0x15120F)

    // Horizon: emberGlow at 0.36, ember at 0.12, nothing.
    static let horizonCore = Color(hex: 0xE8A05C, opacity: 0.36)
    static let horizonMid = Color(hex: 0xC8743C, opacity: 0.12)
    static let bloom = Color(hex: 0xE8A05C, opacity: 0.55)
    static let bloomMid = Color(hex: 0xC8743C, opacity: 0.18)

    // Home: the full-daylight sky.
    static let homeSkyMid = Color(hex: 0x1A130E)
    static let homeSkyLow = Color(hex: 0x3A2212)
    static let homeSun = Color(hex: 0xF6BE84, opacity: 0.42)
    static let homeSunMid = Color(hex: 0xE8A05C, opacity: 0.16)

    // The lock-screen preview (S14 cool, SP3 warm) and its notification.
    static let lockCoolHi = Color(hex: 0x2B3644)
    static let lockCoolMid = Color(hex: 0x18202A)
    static let lockCoolLo = Color(hex: 0x0D1117)
    static let lockWarmHi = Color(hex: 0x33302C)
    static let lockWarmMid = Color(hex: 0x1D1B19)
    static let lockWarmLo = Color(hex: 0x0F0E0D)
    static let notifCool = Color(hex: 0x484E58, opacity: 0.66)
    static let notifWarm = Color(hex: 0x54504C, opacity: 0.66)
    static let notifSecondary = Color(hex: 0xEBEBF5, opacity: 0.6)
    static let iconTileHi = Color(hex: 0x24201C)

    // Blind entry: the floating window.
    static let windowFill = Color(hex: 0x242220, opacity: 0.92)
    static let pipFill = Color(hex: 0x1E1C1A, opacity: 0.95)

    // S15 urge button.
    static let urgeHi = Color(hex: 0xF2B074, opacity: 0.98)
    static let urgeMid = Color(hex: 0xD07C42, opacity: 0.96)
    static let urgeLo = Color(hex: 0x985A30, opacity: 0.96)
    static let urgeBorder = Color(hex: 0xFFD6AA, opacity: 0.45)
    static let urgeInset = Color(hex: 0xFFECD6, opacity: 0.55)
    static let urgeHalo = Color(hex: 0xC8743C, opacity: 0.07)
    static let urgeGlow = Color(hex: 0xC8743C, opacity: 0.30)
    // Home's urge capsule.
    static let capsuleHi = Color(hex: 0xE29258, opacity: 0.98)
    static let capsuleLo = Color(hex: 0xC8743C, opacity: 0.96)
    static let capsuleBorder = Color(hex: 0xFFD6AA, opacity: 0.40)
    static let capsuleInset = Color(hex: 0xFFECD6, opacity: 0.50)
    static let homeCardFill = Color(hex: 0x1A1917, opacity: 0.84)
}

// MARK: - Layout

enum ProtoLayout {
    /// Screen content starts here (reference points from the top of 402 × 874).
    static let topWithChapter: CGFloat = 112
    static let topWithBack: CGFloat = 150
    /// The last control's bottom edge sits this far above the screen's bottom.
    static let bottom: CGFloat = 46
    static let bottomTight: CGFloat = 40
    static let side: CGFloat = 24
    /// Back, Finish later: 20pt from the sides at 92pt; close at 58pt.
    static let controlSide: CGFloat = 20
    static let controlTop: CGFloat = 92
    static let closeTop: CGFloat = 58
    static let previewTagTop: CGFloat = 52
    static let toastTop: CGFloat = 58
    /// Secondary actions sit 6pt under the primary.
    static let buttonGap: CGFloat = 6
}
