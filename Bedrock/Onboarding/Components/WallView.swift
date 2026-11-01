import SwiftUI

/// S3's wall, as the prototype draws it: a 172pt area, a ground line 23pt above
/// its bottom, and courses of 46pt stones (76pt, 35pt halves, 6pt gaps) resting
/// on it. Before building, three dashed courses at 55%. Each course drops in
/// when its write returns, stone by stone 80ms apart; when all are in, the wall
/// dips 3pt and an ember glow blooms at its foot. Bottom → top: web, apps (only
/// when apps were picked), schedule.
struct WallView: View {
    enum Course: Equatable { case empty, landed, failed }

    var web: Course
    var apps: Course?
    var schedule: Course
    /// Before “Put the wall up”: the dashed outline.
    var choosing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dip: CGFloat = 0
    @State private var glow = false

    private var allLanded: Bool {
        web == .landed && schedule == .landed && (apps == nil || apps == .landed)
    }

    private static let full: [CGFloat] = [76, 76, 76, 76]
    private static let offset: [CGFloat] = [35, 76, 76, 76, 35]

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(BedrockColor.lineSubtle)
                .frame(height: 1)
                .padding(.horizontal, -12)
                .padding(.bottom, 23)
            if choosing {
                VStack(spacing: BedrockSize.wallGap) {
                    dashed(Self.full)
                    dashed(Self.offset)
                    dashed(Self.full)
                }
                .opacity(0.55)
                .padding(.bottom, 24)
            } else {
                VStack(spacing: BedrockSize.wallGap) {
                    StoneCourse(widths: Self.full, landed: schedule == .landed)
                    if let apps { StoneCourse(widths: Self.offset, landed: apps == .landed) }
                    StoneCourse(widths: Self.full, landed: web == .landed)
                }
                .offset(y: dip)
                .padding(.bottom, 24)
                EllipticalGradient(stops: [
                    .init(color: BedrockColor.bloom, location: 0),
                    .init(color: BedrockColor.bloomMid, location: 0.6),
                    .init(color: .clear, location: 1),
                ], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                .frame(height: 34)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
                .scaleEffect(x: glow ? 1 : 0.5, y: 1)
                .opacity(glow ? 0.85 : 0)
                .allowsHitTesting(false)
            }
        }
        .frame(width: BedrockSize.wallWidth, height: 172)
        .onChange(of: allLanded) { _, landed in if landed { lock() } }
        .onAppear { if allLanded && !choosing { glow = true } }
        .accessibilityHidden(true)
    }

    private func dashed(_ widths: [CGFloat]) -> some View {
        HStack(spacing: BedrockSize.wallGap) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, width in
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .strokeBorder(BedrockColor.lineStrong, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: width, height: BedrockSize.wallStone.height)
            }
        }
    }

    /// Lock: the wall dips 3pt and returns; heavy, then success; the glow blooms.
    private func lock() {
        BedrockHaptics.lock()
        withAnimation(.easeOut(duration: 1.1)) { glow = true }
        guard !reduceMotion else { return }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.11)) { dip = BedrockSize.wallDip }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.21).delay(0.11)) { dip = 0 }
    }
}

/// One course of S3's stones. Each falls 84pt and settles, 80ms apart, with a
/// soft tap as it lands; Reduce Motion fades them in place.
private struct StoneCourse: View {
    let widths: [CGFloat]
    let landed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        HStack(spacing: BedrockSize.wallGap) {
            ForEach(Array(widths.enumerated()), id: \.offset) { index, width in
                Brick(width: width, height: BedrockSize.wallStone.height, radius: Radius.sm, raised: true)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || reduceMotion ? 0 : BedrockMotion.dropHeight)
                    .animation(reduceMotion ? BedrockMotion.reducedFade
                                            : BedrockMotion.settle.delay(Double(index) * BedrockTiming.wallStoneStagger),
                               value: shown)
            }
        }
        .onAppear { shown = landed }
        .onChange(of: landed) { _, new in
            if new && !shown {
                for index in widths.indices {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(Double(index) * BedrockTiming.wallStoneStagger + BedrockTiming.wallStoneFall))
                        BedrockHaptics.stoneLands()
                    }
                }
            }
            shown = new
        }
    }
}

/// One stone of a wall: the prototype's brick gradient, an inset top highlight
/// and (on S3) a soft drop shadow.
struct Brick: View {
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    var raised = false
    var top: Color = BedrockColor.brickHi
    var bottom: Color = BedrockColor.brickLo

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(LinearGradient(stops: raised
                                 ? [.init(color: top, location: 0), .init(color: BedrockColor.brickMid, location: 0.55),
                                    .init(color: bottom, location: 1)]
                                 : [.init(color: top, location: 0), .init(color: bottom, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(raised ? 0.09 : 0), .clear],
                                             startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.1)), lineWidth: 1))
            .shadow(color: raised ? .black.opacity(0.45) : .clear, radius: 7, x: 0, y: 8)
            .frame(width: width, height: height)
    }
}

/// A small wall: S4's glyph, S9's miniature, S13.6, SP4's status icon.
struct MiniWall: View {
    let rows: [[CGFloat]]
    let height: CGFloat
    let radius: CGFloat
    let gap: CGFloat
    var top: Color = BedrockColor.brickHi
    var bottom: Color = BedrockColor.brickLo

    var body: some View {
        VStack(spacing: gap) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, width in
                        Brick(width: width, height: height, radius: radius, top: top, bottom: bottom)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// S4: 3 × 52 over 24, 52, 52, 24; 30pt tall, 5pt gaps.
    static let test = MiniWall(rows: [[52, 52, 52], [24, 52, 52, 24]], height: 30, radius: 7, gap: 5)
    /// S9: 4 × 46 over 21, 46, 46, 46, 21; 26pt tall, 4pt gaps.
    static let door = MiniWall(rows: [[46, 46, 46, 46], [21, 46, 46, 46, 21]], height: 26, radius: 6, gap: 4)
    /// S13.6: 4 × 64 over 29, 64, 64, 64, 29; 40pt tall, 6pt gaps.
    static let sealed = MiniWall(rows: [[64, 64, 64, 64], [29, 64, 64, 64, 29]], height: 40, radius: 9, gap: 6)
    /// SP4's status card: 3 × 15 over 6, 15, 15, 6; 10pt tall.
    static let status = MiniWall(rows: [[15, 15, 15], [6, 15, 15, 6]], height: 10, radius: 3, gap: 3,
                                 top: BedrockColor.markHi, bottom: BedrockColor.brickMid)
}

/// An ember glow under a wall (S4 held, S13.6, SP4).
struct EmberGlow: View {
    let width: CGFloat
    let height: CGFloat
    var strength: Double = 0.6

    var body: some View {
        EllipticalGradient(colors: [BedrockColor.emberGlow.opacity(strength), .clear], center: .center,
                           startRadiusFraction: 0, endRadiusFraction: 0.5)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}
