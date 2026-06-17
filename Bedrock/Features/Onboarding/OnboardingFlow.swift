import Foundation

/// A signature decorative visual for a message beat.
enum Motif { case none, ember, sandToRock, carve, strata }

/// A data-driven narrative/quote screen.
struct MessageContent {
    var eyebrow: String? = nil
    var title: String? = nil
    var body: String? = nil
    var quote: String? = nil          // rendered large + serif (the "wow" lines)
    var cta: String = "Continue"
    var motif: Motif = .none
}

/// One assessment question. `read`/`apply` bridge display strings ↔ the typed
/// model fields so the screen can re-show prior answers when the user goes back.
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

/// Every kind of screen in the journey. Data-driven where possible; bespoke
/// interactive beats are markers the container maps to their own views.
enum Beat {
    case message(MessageContent)
    case assessment(AssessmentQuestion)
    case brain          // engineered-dopamine animation
    case people         // "you're not alone" field
    case cost           // hours-lost calculator
    case assembling     // "reading your foundation…" loader
    case verdict        // personalized gauge
    case layers         // the four layers (reuses MechanismStep)
    case oath           // press-and-hold "set the first stone"
    case carveWhy       // write the future-self letter
    case projection     // 90-day curve
    case raiseWall      // free protection setup (reuses ProtectStep)
    case standGuard     // local-notification opt-in
    case paywall        // the ask (reuses PaywallView)
    case dayZero        // commit (reuses CommitStep)
}

struct FlowStep {
    let act: Int
    let beat: Beat
}

@MainActor
enum OnboardingFlow {
    static let acts = 6

    static let steps: [FlowStep] = act1 + act2 + act3 + act4 + act5 + act6

    // MARK: ACT I — Recognition

    private static let act1: [FlowStep] = [
        FlowStep(act: 1, beat: .message(MessageContent(
            eyebrow: "BEDROCK",
            title: "Before we build anything —\none honest conversation.",
            cta: "Begin",
            motif: .ember))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "reason", eyebrow: "FIRST, THE TRUTH",
            prompt: "Why are you really here?",
            options: OnboardingModel.reasonOptions, multi: false,
            acknowledgment: "That's reason enough. Let's build on it.",
            read: { $0.reason.map { Set([$0]) } ?? [] },
            apply: { $0.reason = $1.first }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "duration", eyebrow: "2 OF 6",
            prompt: "How long has this had a grip on you?",
            options: OnboardingModel.Duration.allCases.map(\.label), multi: false,
            acknowledgment: "Then you've carried this a long time. That ends here.",
            read: { $0.duration.map { Set([$0.label]) } ?? [] },
            apply: { $0.duration = $1.first.flatMap(OnboardingModel.Duration.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "frequency", eyebrow: "3 OF 6",
            prompt: "How often does it pull you in?",
            options: OnboardingModel.Frequency.allCases.map(\.label), multi: false,
            acknowledgment: "Honesty is the first stone.",
            read: { $0.frequency.map { Set([$0.label]) } ?? [] },
            apply: { $0.frequency = $1.first.flatMap(OnboardingModel.Frequency.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "attempts", eyebrow: "4 OF 6",
            prompt: "Have you tried to stop before?",
            options: OnboardingModel.Attempts.allCases.map(\.label), multi: false,
            acknowledgment: "Every attempt was practice. None were wasted.",
            read: { $0.attempts.map { Set([$0.label]) } ?? [] },
            apply: { $0.attempts = $1.first.flatMap(OnboardingModel.Attempts.from) }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "costs", eyebrow: "5 OF 6",
            prompt: "What has it quietly cost you?",
            options: OnboardingModel.costOptions, multi: true,
            acknowledgment: "Naming it takes its power back.",
            read: { $0.costs },
            apply: { $0.costs = $1 }))),
        FlowStep(act: 1, beat: .assessment(AssessmentQuestion(
            id: "control", eyebrow: "6 OF 6",
            prompt: "Do you feel in control of it?",
            options: OnboardingModel.Control.allCases.map(\.label), multi: false,
            acknowledgment: "Soon, that answer changes.",
            read: { $0.control.map { Set([$0.label]) } ?? [] },
            apply: { $0.control = $1.first.flatMap(OnboardingModel.Control.from) }))),
        FlowStep(act: 1, beat: .message(MessageContent(
            title: "That took courage.",
            body: "Most people never say these things out loud. You just did — and that's not weakness. It's the bravest part of all of this."))),
    ]

    // MARK: ACT II — The Truth

    private static let act2: [FlowStep] = [
        FlowStep(act: 2, beat: .message(MessageContent(
            title: "You are not weak.\nYou were outmatched.",
            motif: .ember))),
        FlowStep(act: 2, beat: .brain),
        FlowStep(act: 2, beat: .message(MessageContent(
            eyebrow: "THE SCIENCE",
            title: "It's called a supernormal stimulus.",
            body: "A signal stronger than anything our brains were built for. Reacting to it isn't a character flaw — it's biology working exactly as designed. Against you."))),
        FlowStep(act: 2, beat: .people),
        FlowStep(act: 2, beat: .cost),
        FlowStep(act: 2, beat: .message(MessageContent(
            eyebrow: "BUT HERE'S THE PART THEY SKIP",
            title: "The brain heals.",
            body: "Rivers carved the canyon. New rivers carve new paths. What was wired can be re-wired — with the right pressure, in the right places.",
            quote: "What was carved can be re-carved.",
            motif: .carve))),
        FlowStep(act: 2, beat: .message(MessageContent(
            eyebrow: "THE TIMELINE",
            title: "In about \(OnboardingStat.resetDays), the pathway begins to reset.",
            body: "We'll be with you for every one of them."))),
    ]

    // MARK: ACT III — The Mirror

    private static let act3: [FlowStep] = [
        FlowStep(act: 3, beat: .assembling),
        FlowStep(act: 3, beat: .verdict),
        FlowStep(act: 3, beat: .message(MessageContent(
            title: "The men who get free all did one thing.",
            body: "They stopped relying on willpower — and started building on something that holds when they don't.",
            cta: "Show me"))),
    ]

    // MARK: ACT IV — Why Bedrock

    private static let act4: [FlowStep] = [
        FlowStep(act: 4, beat: .message(MessageContent(
            title: "You've been building on sand.",
            body: "Every urge washes a little more away. No wonder willpower kept collapsing — there was nothing underneath it.\n\nWe're going to pour bedrock.",
            motif: .sandToRock))),
        FlowStep(act: 4, beat: .layers),
        FlowStep(act: 4, beat: .message(MessageContent(
            title: "Every other app asks you to be strong.",
            body: "Bedrock makes you unbreakable. We're the first to lock the door — and hand the key to your future self.",
            quote: "Bedrock makes you unbreakable."))),
        FlowStep(act: 4, beat: .message(MessageContent(
            quote: "You don't break a habit.\nYou bury it — under something heavier.",
            motif: .carve))),
        FlowStep(act: 4, beat: .message(MessageContent(
            eyebrow: "YOU'RE NOT THE FIRST TO STAND HERE",
            title: "\(OnboardingStat.communitySize) men are rebuilding their foundation.",
            body: "\(OnboardingStat.testimonial)\n\(OnboardingStat.testimonialAttribution)"))),
    ]

    // MARK: ACT V — The Commitment

    private static let act5: [FlowStep] = [
        FlowStep(act: 5, beat: .message(MessageContent(
            title: "This only works the day you decide it isn't optional.",
            cta: "I'm ready"))),
        FlowStep(act: 5, beat: .oath),
        FlowStep(act: 5, beat: .carveWhy),
        FlowStep(act: 5, beat: .projection),
        FlowStep(act: 5, beat: .message(MessageContent(
            quote: "You're not quitting something.\nYou're building someone.",
            motif: .ember))),
    ]

    // MARK: ACT VI — Build It

    private static let act6: [FlowStep] = [
        FlowStep(act: 6, beat: .raiseWall),
        FlowStep(act: 6, beat: .standGuard),
        FlowStep(act: 6, beat: .paywall),
        FlowStep(act: 6, beat: .dayZero),
    ]
}
