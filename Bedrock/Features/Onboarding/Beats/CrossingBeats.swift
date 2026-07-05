import SwiftUI
import StoreKit

// ACT V — THE CROSSING (spec S25.5–S28): the paywall as the story's conclusion.
// S27 itself is PaywallView(.onboarding); these are the frames around it.

/// ⚠️ MOCK values for UI preview — // VERIFY BEFORE LAUNCH.
/// Replace with real, sourced numbers and real, consented quotes (first name +
/// one detail only, plain, no photos) or REMOVE the pills/carousel entirely.
/// Apple rejects fabricated statistics — and so does this brand.
enum OnboardingStat {
    static let rating = "4.8 App Store"            // VERIFY
    static let rebuilding = "12,400+ rebuilding"   // VERIFY
    static let holding = "89% holding at 30 days"  // VERIFY
    static let testimonials: [(quote: String, who: String)] = [ // VERIFY — must be real + consented
        ("First thing in 6 years that held past week two.", "Daniel, 27"),
        ("The 2am wall doesn't move. That's the whole thing.", "M., 31"),
        ("My why comes up right when I need it. Hard to explain how much that helps.", "Ren, 24"),
    ]
}

// MARK: - S25.5 · You're Not the Only One (quiet, not loud)

struct SocialProofBeat: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview
    @State private var page = 0
    @State private var rotateTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "THE ONES WHO HELD")
                .padding(.top, Theme.Spacing.md)
            Spacer(minLength: 0)
            Text("Thousands of men are on this exact ground with you — most too ashamed to say it out loud.")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .settleIn(reduceMotion: reduceMotion)
            Text("You're just one of the ones doing something about it.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .settleIn(0.1, reduceMotion: reduceMotion)

            // Three quiet stone seals.
            HStack(spacing: Theme.Spacing.sm) {
                statPill(OnboardingStat.rating, index: 0)
                statPill(OnboardingStat.rebuilding, index: 1)
                statPill(OnboardingStat.holding, index: 2)
            }
            .padding(.top, Theme.Spacing.sm)

            // Carved lines on slate, rotating gently.
            testimonialCard
                .settleIn(0.4, reduceMotion: reduceMotion)

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(Theme.Spacing.xl)
        .onAppear { startRotation() }
        .onDisappear { rotateTask?.cancel() }
        .task {
            // Apple rate-limits this; it shows at most a few times a year.
            try? await Task.sleep(for: .seconds(1.2))
            requestReview()
        }
    }

    private func statPill(_ text: String, index: Int) -> some View {
        Text(text)
            .font(Theme.Typography.monoCaption)
            .tracking(0.5)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.55)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
            .strata(index, base: 0.2, reduceMotion: reduceMotion)
    }

    private var testimonialCard: some View {
        let item = OnboardingStat.testimonials[page]
        return VStack(spacing: Theme.Spacing.sm) {
            Text("“\(item.quote)”")
                .font(.system(.body, design: .serif, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(item.who)")
                .font(Theme.Typography.monoCaption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                 startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
        .id(page)
        .transition(.opacity)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.6), when: reduceMotion), value: page)
        .accessibilityElement()
        .accessibilityLabel("Quote: \(item.quote) — \(item.who)")
    }

    private func startRotation() {
        guard !reduceMotion else { return }
        rotateTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4.2))
                guard !Task.isCancelled else { return }
                page = (page + 1) % OnboardingStat.testimonials.count
            }
        }
    }
}

// MARK: - S26 · The Bridge (no price yet — kills whiplash)

struct BridgeBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            // Their finished foundation holds in dawn light.
            FoundationWall(blocks: 5, capstone: model.bestSelfWord)
                .breath(reduceMotion: reduceMotion)
            CarveSequence(lines: [
                .init(text: "You've built something real here."),
                .init(text: "Bedrock works for one reason:\nit doesn't bend.", ember: true),
                .init(text: "Keeping it that way is the next step\nof the same decision you just made.",
                      font: .system(.title3, design: .serif, weight: .medium)),
            ], interlinePause: 0.7) { finished = true }
            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "Continue") { onNext() }
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - S28 · Day One (grounded — not euphoric)

struct DayOneBeat: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onDone: () -> Void

    @State private var finished = false
    @State private var whyShown = false

    private var why: String { model.whyLine.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Welcome to solid ground."),
                .init(text: "Day one starts now.", ember: true),
                .init(text: "When the first urge comes — and it will —\npress this. Your why is waiting.",
                      font: .system(.title3, design: .serif, weight: .medium)),
            ], interlinePause: 0.7) {
                withAnimation { finished = true }
            }

            if finished {
                // The in-app lifeline, previewed exactly as it will live on home.
                Button {
                    BedrockHaptics.stoneSet()
                    withAnimation(.smooth(duration: 0.4)) { whyShown = true }
                } label: {
                    Label("The urge is here", systemImage: "hand.raised.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Capsule().fill(Theme.accent))
                }
                .buttonStyle(.plain)
                .settleIn(reduceMotion: reduceMotion)
                .accessibilityHint("In the app, this opens your intercept moment.")

                if whyShown, !why.isEmpty {
                    CornerstoneView(line: why, sub: model.commitmentName.isEmpty ? nil : "— \(model.commitmentName)")
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }

            Spacer()
            if finished {
                OnboardingPrimaryButton(title: "Enter Bedrock") {
                    model.complete(services: services)
                    BedrockHaptics.milestone()
                    onDone()
                }
                .settleIn(0.15, reduceMotion: reduceMotion)
                StrugglingLink()
                    .settleIn(0.25, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
