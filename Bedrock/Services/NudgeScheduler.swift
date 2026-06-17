import Foundation
import Observation
import UserNotifications

/// Schedules on-device, supportive check-in notifications around the user's
/// danger windows (§4 proactive intervention, §10.6). Everything is local —
/// no server, no push token, nothing leaves the phone. Always supportive-framed
/// ("a steadier minute?"), never "caught". Opt-in only.
@MainActor
@Observable
final class NudgeScheduler {
    private static let idPrefix = "bedrock.nudge."
    private let center: UNUserNotificationCenter?

    /// Whether the user has opted in to local check-ins.
    private(set) var isEnabled: Bool

    /// `center: nil` for previews/stubs — no notification machinery touched.
    init(useNotificationCenter: Bool = true) {
        center = useNotificationCenter ? .current() : nil
        isEnabled = AppGroup.defaults.bool(forKey: AppGroup.Key.nudgesEnabled)
    }

    /// Turn check-ins on (requesting permission) or off. Returns the resulting
    /// enabled state — `false` if the user declined the system prompt.
    @discardableResult
    func setEnabled(_ on: Bool, windows: [TriggerEngine.DangerWindow]) async -> Bool {
        guard let center else { return false }
        if on {
            guard await requestAuthorizationIfNeeded() else {
                persist(false)
                return false
            }
            persist(true)
            await reschedule(for: windows)
        } else {
            persist(false)
            center.removeAllPendingNotificationRequests()
        }
        return isEnabled
    }

    /// Re-aim the scheduled nudges at the current top windows. No-op unless the
    /// user has opted in. Safe to call after every logged urge.
    func refreshIfEnabled(windows: [TriggerEngine.DangerWindow]) async {
        guard isEnabled else { return }
        await reschedule(for: windows)
    }

    // MARK: - Internals

    private func requestAuthorizationIfNeeded() async -> Bool {
        guard let center else { return false }
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    /// Weekly-repeating local notifications at the start of each top window.
    private func reschedule(for windows: [TriggerEngine.DangerWindow]) async {
        guard let center else { return }
        let existing = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: existing.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        )

        for window in windows.prefix(3) {
            var components = DateComponents()
            components.weekday = window.weekday
            components.hour = window.block * 3
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "A steadier minute?"
            content.body = "This is usually a tougher stretch for you. Want to breathe through it before it builds?"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: Self.idPrefix + window.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func persist(_ on: Bool) {
        isEnabled = on
        AppGroup.defaults.set(on, forKey: AppGroup.Key.nudgesEnabled)
    }
}
