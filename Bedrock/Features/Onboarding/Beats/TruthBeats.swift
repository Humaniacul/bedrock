import SwiftUI

// MARK: - Beat 10: The machine (engineered dopamine)

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
                        .animation(reduceMotion ? nil :
                            .easeInOut(duration: 1.1).repeatForever().delay(Double(i) * 0.16), value: pulse)
                }
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 78, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(height: 170)
            .riseIn(0, reduceMotion: reduceMotion)
            .accessibilityHidden(true)

            Text("On the other side of that screen are hundreds of engineers, A/B-testing your attention.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .riseIn(0.15, reduceMotion: reduceMotion)
            Text("You've been fighting them with willpower alone. That fight was never fair.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .riseIn(0.3, reduceMotion: reduceMotion)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.45, reduceMotion: reduceMotion)
        }
        .padding(Theme.Spacing.xl)
        .onAppear { pulse = true }
    }

    private func dotOffset(_ i: Int) -> CGSize {
        let angle = Double(i) / 6 * 2 * .pi
        return CGSize(width: cos(angle) * 70, height: sin(angle) * 60)
    }
}

// MARK: - Beat 12: You're not alone

struct PeopleFieldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var lit = false

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
                                .animation(reduceMotion ? nil :
                                    .easeInOut(duration: 0.5).delay(Double((r * columns + c) % 9) * 0.05), value: lit)
                        }
                    }
                }
            }
            .riseIn(0, reduceMotion: reduceMotion)
            .accessibilityHidden(true)

            Text("\(OnboardingStat.prevalence) are fighting this in silence right now.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .riseIn(0.2, reduceMotion: reduceMotion)
            Text("You just happen to be brave enough to do something about it.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .riseIn(0.32, reduceMotion: reduceMotion)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.45, reduceMotion: reduceMotion)
        }
        .padding(Theme.Spacing.xl)
        .onAppear { lit = true }
    }
}

// MARK: - Beat 13: The cost calculator

struct CostCalculatorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var shown = 0
    @State private var revealReframe = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Text("At your pace, this has quietly taken")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("\(shown.formatted()) hours")
                .font(.system(size: 52, weight: .bold, design: .serif))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("≈ \(model.daysLost.formatted()) days of your one life.")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer()
            if revealReframe {
                Text("But that number stops growing today.")
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
        .task {
            if reduceMotion {
                shown = model.hoursLost
            } else {
                withAnimation(.easeOut(duration: 1.6)) { shown = model.hoursLost }
                try? await Task.sleep(for: .seconds(1.9))
            }
            withAnimation { revealReframe = true }
        }
    }
}
