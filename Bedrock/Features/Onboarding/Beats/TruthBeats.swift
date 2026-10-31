import SwiftUI

// ACT III — THE TRUTH (spec v2 S14–S18): understanding, discovered by doing.
// No fake spinner, no benchmark counter, no numeric score — the user assembles
// their own reading, uncovers it at their own pace, walks the loop with their
// thumb, scrubs the road ahead, and feels willpower drain against a door.

// MARK: - S14 · The Reading [Trace — they initiate]

struct ReadingBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var gather: CGFloat = 0     // 0 scattered … 1 assembled
    @State private var assembled = false

    /// Their actual answers, becoming the strata of their column.
    private var strata: [String] {
        var labels: [String] = []
        if let first = OnboardingModel.motivationOptions.first(where: { model.motivation.contains($0) }) {
            labels.append(first)
        }
        if let span = model.duration { labels.append(span.label) }
        if let trigger = OnboardingModel.triggerOptions.first(where: { model.triggers.contains($0) }) {
            labels.append(trigger)
        }
        if let top = model.topCost { labels.append(top) }
        labels.append(model.bestSelfWord.capitalized)
        return labels
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Text(assembled ? "There you are." : "Bring it together.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .animation(Theme.Motion.reduced(.easeInOut(duration: 0.4), when: reduceMotion), value: assembled)
            Text(assembled ? "Everything you told us, in one column." : "Swipe your answers inward.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .animation(Theme.Motion.reduced(.easeInOut(duration: 0.4), when: reduceMotion), value: assembled)

            column
                .frame(height: 300)

            if voiceOver || reduceMotion, !assembled {
                Button("Bring it together") { assemble() }
                    .buttonStyle(.bedrockPrimary)
            }
            Spacer()
            if assembled {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { drag in
                    guard !assembled else { return }
                    let pull = (abs(drag.translation.width) + abs(drag.translation.height)) / 340
                    gather = min(1, max(gather, pull))
                }
                .onEnded { _ in
                    guard !assembled else { return }
                    if gather > 0.75 { assemble() }
                    else { withAnimation(.easeOut(duration: 0.5)) { gather = 0 } }
                }
        )
    }

    /// Fragments hover scattered, then Settle into a strata column they drive.
    private var column: some View {
        VStack(spacing: 7) {
            ForEach(Array(strata.enumerated()), id: \.offset) { index, label in
                let scatter = scatterOffset(index)
                Text(label)
                    .font(Theme.Typography.monoCaption)
                    .tracking(1.5)
                    .foregroundStyle(index == strata.count - 1 ? Theme.accent : Theme.textSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 8)
                    .frame(maxWidth: 250)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(BedrockColor.slate.opacity(0.4 + Double(index) * 0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(index == strata.count - 1 && assembled
                                      ? Theme.accent.opacity(0.5) : Theme.hairline))
                    .rotationEffect(.degrees(Double(scatter.rotation) * Double(1 - gather)))
                    .offset(x: scatter.x * (1 - gather), y: scatter.y * (1 - gather))
            }
        }
        .animation(Theme.Motion.reduced(.spring(response: 0.55, dampingFraction: 0.78), when: reduceMotion), value: gather)
        .accessibilityElement()
        .accessibilityLabel(assembled
            ? "Your reading, assembled: \(strata.joined(separator: ", "))"
            : "Your scattered answers: \(strata.joined(separator: ", ")). Use the button to bring them together.")
    }

    private func scatterOffset(_ i: Int) -> (x: CGFloat, y: CGFloat, rotation: CGFloat) {
        let seed = Double(i * 7 + 3)
        return (
            x: CGFloat(sin(seed * 12.9898) * 120),
            y: CGFloat(sin(seed * 78.233) * 110),
            rotation: CGFloat(sin(seed * 5.1) * 16)
        )
    }

    private func assemble() {
        withAnimation(Theme.Motion.reduced(.spring(response: 0.55, dampingFraction: 0.78), when: reduceMotion)) {
            gather = 1
            assembled = true
        }
        BedrockHaptics.stoneSet()
    }
}

// MARK: - S15 · What I See [paced reveal — tap to uncover]

struct RevealBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var uncovered = 1 // first line invites the first tap

    private var lines: [String] { model.revealLines }
    private var allShown: Bool { uncovered >= lines.count }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "WHAT I SEE")
                .padding(.top, Theme.Spacing.md)
            Spacer()
            VStack(spacing: Theme.Spacing.lg) {
                ForEach(0..<uncovered, id: \.self) { i in
                    CarveThenEmber(
                        text: lines[i],
                        font: .system(.title2, design: .serif, weight: .semibold),
                        embers: i == lines.count - 1)
                }
            }
            Spacer()
            Text(allShown ? "Tap to continue" : "Tap to uncover")
                .font(Theme.Typography.monoCaption)
                .tracking(2)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .padding(.bottom, Theme.Spacing.lg)
                .accessibilityHidden(true)
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture {
            if allShown {
                onNext()
            } else {
                BedrockHaptics.set()
                withAnimation(.smooth(duration: 0.4)) { uncovered += 1 }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(lines.prefix(uncovered).joined(separator: " "))
        .accessibilityHint(allShown ? "Tap to continue" : "Tap to uncover the next line")
    }
}

// MARK: - S16 · The Loop [Trace — the centerpiece]

struct LoopBeat: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "THE LOOP")
                .padding(.top, Theme.Spacing.md)
            Spacer(minLength: 0)

            LoopTracer {
                withAnimation(.smooth(duration: 0.5)) { completed = true }
            }

            if completed {
                ChiselText(
                    text: "It's not weakness. It's a groove worn by repetition — and it fills back in the same way. Your brain is built to rebuild.",
                    font: .system(.title3, design: .serif, weight: .semibold),
                    cadence: 0.035)
            }

            Spacer(minLength: 0)
            if completed {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(0.2, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - S17 · The Timeline [scrub to explore]

struct TimelineBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var progress: Double = 0

    private var stages: [TimelineScrubber.Stage] {
        [
            .init(label: "Days 1–3", detail: "loudest"),
            .init(label: "Days 4–10", detail: "hardest — then it loosens"),
            .init(label: "Weeks 2–4", detail: "clarity comes back"),
            .init(label: "Beyond", detail: "it stops running you"),
        ]
    }

    private var explored: Bool { voiceOver || reduceMotion || progress >= 0.9 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.sm)
            Text("Drag ahead — see what's coming.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .settleIn(reduceMotion: reduceMotion)

            TimelineScrubber(
                stages: stages,
                emphasisIndex: model.timelineEmphasis,
                destinationWord: model.bestSelfWord,
                progress: $progress)

            if explored {
                Text("Slip-ups aren't failure. They're data.\nBedrock holds either way.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .settleIn(reduceMotion: reduceMotion)
            }

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: "Continue") { onNext() }
                .disabled(!explored)
                .opacity(explored ? 1 : 0.45)
            StrugglingLink()
                .frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - S18 · The Door [hold — willpower demonstrated as futile]

struct DoorBeat: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "YOUR LAST BLOCKER")
                .padding(.top, Theme.Spacing.md)
            Spacer(minLength: 0)

            HoldTheDoor {
                withAnimation(.smooth(duration: 0.5)) { completed = true }
            }

            if completed {
                CarveThenEmber(
                    text: "Not a door you hold.\nA wall you don't think about.",
                    font: .system(.title3, design: .serif, weight: .semibold),
                    embers: true)
            }

            Spacer(minLength: 0)
            if completed {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(0.15, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
