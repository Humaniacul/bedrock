import SwiftUI

// ACT I — THE THRESHOLD (spec v2 S1–S5): disarm freely, then make them admit
// it themselves. S2 is one of only four "gift" reads in the whole flow —
// everywhere else in this act, the user works.

// MARK: - S1 · Cold Open [watch]

struct ColdOpenBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var advanced = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ChiselText(
                text: "Bedrock",
                font: .system(size: 46, weight: .semibold, design: .serif),
                cadence: 0.09)
            // A thin dawn-ember horizon, breathing once.
            Capsule()
                .fill(LinearGradient(colors: [.clear, Theme.accent.opacity(0.8), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 150, height: 1.5)
                .breath(reduceMotion: reduceMotion)
                .accessibilityHidden(true)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.2 : 2.6))
            guard !Task.isCancelled else { return } // jumped/left — don't advance
            advance()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Bedrock. Tap to begin.")
    }

    private func advance() {
        guard !advanced else { return }
        advanced = true
        onNext()
    }
}

// MARK: - S2 · The Disarm [read — a gift, given freely]

struct DisarmBeat: View {
    var onNext: () -> Void
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "THE THRESHOLD")
                .padding(.top, Theme.Spacing.xl)
            Spacer()
            CarveSequence(lines: [
                .init(text: "You're not broken.",
                      font: .system(.largeTitle, design: .serif, weight: .semibold)),
                .init(text: "You're up against something\nengineered to win.", ember: true),
            ], interlinePause: 0.7) { finished = true }
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

// MARK: - S3 · Recognize [the first real work]

struct RecognizeBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: Set<String> = []
    @State private var payoffShown = false

    var body: some View {
        ZStack {
            GatheringShadow(count: selected.count)
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.sm)
                Text("Be honest.")
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .settleIn(reduceMotion: reduceMotion)
                Text("Which of these do you know?")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .settleIn(0.08, reduceMotion: reduceMotion)

                RecognizeGrid(options: OnboardingModel.recognizeOptions, selected: $selected)

                if payoffShown {
                    ChiselText(
                        text: "You just named it. Most men never do.",
                        font: .system(.title3, design: .serif, weight: .semibold),
                        cadence: 0.04)
                        .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .disabled(selected.isEmpty)
                    .opacity(selected.isEmpty ? 0.45 : 1)
            }
            .padding(Theme.Spacing.xl)
        }
        .onChange(of: selected) { _, new in
            if !new.isEmpty && !payoffShown {
                withAnimation(.smooth(duration: 0.5)) { payoffShown = true }
            }
        }
    }
}

// MARK: - S4 · Reckon [the honest cost, self-set]

struct ReckonBeat: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var payoffShown = false

    private var hasReckoned: Bool { model.dayCostEstimate > 0.04 }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.sm)
            Text("We won't invent a number.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .settleIn(reduceMotion: reduceMotion)
            Text("You tell us — how much of your day\ndoes it quietly take?")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .settleIn(0.08, reduceMotion: reduceMotion)

            HStack(spacing: Theme.Spacing.xl) {
                ReckonDial(value: $model.dayCostEstimate)
                VStack(alignment: .leading, spacing: 6) {
                    Text("ONE DAY")
                        .font(Theme.Typography.monoCaption)
                        .tracking(2.5)
                        .foregroundStyle(Theme.textSecondary.opacity(0.8))
                    Text(hasReckoned ? model.dayCostLabel : "Drag the dial")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(hasReckoned ? Theme.accent : Theme.textSecondary)
                        .animation(.easeInOut(duration: 0.3), value: model.dayCostLabel)
                    if hasReckoned {
                        Text("Your estimate.\nNo one else's.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(width: 130, alignment: .leading)
            }
            .settleIn(0.15, reduceMotion: reduceMotion)

            if payoffShown {
                ChiselText(
                    text: "That's what we're getting back.",
                    font: .system(.title3, design: .serif, weight: .semibold),
                    cadence: 0.04)
            }

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: "Continue") { onNext() }
                .disabled(!hasReckoned)
                .opacity(hasReckoned ? 1 : 0.45)
        }
        .padding(Theme.Spacing.xl)
        .onChange(of: hasReckoned) { _, reckoned in
            if reckoned && !payoffShown {
                withAnimation(.smooth(duration: 0.5)) { payoffShown = true }
            }
        }
    }
}

// MARK: - S5 · The Turn [read + CTA — short]

struct TurnBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Every blocker you've tried\nwas built to be undone."),
                .init(text: "This one isn't.", ember: true),
                .init(text: "Let's build the ground you stand on.",
                      font: .system(.title3, design: .serif, weight: .medium)),
            ], interlinePause: 0.7) { finished = true }
            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "Begin") { onNext() }
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - S6 · Permission [minimal + CTA]

struct PermissionBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Answer honestly.\nNo one sees these but you.",
                      font: .system(.title2, design: .serif, weight: .semibold)),
            ], interlinePause: 0.4) { finished = true }
            if finished {
                Label("Stored on your device.", systemImage: "iphone.and.arrow.forward.inward")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .settleIn(reduceMotion: reduceMotion)
            }
            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "I'm ready") { onNext() }
                    .settleIn(0.1, reduceMotion: reduceMotion)
                StrugglingLink()
                    .settleIn(0.2, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
