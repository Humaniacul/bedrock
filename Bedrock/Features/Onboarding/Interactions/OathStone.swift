import SwiftUI

/// The press-and-hold forge (S20). As the user holds (~2.5s), ember light fills
/// the stone from within — molten metal setting into rock — with dust streaming
/// and a haptic ramp rising to a single deep Lock plus a faint settle-shake.
/// Releasing early resets gently, no penalty. VoiceOver / motor fallback: a
/// plain "Set the cornerstone" button with the same payoff.
struct OathStone: View {
    /// Disabled until the contract has a name in it.
    var enabled: Bool
    var onSealed: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    @State private var progress: CGFloat = 0
    @State private var dust = 0
    @State private var sealed = false
    @State private var shake = false
    @State private var dustTask: Task<Void, Never>?

    private let holdDuration: Double = 2.5

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            stone
            if voiceOver || reduceMotion {
                // Motor/VO fallback — same ceremony, one deliberate tap.
                Button("Set the cornerstone") { complete() }
                    .buttonStyle(.bedrockPrimary)
                    .disabled(!enabled || sealed)
            } else {
                Text(sealed ? "Set." : enabled ? "Press and hold to set it." : "Sign it first.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .onDisappear { dustTask?.cancel() }
    }

    private var stone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(BedrockColor.slate)
            // Molten core: light fills from within as the hold progresses.
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(
                    RadialGradient(
                        colors: [BedrockColor.emberGlow.opacity(0.85), Theme.accent.opacity(0.55), .clear],
                        center: .center, startRadius: 4, endRadius: 130))
                .opacity(progress)
                .scaleEffect(0.65 + 0.35 * progress)
            Image(systemName: sealed ? "checkmark.seal.fill" : "hammer.fill")
                .font(.system(size: 30))
                .foregroundStyle(sealed ? Theme.onAccent : (progress > 0.05 ? Theme.onAccent : Theme.textSecondary))
            StoneParticles(trigger: dust, color: BedrockColor.ash, burst: 4)
        }
        .frame(width: 196, height: 132)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.accent.opacity(0.25 + progress * 0.6), lineWidth: 1.5))
        .shadow(color: BedrockColor.ember.opacity(progress * 0.65), radius: 8 + progress * 26, y: 6)
        .rotationEffect(.degrees(shake ? 0.7 : 0))
        .opacity(enabled || sealed ? 1 : 0.5)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 90) {
            complete()
        } onPressingChanged: { pressing in
            guard enabled, !sealed else { return }
            if pressing { beginHold() } else { cancelHold() }
        }
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Set the cornerstone")
        .accessibilityHint("Seals your commitment")
        .accessibilityAction { complete() }
    }

    private func beginHold() {
        BedrockHaptics.oathRamp(duration: holdDuration)
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }
        dustTask?.cancel()
        dustTask = Task {
            while !Task.isCancelled {
                dust += 1
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }

    private func cancelHold() {
        BedrockHaptics.stopRamp()
        dustTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) { progress = 0 }
    }

    private func complete() {
        guard enabled, !sealed else { return }
        dustTask?.cancel()
        BedrockHaptics.stopRamp()
        BedrockHaptics.stoneSet() // the deep Lock
        withAnimation(.easeInOut(duration: 0.1)) {
            progress = 1
            shake = true
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) { shake = false }
        withAnimation(Theme.Motion.reduced(.smooth(duration: 0.4).delay(0.15), when: reduceMotion)) {
            sealed = true
        }
        // Let the stone land before the flow moves.
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 900))
            onSealed()
        }
    }
}
