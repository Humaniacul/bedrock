import SwiftUI

/// The reusable urge-surf core (§4 Intercept Moment, §6.5). Slows everything
/// down, shifts toward the calm `mineral` register, and breathes on a 4-7-8
/// rhythm. Used as gauntlet step 2 now; Phase 4 extends it for Panic/SOS and
/// block intercepts (adding trigger-naming + a replacement action).
struct UrgeSurfView: View {
    /// Minimum full breath cycles before the user can move on.
    var minCycles: Int = 1
    var collectsRating: Bool = true
    /// Called when the user is steady enough to continue, with their urge rating.
    var onContinue: (Int?) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: BreathPhase = .inhale
    @State private var secondsLeft = BreathPhase.inhale.seconds
    @State private var cycles = 0
    @State private var orbScale: CGFloat = 0.6
    @State private var urge: Double = 5

    private var canContinue: Bool { cycles >= minCycles }

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
            orb
            instruction
            Spacer()
            if collectsRating { rating }
            continueButton
        }
        .padding(Theme.Spacing.xl)
        .task { await runBreathing() }
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [BedrockColor.mineral.opacity(0.5), BedrockColor.mineral.opacity(0.05)],
                        center: .center, startRadius: 4, endRadius: 150
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(orbScale)
            Circle()
                .strokeBorder(BedrockColor.mineral.opacity(0.6), lineWidth: 2)
                .frame(width: 220, height: 220)
                .scaleEffect(orbScale)
            Text("\(secondsLeft)")
                .font(.system(size: 44, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement()
        .accessibilityLabel("\(phase.instruction), \(secondsLeft) seconds")
    }

    private var instruction: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(phase.instruction)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text(cycles >= minCycles ? "When you're ready, continue." : "Stay with the breath.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
        }
        .animation(.easeInOut, value: phase)
    }

    private var rating: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Text("How strong is the urge?")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(urge))")
                    .font(Theme.Typography.mono)
                    .foregroundStyle(Theme.textPrimary)
            }
            Slider(value: $urge, in: 1...10, step: 1)
                .tint(BedrockColor.mineral)
                .accessibilityLabel("Urge intensity")
                .accessibilityValue("\(Int(urge)) out of 10")
        }
    }

    private var continueButton: some View {
        Button(canContinue ? "I'm steady" : "Keep breathing…") {
            onContinue(collectsRating ? Int(urge) : nil)
        }
        .buttonStyle(.bedrockPrimary)
        .disabled(!canContinue)
    }

    private func runBreathing() async {
        while !Task.isCancelled {
            await step(.inhale, target: 1.0)
            await step(.hold, target: 1.0)
            await step(.exhale, target: 0.55)
            cycles += 1
        }
    }

    private func step(_ p: BreathPhase, target: CGFloat) async {
        phase = p
        withAnimation(reduceMotion ? nil : .easeInOut(duration: Double(p.seconds))) {
            orbScale = target
        }
        var left = p.seconds
        secondsLeft = left
        BedrockHaptics.calm()
        while left > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            left -= 1
            secondsLeft = left
        }
    }
}

enum BreathPhase: Equatable {
    case inhale, hold, exhale

    var seconds: Int {
        switch self {
        case .inhale: 4
        case .hold:   7
        case .exhale: 8
        }
    }

    var instruction: String {
        switch self {
        case .inhale: "Breathe in"
        case .hold:   "Hold"
        case .exhale: "Breathe out"
        }
    }
}

#Preview {
    ZStack {
        StoneBackground()
        UrgeSurfView { _ in }
    }
}
