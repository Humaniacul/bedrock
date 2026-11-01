import SwiftUI

// Component values from COMPONENTS.md and SPEC.md that the reference token files
// (BedrockTokens / BedrockMotion) don't carry, so views stay free of literals.
// Anything marked ASSUMED isn't stated in the handoff: it's a placeholder to check
// against the prototype on the design canvas, and the only place to change it.

// MARK: - Colour

extension BedrockColor {
    /// PrimaryButton border · rgba(255, 214, 170, 0.35) (COMPONENTS.md).
    static let primaryBorder = Color(hex: 0xFFD6AA, opacity: 0.35)
    /// PrimaryButton disabled fill · #1F1C1A (COMPONENTS.md).
    static let primaryDisabledFill = Color(hex: 0x1F1C1A)
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

    // ChapterBar (COMPONENTS.md)
    static let chapterTrack: CGFloat = 3

    // Buttons (COMPONENTS.md)
    static let primaryHeight: CGFloat = Space.s9   // 56
    static let textButtonHeight: CGFloat = 44
    static let linkHitHeight: CGFloat = 40
    static let circleButton: CGFloat = 44
    static let finishLaterHeight: CGFloat = 44

    // ChoiceChip (COMPONENTS.md: “min 52pt”, “10pt gaps”; Space.s2 is 8, the spec says 10)
    static let chipMinHeight: CGFloat = 52
    static let chipGridGap: CGFloat = 10

    // BedrockSheet (COMPONENTS.md)
    static let grabber = CGSize(width: 36, height: 5)

    // Toast (COMPONENTS.md, SPEC.md RESUME)
    static let toastDrop: CGFloat = 12

    // Background (ASSETS.md)
    static let horizonWidthFactor: CGFloat = 1.8
    static let horizonHeight: CGFloat = 560
    static let horizonLift: CGFloat = 20
    static let noiseOpacity: Double = 0.06

    // StoneView (the prototype: 148 × 218 on S8, 132 × 194 on Home)
    static let stoneRegular = CGSize(width: 148, height: 218)
    static let stoneHome = CGSize(width: 132, height: 194)
    static let stoneHoverOpacity: Double = 0.45
    /// S8: before it's set, the stone hovers 12pt up.
    static let stoneHoverLift: CGFloat = 12

    // HoldToSetControl (SPEC.md S8)
    static let holdControl: CGFloat = 84
    /// How far a finger can drift and still be holding · ASSUMED.
    static let holdSlop: CGFloat = 40

    // WallView (SPEC.md S3: 322 × 150pt; COMPONENTS.md: 76pt stones, 35pt halves, 46pt tall, 6pt gaps)
    static let wallWidth: CGFloat = 322
    static let wallStone = CGSize(width: 76, height: 46)
    static let wallGap: CGFloat = 6
    static let wallDip: CGFloat = 3
    /// S13.6: the keystone drops 40pt into the top course.
    static let keystoneDrop: CGFloat = 40

    // DoorIllustration (SPEC.md S9)

    // GauntletPath (SPEC.md S10)
    static let pathNode: CGFloat = 12

    // Cards (SPEC.md S11, S12, Home)
    static let planCardMinHeight: CGFloat = 132
    static let planCardRadius: CGFloat = 18

    // Moments (SPEC.md S14, S15)
    static let lockScreenPreview = CGSize(width: 300, height: 232)
    static let urgeCircle: CGFloat = 168
    static let urgeCapsule: CGFloat = 64
    static let breathMinScale: CGFloat = 0.56

    // Blind entry (SPEC.md S13.3B–S13.5A) · ASSUMED sizes for the floating window.
    /// Pixel scale for the Picture in Picture frames.
    static let digitWindowScale: CGFloat = 3

    // Screens
    /// S7: one word, up to 14 characters.
    static let wordMaxLength = 14
    /// S2 / S2-D / B2: the Screen Time card.
    static let permissionCard = CGSize(width: 220, height: 150)
    /// B9: the Preview tag sits at 52pt on the reference, this far above the top
    /// safe-area edge (62pt).
    static let previewTagLift: CGFloat = 10
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
    /// Button press feedback · ASSUMED; answers inside the 100ms the motion rules allow.
    static let press = Animation.easeOut(duration: 0.1)
    static let pressedOpacity: Double = 0.85
    /// S8: the stone drops into place · Lock (0.28 / 0.9).
    static let stoneDrop = lock
    /// S11: a selected card Settles 0.98 → 1.
    static let cardSelectScale: CGFloat = 0.98
    /// S12: the CTA label crossfades in 160ms.
    static let ctaCrossfade = Animation.easeInOut(duration: 0.16)
    /// S2-D, S4: copy crossfades 240ms between states.
    static let stateCrossfade = Animation.easeInOut(duration: 0.24)
}

extension BedrockTiming {
    /// S8: the carve starts 300ms after the stone is set; “DAY 1” at 1.4s; text at 2.6s.
    static let stoneCarveDelay: Double = 0.3
    /// S8: a press shorter than this counts as a tap, not a hold · ASSUMED.
    static let shortTap: Double = 0.35
    /// S3: stones land 80ms apart; each falls for 320ms (Drop).
    static let wallStoneStagger: Double = 0.08
    static let wallStoneFall: Double = 0.32
    /// S3: a beat between writes so each course reads as it lands · ASSUMED.
    static let wallStageGap: Double = 0.5
    /// S3: Continue Settles in 500ms after the wall is up.
    static let wallUpPrimary: Double = 0.5
    /// S2: approved auto-advances to S3 after 500ms.
    static let approvedAdvance: Double = 0.5
    static let pathFooter: Double = 7.6
    /// S12: “You're in.” holds 1.2s.
    static let successHold: Double = 1.2
    /// S12: the late-night block shows from 22:00 to 04:59.
    static let lateNightStart = 22
    static let lateNightEnd = 5
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
