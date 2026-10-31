import Foundation
import PostHog

/// The app's one analytics entry point (wraps `OnboardingAnalytics`).
/// Configured only when Info.plist carries a PostHog project key
/// (`POSTHOG_API_KEY`); with none, every call is a no-op and nothing leaves the
/// phone.
@MainActor
enum Analytics {
    private(set) static var isConfigured = false

    static func configureIfPossible() {
        guard !isConfigured,
              let raw = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String
        else { return }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        OnboardingAnalytics.configure(apiKey: key)
        isConfigured = true
    }

    static func track(_ event: OnboardingEvent, screen: ScreenID, startedAt: Date?) {
        guard isConfigured else { return }
        let context = OnboardingContext(
            screen: screen,
            startedAt: startedAt ?? .now,
            iosMajor: ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
            strictSupported: RemoteConfig.strictModeSupported)
        OnboardingAnalytics.track(event, context: context)
    }
}

/// Shield taps are counted by the shield extension (it can't send analytics)
/// and sent here the next time Bedrock opens, then reset.
@MainActor
enum ShieldStats {
    static func flush() {
        let defaults = AppGroup.defaults
        let closes = defaults.integer(forKey: AppGroup.Key.shieldCloses)
        let minutes = defaults.integer(forKey: AppGroup.Key.shieldMinutes)
        guard closes + minutes > 0 else { return }
        defaults.set(0, forKey: AppGroup.Key.shieldCloses)
        defaults.set(0, forKey: AppGroup.Key.shieldMinutes)
        let startedAt = FirstLightState.load()?.startedAt
        for _ in 0..<min(closes, 50) { Analytics.track(.shieldAction(.close), screen: .home, startedAt: startedAt) }
        for _ in 0..<min(minutes, 50) { Analytics.track(.shieldAction(.needMinute), screen: .home, startedAt: startedAt) }
    }
}

/// Values the product changes without an app update. Read from PostHog feature
/// flags when analytics is configured; otherwise the defaults below apply.
@MainActor
enum RemoteConfig {
    /// Strict Mode is sold only on iOS versions where the lock test passes
    /// (OPEN_QUESTIONS #4). Default: iOS 26.4 or later, the project's security
    /// floor. Flag: `strict_mode_supported`.
    static var strictModeSupported: Bool {
        #if DEBUG
        if let forced = ProcessInfo.processInfo.environment["BEDROCK_STRICT_SUPPORTED"] { return forced == "1" }
        #endif
        if let flag = bool("strict_mode_supported") { return flag }
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 26, minorVersion: 4, patchVersion: 0))
    }

    /// The floating digit window over Settings uses Picture in Picture; when off,
    /// blind entry switches apps instead (OPEN_QUESTIONS #2). Flag: `blind_entry_pip`.
    static var blindEntryUsesPictureInPicture: Bool {
        #if DEBUG
        if let forced = ProcessInfo.processInfo.environment["BEDROCK_BLIND_ENTRY_PIP"] { return forced == "1" }
        #endif
        return bool("blind_entry_pip") ?? true
    }

    private static func bool(_ key: String) -> Bool? {
        guard Analytics.isConfigured else { return nil }
        switch PostHogSDK.shared.getFeatureFlag(key, sendFeatureFlagEvent: false) {
        case let value as Bool: return value
        case let value as String: return value == "true" || value == "on"
        default: return nil
        }
    }
}
