import SwiftUI

/// The wall (COMPONENTS.md · S3, S4 mini, S9 mini, S13.6): up to three courses
/// of stones (76pt and 35pt halves, 46pt tall, 6pt gaps) on a ground line. A
/// course Drops when its write returns; when all have landed the wall Locks
/// (dips 3pt) and ember blooms at the base. Reduce Motion: each course fades
/// in place.
struct WallView: View {
    enum Course: Equatable { case empty, landed, failed }

    /// Bottom → top: web, apps (only when apps were picked), schedule.
    var web: Course
    var apps: Course?
    var schedule: Course
    /// S13.6: the keystone hovering above, then dropping into the top course.
    var keystone: Keystone = .none
    /// 1 = the 322 × 150pt wall; smaller for the S4 glyph and S9 miniature.
    var scale: CGFloat = 1
    /// Dim the whole wall (S9's door left open).
    var dimmed = false

    enum Keystone: Equatable { case none, hovering, set }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dip: CGFloat = 0
    @State private var bloom = false

    private var courses: [(id: Int, state: Course, offset: Bool)] {
        var list: [(Int, Course, Bool)] = [(0, web, false)]
        if let apps { list.append((1, apps, true)) }
        list.append((2, schedule, apps != nil ? false : true))
        return list.reversed() // drawn top-down
    }

    private var allLanded: Bool {
        web == .landed && schedule == .landed && (apps == nil || apps == .landed)
    }

    var body: some View {
        VStack(spacing: BedrockSize.wallGap * scale) {
            ForEach(Array(courses.enumerated()), id: \.element.id) { position, course in
                // S13.6: the keystone is the top course's centre stone. It hovers
                // 40pt above its slot, then drops in and Locks.
                CourseRow(state: course.state, offset: course.offset, scale: scale,
                          keystone: position == 0 ? keystone : .none)
            }
            Capsule()
                .fill(BedrockColor.lineStrong)
                .frame(height: 1)
        }
        // Ember blooms at the base, behind the stones.
        .background(alignment: .bottom) {
            Ellipse()
                .fill(RadialGradient(colors: [BedrockColor.emberGlow.opacity(0.55), .clear],
                                     center: .center, startRadius: 0, endRadius: 160 * scale))
                .frame(height: 56 * scale)
                .offset(y: 20 * scale)
                .opacity(bloom ? 1 : 0)
        }
        .frame(width: BedrockSize.wallWidth * scale)
        .offset(y: dip)
        .opacity(dimmed ? 0.3 : 1)
        .onChange(of: allLanded) { _, landed in
            guard landed else { return }
            lock()
        }
        .onAppear { if allLanded { bloom = true } }
        .accessibilityHidden(true)
    }

    private func lock() {
        BedrockHaptics.lock()
        if reduceMotion {
            withAnimation(BedrockMotion.ember) { bloom = true }
            return
        }
        withAnimation(BedrockMotion.lock) { dip = BedrockSize.wallDip }
        withAnimation(BedrockMotion.lock.delay(BedrockTiming.wallDipReturn)) { dip = 0 }
        withAnimation(BedrockMotion.ember) { bloom = true }
    }
}

/// One course: 4 full stones, or (offset) a half, 3 full and a half.
private struct CourseRow: View {
    let state: WallView.Course
    let offset: Bool
    let scale: CGFloat
    var keystone: WallView.Keystone = .none

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var landed = false

    private var widths: [CGFloat] {
        offset
            ? [BedrockSize.wallHalf, BedrockSize.wallStone.width, BedrockSize.wallStone.width, BedrockSize.wallStone.width, BedrockSize.wallHalf]
            : Array(repeating: BedrockSize.wallStone.width, count: 4)
    }

    var body: some View {
        HStack(spacing: BedrockSize.wallGap * scale) {
            ForEach(Array(widths.enumerated()), id: \.offset) { index, width in
                ZStack {
                    // The empty course: a faint outline.
                    RoundedRectangle(cornerRadius: Radius.sm * scale, style: .continuous)
                        .strokeBorder(BedrockColor.lineSubtle, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    // The stone.
                    RoundedRectangle(cornerRadius: Radius.sm * scale, style: .continuous)
                        .fill(LinearGradient(colors: [BedrockColor.stoneLight, BedrockColor.stoneMid],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: Radius.sm * scale, style: .continuous)
                            .strokeBorder(BedrockColor.inkPrimary.opacity(0.08), lineWidth: 1))
                        .opacity(landed ? 1 : 0)
                        .offset(y: landed || reduceMotion ? 0 : BedrockMotion.dropHeight)
                        .animation(stoneAnimation(index), value: landed)
                }
                .frame(width: width * scale, height: BedrockSize.wallStone.height * scale)
                .opacity(isKeystoneSlot(index) ? 0 : 1)
                .overlay {
                    if isKeystoneSlot(index) { keystoneStone }
                }
            }
        }
        .onAppear { landed = state == .landed }
        .onChange(of: state) { _, new in
            let landing = new == .landed
            if landing && !landed && scale >= 1 {
                // A soft tap per stone as it lands, 80ms apart.
                for index in widths.indices {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(Double(index) * BedrockTiming.wallStoneStagger + BedrockTiming.wallStoneFall))
                        BedrockHaptics.stoneLands()
                    }
                }
            }
            landed = landing
        }
    }

    private var keystoneIndex: Int { widths.count / 2 }

    private func isKeystoneSlot(_ index: Int) -> Bool {
        keystone != .none && index == keystoneIndex
    }

    /// The keystone: ember, a wedge wider at the top, with its empty slot outlined below.
    private var keystoneStone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.sm * scale, style: .continuous)
                .strokeBorder(BedrockColor.emberDeep, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            KeystoneShape()
                .fill(LinearGradient(colors: [BedrockColor.emberHot, BedrockColor.emberGlow, BedrockColor.ember],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: BedrockColor.emberGlow.opacity(keystone == .set ? 0.6 : 0.3), radius: 8 * scale)
                .offset(y: keystone == .hovering ? -BedrockSize.keystoneDrop * scale : 0)
                .animation(reduceMotion ? nil : BedrockMotion.lock, value: keystone)
        }
    }

    private func stoneAnimation(_ index: Int) -> Animation? {
        if reduceMotion { return BedrockMotion.reducedFade }
        return BedrockMotion.settle.delay(Double(index) * BedrockTiming.wallStoneStagger)
    }
}

/// The keystone: a wedge, wider at the top.
private struct KeystoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.14
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#if DEBUG
struct WallViewPreview: View {
    @State private var web: WallView.Course = .empty
    @State private var apps: WallView.Course = .empty
    @State private var schedule: WallView.Course = .empty

    var body: some View {
        PreviewPage {
            VStack(spacing: Space.s8) {
                WallView(web: web, apps: apps, schedule: schedule)
                WallView(web: .landed, apps: nil, schedule: .landed, keystone: .set)
                WallView(web: .landed, apps: .landed, schedule: .landed, scale: 0.4)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.8)); web = .landed
            try? await Task.sleep(for: .seconds(0.6)); apps = .landed
            try? await Task.sleep(for: .seconds(0.6)); schedule = .landed
        }
    }
}

#Preview("WallView · 402×874", traits: .fixedLayout(width: 402, height: 874)) { WallViewPreview().onboardingPreview(.standard) }
#Preview("WallView · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { WallViewPreview().onboardingPreview(.reduceMotion) }
#Preview("WallView · AX5", traits: .fixedLayout(width: 402, height: 874)) { WallViewPreview().onboardingPreview(.ax5) }
#Preview("WallView · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { WallViewPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
