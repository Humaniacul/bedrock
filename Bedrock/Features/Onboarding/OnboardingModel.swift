import Foundation
import Observation

/// Holds what the user tells us during the onboarding journey. Answers
/// personalize the copy, the verdict, the cost estimate, and the projection; the
/// "why" becomes their future-self letter (it feeds the gauntlet, §4). Nothing
/// here is uploaded — it lives on-device (§10.6).
@MainActor
@Observable
final class OnboardingModel {
    // MARK: Assessment answers
    var reason: String?
    var frequency: Frequency?
    var duration: Duration?
    var attempts: Attempts?
    var control: Control?
    var costs: Set<String> = []
    var why: String = ""

    // MARK: Answer scales

    enum Frequency: CaseIterable {
        case occasionally, weekly, daily, manyTimesDaily
        var label: String {
            switch self {
            case .occasionally:   "Now and then"
            case .weekly:         "Most weeks"
            case .daily:          "Most days"
            case .manyTimesDaily: "Many times a day"
            }
        }
        var sessionsPerDay: Double {
            switch self { case .occasionally: 0.15; case .weekly: 0.4; case .daily: 1.1; case .manyTimesDaily: 3 }
        }
        var weight: Int { switch self { case .occasionally: 1; case .weekly: 2; case .daily: 3; case .manyTimesDaily: 4 } }
        static func from(_ label: String) -> Frequency? { allCases.first { $0.label == label } }
    }

    enum Duration: CaseIterable {
        case months, fewYears, mostOfLife, unsure
        var label: String {
            switch self {
            case .months:     "A few months"
            case .fewYears:   "A few years"
            case .mostOfLife: "Most of my life"
            case .unsure:     "I'm not sure"
            }
        }
        var years: Double { switch self { case .months: 0.5; case .fewYears: 3; case .mostOfLife: 12; case .unsure: 4 } }
        var weight: Int { switch self { case .months: 1; case .fewYears: 2; case .mostOfLife: 3; case .unsure: 2 } }
        static func from(_ label: String) -> Duration? { allCases.first { $0.label == label } }
    }

    enum Attempts: CaseIterable {
        case fewTimes, manyTimes, constantly
        var label: String {
            switch self { case .fewTimes: "Once or twice"; case .manyTimes: "Many times"; case .constantly: "Over and over" }
        }
        var weight: Int { switch self { case .fewTimes: 1; case .manyTimes: 2; case .constantly: 3 } }
        static func from(_ label: String) -> Attempts? { allCases.first { $0.label == label } }
    }

    enum Control: CaseIterable {
        case yes, sometimes, no
        var label: String { switch self { case .yes: "Mostly, yes"; case .sometimes: "Sometimes"; case .no: "Not really" } }
        var weight: Int { switch self { case .yes: 0; case .sometimes: 1; case .no: 2 } }
        static func from(_ label: String) -> Control? { allCases.first { $0.label == label } }
    }

    static let reasonOptions = [
        "I can't stop", "It's hurting someone I love", "I've lost control of my time",
        "I want to feel free again", "I'm just curious",
    ]
    static let costOptions = ["My focus", "My confidence", "A relationship", "My sleep", "My self-respect"]

    // MARK: Derived — the verdict (personalized mirror)

    struct Verdict { let score: Int; let level: String; let copy: String }

    /// Erosion (0–100) from the answers → foundation strength (100 − erosion).
    var verdict: Verdict {
        // Max raw = freq 4 + dur 3 + att 3 + ctrl 2 + costs 5 = 17.
        let freqW: Int = frequency?.weight ?? 2
        let durW: Int = duration?.weight ?? 2
        let attW: Int = attempts?.weight ?? 1
        let ctrlW: Int = control?.weight ?? 1
        let costW: Int = min(costs.count, 5)
        let raw = freqW + durW + attW + ctrlW + costW
        let erosion = min(100, Int((Double(raw) / 17.0) * 100))
        let strength = max(4, 100 - erosion) // never show a hopeless zero
        let level: String
        let copy: String
        switch erosion {
        case 0..<30:
            level = "Early erosion"
            copy = "You're catching this early — that's a real advantage. The foundation is mostly intact."
        case 30..<55:
            level = "Moderate erosion"
            copy = "There's real wear here, but nothing we can't rebuild. You're far from too late."
        case 55..<78:
            level = "Significant erosion"
            copy = "Serious — but completely rebuildable. People who start exactly here succeed every day."
        default:
            level = "Severe erosion"
            copy = "It's gone deep. That's not a verdict on you — it's a measure of what you've survived. We can rebuild it."
        }
        return Verdict(score: strength, level: level, copy: copy)
    }

    // MARK: Derived — the cost

    /// Rough lifetime hours lost. `avgSessionHours` is an estimate — VERIFY BEFORE LAUNCH.
    var hoursLost: Int {
        let avgSessionHours = 0.4 // ~24 min/session (assumption)
        let perDay = frequency?.sessionsPerDay ?? 0.5
        let years = duration?.years ?? 2
        return Int((perDay * avgSessionHours * 365 * years).rounded())
    }
    var daysLost: Int { Int((Double(hoursLost) / 24).rounded()) }

    // MARK: Derived — the 90-day projection

    /// 13 normalized points (0…1) — a confident rising recovery curve.
    var projectionPoints: [Double] {
        let baseline = Double(verdict.score) / 100.0 * 0.25
        return (0...12).map { i in
            let t = Double(i) / 12.0
            return baseline + (1 - baseline) * (1 - pow(1 - t, 2.2))
        }
    }

    // MARK: Lifecycle

    static var isComplete: Bool { AppGroup.defaults.bool(forKey: AppGroup.Key.onboardingComplete) }

    /// Persist what matters and mark onboarding done.
    func complete(services: AppServices) {
        let trimmed = why.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            services.commitment.letter = trimmed // their own words, ready for the gauntlet
        }
        AppGroup.defaults.set(true, forKey: AppGroup.Key.onboardingComplete)
    }

    #if DEBUG
    static func debugReset() {
        AppGroup.defaults.set(false, forKey: AppGroup.Key.onboardingComplete)
    }
    #endif
}
