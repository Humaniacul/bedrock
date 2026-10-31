import SwiftUI

/// The foundation stone (COMPONENTS.md): a five-point polygon with stratified
/// fill, their word carved in, the day count, and the seam that shows a slip
/// cracks the stone but never takes a day away. Drawn in SwiftUI, no raster.
/// S8 sets it; Home inherits it, so the two feel like the same object.
struct StoneView: View {
    enum Phase: Equatable {
        /// S8 before setting: 45% opacity, raised 12pt.
        case hovering
        /// Set. `carve` plays the S8 sequence once (word, day, demo seam).
        case set(carve: Bool)
        /// Home after a slip: a dark crack, or an ember seam once repaired.
        case cracked(repaired: Bool)
    }

    let word: String
    let day: Int
    var phase: Phase = .set(carve: false)
    var size: CGSize = BedrockSize.stoneRegular

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false
    @State private var carveStart: Date?
    @State private var dayShown = false
    @State private var seamDrawn: CGFloat = 0
    @State private var seamLit = false

    private var isHovering: Bool { phase == .hovering }

    var body: some View {
        ZStack {
            body(in: size)
            carvedWord
            dayLabel
            seam
        }
        .frame(width: size.width, height: size.height)
        .opacity(isHovering ? BedrockSize.stoneHoverOpacity : 1)
        .offset(y: offsetY)
        .drawingGroup(opaque: false)
        .accessibilityElement()
        .accessibilityLabel(OnbCopy.string("onb.s8.a11y_stone")
            .replacingOccurrences(of: "{n}", with: "\(day)")
            .replacingOccurrences(of: "{word}", with: word))
        .onAppear { if case .set(carve: true) = phase { playSet() } else { settleStatic() } }
        .onChange(of: phase) { _, new in
            if case .set(carve: true) = new { playSet() } else { settleStatic() }
        }
    }

    private var offsetY: CGFloat {
        if isHovering { return -BedrockSize.stoneHoverLift }
        if case .set(carve: true) = phase, !dropped { return -BedrockSize.stoneHoverLift }
        return 0
    }

    // MARK: Pieces

    private func body(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let path = StoneOutline().path(in: CGRect(origin: .zero, size: canvasSize))
            // Highlight from the top left, shade to the bottom right.
            context.fill(path, with: .linearGradient(
                Gradient(colors: [BedrockColor.stoneLight, BedrockColor.stoneMid, BedrockColor.stoneDark]),
                startPoint: .zero, endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)))
            // Strata: faint, slightly tilted lines, clipped to the stone.
            context.clip(to: path)
            let layers = 9
            for i in 1..<layers {
                let y = canvasSize.height * CGFloat(i) / CGFloat(layers)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y + 3))
                line.addCurve(to: CGPoint(x: canvasSize.width, y: y - 4),
                              control1: CGPoint(x: canvasSize.width * 0.35, y: y - 2),
                              control2: CGPoint(x: canvasSize.width * 0.65, y: y + 2))
                context.stroke(line, with: .color(BedrockColor.lineStrong.opacity(i.isMultiple(of: 3) ? 0.9 : 0.45)),
                               lineWidth: i.isMultiple(of: 3) ? 1 : 0.5)
            }
            // Top-edge light.
            context.stroke(path, with: .linearGradient(
                Gradient(colors: [BedrockColor.inkPrimary.opacity(0.18), .clear]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: canvasSize.height * 0.4)), lineWidth: 1.5)
        }
    }

    /// The word, carved: each letter glows ember, then cools to an engraving.
    private var carvedWord: some View {
        TimelineView(.animation(paused: carveStart == nil || carveDone)) { timeline in
            let elapsed = carveStart.map { timeline.date.timeIntervalSince($0) } ?? (showsWordAtRest ? .infinity : -1)
            HStack(spacing: 0) {
                ForEach(Array(word.uppercased().enumerated()), id: \.offset) { index, letter in
                    let local = elapsed - Double(index) * BedrockMotion.carveStaggerWord
                    let cool = min(max(local / BedrockTiming.carveCool, 0), 1)
                    Text(String(letter))
                        .foregroundStyle(cool >= 1 ? AnyShapeStyle(BedrockColor.stoneDark) : AnyShapeStyle(BedrockColor.emberHot.mix(with: BedrockColor.stoneDark, by: cool)))
                        .shadow(color: BedrockColor.emberGlow.opacity((1 - cool) * 0.8), radius: (1 - cool) * 6)
                        .opacity(local >= 0 ? 1 : 0)
                }
            }
            .font(BedrockFont.stoneWord)
            .tracking(BedrockLine.stoneWord.tracking)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            // Engraved: a light lower edge under dark letters reads as cut into stone.
            .shadow(color: BedrockColor.inkPrimary.opacity(0.22), radius: 0, x: 0, y: 1)
            .padding(.horizontal, size.width * 0.14)
        }
        .offset(y: -size.height * 0.08)
        .accessibilityHidden(true)
    }

    private var dayLabel: some View {
        Text(OnbCopy.string("onb.common.day").replacingOccurrences(of: "{n}", with: "\(day)"))
            .bedrockEyebrow(color: BedrockColor.inkSecondary)
            .opacity(dayShown ? 1 : 0)
            .offset(y: size.height * 0.12)
            .accessibilityHidden(true)
    }

    private var seam: some View {
        StoneSeam()
            .trim(from: 0, to: seamDrawn)
            .stroke(seamLit ? AnyShapeStyle(BedrockColor.ember) : AnyShapeStyle(BedrockColor.stoneDark),
                    style: StrokeStyle(lineWidth: seamLit ? 1.6 : 1.2, lineCap: .round, lineJoin: .round))
            .shadow(color: seamLit ? BedrockColor.emberGlow.opacity(0.6) : .clear, radius: 3)
            .accessibilityHidden(true)
    }

    // MARK: Motion

    private var showsWordAtRest: Bool { !isHovering }
    private var carveDone: Bool {
        guard let carveStart else { return true }
        let total = Double(max(word.count - 1, 0)) * BedrockMotion.carveStaggerWord + BedrockTiming.carveCool
        return Date.now.timeIntervalSince(carveStart) > total + 0.1
    }

    /// The resting look for each phase, with no sequence.
    private func settleStatic() {
        dropped = true
        carveStart = nil
        dayShown = !isHovering
        switch phase {
        case .cracked(let repaired):
            seamDrawn = 1
            seamLit = repaired
        default:
            seamDrawn = 0
            seamLit = false
        }
    }

    /// S8: Lock drop, carve the word, show the day, draw the demo seam and fill it.
    private func playSet() {
        guard !reduceMotion else {
            dropped = true
            dayShown = true
            carveStart = .distantPast
            seamDrawn = 1
            seamLit = true
            return
        }
        withAnimation(BedrockMotion.stoneDrop) { dropped = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(BedrockTiming.stoneCarveDelay))
            carveStart = .now
            try? await Task.sleep(for: .seconds(BedrockTiming.stoneDayDelay - BedrockTiming.stoneCarveDelay))
            withAnimation(BedrockMotion.reducedFade) { dayShown = true }
            withAnimation(BedrockMotion.seamDraw) { seamDrawn = 1 }
            try? await Task.sleep(for: .seconds(BedrockTiming.seamDraw))
            withAnimation(BedrockMotion.ember) { seamLit = true }
        }
    }
}

/// The five-point stone silhouette shared by `StoneView` and `StoneMark`: a
/// standing stone with a chamfered top and a level base, so it reads as set.
struct StoneOutline: Shape {
    static let points: [CGPoint] = [
        CGPoint(x: 0.10, y: 0.08),
        CGPoint(x: 0.60, y: 0.00),
        CGPoint(x: 1.00, y: 0.16),
        CGPoint(x: 0.95, y: 1.00),
        CGPoint(x: 0.03, y: 0.97),
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(Self.points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

/// The hairline crack across the base (S8's demo seam, Home after a slip).
private struct StoneSeam: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.05, y: 0.80), CGPoint(x: 0.22, y: 0.77), CGPoint(x: 0.31, y: 0.83),
            CGPoint(x: 0.47, y: 0.79), CGPoint(x: 0.58, y: 0.85), CGPoint(x: 0.74, y: 0.81),
            CGPoint(x: 0.94, y: 0.86),
        ]
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        return path
    }
}

#if DEBUG
struct StoneViewPreview: View {
    @State private var phase: StoneView.Phase = .hovering

    var body: some View {
        PreviewPage {
            VStack(spacing: Space.s8) {
                StoneView(word: "steady", day: 1, phase: phase)
                HStack(spacing: Space.s6) {
                    StoneView(word: "steady", day: 12, phase: .cracked(repaired: false), size: BedrockSize.stoneHome)
                    StoneView(word: "steady", day: 12, phase: .cracked(repaired: true), size: BedrockSize.stoneHome)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1))
            phase = .set(carve: true)
        }
    }
}

#Preview("StoneView · 402×874", traits: .fixedLayout(width: 402, height: 874)) { StoneViewPreview().onboardingPreview(.standard) }
#Preview("StoneView · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { StoneViewPreview().onboardingPreview(.reduceMotion) }
#Preview("StoneView · AX5", traits: .fixedLayout(width: 402, height: 874)) { StoneViewPreview().onboardingPreview(.ax5) }
#Preview("StoneView · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { StoneViewPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
