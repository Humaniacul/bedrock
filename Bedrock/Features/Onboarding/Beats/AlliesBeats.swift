import SwiftUI

// MARK: - Sand vs. rock

struct SandToRockView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var set = false
    @State private var blow = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ZStack {
                // The bedrock revealed beneath.
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 168, height: 96)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.accent.opacity(0.4)))
                    .opacity(set ? 1 : 0)
                    .scaleEffect(set ? 1 : 0.92)
                // The sand that blows away.
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(BedrockColor.ash.opacity(0.4))
                    .frame(width: 168, height: 96)
                    .opacity(set ? 0 : 0.85)
                    .offset(x: set ? 50 : 0)
                    .blur(radius: set ? 6 : 0)
                StoneParticles(trigger: blow, color: BedrockColor.ash, burst: 5)
            }
            .frame(height: 120)
            .accessibilityHidden(true)

            ChiselText(
                text: "You've been building on sand. Every urge washes a little more away.",
                font: .system(.title2, design: .serif, weight: .semibold))
            Text("We're going to pour bedrock.")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.accent)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .task {
            if reduceMotion { set = true; return }
            for _ in 0..<5 { blow += 1; try? await Task.sleep(for: .milliseconds(90)) }
            withAnimation(.easeInOut(duration: 1.0)) { set = true }
            try? await Task.sleep(for: .seconds(0.6))
            BedrockHaptics.set()
        }
    }
}

// MARK: - The founder's vow (humanize)

// ⚠️ FOUNDER: rewrite this in your own voice and make it TRUE to your story.
// Real beats cheesy every time — name what you actually watched happen, and why
// you actually built this. The signature should be you.
struct FoundersVowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var carved = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .riseIn(0, reduceMotion: reduceMotion)
            ChiselText(
                text: "Why we built this.",
                font: .system(.title, design: .serif, weight: .semibold),
                onFinished: { withAnimation(.smooth(duration: 0.5)) { carved = true } })
            Group {
                Text("We didn't build Bedrock to get rich off your worst nights. We built it because we watched people we love lose years to this — and every app that was supposed to help just asked them to try harder.\n\nSo we made the one we wished they'd had. The one that actually holds.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("You're not a user to us. You're the reason this exists.")
                    .font(.system(.body, design: .serif, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("— The team behind Bedrock")
                    .font(Theme.Typography.monoCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .opacity(carved ? 1 : 0)
            .animation(.smooth(duration: 0.6), value: carved)

            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
                .opacity(carved ? 1 : 0)
                .animation(.smooth(duration: 0.4), value: carved)
                .allowsHitTesting(carved)
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - The four guardians (promises, not features)

struct LayersView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void

    private struct Guardian { let icon: String, promise: String }
    private let guardians: [Guardian] = [
        .init(icon: "shield.fill", promise: "We stand at the door — so what pulls you in can't reach you."),
        .init(icon: "lock.fill", promise: "We hand the key to your future self — so a weak moment can't undo a strong decision."),
        .init(icon: "person.2.fill", promise: "We put someone quietly in your corner — so you never fight alone."),
        .init(icon: "eye.fill", promise: "We learn your hardest hour — and we're there before it arrives."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()
            Text("Here's how we hold you.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .riseIn(0, reduceMotion: reduceMotion)

            VStack(spacing: Theme.Spacing.md) {
                ForEach(Array(guardians.enumerated()), id: \.offset) { index, guardian in
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: guardian.icon)
                            .font(.title3).foregroundStyle(Theme.accent).frame(width: 30)
                        Text(guardian.promise)
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(Theme.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.5)))
                    .riseIn(0.2 + Double(index) * 0.2, reduceMotion: reduceMotion)
                }
            }

            Text("When one layer gives, the others hold.")
                .font(.system(.body, design: .serif, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .riseIn(0.2 + Double(guardians.count) * 0.2, reduceMotion: reduceMotion)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.3 + Double(guardians.count) * 0.2, reduceMotion: reduceMotion)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
    }
}
