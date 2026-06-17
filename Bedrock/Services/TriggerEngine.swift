import Foundation
import Observation

/// On-device trigger intelligence (§4, §10.6). ALL analysis runs locally —
/// nothing leaves the phone. Logs urge moments with context and surfaces the
/// user's personal danger windows from a transparent, explainable heuristic.
///
/// We deliberately ship a statistical model here rather than a Core ML net: a
/// new user has zero data, the heuristic degrades gracefully from the very
/// first event, and every score is explainable ("Sun 21:00–00:00"). The whole
/// model is isolated behind `risk(at:)` / `dangerWindows()` / `heatmap()`, so a
/// Create ML tabular classifier can replace it later without touching callers.
@MainActor
@Observable
final class TriggerEngine {
    /// How a logged moment resolved. Slips are logged without shame (§6.4).
    enum Outcome: String, Codable, CaseIterable {
        case surfed   // rode the urge out
        case called   // reached out to their person
        case slipped  // honest log of a relapse
    }

    struct Event: Identifiable, Codable {
        var id = UUID()
        var date: Date
        var trigger: String?     // named feeling / context ("Stress", "Boredom"…)
        var urgeIntensity: Int?  // 1–10
        var outcome: Outcome

        var weekday: Int { Calendar.current.component(.weekday, from: date) } // 1=Sun…7=Sat
        var hour: Int { Calendar.current.component(.hour, from: date) }
    }

    private(set) var events: [Event] = []
    private let persist: Bool

    /// Don't surface risk/windows until there's the faintest pattern to stand on.
    static let minEvents = 4

    init(persist: Bool = true) {
        self.persist = persist
        if persist { events = Self.load() }
    }

    // MARK: - Logging

    func log(_ event: Event) {
        events.append(event)
        events.sort { $0.date < $1.date }
        save()
    }

    // MARK: - Danger windows (explainable heuristic)

    struct DangerWindow: Identifiable {
        let weekday: Int    // 1=Sun…7=Sat
        let block: Int      // 3-hour block, 0 (00:00–03:00) … 7 (21:00–00:00)
        let score: Double   // 0…1, normalized to the user's hottest bucket
        let count: Int
        var id: String { "\(weekday)-\(block)" }
        var label: String { "\(TriggerEngine.weekdayName(weekday)) \(TriggerEngine.blockLabel(block))" }
    }

    /// The user's hottest recurring windows, recency- and intensity-weighted.
    /// Empty until a small pattern exists (a bucket needs ≥ 2 events).
    func dangerWindows(top: Int = 3) -> [DangerWindow] {
        let scores = bucketScores()
        guard let maxScore = scores.values.map(\.score).max(), maxScore > 0 else { return [] }
        return scores
            .filter { $0.value.count >= 2 }
            .map { DangerWindow(weekday: $0.key.weekday, block: $0.key.block,
                                score: $0.value.score / maxScore, count: $0.value.count) }
            .sorted { $0.score > $1.score }
            .prefix(top)
            .map { $0 }
    }

    /// Risk for any moment, 0…1, from how close it sits to the user's hot
    /// buckets (the bucket itself, plus a softened look at the neighbours).
    func risk(at date: Date = .now) -> Double {
        guard events.count >= Self.minEvents else { return 0 }
        let scores = bucketScores(asOf: date)
        guard let maxScore = scores.values.map(\.score).max(), maxScore > 0 else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: date)
        let block = Calendar.current.component(.hour, from: date) / 3
        func norm(_ b: Bucket) -> Double { (scores[b]?.score ?? 0) / maxScore }
        let here = norm(Bucket(weekday: weekday, block: block))
        let prev = norm(Bucket(weekday: weekday, block: (block + 7) % 8)) * 0.5
        let next = norm(Bucket(weekday: weekday, block: (block + 1) % 8)) * 0.5
        return min(1, max(here, prev, next))
    }

    /// Are we in a known tough stretch right now? Gated on having enough data.
    var isHighRiskNow: Bool { risk() >= 0.6 }

    // MARK: - Insights aggregates

    /// 7×8 grid [weekdayIndex 0=Sun…6=Sat][block 0…7] of normalized intensity.
    func heatmap() -> [[Double]] {
        var grid = Array(repeating: Array(repeating: 0.0, count: 8), count: 7)
        let scores = bucketScores()
        guard let maxScore = scores.values.map(\.score).max(), maxScore > 0 else { return grid }
        for (bucket, value) in scores {
            grid[(bucket.weekday - 1) % 7][bucket.block] = value.score / maxScore
        }
        return grid
    }

    /// Named triggers by frequency, most common first.
    func triggerCounts() -> [(trigger: String, count: Int)] {
        var counts: [String: Int] = [:]
        for event in events {
            guard let raw = event.trigger?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { continue }
            counts[raw, default: 0] += 1
        }
        return counts.map { (trigger: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    /// Most recent moments first, for the Insights log.
    var recent: [Event] { events.suffix(25).reversed() }

    // MARK: - Scoring internals

    private struct Bucket: Hashable { let weekday: Int; let block: Int }

    /// Sum a recency- and intensity-weighted score into each (weekday, block)
    /// bucket. Half-life of 21 days keeps the picture current as habits shift.
    private func bucketScores(asOf now: Date = .now) -> [Bucket: (score: Double, count: Int)] {
        let halfLife = 21.0
        var out: [Bucket: (score: Double, count: Int)] = [:]
        for event in events {
            let ageDays = max(0, now.timeIntervalSince(event.date) / 86_400)
            let recency = pow(0.5, ageDays / halfLife)
            let intensity = Double(event.urgeIntensity ?? 5) / 10.0
            let outcomeWeight: Double = switch event.outcome {
            case .slipped: 1.4   // slips carry the most signal
            case .called:  1.1
            case .surfed:  1.0
            }
            let weight = recency * intensity * outcomeWeight
            let bucket = Bucket(weekday: event.weekday, block: event.hour / 3)
            let prev = out[bucket] ?? (0, 0)
            out[bucket] = (prev.score + weight, prev.count + 1)
        }
        return out
    }

    // MARK: - Labels

    nonisolated static func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols // index 0 = Sunday (Gregorian)
        return symbols[(weekday - 1) % symbols.count]
    }

    nonisolated static func blockLabel(_ block: Int) -> String {
        let start = block * 3
        let end = (start + 3) % 24
        return String(format: "%02d:00–%02d:00", start, end)
    }

    // MARK: - Persistence (App Group JSON — on-device only, §10.6)

    private func save() {
        guard persist, let data = try? JSONEncoder().encode(events) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.triggerEvents)
    }

    private static func load() -> [Event] {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Key.triggerEvents),
              let events = try? JSONDecoder().decode([Event].self, from: data)
        else { return [] }
        return events.sorted { $0.date < $1.date }
    }

    // MARK: - Seeded data for previews / DEBUG

    static func preview() -> TriggerEngine {
        let engine = TriggerEngine(persist: false)
        engine.events = engine.sampleEvents()
        return engine
    }

    #if DEBUG
    /// Seed a realistic pattern so Insights renders without logging by hand.
    func debugSeedSamples() {
        events = sampleEvents()
        save()
    }
    #endif

    private func sampleEvents() -> [Event] {
        let cal = Calendar.current
        let now = Date()
        func at(daysAgo: Int, hour: Int, _ trigger: String, _ intensity: Int, _ outcome: Outcome) -> Event {
            let base = cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
            let date = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? now
            return Event(date: date, trigger: trigger, urgeIntensity: intensity, outcome: outcome)
        }
        return [
            at(daysAgo: 1, hour: 23, "Boredom", 7, .surfed),
            at(daysAgo: 2, hour: 0, "Loneliness", 8, .called),
            at(daysAgo: 5, hour: 22, "Stress", 6, .surfed),
            at(daysAgo: 7, hour: 23, "Tired", 9, .slipped),
            at(daysAgo: 8, hour: 14, "Procrastinating", 5, .surfed),
            at(daysAgo: 9, hour: 23, "Boredom", 7, .surfed),
            at(daysAgo: 12, hour: 1, "Anxious", 8, .called),
            at(daysAgo: 14, hour: 23, "Loneliness", 9, .slipped),
            at(daysAgo: 16, hour: 22, "Boredom", 6, .surfed),
        ].sorted { $0.date < $1.date }
    }
}
