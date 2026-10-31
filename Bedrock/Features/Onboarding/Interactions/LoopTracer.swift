import SwiftUI

/// Trace (spec v2 S16) — embodied neuroscience, the centerpiece.
/// The user walks the loop with their thumb: tap Trigger → craving swells →
/// tap Relief → it fizzles to nothing and the groove deepens. Twice.
/// Then: "Now — don't." An urge rises on its own, and instead of tapping
/// Relief they HOLD "Let it pass" while it crests and fades — and the groove
/// fills a little, dawn seeping in. They perform neuroplasticity.
struct LoopTracer: View {
    /// Fires once the pass-through succeeds (parent then reveals the payoff).
    var onCompleted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    private enum Phase: Equatable {
        case waitingTrigger      // tap Trigger
        case cravingRising       // auto ~0.9s
        case waitingRelief       // tap Relief
        case fizzling            // auto ~0.8s, groove deepens
        case dontIntro           // "Now — don't." urge rises on its own
        case holding             // hold "Let it pass"
        case passed              // groove fills, dawn
    }

    @State private var phase: Phase = .waitingTrigger
    @State private var cycle = 0                 // 0, 1 — two walked loops
    @State private var craving: CGFloat = 0      // 0…1 meter
    @State private var grooveDepth: CGFloat = 0.15
    @State private var dawn = false
    @State private var holdProgress: CGFloat = 0
    @State private var urgeTask: Task<Void, Never>?

    private let holdDuration: Double = 2.6

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            instruction
                .frame(minHeight: 44)

            // The craving meter — swells and fizzles under their taps.
            cravingMeter

            // The loop nodes.
            HStack(spacing: Theme.Spacing.xl) {
                node("bolt.fill", "Trigger", active: phase == .waitingTrigger) {
                    fireTrigger()
                }
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .accessibilityHidden(true)
                node("seal.fill", "Relief", active: phase == .waitingRelief) {
                    fireRelief()
                }
            }

            // The groove — worn by repetition, filled by repetition.
            groove

            if phase == .dontIntro || phase == .holding {
                holdButton
                    .settleIn(reduceMotion: reduceMotion)
            }
        }
        .onDisappear { urgeTask?.cancel() }
        .onAppear { if voiceOver || reduceMotion { /* fallback drives via buttons */ } }
    }

    // MARK: - Pieces

    private var instruction: some View {
        Group {
            switch phase {
            case .waitingTrigger:
                Text(cycle == 0 ? "This is the loop you've been in. Walk it — tap the trigger."
                                : "Once more. Tap the trigger.")
            case .cravingRising:
                Text("The craving swells…")
            case .waitingRelief:
                Text("And you know what comes next. Tap it.")
            case .fizzling:
                Text("A few seconds of relief — then gone. And the groove cuts deeper.")
            case .dontIntro, .holding:
                Text("Now — don't. Hold ‘Let it pass' while the urge crests.")
            case .passed:
                Text("It passed. And the groove filled in — a little.")
            }
        }
        .font(Theme.Typography.callout)
        .foregroundStyle(Theme.textSecondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.3), when: reduceMotion), value: phase)
    }

    private var cravingMeter: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(BedrockColor.basalt.opacity(0.6))
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Theme.accent, BedrockColor.emberGlow],
                                     startPoint: .bottom, endPoint: .top))
                .frame(height: max(0, 92 * craving))
                .frame(maxWidth: .infinity)
        }
        .frame(width: 52, height: 92)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairline))
        .accessibilityElement()
        .accessibilityLabel("Craving meter")
        .accessibilityValue(craving > 0.6 ? "High" : craving > 0.2 ? "Rising" : "Quiet")
    }

    private func node(_ symbol: String, _ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(active ? Theme.onAccent : Theme.textSecondary)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(active ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(BedrockColor.slate.opacity(0.6))))
                    .overlay(Circle().strokeBorder(active ? Theme.accent : Theme.hairline))
                    .breath(active && !reduceMotion, reduceMotion: reduceMotion)
                Text(label)
                    .font(Theme.Typography.monoCaption)
                    .foregroundStyle(active ? Theme.textPrimary : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .accessibilityHint(active ? "Tap to continue the loop" : "")
    }

    /// The groove: a slot in the stone that deepens with each pass, then fills.
    private var groove: some View {
        ZStack {
            Capsule()
                .fill(BedrockColor.slate.opacity(0.55))
                .frame(height: 18)
            Capsule()
                .fill(dawn
                      ? AnyShapeStyle(LinearGradient(colors: [BedrockColor.emberGlow.opacity(0.45), Theme.accent.opacity(0.3)],
                                                     startPoint: .leading, endPoint: .trailing))
                      : AnyShapeStyle(Color.black.opacity(0.75)))
                .frame(width: 170, height: 12 * grooveDepth + 4)
        }
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.9), when: reduceMotion), value: grooveDepth)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 1.2), when: reduceMotion), value: dawn)
        .accessibilityElement()
        .accessibilityLabel("The groove")
        .accessibilityValue(dawn ? "Filling back in" : grooveDepth > 0.6 ? "Deep" : "Wearing deeper")
    }

    private var holdButton: some View {
        ZStack {
            Capsule()
                .fill(BedrockColor.slate.opacity(0.7))
            Capsule()
                .fill(LinearGradient(colors: [Theme.accent.opacity(0.7), BedrockColor.emberGlow.opacity(0.5)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 220 * holdProgress)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Let it pass")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: 220, height: 54)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.5)))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 80) {
            passed()
        } onPressingChanged: { pressing in
            guard phase == .dontIntro || phase == .holding else { return }
            if pressing { beginHold() } else if phase == .holding { releaseEarly() }
        }
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Let it pass")
        .accessibilityHint("Hold while the urge crests and fades")
        .accessibilityAction { passed() } // VO fallback: single activate completes
    }

    // MARK: - The walked loop

    private func fireTrigger() {
        guard phase == .waitingTrigger else { return }
        BedrockHaptics.selection()
        phase = .cravingRising
        withAnimation(reduceMotion ? nil : .easeIn(duration: 0.9)) { craving = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 950))
            guard !Task.isCancelled, phase == .cravingRising else { return }
            phase = .waitingRelief
        }
    }

    private func fireRelief() {
        guard phase == .waitingRelief else { return }
        BedrockHaptics.set()
        phase = .fizzling
        // Relief fizzles to nothing — hollow, not rewarding.
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) { craving = 0 }
        BedrockHaptics.calm()
        grooveDepth = min(1, grooveDepth + 0.4)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 1500))
            guard !Task.isCancelled else { return }
            if cycle == 0 {
                cycle = 1
                phase = .waitingTrigger
            } else {
                startDont()
            }
        }
    }

    // MARK: - "Now — don't."

    private func startDont() {
        phase = .dontIntro
        // The urge rises on its own this time.
        withAnimation(reduceMotion ? nil : .easeIn(duration: 1.6)) { craving = 0.85 }
    }

    private func beginHold() {
        phase = .holding
        BedrockHaptics.oathRamp(duration: holdDuration)
        withAnimation(.linear(duration: holdDuration)) { holdProgress = 1 }
        // The urge crests, then fades under the hold.
        urgeTask?.cancel()
        urgeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: holdDuration - 0.6)) { craving = 0 }
        }
    }

    private func releaseEarly() {
        // No penalty — the urge is still there; hold again.
        BedrockHaptics.stopRamp()
        urgeTask?.cancel()
        phase = .dontIntro
        withAnimation(.easeOut(duration: 0.4)) {
            holdProgress = 0
            craving = max(craving, 0.7)
        }
    }

    private func passed() {
        guard phase == .holding || phase == .dontIntro else { return }
        urgeTask?.cancel()
        BedrockHaptics.stopRamp()
        BedrockHaptics.stoneSet()
        phase = .passed
        withAnimation(reduceMotion ? nil : .easeOut(duration: 1.2)) {
            craving = 0
            holdProgress = 1
            grooveDepth = max(0.2, grooveDepth - 0.35)
        }
        dawn = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 1100))
            guard !Task.isCancelled else { return }
            onCompleted()
        }
    }
}
