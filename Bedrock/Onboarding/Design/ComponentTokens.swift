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
    /// The carved word once it cools: chalk in the cut · ASSUMED.
    static let engraving = Color(hex: 0xD9D1C5, opacity: 0.82)
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

    // StoneView (SPEC.md S8, Home)
    static let stoneRegular = CGSize(width: 176, height: 266)
    /// Home, and S8 at accessibility text sizes (“the stone shrinks to 132 × 200pt”).
    static let stoneHome = CGSize(width: 132, height: 200)
    static let stoneHoverOpacity: Double = 0.45
    /// S8: the stone drops 14pt when set (BedrockMotion.lock).
    static let stoneHoverLift: CGFloat = 14

    // HoldToSetControl (SPEC.md S8)
    static let holdControl: CGFloat = 84
    static let holdRingWidth: CGFloat = 3
    static let holdGlyph = CGSize(width: 18, height: 26)
    /// How far a finger can drift and still be holding · ASSUMED.
    static let holdSlop: CGFloat = 40

    // WallView (SPEC.md S3: 322 × 150pt; COMPONENTS.md: 76pt stones, 35pt halves, 46pt tall, 6pt gaps)
    static let wallWidth: CGFloat = 322
    static let wallStone = CGSize(width: 76, height: 46)
    static let wallHalf: CGFloat = 35
    static let wallGap: CGFloat = 6
    static let wallDip: CGFloat = 3
    /// S13.6: the keystone drops 40pt into the top course.
    static let keystoneDrop: CGFloat = 40
    /// The S4 glyph above the button.
    static let wallGlyphScale: CGFloat = 0.28

    // DoorIllustration (SPEC.md S9)
    static let doorWallScale: CGFloat = 0.62
    static let doorSlip: CGFloat = 6
    static let touchDot: CGFloat = 26
    static let switchSize = CGSize(width: 51, height: 31)

    // GauntletPath (SPEC.md S10)
    static let pathNode: CGFloat = 12
    static let pathRing: CGFloat = 28
    static let pathLabelDim: Double = 0.4

    // Cards (SPEC.md S11, S12, Home)
    static let planCardMinHeight: CGFloat = 132
    static let planCardRadius: CGFloat = 18
    static let badgeOverlap: CGFloat = 11
    static let homeCardMinHeight: CGFloat = 64
    static let statusDot: CGFloat = 7
    static let outcomeGlyph: CGFloat = 22

    // Moments (SPEC.md S14, S15)
    static let lockScreenPreview = CGSize(width: 300, height: 232)
    static let previewIcon: CGFloat = 38
    static let urgeCircle: CGFloat = 168
    static let urgeCapsule: CGFloat = 64
    static let breathMinScale: CGFloat = 0.56

    // Blind entry (SPEC.md S13.3B–S13.5A) · ASSUMED sizes for the floating window.
    static let digitWindow = CGSize(width: 240, height: 120)
    static let digitRing: CGFloat = 76
    /// Pixel scale for the Picture in Picture frames.
    static let digitWindowScale: CGFloat = 3
    static let keypadKey: CGFloat = 68

    // Screens
    /// S7: one word, up to 14 characters.
    static let wordMaxLength = 14
    /// S1: the stone mark sits 96pt from the top of the reference (62pt safe area).
    static let arrivalMarkTop: CGFloat = 34
    /// S2 / S2-D / B2: the Screen Time card.
    static let permissionCard = CGSize(width: 220, height: 150)
    static let permissionGlyph: CGFloat = 40
    /// S13.1: the letter's text area.
    static let letterMinHeight: CGFloat = 200
    /// S13.2B, S13.4B: numbered step badges.
    static let stepBadge: CGFloat = 26
    /// S12: the trial timeline's dots.
    static let timelineDot: CGFloat = 10
    /// B9: the Preview tag sits just under the Dynamic Island, this far above the
    /// top safe-area edge (the island ends about 14pt above it on the reference).
    static let previewTagLift: CGFloat = 14
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
    /// Caption · SF Pro 12.
    static let caption = Font.caption
    /// The carved word on the stone · SF Pro Semibold, wide tracking · ASSUMED 22pt.
    static let stoneWord = Font.system(size: 22, weight: .semibold)
    /// S11 option titles · serif 26 (COMPONENTS.md).
    static let optionTitle = serif(26, relativeTo: .title2)
    /// S12 plan prices · SF Pro Semibold 22, tabular · ASSUMED.
    static let planPrice = Font.title2.weight(.semibold).monospacedDigit()
    /// S14 lock-screen preview clock · ASSUMED.
    static let lockScreenTime = Font.system(size: 54, weight: .semibold, design: .rounded)
    /// S13.3B / S13.4B: the one digit in the floating window.
    static let digitHero = Font.system(size: 40, weight: .semibold, design: .monospaced)
    /// S13.3B: the practice keypad.
    static let keypad = Font.system(size: 30, weight: .regular, design: .rounded)

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
    /// The carved word · wide, like an inscription · ASSUMED.
    static let stoneWord = LineSpec(tracking: 3, lineSpacing: 0)
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
    /// S8: the stone drops into place · Lock (0.28 / 0.9).
    static let stoneDrop = lock
    /// S8: the hairline seam draws across the base in 600ms.
    static let seamDraw = Animation.easeInOut(duration: BedrockTiming.seamDraw)
    /// S9: the switch slides off · 220ms ease-in-out.
    static let doorSwitch = Animation.easeInOut(duration: 0.22)
    /// S11: a selected card Settles 0.98 → 1.
    static let cardSelectScale: CGFloat = 0.98
    /// S12: the CTA label crossfades in 160ms.
    static let ctaCrossfade = Animation.easeInOut(duration: 0.16)
    /// S2-D, S4: copy crossfades 240ms between states.
    static let stateCrossfade = Animation.easeInOut(duration: 0.24)
    /// S13.3B: a typed digit slides away left in 160ms.
    static let digitSlide = Animation.easeIn(duration: 0.16)
    /// S13.3B: the field shakes 3 times over 300ms.
    static let shake = Animation.linear(duration: 0.3)
    /// S15 → Home: Dawn reaches full daylight over 1.2s.
    static let fullDaylight = Animation.easeInOut(duration: 1.2)
}

extension BedrockTiming {
    /// S8: each carved letter glows ember, then cools to an engraving over 900ms.
    static let carveCool: Double = 0.9
    /// S8: the carve starts 300ms after the stone is set; “DAY 1” at 1.4s; text at 2.6s.
    static let stoneCarveDelay: Double = 0.3
    static let stoneDayDelay: Double = 1.4
    static let stoneTextDelay: Double = 2.6
    static let seamDraw: Double = 0.6
    /// S8: a press shorter than this counts as a tap, not a hold · ASSUMED.
    static let shortTap: Double = 0.35
    /// S8: the three reflection lines rise 450ms apart.
    static let reflectionStagger: Double = 0.45
    /// S3: stones land 80ms apart; each falls for 320ms (Drop).
    static let wallStoneStagger: Double = 0.08
    static let wallStoneFall: Double = 0.32
    /// S3: the wall dips 3pt and returns.
    static let wallDipReturn: Double = 0.14
    /// S3: a beat between writes so each course reads as it lands · ASSUMED.
    static let wallStageGap: Double = 0.5
    /// S3: Continue Settles in 500ms after the wall is up.
    static let wallUpPrimary: Double = 0.5
    /// S2: approved auto-advances to S3 after 500ms.
    static let approvedAdvance: Double = 0.5
    /// S9: a touch dot at 600ms, the switch at 900ms, a reset at 4.0s.
    static let doorTouch: Double = 0.6
    static let doorSwitch: Double = 0.9
    static let doorTouchFade: Double = 0.2
    static let doorReset: Double = 4.0
    /// S10: the ring closes around step 5 from 4.6s to 6.8s; footer at 7.6s.
    static let pathRing: Double = 2.2
    static let pathFooter: Double = 7.6
    /// S10: the 30-minute wait the product commits to.
    static let gauntletWait: Double = 1800
    /// S12: “You're in.” holds 1.2s.
    static let successHold: Double = 1.2
    /// S13.1: the letter folds into an envelope in 300ms.
    static let letterFold: Double = 0.3
    /// S12: the late-night block shows from 22:00 to 04:59.
    static let lateNightStart = 22
    static let lateNightEnd = 5
    /// S13.3B: a beat before the first practice digit's clock starts · ASSUMED.
    static let practiceLeadIn: Double = 1.2
    /// Wall test: give up on the background check after this long.
    static let wallTestTimeout: Double = 12
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
