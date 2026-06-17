import SwiftUI

/// The first-run conversion journey (§8) — a ~30-beat, six-act flow that builds
/// recognition → understanding → a personalized verdict → the promise → a
/// commitment → activation, so the paywall lands as joining a mission rather
/// than a transaction. Data-driven from `OnboardingFlow.steps`; value-first
/// (the ask is skippable). Same `OnboardingView(onComplete:)` API as before.
struct OnboardingView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onComplete: () -> Void

    @State private var model = OnboardingModel()
    @State private var index: Int = OnboardingView.initialIndex
    @State private var goingForward = true

    private var steps: [FlowStep] { OnboardingFlow.steps }
    private var current: FlowStep { steps[min(index, steps.count - 1)] }
    private var isFirst: Bool { index == 0 }
    private var isLast: Bool { index >= steps.count - 1 }
    private var showsChrome: Bool { !isFirst && !isLast }

    var body: some View {
        ZStack {
            StoneBackground(emberGlow: glow)
            beatView(current.beat)
                .id(index)
                .transition(stepTransition)
                .padding(.top, showsChrome ? 56 : 0)
        }
        .overlay(alignment: .top) { if showsChrome { chrome } }
        .animation(Theme.Motion.reduced(.smooth(duration: 0.5), when: reduceMotion), value: index)
    }

    // MARK: - Beat routing

    @ViewBuilder private func beatView(_ beat: Beat) -> some View {
        switch beat {
        case .chisel(let content): ChiselBeatView(content: content, onNext: advance)
        case .assessment(let question): AssessmentBeatView(question: question, model: model, onNext: advance)
        case .brainPulse: BrainPulseView(onNext: advance)
        case .peopleField: PeopleFieldView(onNext: advance)
        case .cost: CostCalculatorView(model: model, onNext: advance)
        case .assembling: AssemblingView(onNext: advance)
        case .verdict: VerdictGaugeView(model: model, onNext: advance)
        case .sandToRock: SandToRockView(onNext: advance)
        case .foundersVow: FoundersVowView(onNext: advance)
        case .layers: LayersView(onNext: advance)
        case .oath: OathStoneView(onNext: advance)
        case .carveWhy: CarveWhyView(model: model, onNext: advance)
        case .projection: ProjectionView(model: model, onNext: advance)
        case .raiseWall: ProtectStep(onNext: advance)
        case .standGuard: StandGuardView(onNext: advance)
        case .paywall: PaywallView(context: .onboarding(why: model.why), onContinue: advance)
        case .dayZero: CommitStep(model: model, onDone: finish)
        }
    }

    // MARK: - Chrome (back + six-act progress)

    private var chrome: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button { back() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Back")

            HStack(spacing: 4) {
                ForEach(1...OnboardingFlow.acts, id: \.self) { act in
                    Capsule()
                        .fill(act <= current.act ? Theme.accent : Theme.hairline)
                        .frame(height: 3)
                        .animation(Theme.Motion.reduced(.smooth, when: reduceMotion), value: index)
                }
            }
            Color.clear.frame(width: 30, height: 1) // balance the back button
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
    }

    // The molten core warms as the journey deepens.
    private var glow: Double {
        0.07 + Double(index) / Double(max(steps.count - 1, 1)) * 0.26
    }

    private var stepTransition: AnyTransition {
        if reduceMotion { return .opacity }
        // Act seams "set into place" (ember → stone) rather than slide.
        if current.emberSeam, goingForward {
            return .asymmetric(
                insertion: .scale(scale: 1.06).combined(with: .opacity),
                removal: .opacity)
        }
        let insertion: Edge = goingForward ? .trailing : .leading
        let removal: Edge = goingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }

    // MARK: - Navigation

    private func advance() {
        guard index + 1 < steps.count else { finish(); return }
        goingForward = true
        index += 1
    }

    private func back() {
        guard index > 0 else { return }
        goingForward = false
        index -= 1
    }

    private func finish() {
        model.complete(services: services)
        BedrockHaptics.milestone()
        onComplete()
    }

    private static var initialIndex: Int {
        #if DEBUG
        // Jump to any beat for testing: SIMCTL_CHILD_BEDROCK_ONBOARDING_STEP=<index>.
        // Out-of-range values are clamped at render time by `current`.
        if let raw = ProcessInfo.processInfo.environment["BEDROCK_ONBOARDING_STEP"],
           let i = Int(raw), i >= 0 {
            return i
        }
        #endif
        return 0
    }
}

#Preview {
    OnboardingView(onComplete: {}).environment(AppServices.makeStub())
}
