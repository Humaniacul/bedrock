import Foundation
import Observation

/// The Foundation streak engine (§4, §6.4) — the signature system.
///
/// Core mechanic: `foundationDays` is the monolith's height and the hero number,
/// and it **never decreases**. A clean day lays a stratum; a relapse *cracks the
/// current stratum* (a fracture you repair through the recovery flow) — it never
/// demolishes the foundation below. `currentCleanStreak` is the secondary,
/// honest "consecutive clean days" metric that does reset on a relapse.
///
/// (Design note: leading with a never-shrinking foundation is the deliberate
/// anti-shame choice from §6.4. To make relapses reset the hero number instead,
/// change only `StreakState.relapse()`.)
@MainActor
@Observable
final class StreakStore {
    private(set) var state: StreakState
    private let persistent: Bool
    private let calendar: Calendar

    init(state: StreakState, persistent: Bool, calendar: Calendar = .current) {
        self.state = state
        self.persistent = persistent
        self.calendar = calendar
    }

    /// The persisted live store, rolled forward to today.
    static func live(now: Date = .now) -> StreakStore {
        #if DEBUG
        // Dev affordance: seed a demo foundation for screenshots without touching
        // persisted state — e.g. `SIMCTL_CHILD_BEDROCK_DEMO_DAYS=31`.
        if let demo = StreakState.demoFromEnvironment() {
            return StreakStore(state: demo, persistent: false)
        }
        #endif
        let loaded = StreakState.load() ?? StreakState.new(now: now)
        let store = StreakStore(state: loaded, persistent: true)
        store.refreshForToday(now: now)
        return store
    }

    /// A non-persistent store for previews.
    static func preview(foundationDays: Int = 6, hasCrack: Bool = false) -> StreakStore {
        StreakStore(state: .preview(foundationDays: foundationDays, hasCrack: hasCrack), persistent: false)
    }

    // Read surface for the UI.
    var foundationDays: Int { state.foundationDays }
    var currentCleanStreak: Int { state.currentCleanStreak }
    var longestCleanStreak: Int { state.longestCleanStreak }
    var hasCrack: Bool { state.hasCrack }

    var currentMilestone: Milestone? { Milestone.ladder.last { $0.day <= state.foundationDays } }
    var nextMilestone: Milestone? { Milestone.ladder.first { $0.day > state.foundationDays } }

    /// Credit clean days that elapsed while the app was closed. Call on launch
    /// and whenever the app becomes active.
    func refreshForToday(now: Date = .now) {
        let advanced = state.advancedForToday(now: now, calendar: calendar)
        guard advanced != state else { return }
        state = advanced
        persist()
    }

    /// Log a relapse — cracks the current stratum, resets the clean streak, keeps
    /// the foundation.
    func recordRelapse() {
        state.relapse()
        persist()
    }

    /// Completing the recovery flow repairs the crack.
    func repairCrack() {
        state.repair()
        persist()
    }

    #if DEBUG
    func debugAdvanceDay() {
        state.creditDays(1)
        persist()
    }

    func debugReset() {
        state = .new()
        persist()
    }
    #endif

    private func persist() {
        guard persistent else { return }
        state.save()
    }
}

/// Persisted streak state. Codable so it survives launches via the App Group.
struct StreakState: Codable, Equatable {
    var foundationDays: Int
    var currentCleanStreak: Int
    var longestCleanStreak: Int
    var hasCrack: Bool
    var relapseCount: Int
    /// Start-of-day we last credited a stratum (prevents double-counting).
    var lastTickDay: Date
    /// When the journey began.
    var startDay: Date

    static func new(now: Date = .now, calendar: Calendar = .current) -> StreakState {
        let today = calendar.startOfDay(for: now)
        return StreakState(
            foundationDays: 1,
            currentCleanStreak: 1,
            longestCleanStreak: 1,
            hasCrack: false,
            relapseCount: 0,
            lastTickDay: today,
            startDay: today
        )
    }

    static func preview(foundationDays: Int, hasCrack: Bool, calendar: Calendar = .current) -> StreakState {
        let today = calendar.startOfDay(for: .now)
        return StreakState(
            foundationDays: foundationDays,
            currentCleanStreak: hasCrack ? 0 : foundationDays,
            longestCleanStreak: foundationDays,
            hasCrack: hasCrack,
            relapseCount: hasCrack ? 1 : 0,
            lastTickDay: today,
            startDay: calendar.date(byAdding: .day, value: -(foundationDays - 1), to: today) ?? today
        )
    }

    /// A pure transform: credit whole clean days elapsed since the last tick.
    /// While a crack is unrepaired, days don't credit (you repair, then resume),
    /// but the tick still advances so they aren't retroactively counted later.
    func advancedForToday(now: Date, calendar: Calendar) -> StreakState {
        let today = calendar.startOfDay(for: now)
        let elapsed = calendar.dateComponents([.day], from: lastTickDay, to: today).day ?? 0
        guard elapsed > 0 else { return self }

        var next = self
        if !hasCrack {
            next.creditDays(elapsed)
        }
        next.lastTickDay = today
        return next
    }

    mutating func creditDays(_ count: Int) {
        guard count > 0 else { return }
        foundationDays += count
        currentCleanStreak += count
        longestCleanStreak = max(longestCleanStreak, currentCleanStreak)
    }

    mutating func relapse() {
        hasCrack = true
        currentCleanStreak = 0
        relapseCount += 1
    }

    mutating func repair() {
        hasCrack = false
    }

    // MARK: Persistence (App Group)

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.streakState)
    }

    static func load() -> StreakState? {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Key.streakState) else { return nil }
        return try? JSONDecoder().decode(StreakState.self, from: data)
    }

    #if DEBUG
    static func demoFromEnvironment() -> StreakState? {
        let env = ProcessInfo.processInfo.environment
        guard let raw = env["BEDROCK_DEMO_DAYS"], let days = Int(raw) else { return nil }
        return .preview(foundationDays: days, hasCrack: env["BEDROCK_DEMO_CRACK"] == "1")
    }
    #endif
}

/// Named rock layers tied to the recovery timeline (§4, §6.4).
/// Phase 4 ties each to a real dopamine-reset / rewiring marker.
struct Milestone: Identifiable, Hashable {
    var id: Int { day }
    let day: Int
    let name: String

    static let ladder: [Milestone] = [
        Milestone(day: 3,   name: "Topsoil"),
        Milestone(day: 7,   name: "Clay"),
        Milestone(day: 14,  name: "Sandstone"),
        Milestone(day: 30,  name: "Limestone"),
        Milestone(day: 60,  name: "Granite"),
        Milestone(day: 90,  name: "Basalt"),
        Milestone(day: 180, name: "Bedrock"),
    ]
}
