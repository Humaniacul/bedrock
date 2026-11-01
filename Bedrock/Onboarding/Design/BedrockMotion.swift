//  BedrockMotion.swift
//  Bedrock onboarding · motion primitives (Phase 5 V2, revised in Phase 7)
//
//  Things move like stone: they fall, settle and lock. Light warms slowly. Nothing bounces for fun.
//  Rules: one hero per screen; stagger 40–80ms, at most six items, at most 400ms in total;
//  emotional beats 600–1200ms; interactions answer within 100ms; prices, legal text and close
//  buttons never animate; a haptic always pairs with a visible change.
//
//  Every primitive has a Reduce Motion version. Use `BedrockMotion.resolve(_:reduceMotion:)`
//  or the view modifiers below, which read the environment for you.

import SwiftUI

public enum BedrockMotion {

    // MARK: Primitives

    /// Carve · per glyph, curve (0.2, 0.8, 0.2, 1), 0.42s, stagger 0.022s (headlines) or 0.10s (carved word).
    /// Only where a screen asks for it: S1, “You’re in.”, S13.6, Home’s first headline, SP1, the S8 word.
    public static let carveGlyph = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.42)
    public static let carveStaggerHeadline: Double = 0.022
    public static let carveStaggerWord: Double = 0.10

    /// Settle · an element arrives with weight and a small overshoot. From y +16, scale 0.98, opacity 0.
    public static let settle = Animation.spring(response: 0.42, dampingFraction: 0.62)

    /// Strata · rows and chips rise in sequence. From y +12…+24, stagger 0.04–0.06s.
    public static let strata = Animation.spring(response: 0.5, dampingFraction: 0.82)
    public static let strataStagger: Double = 0.05

    /// Ember · one word warms Chalk → Glow; glow radius 0 → 10 → 3.
    public static let ember = Animation.easeInOut(duration: 0.6)

    /// Breath · scale 1.0 ↔ 1.02, 2s each way. Held moments only (S15 button).
    public static let breath = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    public static let breathScale: CGFloat = 1.02

    /// Lock · something snaps into its final place: wall dips 3pt, text 1.06 → 1, stone drops 14pt.
    /// Pair with `BedrockHaptics.lock()` (heavy, then success 80ms later).
    public static let lock = Animation.spring(response: 0.28, dampingFraction: 0.9)

    /// Rise · screen to screen. Out: ease-in 0.18s, opacity → 0, y −8. In: Settle after 0.08s.
    public static let riseOut = Animation.easeIn(duration: 0.18)
    public static let riseInDelay: Double = 0.08

    /// Drop · stones and the keystone fall from y −84 (0.32s, accelerating), then Settle.
    public static let dropFall = Animation.timingCurve(0.55, 0, 0.9, 0.4, duration: 0.32)
    public static let dropHeight: CGFloat = -84

    /// Dawn · horizon opacity to the screen’s level (see `Dawn.level(for:)`).
    public static let dawn = Animation.easeInOut(duration: 0.9)

    /// Drain · an unfinished hold empties.
    public static let drain = Animation.easeOut(duration: 0.3)

    /// Pop · checkmarks, scale 1.15 → 1.
    public static let pop = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Expand · step details, the word field.
    public static let expand = Animation.spring(response: 0.35, dampingFraction: 0.85)

    // MARK: Reduce Motion

    /// Fade used in place of movement when Reduce Motion is on.
    public static let reducedFade = Animation.easeOut(duration: 0.2)
    public static let reducedCarve = Animation.easeOut(duration: 0.25)

    public enum Kind { case carve, settle, strata, ember, breath, lock, rise, drop, dawn, drain, pop, expand }

    /// The animation to use for a primitive, honouring Reduce Motion.
    /// Dawn and Drain are opacity/progress only, so they stay the same.
    public static func resolve(_ kind: Kind, reduceMotion: Bool) -> Animation? {
        switch (kind, reduceMotion) {
        case (.carve, false): return carveGlyph
        case (.carve, true): return reducedCarve
        case (.settle, false): return settle
        case (.strata, false): return strata
        case (.ember, _): return ember            // colour change stays; the glow is dropped by the view
        case (.breath, false): return breath
        case (.breath, true): return nil           // static
        case (.lock, false): return lock
        case (.rise, false): return riseOut
        case (.drop, false): return dropFall
        case (.dawn, _): return dawn
        case (.drain, _): return drain
        case (.pop, false): return pop
        case (.expand, false): return expand
        case (.expand, true): return nil           // instant
        default: return reducedFade
        }
    }
}

// MARK: - Appear modifiers

public enum AppearStyle { case settle, strata(index: Int), rise, drop }

private struct BedrockAppear: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let style: AppearStyle
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : startOffset)
            .scaleEffect(shown || reduceMotion ? 1 : startScale)
            .onAppear {
                let animation: Animation = reduceMotion ? BedrockMotion.reducedFade : baseAnimation
                withAnimation(animation.delay(reduceMotion ? 0 : totalDelay)) { shown = true }
            }
    }

    private var startOffset: CGFloat {
        switch style {
        case .settle: return 16
        case .strata: return 16
        case .rise: return 8
        case .drop: return BedrockMotion.dropHeight
        }
    }
    private var startScale: CGFloat { if case .settle = style { return 0.98 } else { return 1 } }
    private var baseAnimation: Animation {
        switch style {
        case .settle, .rise: return BedrockMotion.settle
        case .strata: return BedrockMotion.strata
        case .drop: return BedrockMotion.dropFall
        }
    }
    private var totalDelay: Double {
        switch style {
        case .strata(let i): return delay + Double(min(i, 5)) * BedrockMotion.strataStagger
        case .rise: return delay + BedrockMotion.riseInDelay
        default: return delay
        }
    }
}

public extension View {
    /// `.bedrockAppear(.settle)`, `.bedrockAppear(.strata(index: i))`, `.bedrockAppear(.drop, delay: 0.3)`
    func bedrockAppear(_ style: AppearStyle, delay: Double = 0) -> some View {
        modifier(BedrockAppear(style: style, delay: delay))
    }

    /// Breath: 1.0 ↔ 1.02 forever. Static under Reduce Motion.
    func bedrockBreath() -> some View { modifier(BreathModifier()) }
}

private struct BreathModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhale = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(inhale ? BedrockMotion.breathScale : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(BedrockMotion.breath) { inhale = true }
            }
    }
}

// MARK: - Carve (per glyph, iOS 18+ TextRenderer)

/// Draws each glyph from 4pt blur and 6pt below to rest, staggered.
public struct CarveRenderer: TextRenderer, Animatable {
    public var elapsed: Double
    public var stagger: Double
    public var glyphDuration: Double = 0.42

    public var animatableData: Double {
        get { elapsed }
        set { elapsed = newValue }
    }

    private static let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.2, y: 0.8),
                                                endControlPoint: UnitPoint(x: 0.2, y: 1))

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var index = 0
        for line in layout {
            for run in line {
                for slice in run {
                    let start = Double(index) * stagger
                    let t = max(0, min(1, (elapsed - start) / glyphDuration))
                    let p = CarveRenderer.curve.value(at: t)
                    var glyph = context
                    glyph.opacity = p
                    glyph.translateBy(x: 0, y: (1 - p) * 6)
                    if p < 1 { glyph.addFilter(.blur(radius: (1 - p) * 4)) }
                    glyph.draw(slice)
                    index += 1
                }
            }
        }
    }
}

/// A headline that carves in once. Under Reduce Motion the whole line fades in over 0.25s.
public struct CarveText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let text: Text
    private let glyphCount: Int
    private let stagger: Double
    private let delay: Double
    @State private var elapsed: Double = 0
    @State private var visible = false

    /// With no `font`, the line takes the environment's (set it with `.ptype`).
    public init(_ string: String, word: Bool = false, delay: Double = 0, font: Font? = nil) {
        self.text = font.map { Text(string).font($0) } ?? Text(string)
        self.glyphCount = string.count
        self.stagger = word ? BedrockMotion.carveStaggerWord : BedrockMotion.carveStaggerHeadline
        self.delay = delay
    }

    /// A styled line (e.g. one word in Glow); `glyphs` sets the carve's length.
    public init(_ text: Text, glyphs: Int, delay: Double = 0) {
        self.text = text
        self.glyphCount = glyphs
        self.stagger = BedrockMotion.carveStaggerHeadline
        self.delay = delay
    }

    private var total: Double { Double(max(glyphCount - 1, 0)) * stagger + 0.42 }

    public var body: some View {
        Group {
            if reduceMotion {
                text.opacity(visible ? 1 : 0)
            } else {
                text.textRenderer(CarveRenderer(elapsed: elapsed, stagger: stagger))
            }
        }
        .onAppear {
            if reduceMotion {
                withAnimation(BedrockMotion.reducedCarve.delay(delay)) { visible = true }
            } else {
                withAnimation(.linear(duration: total).delay(delay)) { elapsed = total }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Timings that the spec names

public enum BedrockTiming {
    /// S8: hold to set the first stone.
    public static let holdToSet: Double = 1.4
    /// S8: an early release drains the ring.
    public static let holdDrain: Double = 0.3
    /// S10: the path starts at 0.6s, one step per second, step 6 at 7.2s; the primary is available at 0.9s.
    public static let pathStart: Double = 0.6
    public static let pathStep: Double = 1.0
    public static let pathFinal: Double = 7.2
    public static let s10PrimaryAt: Double = 0.9
    /// S13.4B: each digit stays 3s (5s in slow mode after S13.7A).
    public static let digitDuration: Double = 3.0
    public static let digitDurationSlow: Double = 5.0
    /// S15: one breath, 4s in, 4s out.
    public static let breathIn: Double = 4.0
    public static let breathOut: Double = 4.0
    /// S9: the door illustration plays twice, then rests off.
    public static let doorPlays: Int = 2
    /// Toasts: drop 12pt, hold 2s, fade.
    public static let toastHold: Double = 2.0
}
