import SwiftUI

// ACT I — THE THRESHOLD (spec S1–S6): disarm, earn "they get me," reframe past
// failure as relief. Emotional beats have no chrome; tempo is the cinematography.

// MARK: - S1 · Cold Open

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

// MARK: - S2 · The Disarm — protect this screen above all

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
                .init(text: "You're not weak.",
                      font: .system(.largeTitle, design: .serif, weight: .semibold)),
                .init(text: "You're just up against something\nengineered to win.",
                      ember: true),
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

// MARK: - S3 · Recognition — the screen people screenshot

struct RecognitionBeat: View {
    var onNext: () -> Void
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "The thing you reach for\nbefore you're even awake."),
                .init(text: "The tab you open\nwhen no one is watching."),
                .init(text: "The scroll that swallows the night\nand gives nothing back."),
            ], dimsPrevious: true, interlinePause: 1.2) { finished = true }
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

// MARK: - S4 · The Cycle & Why It Didn't Hold

struct CycleBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false
    @State private var ghostsGone = false
    @State private var planeSet = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ghosts
                .frame(height: 64)
                .accessibilityHidden(true)
            CarveSequence(lines: [
                .init(text: "You've tried to stop before.\nAn app. A promise to yourself.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "And it held —\nuntil it didn't.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "Every blocker you've used\nwas built to be undone.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "Willpower against a machine that never sleeps\nwas never a fair fight.",
                      ember: true),
            ], spacing: Theme.Spacing.md, interlinePause: 0.6) {
                setPlane()
            }
            if planeSet {
                // The solid ground arriving under the story (Settle, .heavy).
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 200, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(Theme.accent.opacity(0.4)))
                    .settleIn(reduceMotion: reduceMotion)
                    .accessibilityHidden(true)
            }
            Spacer()
            TapToContinue(visible: finished)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture { if finished { onNext() } }
        .task {
            guard !reduceMotion else { ghostsGone = true; return }
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeIn(duration: 1.6)) { ghostsGone = true }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }

    /// Ghosted generic-blocker icons that drift and dissolve.
    private var ghosts: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ForEach(Array(["shield.slash", "app.dashed", "hand.raised.slash"].enumerated()), id: \.offset) { i, symbol in
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(BedrockColor.ash.opacity(0.5))
                    .offset(y: ghostsGone ? -14 - CGFloat(i) * 6 : 0)
                    .opacity(ghostsGone ? 0 : 1)
                    .blur(radius: ghostsGone ? 4 : 0)
            }
        }
    }

    private func setPlane() {
        withAnimation { planeSet = true }
        BedrockHaptics.stoneSet()
        finished = true
    }
}

// MARK: - S5 · The Turn

struct TurnBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Bedrock isn't another door\nyou hold shut."),
                .init(text: "It's the ground you stand on.", ember: true),
                .init(text: "Let's build it together.",
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

// MARK: - S6 · Permission to Begin

struct PermissionBeat: View {
    var onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Before I can hold anything steady,\nI need to understand you."),
                .init(text: "Honest answers.\nNo one sees these but you.",
                      font: .system(.title3, design: .serif, weight: .medium)),
            ], interlinePause: 0.6) { finished = true }
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
