import Foundation
import Observation

/// Everything the user tells us during onboarding (spec v2.0 §Data model).
/// All of it stays on-device — no account exists yet, nothing is uploaded.
///
/// Deliberately HONEST: no computed "addiction score", no fabricated "hours
/// lost" figure, no fake user counter. The only derived values are templated
/// reflections assembled from the user's own words, with warm fallbacks —
/// and the one number in the flow (S4) is the user's own estimate.
@MainActor
@Observable
final class OnboardingModel {
    // MARK: Answers

    var dayCostEstimate: Double = 0           // S4  — Reckon: their own estimate (0…1 of the day)
    var motivation: Set<String> = []          // S7  — what brought you here
    var duration: Span?                       // S8  — how long it's been with you
    var affirmedReflectionOne = false         // S9  — "Yes, that's me"
    var triggers: Set<String> = []            // S10 — when it pulls hardest
    var costs: Set<String> = []               // S11 — what it's costing
    var topCost: String?                      // S11 — Weigh: the one that hurts most
    var affirmedReflectionTwo = false         // S12
    var bestSelf: Set<String> = []            // S13 — who you are at your best
    var bestSelfText: String = ""             // S13 — optional, their own words
    var futureReturns: Set<String> = []       // S19 — what comes back first

    var commitmentName: String = ""           // S20 — typed into the contract
    var hasSealedOath = false                 // S20 — cornerstone set
    var oathSealedAt: Date?

    var guardrails: Set<Guardrail> = []       // S21
    var frictionTier: FrictionTier = .reflectionDelay // S22
    var preferredTimes: Set<TimeSlot> = []    // S23
    var whyLine: String = ""                  // S25 — surfaced at the urge moment

    // MARK: Option vocabulary (single source for the beats)

    static let recognizeOptions = [
        "Reaching for it before I'm awake", "Opening it when no one's watching",
        "The night gone, nothing to show", "\u{201C}Never again\u{201D} — then again",
        "Hiding it", "Can't feel much without it",
    ]
    static let motivationOptions = [
        "Losing hours", "Hurting someone I love", "I don't feel like myself",
        "I want my focus back", "I know I can do better", "Something happened",
    ]
    static let triggerOptions = [
        "Late night", "Alone & bored", "Stressed or low",
        "Mornings", "After a win", "Everywhere",
    ]
    static let costOptions = [
        "Hours", "Focus & drive", "How I see myself",
        "Being present", "Sleep", "My control",
    ]
    static let bestSelfOptions = [
        "Focused & sharp", "Present", "Disciplined",
        "Calm, not restless", "Driven", "Just… free",
    ]
    static let futureReturnOptions = [
        "My mornings", "My focus", "Being present", "Feeling like myself",
    ]

    enum Span: String, CaseIterable, Codable {
        case underYear, fewYears, sinceTeens, always
        var label: String {
            switch self {
            case .underYear: "Under a year"
            case .fewYears:  "A few years"
            case .sinceTeens: "Since my teens"
            case .always:    "As long as I remember"
            }
        }
        /// How deep the sediment sits (0…1) — drives the S8 visual.
        var depth: Double {
            switch self { case .underYear: 0.25; case .fewYears: 0.5; case .sinceTeens: 0.75; case .always: 1 }
        }
    }

    enum Guardrail: String, CaseIterable, Codable {
        case adultContent, pullApps, namedTriggers, lateNight, recommended
        var label: String {
            switch self {
            case .adultContent:  "Adult content"
            case .pullApps:      "The apps that pull you in"
            case .namedTriggers: "Triggers I'll name"
            case .lateNight:     "Late-night hours"
            case .recommended:   "Let Bedrock recommend"
            }
        }
        var icon: String {
            switch self {
            case .adultContent:  "shield.fill"
            case .pullApps:      "app.badge.checkmark"
            case .namedTriggers: "target"
            case .lateNight:     "moon.fill"
            case .recommended:   "wand.and.stars"
            }
        }
    }

    enum FrictionTier: String, CaseIterable, Codable {
        case reflectionDelay, partner, locked
        var label: String {
            switch self {
            case .reflectionDelay: "Reflection delay"
            case .partner:         "Accountability partner"
            case .locked:          "Locked mode"
            }
        }
        var detail: String {
            switch self {
            case .reflectionDelay: "A forced pause before any change. Your future self gets a vote."
            case .partner:         "Someone you trust is quietly notified if the wall comes down."
            case .locked:          "Your strong self sets terms your weak self can't break."
            }
        }
        var icon: String {
            switch self {
            case .reflectionDelay: "hourglass"
            case .partner:         "person.2.fill"
            case .locked:          "lock.fill"
            }
        }
    }

    enum TimeSlot: String, CaseIterable, Codable {
        case morning, afternoon, evening, lateNight
        var label: String {
            switch self {
            case .morning:   "Morning (6–10)"
            case .afternoon: "Afternoon (12–4)"
            case .evening:   "Evening (5–9)"
            case .lateNight: "Late night (9–12)"
            }
        }
    }

    // MARK: Derived — the best-self word (the North Star)

    /// The single word reused on S15/17/19/24 and the paywall. Their own typed
    /// words win; otherwise the first selection, distilled; graceful fallback.
    var bestSelfWord: String {
        let typed = bestSelfText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            return typed.split(separator: " ").prefix(3).joined(separator: " ").lowercased()
        }
        for option in Self.bestSelfOptions where bestSelf.contains(option) {
            switch option {
            case "Focused & sharp":     return "focused"
            case "Present":             return "present"
            case "Disciplined":         return "disciplined"
            case "Calm, not restless":  return "calm"
            case "Driven":              return "driven"
            default:                    return "free"
            }
        }
        return "free"
    }

    // MARK: Derived — Reckon (S4) qualitative reading of their own estimate

    /// A label for the fraction they set — their words for their number.
    var dayCostLabel: String {
        switch dayCostEstimate {
        case ..<0.1:   "A sliver"
        case ..<0.25:  "An hour or two"
        case ..<0.45:  "A few hours"
        case ..<0.7:   "Half my day"
        default:       "Most of it"
        }
    }

    // MARK: Derived — templated reflections (the active-listening moat)

    /// S9 — after Q1/Q2. Says their answers back, ends on aspiration.
    /// Short (v2): two lines max, then the Affirm ask carries the weight.
    var reflectionOne: [String] {
        var lines: [String] = []
        let opener: String? = {
            switch duration {
            case .underYear:  "Not even a year in — and you're already facing it."
            case .fewYears:   "A few years of this."
            case .sinceTeens: "Since your teens."
            case .always:     "As long as you can remember."
            case nil:         nil
            }
        }()
        if let opener { lines.append(opener) }
        lines.append(primaryMotivationMirror)
        return lines
    }

    private var primaryMotivationMirror: String {
        // Priority order: the most personal reason wins the mirror.
        if motivation.contains("Hurting someone I love") {
            return "And you're not here out of fear — it's reaching someone you love."
        }
        if motivation.contains("I don't feel like myself") {
            return "And you're not here out of fear. You're here because you don't feel like yourself."
        }
        if motivation.contains("Something happened") {
            return "Something happened — and you decided that was enough."
        }
        if motivation.contains("Losing hours") {
            return "You're here because you're done losing hours to it."
        }
        if motivation.contains("I want my focus back") {
            return "You're here to take your focus back."
        }
        if motivation.contains("I know I can do better") {
            return "You're here because you know you're capable of more."
        }
        return "You showed up. That's the honest start most men never make."
    }

    /// S12 — after Q4+Weigh. Names their top cost, then pivots to agency.
    var reflectionTwo: [String] {
        let named: String = {
            guard let top = topCost else {
                return "Whatever it's taken from you —"
            }
            let phrase: [String: String] = [
                "Hours": "The hours most of all",
                "Focus & drive": "Focus most of all",
                "How I see myself": "The way you see yourself, most of all",
                "Being present": "Being present, most of all",
                "Sleep": "Sleep most of all",
                "My control": "Your sense of control, most of all",
            ]
            return (phrase[top] ?? top) + "."
        }()
        return [
            named,
            "Here's what most men miss:",
            "none of it is permanent.",
        ]
    }

    /// S15 — the reveal, uncovered tap by tap. A coach who was listening.
    var revealLines: [String] {
        var lines: [String] = []
        if let when = patternWhen { lines.append(when) }
        if let held = patternHeld { lines.append(held) }
        if motivation.contains("Hurting someone I love") {
            lines.append("But you're not here out of fear — you're here for the people this touches, and for who you could be.")
        } else {
            lines.append("But you're not here out of fear — you're here because you know who you could be.")
        }
        lines.append("That's everything we need.")
        return lines
    }

    private var patternWhen: String? {
        if triggers.contains("Late night") { return "Hits hardest late at night, when the house goes quiet." }
        if triggers.contains("Mornings") { return "It's there before your feet even hit the floor." }
        if triggers.contains("Alone & bored") { return "Hits hardest when you're alone with nothing pulling at you." }
        if triggers.contains("Stressed or low") { return "It shows up when you're stressed or low — relief on demand." }
        if triggers.contains("After a win") { return "It even shows up after your wins." }
        if triggers.contains("Everywhere") { return "It's threaded through the whole day." }
        return "The pattern is real — and now it has a name."
    }

    private var patternHeld: String? {
        switch duration {
        case .underYear:  "It moved in fast."
        case .fewYears:   "Been with you for years."
        case .sinceTeens: "Been with you since your teens."
        case .always:     "Been there as long as you can remember."
        case nil:         nil
        }
    }

    /// S17 — which stretch of the timeline gets the emphasis.
    var timelineEmphasis: Int {
        switch duration {
        case .underYear, .fewYears, nil: 1  // "Days 4–10 · hardest, then it loosens"
        case .sinceTeens, .always:       2  // "Weeks 2–4 · clarity"
        }
    }

    /// S24 — one line naming what the foundation now covers, from their config.
    var foundationSummary: String {
        var parts: [String] = []
        if guardrails.contains(.lateNight) || triggers.contains("Late night") {
            parts.append("Guarding the late nights.")
        }
        if guardrails.contains(.adultContent) || guardrails.contains(.recommended) {
            parts.append("Holding the line on what pulls hardest.")
        } else if guardrails.contains(.pullApps) {
            parts.append("Holding the line on the apps that pull you in.")
        }
        parts.append("Set to \(frictionTier.label.lowercased()).")
        return parts.joined(separator: " ")
    }

    // MARK: Resume (pre-paywall completion is the top funnel metric)

    private struct Snapshot: Codable {
        var step: Int
        var dayCostEstimate: Double
        var motivation: [String]
        var duration: Span?
        var affirm1: Bool
        var triggers: [String]
        var costs: [String]
        var topCost: String?
        var affirm2: Bool
        var bestSelf: [String]
        var bestSelfText: String
        var futureReturns: [String]
        var commitmentName: String
        var hasSealedOath: Bool
        var oathSealedAt: Date?
        var guardrails: [Guardrail]
        var frictionTier: FrictionTier
        var preferredTimes: [TimeSlot]
        var whyLine: String
    }

    /// Persist progress so a backgrounded flow resumes, never restarts.
    func save(step: Int) {
        let snap = Snapshot(
            step: step, dayCostEstimate: dayCostEstimate, motivation: Array(motivation),
            duration: duration, affirm1: affirmedReflectionOne, triggers: Array(triggers),
            costs: Array(costs), topCost: topCost, affirm2: affirmedReflectionTwo,
            bestSelf: Array(bestSelf), bestSelfText: bestSelfText,
            futureReturns: Array(futureReturns), commitmentName: commitmentName,
            hasSealedOath: hasSealedOath, oathSealedAt: oathSealedAt,
            guardrails: Array(guardrails), frictionTier: frictionTier,
            preferredTimes: Array(preferredTimes), whyLine: whyLine)
        if let data = try? JSONEncoder().encode(snap) {
            AppGroup.defaults.set(data, forKey: AppGroup.Key.onboardingProgress)
        }
    }

    /// Restore a saved flow. Returns the step to resume at (0 if fresh).
    func restore() -> Int {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Key.onboardingProgress),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return 0 }
        dayCostEstimate = snap.dayCostEstimate
        motivation = Set(snap.motivation)
        duration = snap.duration
        affirmedReflectionOne = snap.affirm1
        triggers = Set(snap.triggers)
        costs = Set(snap.costs)
        topCost = snap.topCost
        affirmedReflectionTwo = snap.affirm2
        bestSelf = Set(snap.bestSelf)
        bestSelfText = snap.bestSelfText
        futureReturns = Set(snap.futureReturns)
        commitmentName = snap.commitmentName
        hasSealedOath = snap.hasSealedOath
        oathSealedAt = snap.oathSealedAt
        guardrails = Set(snap.guardrails)
        frictionTier = snap.frictionTier
        preferredTimes = Set(snap.preferredTimes)
        whyLine = snap.whyLine
        return snap.step
    }

    // MARK: Lifecycle

    static var isComplete: Bool { AppGroup.defaults.bool(forKey: AppGroup.Key.onboardingComplete) }

    /// Persist what matters and mark onboarding done. The whyLine becomes the
    /// commitment letter — read back at the urge moment and in the gauntlet.
    func complete(services: AppServices) {
        let why = whyLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !why.isEmpty {
            services.commitment.letter = why
        }
        AppGroup.defaults.set(true, forKey: AppGroup.Key.onboardingComplete)
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.onboardingProgress)
    }

    #if DEBUG
    static func debugReset() {
        AppGroup.defaults.set(false, forKey: AppGroup.Key.onboardingComplete)
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.onboardingProgress)
    }
    #endif
}
