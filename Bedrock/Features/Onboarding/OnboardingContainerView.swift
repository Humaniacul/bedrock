import SwiftUI

/// The onboarding coordinator (spec v2.0): routes the 29 beats, owns the only
/// progress chrome (a thin bar across the question block, S7–13 — emotional
/// screens carry no chrome), and persists progress so a backgrounded flow
/// resumes, never restarts. Tempo contrast is the cinematography: slow carved
/// gifts, snappy interactions.
struct OnboardingContainerView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var onComplete: () -> Void

    @State private var model = OnboardingModel()
    @State private var index = 0
    @State private var goingForward = true
    @State private var restored = false

    private var steps: [OnboardingStep] { OnboardingFlow.steps }
    private var current: OnboardingStep { steps[min(max(index, 0), steps.count - 1)] }
    private var questionProgress: Double? { OnboardingFlow.questionProgress(at: index) }

    var body: some View {
        ZStack {
            StoneBackground(emberGlow: current.glow)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: current.glow)
            beatView(current.beat)
                .id(index)
                .transition(stepTransition)
                .padding(.top, questionProgress != nil ? 48 : 0)
        }
        .overlay(alignment: .top) {
            if let fraction = questionProgress {
                chrome(fraction: fraction)
            }
        }
        .animation(Theme.Motion.reduced(.smooth(duration: 0.5), when: reduceMotion), value: index)
        .onAppear { restoreIfNeeded() }
        .onChange(of: index) { _, newIndex in
            model.save(step: newIndex)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { model.save(step: index) }
        }
    }

    // MARK: - Beat routing

    @ViewBuilder private func beatView(_ beat: OnboardingBeat) -> some View {
        switch beat {
        // ACT I — THE THRESHOLD
        case .coldOpen:  ColdOpenBeat(onNext: advance)
        case .disarm:    DisarmBeat(onNext: advance)
        case .recognize: RecognizeBeat(model: model, onNext: advance)
        case .reckon:    ReckonBeat(model: model, onNext: advance)
        case .turn:      TurnBeat(onNext: advance)
        // ACT II — THE MIRROR
        case .permission: PermissionBeat(onNext: advance)
        case .question(let question):
            QuestionBeat(question: question, model: model, onNext: advance)
        case .reflectionOne: ReflectionBeat(kind: .one, model: model, onNext: advance)
        case .reflectionTwo: ReflectionBeat(kind: .two, model: model, onNext: advance)
        // ACT III — THE TRUTH
        case .reading:  ReadingBeat(model: model, onNext: advance)
        case .reveal:   RevealBeat(model: model, onNext: advance)
        case .loop:     LoopBeat(onNext: advance)
        case .timeline: TimelineBeat(model: model, onNext: advance)
        case .door:     DoorBeat(onNext: advance)
        // ACT IV — THE COVENANT
        case .futureSelf:  FutureSelfBeat(model: model, onNext: advance)
        case .cornerstone: CornerstoneBeat(model: model, onNext: advance)
        case .guardrails:  GuardrailsBeat(model: model, onNext: advance)
        case .unbeatable:  UnbeatableBeat(model: model, onNext: advance)
        case .rhythm:      RhythmBeat(model: model, onNext: advance)
        case .foundationReady: FoundationReadyBeat(model: model, onNext: advance)
        case .nameWhy:     NameWhyBeat(model: model, onNext: advance)
        // ACT V — THE CROSSING
        case .socialProof: SocialProofBeat(onNext: advance)
        case .bridge:      BridgeBeat(model: model, onNext: advance)
        case .paywall:
            PaywallView(
                context: .onboarding(why: model.whyLine,
                                     bestSelfWord: model.bestSelfWord,
                                     topCost: model.topCost),
                onContinue: advance)
        case .dayOne:      DayOneBeat(model: model, onDone: finish)
        }
    }

    // MARK: - Chrome (question block only)

    private func chrome(fraction: Double) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Button { back() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            OnboardingProgressBar(fraction: fraction)
            Color.clear.frame(width: 30, height: 1) // optical balance
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Transitions

    private var stepTransition: AnyTransition {
        if reduceMotion { return .opacity }
        let insertion: Edge = goingForward ? .trailing : .leading
        let removal: Edge = goingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity))
    }

    // MARK: - Navigation

    private func advance() {
        #if DEBUG
        print("[onb] advance from \(index)")
        #endif
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
        onComplete()
    }

    private func restoreIfNeeded() {
        guard !restored else { return }
        restored = true
        #if DEBUG
        // Jump to any beat for testing: SIMCTL_CHILD_BEDROCK_ONBOARDING_STEP=<index>.
        if let raw = ProcessInfo.processInfo.environment["BEDROCK_ONBOARDING_STEP"],
           let jump = Int(raw), jump >= 0 {
            index = min(jump, steps.count - 1)
            print("[onb] debug jump to \(index)")
            return
        }
        #endif
        let saved = model.restore()
        if saved > 0 { index = min(saved, steps.count - 1) }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {}).environment(AppServices.makeStub())
}
