import SwiftUI

// Component values from COMPONENTS.md and SPEC.md that the reference token files
// (BedrockTokens / BedrockMotion) don't carry, so views stay free of literals.
// Anything marked ASSUMED isn't stated in the handoff: it's a placeholder to check
// against the prototype on the design canvas, and the only place to change it.

// MARK: - Colour

extension BedrockColor {
    /// PrimaryButton border · rgba(255, 214, 170, 0.35) (COMPONENTS.md).
    static let primaryBorder = Color(hex: 0xFFD6AA, opacity: 0.35)
    /// PrimaryButton inner top highlight · ASSUMED: the border hue, fading out by mid-height.
    static let primaryHighlight = Color(hex: 0xFFD6AA, opacity: 0.30)
    /// PrimaryButton disabled fill · #1F1C1A (COMPONENTS.md).
    static let primaryDisabledFill = Color(hex: 0x1F1C1A)
    /// PrimaryButton baked ember shadow · ASSUMED opacity.
    static let primaryShadow = ember.opacity(0.35)
    /// HorizonGlow core · ASSUMED: ember at 55%, fading to clear. Replaced by the
    /// `HorizonGlow` image asset when one is added (ASSETS.md).
    static let horizonCore = ember.opacity(0.55)
}

// MARK: - Size

enum BedrockSize {
    // Scaffold anchors, in points from the top of the 402 × 874 reference
    // (iPhone 17 Pro, 62pt top safe area). On other iPhones they move with the
    // safe area so their relationship to the Dynamic Island holds.
    static let referenceTopInset: CGFloat = 62
    /// Used only when there's no safe area at all (a fixed-size canvas preview).
    static let referenceBottomInset: CGFloat = 34
    static let chapterBarTop: CGFloat = 58
    static let backRowTop: CGFloat = 92

    // ChapterBar (COMPONENTS.md)
    static let chapterTrack: CGFloat = 3
    static let chapterLabel: CGFloat = 9.5

    // Buttons (COMPONENTS.md)
    static let primaryHeight: CGFloat = Space.s9   // 56
    static let textButtonHeight: CGFloat = 44
    static let linkHitHeight: CGFloat = 40
    static let linkText: CGFloat = 14
    static let circleButton: CGFloat = 44
    static let finishLaterHeight: CGFloat = 44
    /// PrimaryButton baked shadow · ASSUMED radius and drop.
    static let primaryShadowRadius: CGFloat = 18
    static let primaryShadowY: CGFloat = 10

    // ChoiceChip (COMPONENTS.md: “min 52pt”, “10pt gaps”; Space.s2 is 8, the spec says 10)
    static let chipMinHeight: CGFloat = 52
    static let chipGridGap: CGFloat = 10

    // BedrockSheet (COMPONENTS.md)
    static let grabber = CGSize(width: 36, height: 5)

    // Toast (COMPONENTS.md, SPEC.md RESUME)
    static let toastDrop: CGFloat = 12

    // Background (ASSETS.md)
    static let horizonGlow = CGSize(width: 724, height: 560)
    static let noiseOpacity: Double = 0.06

    /// The five-point stone mark (PrivacyCover, S1, SP1) · ASSUMED size.
    static let stoneMark = CGSize(width: 34, height: 50)
}

// MARK: - Type

extension BedrockFont {
    /// TextButton · SF Pro 16 (COMPONENTS.md). Callout is 16pt and scales with Dynamic Type.
    static let textButton = Font.callout
    /// FinishLaterButton · ASSUMED: Subhead.
    static let finishLater = Font.subheadline.weight(.medium)
    /// ChoiceChip label · ASSUMED: Subhead Medium (two columns of 172pt at 402 wide).
    static let chip = Font.subheadline.weight(.medium)
    /// Toast · ASSUMED: Subhead.
    static let toast = Font.subheadline

    /// ChapterBar label · SF Mono 9.5pt (COMPONENTS.md); Medium weight ASSUMED, matching
    /// the eyebrow. Pass the size through `@ScaledMetric` so it follows Dynamic Type.
    static func chapterLabel(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// LinkButton · SF Pro 14pt (COMPONENTS.md). Pass the size through `@ScaledMetric`.
    static func link(size: CGFloat) -> Font {
        .system(size: size)
    }
}

extension BedrockLine {
    /// ChapterBar labels · +1.6 tracking (COMPONENTS.md).
    static let chapterLabel = LineSpec(tracking: 1.6, lineSpacing: 0)
}

// MARK: - Motion

extension BedrockMotion {
    /// ChapterBar fill · 0.6s ease (COMPONENTS.md). Progress-only, so it stays under
    /// Reduce Motion, like Dawn and Drain in `resolve(_:reduceMotion:)`.
    static let chapterFill = Animation.easeInOut(duration: 0.6)
    /// ChoiceChip selection · border and fill in 0.2s (COMPONENTS.md).
    static let chipColour = Animation.easeInOut(duration: 0.2)
    /// ChoiceChip selection bump · scale 0.96 → 1, spring 0.25 / 0.7 (SPEC.md S5). None under Reduce Motion.
    static let chipBump = Animation.spring(response: 0.25, dampingFraction: 0.7)
    static let chipBumpScale: CGFloat = 0.96
    /// Length of `reducedFade` (0.2s), which also covers `riseOut` (0.18s): how long to
    /// wait before removing a view that's fading out (Toast).
    static let reducedFadeDuration: Double = 0.2
    /// Button press feedback · ASSUMED; answers inside the 100ms the motion rules allow.
    static let press = Animation.easeOut(duration: 0.1)
    static let pressedOpacity: Double = 0.85
}

// MARK: - Screens

extension ScreenID {
    /// The Dawn group for this screen (BedrockTokens keeps a coarser screen list).
    var dawnScreen: OnboardingScreen {
        switch self {
        case .s1, .r1: .s1
        case .s2: .s2
        case .s2_d: .s2d
        case .b2: .b2
        case .b9: .b9
        case .s3: .s3
        case .s4: .s4
        case .s5: .s5
        case .s6: .s6
        case .s7: .s7
        case .s8: .s8
        case .s9: .s9
        case .s10: .s10
        case .s11: .s11
        case .s12: .s12
        case .s12u: .s12u
        case .siwa: .siwa
        case .s13_1, .s13_2b, .s13_3b, .s13_4b, .s13_5a, .s13_5b, .s13_7a, .s13_7b, .s13_2p: .strictSetup
        case .s13_6: .sealed
        case .s14: .s14
        case .s15: .s15
        case .home: .home
        case .sp1: .sp1
        case .sp2: .sp2
        case .sp3: .sp3
        case .sp4: .sp4
        }
    }

    /// S5–S8, S13.1 and Home show `PrivacyCover` in the app switcher (SPEC.md rules).
    var usesPrivacyCover: Bool {
        switch self {
        case .s5, .s6, .s7, .s8, .s13_1, .home: true
        default: false
        }
    }
}

extension Chapter {
    /// The four chapters the ChapterBar shows, in order.
    static var barChapters: [Chapter] { [.wall, .you, .lock, .begin] }

    var barLabelKey: String? {
        switch self {
        case .wall: "onb.common.chapter_wall"
        case .you: "onb.common.chapter_you"
        case .lock: "onb.common.chapter_lock"
        case .begin: "onb.common.chapter_begin"
        case .branch, .supporter: nil
        }
    }
}
