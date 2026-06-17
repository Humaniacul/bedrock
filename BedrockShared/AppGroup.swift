import Foundation

/// Shared constants for the App Group that lets the main app and the
/// DeviceActivityMonitor extension read/write the same blocking state and the
/// same `ManagedSettingsStore`. Compiled into both targets (§3).
///
/// Framework-free on purpose (Foundation only) so it is safe to import anywhere.
enum AppGroup {
    static let identifier = "group.com.thebedrock.app"

    /// Shared defaults. Falls back to `.standard` if the suite is unavailable
    /// (e.g. an unprovisioned Simulator build) so nothing crashes during dev.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    enum Key {
        static let selection = "blocking.selection"             // Data — encoded FamilyActivitySelection
        static let safariFilterEnabled = "blocking.safariFilter" // Bool
        static let webDenylist = "blocking.webDenylist"          // [String]
        static let protectionActive = "blocking.protectionActive" // Bool
        static let uninstallLock = "blocking.uninstallLock"      // Bool — denyAppRemoval restriction
        static let streakState = "streak.state"                  // Data — encoded StreakState
        static let strictConfig = "strict.config"                // Data — encoded StrictConfig
        static let commitmentLetter = "strict.commitmentLetter"  // String — future-self letter
        static let commitmentPassage = "strict.commitmentPassage" // [String] — passage to retype
        static let tamperQueue = "accountability.tamperQueue"    // [String] — tamper kinds awaiting upload
        static let triggerEvents = "triggers.events"             // Data — encoded [TriggerEngine.Event] (on-device only)
        static let supportContact = "support.contact"            // Data — encoded SupportContactStore.Contact (on-device only)
        static let nudgesEnabled = "triggers.nudgesEnabled"      // Bool — opt-in to local danger-window check-ins
        static let onboardingComplete = "onboarding.complete"   // Bool — first-run flow finished
        static let premiumEntitlement = "paywall.premium"       // Bool — premium active (mirrors StoreKit; §8)
    }

    /// Identifiers for the shared Screen Time objects. Kept as raw strings here
    /// (Foundation-only); the typed `ManagedSettingsStore.Name` /
    /// `DeviceActivityName` are built from these in `ShieldApplier`.
    enum Blocking {
        static let storeName = "BedrockShield"   // ManagedSettingsStore name (app + monitor share it)
        static let activityName = "bedrock.daily" // DeviceActivityName for the re-apply schedule
    }
}
