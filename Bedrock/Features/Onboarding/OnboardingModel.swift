import Foundation
import Observation

/// Everything the user tells us during onboarding (spec v1.0 §Data model).
/// All of it stays on-device — no account exists yet, nothing is uploaded.
///
/// Deliberately HONEST: there is no computed "addiction score", no fabricated
/// "hours lost" figure, no fake user counter. The only derived values are
/// templated reflections assembled from the user's own words, with warm
/// fallbacks when inputs are sparse.
@MainActor
@Observable
final class OnboardingModel {
    // MARK: Answers

    var motivation: Set<String> = []          // S7  — what brought you here
    var duration: Span?                       // S8  — how long it's been with you
    var triggers: Set<String> = []            // S10 — when it pulls hardest
    var costs: Set<String> = []               // S11 — what it's costing
    var bestSelf: Set<String> = []            // S13 — who you are at your best
    var bestSelfText: String = ""             // S13 — optional, their own words

    var commitmentName: String = ""           // S20 — typed into the contract
    var hasSealedOath = false                 // S20 — cornerstone set
    var oathSealedAt: Date?

    var guardrails: Set<Guardrail> = []       // S21
    var frictionTier: FrictionTier = .reflectionDelay // S22
    var preferredTimes: Set<TimeSlot> = []    // S23
    var whyLine: String = ""                  // S25 — surfaced at the urge moment

    // MARK: Option vocabulary (single source for the question beats)

    static let motivationOptions = [
        "Tired of losing hours", "It's hurting someone I love", "I don't feel like myself",
        "I want my focus back", "I know I can do better", "Something happened",
    ]
    static let triggerOptions = [
        "Late at night", "Alone and bored", "Stressed or low",
        "First thing in the morning", "After a win", "It's everywhere",
    ]
    static let costOptions = [
        "Hours I'll never get back", "My focus and drive", "How I see myself",
        "Being present with people", "Sleep", "My sense of control",
    ]
    static let bestSelfOptions = [
        "Focused and sharp", "Present with people I love", "Disciplined",
        "Calm, not restless", "Driven", "Just… free",
    ]

    enum Span: String, CaseIterable, Codable {
        case underYear, fewYears, sinceTeens, always
        var label: String {
            switch self {
            case .underYear: "Under a year"
            case .fewYears:  "A few years"
            case .sinceTeens: "Since my teens"
            case .always:    "As long as I can remember"
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
            case .adultContent:  "Adult sites & content"
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
            case "Focused and sharp":            return "focused"
            case "Present with people I love":   return "present"
            case "Disciplined":                  return "disciplined"
            case "Calm, not restless":           return "calm"
            case "Driven":                       return "driven"
            default:                             return "free"
            }
        }
        return "free"
    }

    // MARK: Derived — templated reflections (the active-listening moat)

    /// S9 — after Q1/Q2. Says their answers back, ends on aspiration.
    var reflectionOne: [String] {
        var lines: [String] = []
        switch duration {
        case .underYear:  lines.append("So — this is newer for you. You're catching it early.")
        case .fewYears:   lines.append("So — a few years of this.")
        case .sinceTeens: lines.append("So — it's been with you since your teens.")
        case .always:     lines.append("So — you can't remember a time before it.")
        case nil:         break
        }
        lines.append(primaryMotivationMirror)
        lines.append("Hold onto that. We'll come back to it.")
        return lines
    }

    private var primaryMotivationMirror: String {
        // Priority order: the most personal reason wins the mirror.
        if motivation.contains("It's hurting someone I love") {
            return "And you're not here for yourself alone — it's reaching someone you love."
        }
        if motivation.contains("I don't feel like myself") {
            return "And you're not here out of fear. You're here because you don't feel like yourself."
        }
        if motivation.contains("Something happened") {
            return "Something happened — and you decided that was enough."
        }
        if motivation.contains("Tired of losing hours") {
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

    /// S12 — after Q4. Sits with the named cost one beat, then pivots to agency.
    var reflectionTwo: [String] {
        let named = costSummary
        return [
            named.isEmpty ? "Whatever it's taken from you —" : "\(named).",
            "Here's the part most people miss:",
            "none of it is permanent.",
        ]
    }

    private var costSummary: String {
        let short: [String: String] = [
            "Hours I'll never get back": "Hours",
            "My focus and drive": "focus",
            "How I see myself": "the way you see yourself",
            "Being present with people": "presence with the people you love",
            "Sleep": "sleep",
            "My sense of control": "your sense of control",
        ]
        let picked = Self.costOptions.filter { costs.contains($0) }.compactMap { short[$0] }
        guard !picked.isEmpty else { return "" }
        var parts = Array(picked.prefix(3))
        // Capitalize the first fragment so the sentence reads carved, not pasted.
        parts[0] = parts[0].prefix(1).uppercased() + parts[0].dropFirst()
        switch parts.count {
        case 1:  return parts[0]
        case 2:  return "\(parts[0]) and \(parts[1])"
        default: return "\(parts[0]), \(parts[1]), and \(parts[2])"
        }
    }

    /// S15 — the reveal. A coach who was paying attention, not a gauge.
    var revealLines: [String] {
        var lines = ["Here's what I see."]
        lines.append(patternLine)
        if motivation.contains("It's hurting someone I love") {
            lines.append("But you're not here out of fear. You're here for the people this touches — and for who you could be.")
        } else {
            lines.append("But you're not here out of fear. You're here because you know who you could be.")
        }
        lines.append("That's everything we need.")
        return lines
    }

    private var patternLine: String {
        let when: String? = {
            if triggers.contains("Late at night") { return "It hits hardest late at night, when the house goes quiet" }
            if triggers.contains("First thing in the morning") { return "It's there before your feet even hit the floor" }
            if triggers.contains("Alone and bored") { return "It hits hardest when you're alone with nothing pulling at you" }
            if triggers.contains("Stressed or low") { return "It shows up when you're stressed or low — relief on demand" }
            if triggers.contains("After a win") { return "It even shows up after your wins" }
            if triggers.contains("It's everywhere") { return "It's threaded through the whole day" }
            return nil
        }()
        let held: String? = {
            switch duration {
            case .underYear:  "it moved in fast"
            case .fewYears:   "it's been with you for years"
            case .sinceTeens: "it's been with you since your teens"
            case .always:     "it's been there as long as you can remember"
            case nil:         nil
            }
        }()
        switch (when, held) {
        case let (w?, h?): return "\(w) — and \(h)."
        case let (w?, nil): return "\(w)."
        case let (nil, h?): return "And \(h)."
        default: return "The pattern is real — and now it has a name."
        }
    }

    /// S17 — which stretch of the timeline gets the emphasis.
    /// Longer histories → emphasize that clarity still returns; shorter →
    /// emphasize the early hard stretch they're about to hit.
    var timelineEmphasis: Int {
        switch duration {
        case .underYear, .fewYears, nil: 1  // "Days 4–10 · the hardest stretch"
        case .sinceTeens, .always:       2  // "Weeks 2–4 · clarity returns"
        }
    }

    /// S24 — one line naming what the foundation now covers, from their config.
    var foundationSummary: String {
        var parts: [String] = []
        if guardrails.contains(.lateNight) || triggers.contains("Late at night") {
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
        var motivation: [String]
        var duration: Span?
        var triggers: [String]
        var costs: [String]
        var bestSelf: [String]
        var bestSelfText: String
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
            step: step, motivation: Array(motivation), duration: duration,
            triggers: Array(triggers), costs: Array(costs), bestSelf: Array(bestSelf),
            bestSelfText: bestSelfText, commitmentName: commitmentName,
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
        motivation = Set(snap.motivation)
        duration = snap.duration
        triggers = Set(snap.triggers)
        costs = Set(snap.costs)
        bestSelf = Set(snap.bestSelf)
        bestSelfText = snap.bestSelfText
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
