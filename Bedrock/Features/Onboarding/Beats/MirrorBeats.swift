import SwiftUI

// MARK: - Beat 16: Assembling

struct AssemblingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            VStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BedrockColor.slate.opacity(0.5 + Double(i) * 0.1))
                        .frame(width: CGFloat(160 - i * 20), height: 18)
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.accent.opacity(i == 4 ? 0.5 : 0.12)))
                        .offset(y: appeared ? 0 : -44)
                        .opacity(appeared ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.12), value: appeared)
                }
            }
            .accessibilityHidden(true)
            Text("Reading your foundation…")
                .font(Theme.Typography.monoCaption)
                .tracking(3)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .task {
            appeared = true
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.0 : 2.3))
            onNext()
        }
    }
}

// MARK: - Beat 17: The verdict

struct VerdictGaugeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var progress: Double = 0
    @State private var scoreShown = 0

    var body: some View {
        let verdict = model.verdict
        return VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Text("YOUR FOUNDATION")
                .font(Theme.Typography.monoCaption)
                .tracking(3)
                .foregroundStyle(Theme.textSecondary)

            ZStack {
                Circle()
                    .stroke(BedrockColor.slate, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(scoreShown)")
                        .font(.system(size: 56, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("/ 100")
                        .font(Theme.Typography.monoCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 196, height: 196)
            .accessibilityElement()
            .accessibilityLabel("Foundation strength \(verdict.score) out of 100. \(verdict.level).")

            Text(verdict.level)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text(verdict.copy)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .task {
            let target = Double(verdict.score) / 100
            if reduceMotion {
                progress = target
                scoreShown = verdict.score
            } else {
                withAnimation(.easeOut(duration: 1.4)) {
                    progress = target
                    scoreShown = verdict.score
                }
            }
        }
    }
}
