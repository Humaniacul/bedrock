import SwiftUI

/// One assessment question. Single-select auto-advances on tap; multi-select
/// uses chips + Continue. Either way, the answer is met with a one-line
/// acknowledgment that builds trust before moving on.
struct AssessmentBeatView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let question: AssessmentQuestion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var selection: Set<String> = []
    @State private var acknowledging = false

    var body: some View {
        ZStack {
            if acknowledging {
                acknowledgment
            } else {
                asking
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { selection = question.read(model) }
        .animation(Theme.Motion.reduced(.smooth(duration: 0.45), when: reduceMotion), value: acknowledging)
    }

    // MARK: Asking

    private var asking: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()
            Text(question.eyebrow)
                .font(Theme.Typography.monoCaption)
                .tracking(3)
                .foregroundStyle(Theme.textSecondary)
            Text(question.prompt)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if question.multi {
                MultiChips(options: question.options, selected: $selection)
                Spacer()
                Button("Continue") { commit() }
                    .buttonStyle(.bedrockPrimary)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(question.options, id: \.self) { option in
                        QuizRow(text: option, selected: selection.contains(option)) { pick(option) }
                    }
                }
                Spacer()
            }
        }
        .transition(.opacity)
    }

    // MARK: Acknowledging

    private var acknowledgment: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(question.acknowledgment)
                .font(.system(.title2, design: .serif, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .riseIn(0, reduceMotion: reduceMotion)
            Spacer()
        }
        .transition(.opacity)
        .task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.8 : 1.2))
            onNext()
        }
    }

    private func pick(_ option: String) {
        selection = [option]
        commit()
    }

    private func commit() {
        question.apply(model, selection)
        BedrockHaptics.selection()
        acknowledging = true
    }
}

/// A full-width, tappable quiz option.
private struct QuizRow: View {
    let text: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt.opacity(selected ? 1 : 0.7)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
