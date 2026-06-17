import Foundation

/// A statement/quote screen rendered with the Chisel-Type engine: the headline
/// is carved glyph-by-glyph; the body (if any) fades in after.
struct ChiselContent {
    var eyebrow: String? = nil
    var headline: String
    var body: String? = nil
    var cta: String = "Continue"
    var isQuote: Bool = false   // larger, full-bleed serif treatment for the "wow" lines
}

/// One assessment question. `read`/`apply` bridge display strings ↔ the typed
/// model fields so a screen can re-show prior answers when the user goes back.
struct AssessmentQuestion {
    let id: String
    let eyebrow: String
    let prompt: String
    let options: [String]
    let multi: Bool
    let acknowledgment: String
    let read: @MainActor (OnboardingModel) -> Set<String>
    let apply: @MainActor (OnboardingModel, Set<String>) -> Void
}

/// Every kind of screen. Statement screens are data-driven (`.chisel`); the
/// signature interactions are bespoke markers the container maps to their views.
enum Beat {
    case chisel(ChiselContent)
    case assessment(AssessmentQuestion)
    case brainPulse      // engineered dopamine
    case peopleField     // "you're not alone" ignition
    case cost            // hourglass cost calculator
    case assembling      // "reading your foundation…"
    case verdict         // geological-survey gauge
    case sandToRock      // sand erodes → stone sets
    case foundersVow     // the humanizing founder screen
    case layers          // the four guardians
    case oath            // forging press-and-hold
    case carveWhy        // the future-self letter
    case projection      // rising mountain + milestones
    case raiseWall       // free protection (ProtectStep)
    case standGuard      // local-notification opt-in
    case paywall         // the threshold (PaywallView)
    case dayZero         // commit (CommitStep)
}

/// Act seams that get the heavier "ember-to-stone" transition.
struct FlowStep {
    let act: Int
    let beat: Beat
    var emberSeam: Bool = false
}

@MainActor
enum OnboardingFlow {
    static let acts = 6
    static let steps: [FlowStep] = act1 + act2 + act3 + act4 + act5 + act6

    // MARK: ACT I — Recognition (you're seen)

    private static let act1: [FlowStep] = [
        FlowStep(act: 1, beat: .chisel(ChiselContent(
            eyebrow: "BEDROCK",
            headline: "Before we build anything —\none honest conversation.",
            cta: "Begin"))),
        FlowStep(act: 1, beat: .chisel(ChiselContent(
            headline: "You've tried to stop before. An app. A promise to yourself. It held for a while. Then it didn't.",
            body: "We know that cycle. This is where it ends."))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "reason", eyebrow: "FIRST, THE TRUTH",
            prompt: "Why are you really here?",
            options: OnboardingModel.reasonOptions, multi: false,
            acknowledgment: "Hold onto that. We'll come back to it.",
            read: { $0.reason.map { Set([$0]) } ?? [] },
            apply: { $0.reason = $1.first }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "duration", eyebrow: "2 OF 6",
            prompt: "How long has this had a grip on you?",
            options: OnboardingModel.Duration.allCases.map(\.label), multi: false,
            acknowledgment: "Then you've carried this a long time. That weight comes off here.",
            read: { $0.duration.map { Set([$0.label]) } ?? [] },
            apply: { $0.duration = $1.first.flatMap(OnboardingModel.Duration.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "frequency", eyebrow: "3 OF 6",
            prompt: "How often does it pull you under?",
            options: OnboardingModel.Frequency.allCases.map(\.label), multi: false,
            acknowledgment: "Honesty is the first stone. You just set it.",
            read: { $0.frequency.map { Set([$0.label]) } ?? [] },
            apply: { $0.frequency = $1.first.flatMap(OnboardingModel.Frequency.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "attempts", eyebrow: "4 OF 6",
            prompt: "Have you tried to stop before?",
            options: OnboardingModel.Attempts.allCases.map(\.label), multi: false,
            acknowledgment: "Every attempt was practice. Not one was wasted.",
            read: { $0.attempts.map { Set([$0.label]) } ?? [] },
            apply: { $0.attempts = $1.first.flatMap(OnboardingModel.Attempts.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "costs", eyebrow: "5 OF 6",
            prompt: "What has it taken from you?",
            options: OnboardingModel.costOptions, multi: true,
            acknowledgment: "Naming it is how you take it back.",
            read: { $0.costs },
            apply: { $0.costs = $1 }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "control", eyebrow: "6 OF 6",
            prompt: "Right now — do you feel in control?",
            options: OnboardingModel.Control.allCases.map(\.label), multi: false,
            acknowledgment: "Hold that answer. We're going to change it.",
            read: { $0.control.map { Set([$0.label]) } ?? [] },
            apply: { $0.control = $1.first.flatMap(OnboardingModel.Control.from) }))),
        FlowStep(act: 1, beat: .chisel(ChiselContent(
            headline: "Most men carry this their whole lives and never say a word. You just did. That isn't weakness — it's the bravest part.")), emberSeam: true),
    ]

    // MARK: ACT II — The Truth (not your fault)

    private static let act2: [FlowStep] = [
        FlowStep(act: 2, beat: .chisel(ChiselContent(
            headline: "You are not weak.\nYou were outmatched.", isQuote: true))),
        FlowStep(act: 2, beat: .brainPulse),
        FlowStep(act: 2, beat: .chisel(ChiselContent(
            eyebrow: "THE SCIENCE",
            headline: "It's called a supernormal stimulus.",
            body: "A signal stronger than anything we were built to resist. Reacting to it isn't a flaw in you — it's biology, working exactly as designed. Against you."))),
        FlowStep(act: 2, beat: .peopleField),
        FlowStep(act: 2, beat: .cost),
        FlowStep(act: 2, beat: .chisel(ChiselContent(
            eyebrow: "WHAT NO ONE TELLS YOU",
            headline: "The brain heals.",
            body: "The same wiring that learned this can unlearn it. Rivers carved the canyon — new rivers carve new paths."))),
    ]

    // MARK: ACT III — The Mirror (the honest cost)

    private static let act3: [FlowStep] = [
        FlowStep(act: 3, beat: .assembling, emberSeam: true),
        FlowStep(act: 3, beat: .verdict),
        FlowStep(act: 3, beat: .chisel(ChiselContent(
            headline: "The men who get free aren't stronger.",
            body: "They stopped trusting willpower — and started building on something that holds.",
            cta: "Show me"))),
    ]

    // MARK: ACT IV — The Allies (why we built this)

    private static let act4: [FlowStep] = [
        FlowStep(act: 4, beat: .sandToRock, emberSeam: true),
        FlowStep(act: 4, beat: .foundersVow),
        FlowStep(act: 4, beat: .chisel(ChiselContent(
            eyebrow: "YOUR LAST BLOCKER",
            headline: "You've deleted blockers before. Found the workaround. Started over.",
            body: "We built Bedrock to be the last name on that list."))),
        FlowStep(act: 4, beat: .layers),
        FlowStep(act: 4, beat: .chisel(ChiselContent(
            headline: "You don't break a habit.\nYou bury it — under something heavier.", isQuote: true))),
        FlowStep(act: 4, beat: .chisel(ChiselContent(
            eyebrow: "YOU'RE NOT ALONE IN THIS",
            headline: "\(OnboardingStat.communitySize) men are rebuilding their foundation right now.",
            body: "\(OnboardingStat.testimonial)\n\(OnboardingStat.testimonialAttribution)"))),
    ]

    // MARK: ACT V — The Oath (you decide, with your body)

    private static let act5: [FlowStep] = [
        FlowStep(act: 5, beat: .chisel(ChiselContent(
            headline: "This only works the day it stops being something you're trying — and becomes something you've decided.",
            cta: "I'm ready")), emberSeam: true),
        FlowStep(act: 5, beat: .oath),
        FlowStep(act: 5, beat: .carveWhy),
        FlowStep(act: 5, beat: .chisel(ChiselContent(
            headline: "You're not quitting something.\nYou're building someone.", isQuote: true))),
    ]

    // MARK: ACT VI — Build It (the way out, then the ask)

    private static let act6: [FlowStep] = [
        FlowStep(act: 6, beat: .projection),
        FlowStep(act: 6, beat: .raiseWall),
        FlowStep(act: 6, beat: .standGuard),
        FlowStep(act: 6, beat: .paywall),
        FlowStep(act: 6, beat: .dayZero),
    ]
}
