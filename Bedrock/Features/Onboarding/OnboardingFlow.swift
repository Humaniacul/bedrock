import Foundation

/// One assessment question (Act II — The Mirror). The visual `variant` gives
/// each question its own ornament without forking the interaction pattern.
struct OnboardingQuestion {
    enum Variant {
        case tiles       // Q1 — stone tiles, fragments drop as you choose
        case sediment    // Q2 — deeper = longer, auto-advance
        case clockRing   // Q3 — 24-hour ring dims to night
        case vignette    // Q4 — each pick removes a sliver of dawn (then Weigh)
        case dawn        // Q5 — brightest screen, optional free text
    }

    let id: String
    let eyebrow: String      // "QUESTION 01"
    let prompt: String
    let sub: String
    let options: [String]
    let multi: Bool
    let variant: Variant
    let read: @MainActor (OnboardingModel) -> Set<String>
    let apply: @MainActor (OnboardingModel, Set<String>) -> Void
}

/// Every screen in the flow (spec v2.0). Each has a verb; reading is reserved
/// for four gift moments (S2, S5, S27 and the payoff lines inside beats).
enum OnboardingBeat {
    // ACT I — THE THRESHOLD
    case coldOpen            // 1  — [watch] wordmark carves, horizon breathes
    case disarm              // 2  — [read — a gift] "You're not broken."
    case recognize           // 3  — [Recognize] tap what's true; shadow gathers
    case reckon              // 4  — [Reckon] drag their own honest cost
    case turn                // 5  — [read + CTA] "Let's build the ground"
    // ACT II — THE MIRROR
    case permission          // 6  — consent + privacy line
    case question(OnboardingQuestion) // 7, 8, 10, 11, 13
    case reflectionOne       // 9  — [read → Affirm]
    case reflectionTwo       // 12 — [read → Affirm]
    // ACT III — THE TRUTH
    case reading             // 14 — [Trace] swipe fragments into their column
    case reveal              // 15 — [tap to uncover] what I see, stratum by stratum
    case loop                // 16 — [Trace] walk the loop, then hold "Let it pass"
    case timeline            // 17 — [scrub] drag ahead to see what's coming
    case door                // 18 — [hold] willpower drains; the wall doesn't
    // ACT IV — THE COVENANT
    case futureSelf          // 19 — [Choose] what comes back first
    case cornerstone         // 20 — [Inscribe + Forge] name + press-and-hold
    case guardrails          // 21 — [Build] FamilyControls, in-context
    case unbeatable          // 22 — [Choose] friction tier
    case rhythm              // 23 — [Choose] notification windows
    case foundationReady     // 24 — [one touch] run your hand across it
    case nameWhy             // 25 — [Inscribe] the crown jewel
    // ACT V — THE CROSSING
    case socialProof         // 26 — quiet, not loud
    case bridge              // 27 — [short read] no price yet
    case paywall             // 28 — the decision
    case dayOne              // 29 — hand them the lifeline
}

struct OnboardingStep {
    let act: Int
    let beat: OnboardingBeat
    /// Progress chrome shows only across the question block (S7–13).
    var inQuestionBlock: Bool = false
    /// Background ember glow (0…1) — light literally rises across the flow.
    var glow: Double = 0.08
}

@MainActor
enum OnboardingFlow {
    static let steps: [OnboardingStep] = actOne + actTwo + actThree + actFour + actFive

    /// Fraction through the question block for the progress bar (nil outside it).
    static func questionProgress(at index: Int) -> Double? {
        let block = steps.enumerated().filter { $0.element.inQuestionBlock }.map(\.offset)
        guard let first = block.first, let last = block.last, index >= first, index <= last else { return nil }
        return Double(index - first + 1) / Double(last - first + 1)
    }

    // MARK: ACT I — THE THRESHOLD

    private static let actOne: [OnboardingStep] = [
        OnboardingStep(act: 1, beat: .coldOpen,  glow: 0.05),
        OnboardingStep(act: 1, beat: .disarm,    glow: 0.07),
        OnboardingStep(act: 1, beat: .recognize, glow: 0.07),
        OnboardingStep(act: 1, beat: .reckon,    glow: 0.08),
        OnboardingStep(act: 1, beat: .turn,      glow: 0.12),
    ]

    // MARK: ACT II — THE MIRROR

    private static let actTwo: [OnboardingStep] = [
        OnboardingStep(act: 2, beat: .permission, glow: 0.08),
        OnboardingStep(act: 2, beat: .question(OnboardingQuestion(
            id: "motivation", eyebrow: "QUESTION 01",
            prompt: "What brought you here?",
            sub: "Your reason shapes everything.",
            options: OnboardingModel.motivationOptions, multi: true, variant: .tiles,
            read: { $0.motivation },
            apply: { $0.motivation = $1 })), inQuestionBlock: true, glow: 0.09),
        OnboardingStep(act: 2, beat: .question(OnboardingQuestion(
            id: "duration", eyebrow: "QUESTION 02",
            prompt: "How long has it been with you?",
            sub: "No judgment. Just so I understand.",
            options: OnboardingModel.Span.allCases.map(\.label), multi: false, variant: .sediment,
            read: { $0.duration.map { Set([$0.label]) } ?? [] },
            apply: { model, picked in
                model.duration = picked.first.flatMap { label in
                    OnboardingModel.Span.allCases.first { $0.label == label }
                }
            })), inQuestionBlock: true, glow: 0.09),
        OnboardingStep(act: 2, beat: .reflectionOne, inQuestionBlock: true, glow: 0.11),
        OnboardingStep(act: 2, beat: .question(OnboardingQuestion(
            id: "triggers", eyebrow: "QUESTION 03",
            prompt: "When does it pull hardest?",
            sub: "Noticing the pattern is half the work.",
            options: OnboardingModel.triggerOptions, multi: true, variant: .clockRing,
            read: { $0.triggers },
            apply: { $0.triggers = $1 })), inQuestionBlock: true, glow: 0.10),
        OnboardingStep(act: 2, beat: .question(OnboardingQuestion(
            id: "costs", eyebrow: "QUESTION 04",
            prompt: "What is it costing you?",
            sub: "When you're honest.",
            options: OnboardingModel.costOptions, multi: true, variant: .vignette,
            read: { $0.costs },
            apply: { $0.costs = $1 })), inQuestionBlock: true, glow: 0.08),
        OnboardingStep(act: 2, beat: .reflectionTwo, inQuestionBlock: true, glow: 0.12),
        OnboardingStep(act: 2, beat: .question(OnboardingQuestion(
            id: "bestSelf", eyebrow: "QUESTION 05",
            prompt: "Who are you at your best?",
            sub: "Forget the struggle for a second.",
            options: OnboardingModel.bestSelfOptions, multi: true, variant: .dawn,
            read: { $0.bestSelf },
            apply: { $0.bestSelf = $1 })), inQuestionBlock: true, glow: 0.2),
    ]

    // MARK: ACT III — THE TRUTH

    private static let actThree: [OnboardingStep] = [
        OnboardingStep(act: 3, beat: .reading,  glow: 0.12),
        OnboardingStep(act: 3, beat: .reveal,   glow: 0.2),
        OnboardingStep(act: 3, beat: .loop,     glow: 0.14),
        OnboardingStep(act: 3, beat: .timeline, glow: 0.16),
        OnboardingStep(act: 3, beat: .door,     glow: 0.16),
    ]

    // MARK: ACT IV — THE COVENANT

    private static let actFour: [OnboardingStep] = [
        OnboardingStep(act: 4, beat: .futureSelf,      glow: 0.3),
        OnboardingStep(act: 4, beat: .cornerstone,     glow: 0.2),
        OnboardingStep(act: 4, beat: .guardrails,      glow: 0.16),
        OnboardingStep(act: 4, beat: .unbeatable,      glow: 0.16),
        OnboardingStep(act: 4, beat: .rhythm,          glow: 0.16),
        OnboardingStep(act: 4, beat: .foundationReady, glow: 0.32),
        OnboardingStep(act: 4, beat: .nameWhy,         glow: 0.2),
    ]

    // MARK: ACT V — THE CROSSING

    private static let actFive: [OnboardingStep] = [
        OnboardingStep(act: 5, beat: .socialProof, glow: 0.14),
        OnboardingStep(act: 5, beat: .bridge,      glow: 0.24),
        OnboardingStep(act: 5, beat: .paywall,     glow: 0.2),
        OnboardingStep(act: 5, beat: .dayOne,      glow: 0.3),
    ]
}
