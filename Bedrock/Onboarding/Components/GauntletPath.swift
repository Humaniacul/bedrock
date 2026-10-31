import SwiftUI

/// S10 (COMPONENTS.md): six tappable rows on a vertical line with nodes. An
/// ember light travels down the path from 0.6s, one step a second; each node
/// flares and cools and its label rises from 40% to full. It holds at step 5 while
/// a ring closes around it and 30:00 shows, then reaches step 6 at 7.2s.
/// Plays once; revisits show it lit. Reduce Motion: all lit, a still ring.
struct GauntletPath: View {
    /// Each step's title and detail (`onb.s10.step_n`, split on “ · ”).
    let steps: [(title: String, detail: String)]
    /// Skip the travelling light (revisited, or Reduce Motion).
    var lit: Bool
    let onOpen: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reached = -1          // highest step the light has reached
    @State private var ringProgress: CGFloat = 0
    @State private var expanded: Int?

    private var showsAll: Bool { lit || reduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(index)
            }
        }
        .task {
            guard !showsAll else { reached = steps.count - 1; ringProgress = 1; return }
            await play()
        }
    }

    private func row(_ index: Int) -> some View {
        let isLit = showsAll || index <= reached
        let isOpen = expanded == index
        return Button {
            BedrockHaptics.select()
            withAnimation(Theme.Motion.reduced(BedrockMotion.expand, when: reduceMotion)) {
                expanded = isOpen ? nil : index
            }
            if !isOpen { onOpen(index + 1) }
        } label: {
            HStack(alignment: .top, spacing: Space.s4) {
                node(index, isLit: isLit)
                VStack(alignment: .leading, spacing: Space.s1) {
                    Text(steps[index].title)
                        .font(BedrockFont.headline)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .opacity(isLit ? 1 : BedrockSize.pathLabelDim)
                        .multilineTextAlignment(.leading)
                    if isOpen {
                        Text(steps[index].detail)
                            .font(BedrockFont.subhead)
                            .foregroundStyle(BedrockColor.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, Space.s5)
                Spacer(minLength: 0)
                if index == 4 && (ringProgress > 0 || showsAll) {
                    // The wait the product commits to, as a clock face.
                    Text(Duration.seconds(BedrockTiming.gauntletWait).formatted(.time(pattern: .minuteSecond)))
                        .font(BedrockFont.digits)
                        .foregroundStyle(BedrockColor.emberGlow)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(OnbCopy.format("onb.s10.a11y_step", index + 1, steps.count, steps[index].title))
        .accessibilityHint(OnbCopy.string("onb.s10.a11y_step_hint"))
        .accessibilityAddTraits(isOpen ? [.isButton, .isSelected] : .isButton)
    }

    private func node(_ index: Int, isLit: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isLit ? BedrockColor.ember : BedrockColor.bgRaised)
                    .overlay(Circle().strokeBorder(isLit ? BedrockColor.emberGlow : BedrockColor.lineStrong, lineWidth: 1))
                    .frame(width: BedrockSize.pathNode, height: BedrockSize.pathNode)
                    .shadow(color: index == reached && !showsAll ? BedrockColor.emberGlow : .clear, radius: 6)
                if index == 4 {
                    // The 30-minute wait: a ring closing around step 5.
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(BedrockColor.emberGlow, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: BedrockSize.pathRing, height: BedrockSize.pathRing)
                }
            }
            .frame(width: BedrockSize.pathRing, height: BedrockSize.pathRing)
            if index < steps.count - 1 {
                Rectangle()
                    .fill(index < reached || showsAll ? BedrockColor.ember : BedrockColor.lineStrong)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: BedrockSize.pathRing)
        .accessibilityHidden(true)
    }

    /// 0.6–4.6s: one step a second · 4.6–6.8s: the ring closes on step 5 · 7.2s: step 6.
    private func play() async {
        try? await Task.sleep(for: .seconds(BedrockTiming.pathStart))
        for index in 0..<4 {
            if Task.isCancelled { return }
            withAnimation(BedrockMotion.ember) { reached = index }
            BedrockHaptics.pathNode()
            try? await Task.sleep(for: .seconds(BedrockTiming.pathStep))
        }
        withAnimation(BedrockMotion.ember) { reached = 4 }
        BedrockHaptics.pathNode()
        withAnimation(.linear(duration: BedrockTiming.pathRing)) { ringProgress = 1 }
        try? await Task.sleep(for: .seconds(BedrockTiming.pathFinal - BedrockTiming.pathStart - 4 * BedrockTiming.pathStep))
        if Task.isCancelled { return }
        withAnimation(BedrockMotion.ember) { reached = 5 }
        BedrockHaptics.urge() // medium impact at step 6
    }
}
