import SwiftUI

// S9's door and S10's path, as the prototype draws and moves them.

// MARK: - S9 · The door

/// A Bedrock-styled card (not a copy of iOS): a “Screen Time access · Bedrock”
/// row with a switch, and a miniature of the wall. Twice, 3.4s each from 0.6s:
/// the switch slides off at 30–42%, the wall dims to 30% and slips 4pt at
/// 34–50%. It rests off. No haptic: a warning, not an event. Reduce Motion
/// shows the resting state.
struct DoorIllustration: View {
    let rowTitle: String
    let rowApp: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = false
    @State private var wallOn = false

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: Space.s3) {
                UnitPolygon.mark
                    .fill(LinearGradient(colors: [BedrockColor.glyphHi, BedrockColor.glyphLo],
                                         startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
                    .frame(width: 24, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(rowTitle)
                        .ptype(.subheadSemibold)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(rowApp)
                        .ptype(.footnotePlain)
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
                Spacer(minLength: Space.s2)
                DoorSwitch(isOn: on)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Space.s3)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))

            MiniWall.door
                .opacity(wallOn ? 1 : 0.3)
                .offset(y: wallOn ? 0 : 4)
        }
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
        .accessibilityElement()
        .accessibilityLabel(OnbCopy.string("onb.s9.a11y_illustration"))
        .task { await play() }
    }

    private func play() async {
        guard !reduceMotion else { return }
        try? await Task.sleep(for: .seconds(0.6))
        for _ in 0..<BedrockTiming.doorPlays {
            if Task.isCancelled { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                on = true
                wallOn = true
            }
            try? await Task.sleep(for: .seconds(3.4 * 0.30))
            withAnimation(.easeInOut(duration: 3.4 * 0.12)) { on = false }
            withAnimation(.easeInOut(duration: 3.4 * 0.16).delay(3.4 * 0.04)) { wallOn = false }
            try? await Task.sleep(for: .seconds(3.4 * 0.70))
        }
    }
}

/// An iOS-sized switch in Bedrock's colours: 51 × 31, a 27pt Chalk knob.
private struct DoorSwitch: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? BedrockColor.ember : BedrockColor.lineStrong)
            .frame(width: 51, height: 31)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(BedrockColor.inkPrimary)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .frame(width: 27, height: 27)
                    .padding(.leading, 2)
                    .offset(x: isOn ? 20 : 0)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - S10 · The path

/// Six steps on a vertical line. From 0.6s the line fills step by step (one a
/// second) and each node flares from dark to ember as its label rises from 32%
/// to full; step 6 arrives at 7.2s. Tapping a step opens its detail (one at a
/// time). Revisits and Reduce Motion show it lit.
struct GauntletPath: View {
    let steps: [(title: String, detail: String)]
    var lit: Bool
    let onOpen: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reached = -1
    @State private var fill: CGFloat = 0
    @State private var expanded: Int?

    private static let arrivals: [Double] = [0.6, 1.6, 2.6, 3.6, 4.6, 7.2]
    private var showsAll: Bool { lit || reduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(index)
            }
        }
        .background(alignment: .topLeading) {
            GeometryReader { proxy in
                let height = max(proxy.size.height - 14 - 30, 0)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 1).fill(BedrockColor.lineSubtle)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(colors: [BedrockColor.ember, BedrockColor.emberGlow], startPoint: .top, endPoint: .bottom))
                        .frame(height: height * fill)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: 2, height: height)
                .offset(x: 6, y: 14)
            }
            .accessibilityHidden(true)
        }
        .task { await play() }
    }

    private func row(_ index: Int) -> some View {
        let isLit = showsAll || index <= reached
        let isOpen = expanded == index
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                BedrockHaptics.select()
                withAnimation(reduceMotion ? nil : BedrockMotion.expand) { expanded = isOpen ? nil : index }
                if !isOpen { onOpen(index + 1) }
            } label: {
                HStack(alignment: .top, spacing: Space.s4) {
                    Circle()
                        .fill(isLit ? BedrockColor.ember : BedrockColor.lineSubtle)
                        .overlay(Circle().strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
                        .background(Circle().fill(BedrockColor.ember.opacity(isLit ? 0.18 : 0)).padding(-3))
                        .frame(width: 14, height: 14)
                        .scaleEffect(isLit ? 1 : 0.7)
                        .padding(.top, 3.5)
                        .accessibilityHidden(true)
                    Text(steps[index].title)
                        .ptype(PType(face: .sans, size: 16, line: 21, weight: .medium, relativeTo: .callout))
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .opacity(isLit ? 1 : 0.32)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, Space.s2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(OnbCopy.format("onb.s10.a11y_step", index + 1, steps.count, steps[index].title))
            .accessibilityHint(OnbCopy.string("onb.s10.a11y_step_hint"))
            .accessibilityAddTraits(isOpen ? [.isButton, .isSelected] : .isButton)

            if isOpen {
                Text(steps[index].detail)
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 30)
                    .padding(.top, -2)
                    .padding(.bottom, Space.s2)
                    .transition(.opacity)
            }
        }
    }

    private func play() async {
        guard !showsAll else {
            reached = steps.count - 1
            fill = 1
            return
        }
        let start = Date.now
        withAnimation(.linear(duration: 6.6).delay(0.6)) { fill = 1 }
        for (index, at) in Self.arrivals.enumerated() {
            let wait = at - Date.now.timeIntervalSince(start)
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.6)) { reached = index }
            if index == Self.arrivals.count - 1 { BedrockHaptics.urge() } else { BedrockHaptics.pathNode() }
        }
    }
}
