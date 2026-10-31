import SwiftUI

// ACT II — THE MIRROR (spec v2 S6–S13): a conversation where the user acts on
// every screen. Answers drop visible stone fragments (the connective spine);
// reflections end in an Affirm — rapport becomes micro-commitment.

// MARK: - Question beat (all five variants)

struct QuestionBeat: View {
    let question: OnboardingQuestion
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: Set<String> = []
    @State private var freeText = ""
    @State private var autoAdvancing = false
    @State private var weighing = false // Q4 phase 2
    @FocusState private var textFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: question.eyebrow)
                .settleIn(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(weighing ? "Which hurts most?" : question.prompt)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(weighing ? "Drag the one that hurts most to the top." : question.sub)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .settleIn(0.08, reduceMotion: reduceMotion)
            .animation(Theme.Motion.reduced(.easeInOut(duration: 0.3), when: reduceMotion), value: weighing)

            ornament

            if weighing {
                weighStack
            } else {
                optionList
            }

            if question.multi {
                OnboardingPrimaryButton(title: "Continue") { continueTapped() }
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.45)
            }

            // Their answers, becoming stone.
            if showsFragments {
                FragmentPile(count: fragmentCount)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            selected = question.read(model)
            if question.variant == .dawn { freeText = model.bestSelfText }
        }
    }

    // MARK: Fragments (the connective spine)

    private var showsFragments: Bool {
        switch question.variant {
        case .tiles, .sediment, .clockRing: true
        default: false
        }
    }

    private var fragmentCount: Int {
        model.motivation.count + (model.duration != nil ? 1 : 0) + model.triggers.count
    }

    // MARK: Options

    private var optionList: some View {
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
            .padding(.bottom, Theme.Spacing.sm)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Q4 phase 2 — Weigh: the ranked cost becomes `topCost`.
    private var weighStack: some View {
        VStack(spacing: Theme.Spacing.md) {
            WeighStack(
                items: OnboardingModel.costOptions.filter { selected.contains($0) },
                topCost: Binding(get: { model.topCost }, set: { model.topCost = $0 }))
            Spacer(minLength: 0)
        }
    }

    private var canContinue: Bool {
        if weighing { return model.topCost != nil }
        if question.variant == .dawn {
            return !selected.isEmpty || !freeText.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !selected.isEmpty
    }

    private func continueTapped() {
        if question.variant == .vignette && !weighing {
            // One selected cost weighs itself; more than one gets ranked.
            let picked = OnboardingModel.costOptions.filter { selected.contains($0) }
            if picked.count <= 1 {
                model.topCost = picked.first
                onNext()
            } else {
                if let top = model.topCost, !picked.contains(top) { model.topCost = nil }
                withAnimation(.smooth(duration: 0.4)) { weighing = true }
            }
            return
        }
        textFocused = false
        onNext()
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
        case .clockRing: clockRing
        case .vignette: if !weighing { dawnVignette }
        case .dawn: dawnRise
        default: EmptyView()
        }
    }

    /// Q3 — a faint 24-hour ring that dims toward night when late-night is picked.
    private var clockRing: some View {
        let night = selected.contains("Late night") || selected.contains("Everywhere")
        return ZStack {
            Circle()
                .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            Circle()
                .trim(from: night ? 0.72 : 0.28, to: 1)
                .stroke(night ? BedrockColor.mineral.opacity(0.7) : Theme.accent.opacity(0.5),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(90))
        }
        .frame(width: 74, height: 74)
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

// MARK: - Reflection beats (S9 / S12 — read → Affirm)

struct ReflectionBeat: View {
    /// Which reflection to speak back.
    enum Kind { case one, two }
    let kind: Kind
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false
    @State private var tweaking = false
    @State private var carveKey = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: lines, interlinePause: 0.9) {
                withAnimation(.smooth(duration: 0.4)) { finished = true }
            }
            .id(carveKey) // re-carves after a tweak

            if tweaking {
                tweakPicker
                    .settleIn(reduceMotion: reduceMotion)
            }

            Spacer()
            if finished && !tweaking {
                AffirmButton { affirm() }
                    .settleIn(reduceMotion: reduceMotion)
                Button("Not quite") {
                    withAnimation(.smooth(duration: 0.35)) { tweaking = true }
                }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
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

    /// The two-tap tweak: re-pick what's actually true, and the mirror re-carves.
    @ViewBuilder private var tweakPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(kind == .one ? "Then what's closest?" : "Then which hurts most?")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
            FlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(tweakOptions, id: \.self) { option in
                    BedrockChip(text: option, isOn: false) { applyTweak(option) }
                }
            }
        }
    }

    private var tweakOptions: [String] {
        switch kind {
        case .one: OnboardingModel.motivationOptions
        case .two: OnboardingModel.costOptions.filter { model.costs.contains($0) }
        }
    }

    private func applyTweak(_ option: String) {
        BedrockHaptics.selection()
        switch kind {
        case .one:
            // Their correction outranks everything the mirror guessed from.
            model.motivation = [option]
        case .two:
            model.topCost = option
        }
        withAnimation(.smooth(duration: 0.35)) {
            tweaking = false
            finished = false
        }
        carveKey += 1 // speak the corrected reflection back
    }

    private func affirm() {
        switch kind {
        case .one: model.affirmedReflectionOne = true
        case .two: model.affirmedReflectionTwo = true
        }
        onNext()
    }
}
