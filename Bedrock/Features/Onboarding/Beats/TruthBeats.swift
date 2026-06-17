import SwiftUI

// MARK: - The machine (engineered dopamine)

struct BrainPulseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .offset(dotOffset(i))
                        .scaleEffect(pulse ? 1.3 : 0.6)
                        .opacity(pulse ? 0.9 : 0.25)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever().delay(Double(i) * 0.16), value: pulse)
                }
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 78, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(height: 170)
            .accessibilityHidden(true)

            ChiselText(
                text: "Hundreds of engineers are paid to A/B-test your attention. You've been fighting them with willpower alone.",
                font: .system(.title2, design: .serif, weight: .semibold))
            Text("That fight was never fair.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .onAppear { pulse = true }
    }

    private func dotOffset(_ i: Int) -> CGSize {
        let angle = Double(i) / 6 * 2 * .pi
        return CGSize(width: cos(angle) * 70, height: sin(angle) * 60)
    }
}

// MARK: - You're not alone (ignition cascade)

struct PeopleFieldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var lit = false
    @State private var rollTask: Task<Void, Never>?

    private let columns = 12
    private let rows = 9

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            VStack(spacing: 7) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 7) {
                        ForEach(0..<columns, id: \.self) { c in
                            let isLit = (r * columns + c) % 3 == 0
                            Circle()
                                .fill(isLit && lit ? Theme.accent : BedrockColor.ash.opacity(0.25))
                                .frame(width: 9, height: 9)
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5).delay(Double((r * columns + c) % 9) * 0.06), value: lit)
                        }
                    }
                }
            }
            .accessibilityHidden(true)

            Text("\(OnboardingStat.prevalence) is fighting this right now — in silence.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("You're just one of the few brave enough to face it.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            lit = true
            guard !reduceMotion else { return }
            rollTask = Task {
                for _ in 0..<10 {
                    BedrockHaptics.calm()
                    try? await Task.sleep(for: .milliseconds(70))
                }
            }
        }
        .onDisappear { rollTask?.cancel() }
    }
}

// MARK: - The cost (hourglass)

struct CostCalculatorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var pour: Double = 0      // 0 = top full, 1 = drained
    @State private var grains = 0
    @State private var shownHours = 0
    @State private var revealReframe = false
    @State private var cascadeTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Text("At your pace, this has quietly taken")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            ZStack {
                Image(systemName: "hourglass.tophalf.filled")
                    .opacity(1 - pour)
                Image(systemName: "hourglass.bottomhalf.filled")
                    .opacity(pour)
            }
            .font(.system(size: 76, weight: .light))
            .foregroundStyle(Theme.accent)
            .frame(height: 120)
            .overlay { StoneParticles(trigger: grains, origin: nil, color: BedrockColor.bronze, burst: 2) }
            .accessibilityHidden(true)

            Text("≈ \(shownHours.formatted()) hours")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("That's \(model.daysLost.formatted()) days of the one life you get.")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer()
            if revealReframe {
                Text("That number stops growing today.")
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .riseIn(0, reduceMotion: reduceMotion)
                Button("Continue") { onNext() }
                    .buttonStyle(.bedrockPrimary)
                    .riseIn(0.15, reduceMotion: reduceMotion)
            }
        }
        .padding(Theme.Spacing.xl)
        .task { await run() }
        .onDisappear { cascadeTask?.cancel() }
    }

    private func run() async {
        if reduceMotion {
            pour = 1
            shownHours = model.hoursLost
            revealReframe = true
            return
        }
        withAnimation(.easeIn(duration: 1.8)) { pour = 1 }
        cascadeTask = Task {
            for _ in 0..<11 {
                grains += 1
                BedrockHaptics.calm()
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
        try? await Task.sleep(for: .seconds(1.8))
        withAnimation(.easeOut(duration: 0.6)) { shownHours = model.hoursLost }
        BedrockHaptics.set()
        try? await Task.sleep(for: .seconds(0.9))
        withAnimation { revealReframe = true }
    }
}
