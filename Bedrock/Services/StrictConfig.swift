import Foundation

/// Which passcode model guards Strict Mode (§4).
enum PasscodeModel: String, Codable, Equatable {
    case none
    case partnerHeld // Model A — partner sets & holds the Screen Time passcode
    case appHeld     // Model B — app generates it; user enters it blind via Settings
}

/// The "sleep on it" structural lock (§4 P1): disables only process inside a
/// pre-committed daytime window, so impulse-hour bypass is structurally
/// impossible.
struct SleepWindow: Codable, Equatable {
    var enabled: Bool
    var startHour: Int // disables allowed within [startHour, endHour)
    var endHour: Int

    static let `default` = SleepWindow(enabled: false, startHour: 9, endHour: 21)

    func isOpen(at date: Date, calendar: Calendar = .current) -> Bool {
        guard enabled else { return true }
        let hour = calendar.component(.hour, from: date)
        if startHour <= endHour { return hour >= startHour && hour < endHour }
        return hour >= startHour || hour < endHour // window wraps midnight
    }
}

/// Persisted Strict Mode configuration + escalation state.
struct StrictConfig: Codable, Equatable {
    var enabled: Bool
    var passcodeModel: PasscodeModel
    var baseCooldownMinutes: Int
    var sleepWindow: SleepWindow
    /// Number of completed disables — drives escalating friction (§4).
    var disableCount: Int

    static let `default` = StrictConfig(
        enabled: false,
        passcodeModel: .none,
        baseCooldownMinutes: 30,
        sleepWindow: .default,
        disableCount: 0
    )

    /// Each completed disable lengthens the next cooldown, capped at 120 min (§4).
    var effectiveCooldownMinutes: Int { min(baseCooldownMinutes + disableCount * 15, 120) }

    /// …and lengthens the passage that must be hand-typed.
    var requiredCommitmentSentences: Int { min(1 + disableCount, 4) }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.strictConfig)
    }

    static func load() -> StrictConfig {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.strictConfig),
            let config = try? JSONDecoder().decode(StrictConfig.self, from: data)
        else { return .default }
        return config
    }
}
