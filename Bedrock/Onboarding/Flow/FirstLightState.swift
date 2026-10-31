import Foundation

// The onboarding's saved state (SPEC.md › RESUME): screen, answers and wall
// status, written to the App Group on every change so a closed app resumes on
// the exact screen with nothing lost. Answers are stored by stable IDs, never by
// their display strings, so a language change can't break them.

/// S5 · When it usually gets hard. Display strings are `onb.s5.chips`, in this order.
enum HourBand: String, Codable, CaseIterable {
    case lateNight, earlyMorning, middleOfDay, afterWork, weekends, noPattern

    /// The local window it stands for (SPEC.md S5): heads-ups arrive 15 minutes
    /// before `start`. Weekdays use Calendar numbering (1 = Sunday).
    struct Window { let weekdays: [Int]?; let startHour: Int }

    var window: Window? {
        switch self {
        case .lateNight: Window(weekdays: nil, startHour: 22)      // 22:00–02:00
        case .earlyMorning: Window(weekdays: nil, startHour: 5)    // 05:00–08:00
        case .middleOfDay: Window(weekdays: nil, startHour: 12)    // 12:00–15:00
        case .afterWork: Window(weekdays: nil, startHour: 17)      // 17:00–20:00
        case .weekends: Window(weekdays: [7, 1], startHour: 18)    // Saturday and Sunday evenings
        case .noPattern: nil
        }
    }
}

/// S6 · What's usually underneath. Display strings are `onb.s6.chips`, in this order.
enum Feeling: String, Codable, CaseIterable {
    case bored, stressed, lonely, tired, anxious, notSure
}

/// S11 · Who decides when the lock opens.
enum KeyHolder: String, Codable {
    case bedrock, partner

    var analytics: Holder { self == .bedrock ? .bedrock : .partner }
}

/// What happened at the paywall (S12 / S12U).
enum PaywallOutcome: String, Codable {
    case purchased, free, remindTomorrow, waitingForUpdate
}

/// S4's result.
enum WallTestOutcome: String, Codable {
    case held, opened, unverified, skipped
}

struct FirstLightState: Codable, Equatable {
    // Where they are
    var screen: String = ScreenID.s1.rawValue
    var history: [String] = []
    var startedAt: Date?
    var lastActiveAt: Date?

    // Branches
    var previewMode = false          // B9: Screen Time isn't available (Simulator, review)
    var restricted = false           // B2: Screen Time is managed by someone else
    var continuedWithoutWall = false // S2-D: “Continue without the wall”

    // Wall
    var wallUp = false
    var wallTest: WallTestOutcome?
    var pathPlayed = false       // S10 plays once; revisits show it lit

    // You
    var hours: [HourBand] = []
    var feelings: [Feeling] = []
    var word: String?
    var wordIsCustom = false
    var stoneSetAt: Date?

    // Lock and paywall
    var keyHolder: KeyHolder?
    var paywallOutcome: PaywallOutcome?

    // Strict Mode setup
    var letterDraft = ""
    var letterSaved = false
    var practiceDone = false
    var realRunStarted = false   // the code exists; never regenerate it on resume
    var slowDigits = false       // 5s per digit after a mismatch, or after 3 practice errors
    var codeMismatches = 0
    var lockFailures = 0
    var strictSealed = false

    // Partner (S13.2P). A pairing token from the server; no personal data.
    var inviteCode: String?
    var inviteURL: String?
    var inviteSentAt: Date?

    // Supporter (SP1–SP4)
    var supporterPaired = false

    // Ending
    var finishedLater = false
    var completed = false
    var completedAt: Date?

    // Home cards that stay dismissed
    var freeCardDismissed = false
    var headsUpCardDismissed = false

    /// Skips the Lock chapter and the paywall (no wall to lock).
    var hasNoWall: Bool { restricted || continuedWithoutWall }

    var current: ScreenID { ScreenID(rawValue: screen) ?? .s1 }
}

extension FirstLightState {
    static func load() -> FirstLightState? {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Key.firstLight) else { return nil }
        return try? JSONDecoder().decode(FirstLightState.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.firstLight)
    }

    static func clear() {
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.firstLight)
    }

    /// Whether the first-run flow has finished on this phone. Someone who finished
    /// the earlier onboarding counts as done.
    static var isComplete: Bool {
        load()?.completed ?? AppGroup.defaults.bool(forKey: AppGroup.Key.onboardingComplete)
    }
}
