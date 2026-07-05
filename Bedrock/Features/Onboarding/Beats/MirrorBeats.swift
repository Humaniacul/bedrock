import SwiftUI

// ACT II — THE MIRROR (spec S7–S13): a conversation that feels like being
// understood. Questions move fast (snappy Settles, no carve); the reflections
// in between are the rapport moat and are allowed to take their time.

// MARK: - Question beat (all five variants)

struct QuestionBeat: View {
    let question: OnboardingQuestion
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: Set<String> = []
    @State private var freeText = ""
    @State private var autoAdvancing = false
    @FocusState private var textFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: question.eyebrow)
                .settleIn(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(question.prompt)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(question.sub)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .settleIn(0.08, reduceMotion: reduceMotion)

            ornament

            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(question.options.enumerated()), id: \.element) { index, option in
                        OnboardingOptionCard(
                            label: option,
                            isSelected: selected.contains(option)
                        ) { toggle(option) }
                        .strata(index, base: 0.15, reduceMotion: reduceMotion)
                        .padding(.leading, sedimentIndent(index))
                    }
                    if question.variant == .dawn {
                        TextField("In your own words, if you want.", text: $freeText, axis: .vertical)
                            .focused($textFocused)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(Theme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                                .strokeBorder(textFocused ? Theme.accent.opacity(0.6) : Theme.hairline))
                            .strata(question.options.count, base: 0.15, reduceMotion: reduceMotion)
                            .onChange(of: freeText) { _, new in model.bestSelfText = new }
                    }
                }
                .padding(.bottom, Theme.Spacing.md)
            }
            .scrollBounceBehavior(.basedOnSize)

            if question.multi {
                OnboardingPrimaryButton(title: "Continue") {
                    textFocused = false
                    onNext()
                }
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            selected = question.read(model)
            if question.variant == .dawn { freeText = model.bestSelfText }
        }
    }

    private var canContinue: Bool {
        !selected.isEmpty || (question.variant == .dawn && !freeText.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func toggle(_ option: String) {
        if question.multi {
            if selected.contains(option) { selected.remove(option) } else { selected.insert(option) }
            question.apply(model, selected)
            if question.variant == .vignette { BedrockHaptics.calm() } // .soft — a sliver of dawn goes
        } else {
            selected = [option]
            question.apply(model, selected)
            guard !autoAdvancing else { return }
            autoAdvancing = true
            // Single-select auto-advances — the question block moves fast.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 450))
                onNext()
            }
        }
    }

    /// Sediment stack (Q2): deeper answers sit deeper in the earth.
    private func sedimentIndent(_ index: Int) -> CGFloat {
        question.variant == .sediment ? CGFloat(index) * 12 : 0
    }

    // MARK: Variant ornaments

    @ViewBuilder private var ornament: some View {
        switch question.variant {
        case .clockArc: clockArc
        case .vignette: dawnVignette
        case .dawn: dawnRise
        default: EmptyView()
        }
    }

    /// Q3 — a faint 24-hour arc that dims toward night when late-night is picked.
    private var clockArc: some View {
        let night = selected.contains("Late at night")
        return ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            Circle()
                .trim(from: night ? 0.85 : 0.5, to: 1)
                .stroke(night ? BedrockColor.mineral.opacity(0.7) : Theme.accent.opacity(0.5),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(width: 130, height: 60)
        .frame(maxWidth: .infinity)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.8), when: reduceMotion), value: night)
        .accessibilityHidden(true)
    }

    /// Q4 — each named cost removes a sliver of dawn.
    private var dawnVignette: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, BedrockColor.emberGlow],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * dawnRemaining)
            }
        }
        .frame(height: 4)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.6), when: reduceMotion), value: selected)
        .accessibilityHidden(true)
    }

    private var dawnRemaining: Double {
        max(0.15, 1 - Double(selected.count) * 0.15)
    }

    /// Q5 — the brightest screen yet: dawn rises behind the stone.
    private var dawnRise: some View {
        LinearGradient(colors: [Theme.accent.opacity(0.35), .clear],
                       startPoint: .bottom, endPoint: .top)
            .frame(height: 40)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Reflection beats (S9 / S12 — active listening, the moat)

struct ReflectionBeat: View {
    /// Which reflection to speak back.
    enum Kind { case one, two }
    let kind: Kind
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: lines, interlinePause: 0.9) { finished = true }
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

    private var lines: [CarveSequence.Line] {
        let texts: [String] = kind == .one ? model.reflectionOne : model.reflectionTwo
        return texts.enumerated().map { index, text in
            CarveSequence.Line(
                text: text,
                font: .system(.title2, design: .serif, weight: .semibold),
                ember: index == texts.count - 1) // the pivot line warms
        }
    }
}
