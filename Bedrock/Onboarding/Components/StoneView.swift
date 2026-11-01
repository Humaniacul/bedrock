import SwiftUI

/// The foundation stone, as the prototype draws it: a standing stone with faint
/// strata and side shading, the word engraved dark into it (a light lower lip,
/// a dark upper one), the day under it, and on S8 an ember crack drawn across
/// the base — the repair. S8: 148 × 218; Home: 132 × 194 with an ember foot.
struct StoneView: View {
    enum Phase: Equatable {
        /// S8 before setting: 45% opacity, 12pt up.
        case hovering
        /// Set. `carve` plays S8's sequence once (drop, letters, day, crack).
        case set(carve: Bool)
        /// Home after a slip: the crack, ember once repaired.
        case cracked(repaired: Bool)
    }

    enum Style { case onboarding, home }

    let word: String
    let day: Int
    var phase: Phase = .set(carve: false)
    var style: Style = .onboarding

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = true
    @State private var lettersShown = 0
    @State private var dayShown = true
    @State private var crackDrawn: CGFloat = 0

    private var size: CGSize { style == .home ? BedrockSize.stoneHome : BedrockSize.stoneRegular }
    private var isHovering: Bool { phase == .hovering }
    private var letters: [Character] { Array(word.uppercased()) }

    var body: some View {
        ZStack(alignment: .top) {
            body(size: size)
            engraving
            Text(OnbCopy.string("onb.common.day").replacingOccurrences(of: "{n}", with: "\(day)"))
                .ptype(style == .home ? .homeStoneDay : .stoneDay)
                .foregroundStyle(BedrockColor.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, style == .home ? 92 : 104)
                .opacity(isHovering ? 0 : (dayShown ? 1 : 0))
            if showsCrack {
                ProtoIcon.crack
                    .trim(from: 0, to: crackDrawn)
                    .stroke(crackColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .shadow(color: BedrockColor.ember.opacity(0.6), radius: 3)
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(isHovering ? BedrockSize.stoneHoverOpacity : (settled ? 1 : BedrockSize.stoneHoverOpacity))
        .offset(y: isHovering || !settled ? -BedrockSize.stoneHoverLift : 0)
        .accessibilityElement()
        .accessibilityLabel(OnbCopy.string("onb.s8.a11y_stone")
            .replacingOccurrences(of: "{n}", with: "\(day)")
            .replacingOccurrences(of: "{word}", with: word))
        .onAppear(perform: start)
        .onChange(of: phase) { _, _ in start() }
    }

    // MARK: Pieces

    private func body(size: CGSize) -> some View {
        ZStack {
            Canvas { context, canvas in
                let rect = CGRect(origin: .zero, size: canvas)
                let shape = UnitPolygon.foundation.path(in: rect)
                context.clip(to: shape)
                // linear-gradient(160deg, …)
                let stops: [Gradient.Stop] = style == .home
                    ? [.init(color: BedrockColor.markHi, location: 0), .init(color: BedrockColor.homeStoneMid, location: 0.45),
                       .init(color: BedrockColor.stoneDark, location: 1)]
                    : [.init(color: BedrockColor.stoneLight, location: 0), .init(color: BedrockColor.stoneMid, location: 0.45),
                       .init(color: BedrockColor.stoneDark, location: 1)]
                context.fill(Path(rect), with: .linearGradient(Gradient(stops: stops),
                                                             startPoint: CGPoint(x: canvas.width * 0.33, y: 0),
                                                             endPoint: CGPoint(x: canvas.width * 0.67, y: canvas.height)))
                // repeating-linear-gradient(177deg, light 0–2px, clear 2–19px): faint strata.
                let period: CGFloat = style == .home ? 17 : 19
                var strata = context
                strata.translateBy(x: canvas.width / 2, y: canvas.height / 2)
                strata.rotate(by: .degrees(-3))
                var y = -canvas.height
                while y < canvas.height {
                    strata.fill(Path(CGRect(x: -canvas.width, y: y, width: canvas.width * 2, height: 2)),
                                with: .color(.white.opacity(0.028)))
                    y += period
                }
                // Side shading: lit left edge, shadowed right.
                context.fill(Path(rect), with: .linearGradient(Gradient(stops: [
                    .init(color: .white.opacity(0.07), location: 0), .init(color: .clear, location: 0.3),
                    .init(color: .clear, location: 0.7), .init(color: .black.opacity(0.35), location: 1),
                ]), startPoint: .zero, endPoint: CGPoint(x: canvas.width, y: 0)))
                if style == .home {
                    // An ember foot: Home is lit from the horizon.
                    context.fill(Path(rect), with: .linearGradient(Gradient(stops: [
                        .init(color: BedrockColor.emberGlow.opacity(0.2), location: 0), .init(color: .clear, location: 0.38),
                    ]), startPoint: CGPoint(x: 0, y: canvas.height), endPoint: .zero))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var engraving: some View {
        HStack(spacing: 0) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                Text(String(letter))
                    .opacity(index < lettersShown ? 1 : 0)
                    .blur(radius: index < lettersShown ? 0 : 4)
                    .offset(y: index < lettersShown ? 0 : 6)
            }
        }
        .ptype(style == .home ? .homeStoneWord : .stoneWord)
        .foregroundStyle(BedrockColor.engraving)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        // Cut into the stone: a light lower lip and a dark upper one.
        .shadow(color: .white.opacity(0.16), radius: 0, x: 0, y: 1)
        .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: -1)
        .padding(.horizontal, size.width * 0.1)
        .frame(maxWidth: .infinity)
        .padding(.top, style == .home ? 56 : 64)
        .opacity(isHovering ? 0 : 1)
        .accessibilityHidden(true)
    }

    private var showsCrack: Bool {
        switch phase {
        case .set: style == .onboarding
        case .cracked: true
        case .hovering: false
        }
    }

    private var crackColor: Color {
        if case .cracked(repaired: false) = phase { return BedrockColor.stoneDark }
        return BedrockColor.ember
    }

    // MARK: Motion

    private func start() {
        switch phase {
        case .hovering:
            settled = false
            lettersShown = 0
            crackDrawn = 0
        case .set(carve: true) where !reduceMotion:
            playSet()
        default:
            settled = true
            lettersShown = letters.count
            dayShown = true
            crackDrawn = 1
        }
    }

    /// S8: the stone drops into place (0.5s), letters carve in from 0.3s, 100ms
    /// apart; DAY 1 at 1.3s; the crack draws over 1.1s from 1.6s.
    private func playSet() {
        settled = false
        lettersShown = 0
        dayShown = false
        crackDrawn = 0
        withAnimation(BedrockMotion.stoneDrop) { settled = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(BedrockTiming.stoneCarveDelay))
            for index in letters.indices {
                withAnimation(BedrockMotion.carveGlyph) { lettersShown = index + 1 }
                try? await Task.sleep(for: .seconds(BedrockMotion.carveStaggerWord))
            }
            try? await Task.sleep(for: .seconds(max(0, 1.3 - BedrockTiming.stoneCarveDelay
                                                      - Double(letters.count) * BedrockMotion.carveStaggerWord)))
            withAnimation(BedrockMotion.reducedFade) { dayShown = true }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.1)) { crackDrawn = 1 }
        }
    }
}

/// The soft shadow the stone stands on.
struct StoneShadow: View {
    var width: CGFloat = 190
    var height: CGFloat = 22
    var strength: Double = 0.85

    var body: some View {
        EllipticalGradient(colors: [.black.opacity(strength), .clear], center: .center,
                           startRadiusFraction: 0, endRadiusFraction: 0.5)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}
