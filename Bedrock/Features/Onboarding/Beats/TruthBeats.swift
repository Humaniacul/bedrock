import SwiftUI

// ACT III — THE TRUTH (spec S14–S18): honest insight, real mechanism, grounded
// hope. The synthesis is an honest pause (their answers visibly assemble) — no
// fake spinner, no fabricated benchmark, no numeric score. Ever.

// MARK: - S14 · The Synthesis

struct SynthesisBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var subline = "Reading your pattern…"

    /// Their real inputs, assembling as labeled strata.
    private var strataLabels: [String] {
        var labels: [String] = []
        if let first = OnboardingModel.motivationOptions.first(where: { model.motivation.contains($0) }) {
            labels.append(first)
        }
        if let span = model.duration { labels.append(span.label) }
        if let trigger = OnboardingModel.triggerOptions.first(where: { model.triggers.contains($0) }) {
            labels.append(trigger)
        }
        if let cost = OnboardingModel.costOptions.first(where: { model.costs.contains($0) }) {
            labels.append(cost)
        }
        labels.append(model.bestSelfWord.capitalized)
        return labels
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ChiselText(
                text: "Give me a moment.",
                font: .system(.title2, design: .serif, weight: .semibold),
                cadence: 0.05)

            // The column of who they are, assembling (Strata).
            VStack(spacing: 6) {
                ForEach(Array(strataLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(Theme.Typography.monoCaption)
                        .tracking(1.5)
                        .foregroundStyle(index == strataLabels.count - 1 ? Theme.accent : Theme.textSecondary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 7)
                        .frame(maxWidth: 260)
                        .background(RoundedRectangle(cornerRadius: 6)
                            .fill(BedrockColor.slate.opacity(0.4 + Double(index) * 0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(index == strataLabels.count - 1
                                          ? Theme.accent.opacity(0.5) : Theme.hairline))
                        .strata(index, base: 0.9, reduceMotion: reduceMotion)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Your answers, assembling: \(strataLabels.joined(separator: ", "))")

            Text(subline)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.opacity)
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .task {
            // Honest duration: ~3.5s of real assembly, then move on.
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.2 : 2.1))
            withAnimation(.easeInOut(duration: 0.4)) {
                subline = "Finding the version of you underneath."
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.8 : 1.6))
            guard !Task.isCancelled else { return } // left mid-pause — don't advance
            BedrockHaptics.stoneSet()
            onNext()
        }
    }
}

// MARK: - S15 · What I See (the reveal — Peak 1)

struct RevealBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(
                lines: model.revealLines.enumerated().map { index, text in
                    CarveSequence.Line(
                        text: text,
                        font: index == 0
                            ? .system(.largeTitle, design: .serif, weight: .semibold)
                            : .system(.title2, design: .serif, weight: .semibold),
                        ember: index == model.revealLines.count - 1)
                },
                interlinePause: 1.0
            ) { finished = true }
            .breath(finished, reduceMotion: reduceMotion)
            Spacer()
            TapToContinue(visible: finished)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture { if finished { onNext() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }
}

// MARK: - S16 · How It Works, and The Good News

struct LoopScienceBeat: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage = 0       // 0 loop drawing, 1 crack, 2 smoothing
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            loopDiagram
                .frame(height: 130)
                .accessibilityHidden(true)
            CarveSequence(lines: [
                .init(text: "It works in a loop. A trigger, a craving,\na few seconds of relief — then it's gone,\nand the loop is a little deeper.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "It's not weakness.\nIt's a groove worn by repetition.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "And a groove worn by repetition\ncan be worn smooth by repetition too.",
                      font: .system(.title3, design: .serif, weight: .semibold), ember: true),
                .init(text: "Every urge you don't act on, it fills in a little.\nYour brain is built to rebuild. That's biology.",
                      font: .system(.callout, design: .serif, weight: .medium)),
            ], spacing: Theme.Spacing.md, interlinePause: 0.7) {
                finished = true
            }
            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
        .task {
            guard !reduceMotion else { stage = 2; return }
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeInOut(duration: 0.5)) { stage = 1 }
            try? await Task.sleep(for: .seconds(3.4))
            withAnimation(.easeInOut(duration: 1.6)) { stage = 2 }
        }
    }

    /// Trigger → craving → relief, carved node by node; the relief node cracks,
    /// then the groove smooths and dawn pours in.
    private var loopDiagram: some View {
        HStack(spacing: Theme.Spacing.md) {
            node("bolt.fill", "trigger", index: 0)
            arrow
            node("flame.fill", "craving", index: 1)
            arrow
            node(stage >= 1 ? "seal" : "seal.fill", "relief", index: 2)
                .overlay {
                    if stage >= 1 {
                        Image(systemName: stage >= 2 ? "leaf.fill" : "bolt.horizontal")
                            .font(.caption)
                            .foregroundStyle(stage >= 2 ? BedrockColor.emberGlow : BedrockColor.ash)
                            .offset(y: -26)
                            .transition(.opacity)
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func node(_ symbol: String, _ label: String, index: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(stage >= 2 ? BedrockColor.emberGlow : Theme.accent)
                .frame(width: 46, height: 46)
                .background(Circle().fill(BedrockColor.slate.opacity(0.6)))
                .overlay(Circle().strokeBorder(stage >= 2 ? BedrockColor.emberGlow.opacity(0.5) : Theme.hairline))
            Text(label)
                .font(Theme.Typography.monoCaption)
                .foregroundStyle(Theme.textSecondary)
        }
        .strata(index, base: 0.4, reduceMotion: reduceMotion)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.caption)
            .foregroundStyle(Theme.textSecondary.opacity(0.6))
    }
}

// MARK: - S17 · Your Timeline

struct TimelineBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var milestones: [(label: String, detail: String)] {
        [
            ("Days 1–3", "the decision is loudest"),
            ("Days 4–10", "the hardest stretch — urges spike, then loosen"),
            ("Weeks 2–4", "clarity returns"),
            ("Beyond", "it stops running your life"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.sm)
            ChiselText(
                text: "Here's what's ahead — honestly.",
                font: .system(.title, design: .serif, weight: .semibold),
                alignment: .leading)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
                        Text(milestone.label)
                            .font(Theme.Typography.monoCaption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(index == model.timelineEmphasis ? Theme.accent : Theme.textSecondary)
                            .frame(width: 86, alignment: .leading)
                        Text(milestone.detail)
                            .font(index == model.timelineEmphasis
                                  ? Theme.Typography.callout.weight(.semibold)
                                  : Theme.Typography.callout)
                            .foregroundStyle(index == model.timelineEmphasis ? Theme.textPrimary : Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(BedrockColor.slate.opacity(index == model.timelineEmphasis ? 0.7 : 0.35)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(index == model.timelineEmphasis ? Theme.accent.opacity(0.5) : Theme.hairline))
                    .strata(index, base: 0.5, reduceMotion: reduceMotion)
                }
            }

            if appeared {
                HStack(spacing: 6) {
                    Text("Destination:")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                    EmberPhrase(text: model.bestSelfWord, font: .system(.body, design: .serif, weight: .semibold), delay: 0.3)
                }
                .frame(maxWidth: .infinity)
                .settleIn(reduceMotion: reduceMotion)

                Text("Slip-ups aren't failure. They're data.\nBedrock holds the line either way.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .settleIn(0.1, reduceMotion: reduceMotion)
            }

            Spacer(minLength: 0)
            if appeared {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(0.15, reduceMotion: reduceMotion)
                StrugglingLink()
                    .frame(maxWidth: .infinity)
                    .settleIn(0.25, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
        .task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 1.6))
            withAnimation { appeared = true }
        }
    }
}

// MARK: - S18 · Why Friction Beats Willpower

struct FrictionBeat: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorDown = false
    @State private var wallSet = false
    @State private var finished = false
    @State private var flickerTask: Task<Void, Never>?
    @State private var doorOpacity: Double = 1

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            doorVsWall
                .frame(height: 110)
                .accessibilityHidden(true)
            CarveSequence(lines: [
                .init(text: "You already know willpower runs out.\nYou've tested it.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "So Bedrock doesn't ask for more of it.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "It changes the architecture — so the door\nstays shut even when you'd open it.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "Not a door you hold.\nA wall you don't think about.", ember: true),
            ], spacing: Theme.Spacing.md, interlinePause: 0.6) {
                landWall()
            }
            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear { startFlicker() }
        .onDisappear { flickerTask?.cancel() }
    }

    private var doorVsWall: some View {
        ZStack {
            // The fragile held door — flickering, then settling down and away.
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(BedrockColor.ash.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .frame(width: 84, height: 104)
                .opacity(doorDown ? 0 : doorOpacity)
                .offset(y: doorDown ? 30 : 0)
                .blur(radius: doorDown ? 3 : 0)
            // The wall that Locks into its place.
            if wallSet {
                FoundationWall(blocks: 5)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.8), when: reduceMotion), value: doorDown)
    }

    private func startFlicker() {
        guard !reduceMotion else { return }
        flickerTask = Task { @MainActor in
            while !Task.isCancelled && !doorDown {
                doorOpacity = Double.random(in: 0.35...1)
                try? await Task.sleep(for: .milliseconds(Int.random(in: 180...420)))
            }
        }
    }

    private func landWall() {
        flickerTask?.cancel()
        withAnimation { doorDown = true }
        withAnimation(Theme.Motion.reduced(.spring(response: 0.45, dampingFraction: 0.7).delay(0.5), when: reduceMotion)) {
            wallSet = true
        }
        BedrockHaptics.stoneSet() // the Lock
        finished = true
    }
}
