import Foundation
import UIKit
import UserNotifications

/// Notification permission, asked only in context (S14, SP3, the late-night
/// “Remind me”). Either answer moves the flow on.
enum NotificationPermission {
    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the iOS request if it hasn't been answered; returns whether alerts are allowed.
    @discardableResult
    static func request() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await status() {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            // Remote too, so a supporter's requests and alerts can reach this phone.
            if granted { await MainActor.run { UIApplication.shared.registerForRemoteNotifications() } }
            return granted
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
}

/// The local notifications the onboarding promises. Everything is scheduled on
/// the phone; nothing on them says what Bedrock is for (SPEC.md rules).
enum Reminders {
    enum Kind: String {
        case headsUp = "bedrock.headsup."
        case decideTomorrow = "bedrock.decide-tomorrow"
        case trialEnding = "bedrock.trial-ending"
    }

    /// What a notification tap should open.
    static let routeKey = "bedrock.route"

    // MARK: Heads-ups (S5 → S14)

    /// Weekly-repeating heads-ups 15 minutes before each hard-hour window.
    static func scheduleHeadsUps(for bands: [HourBand]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Kind.headsUp.rawValue) })

        for band in bands {
            guard let window = band.window else { continue }
            let (hour, minute) = minutesBefore(window.startHour, 15)
            for weekday in window.weekdays.map({ $0.map(Optional.some) }) ?? [nil] {
                var components = DateComponents(hour: hour, minute: minute)
                components.weekday = weekday
                let content = UNMutableNotificationContent()
                content.body = OnbCopy.string("onb.reminder.heads_up")
                content.sound = .default
                content.userInfo = [routeKey: "home"]
                let id = Kind.headsUp.rawValue + band.rawValue + (weekday.map { ".\($0)" } ?? "")
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    /// The next heads-up for the Home card (“Tonight at 9:45 PM”), if any.
    static func nextHeadsUp(for bands: [HourBand], after now: Date = .now, calendar: Calendar = .current) -> Date? {
        bands.compactMap { band -> Date? in
            guard let window = band.window else { return nil }
            let (hour, minute) = minutesBefore(window.startHour, 15)
            return (window.weekdays.map({ $0.map(Optional.some) }) ?? [nil]).compactMap { weekday -> Date? in
                var components = DateComponents(hour: hour, minute: minute)
                components.weekday = weekday
                return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
            }.min()
        }.min()
    }

    // MARK: Decide tomorrow (S12 late night)

    /// 12:00 the next day; opens the paywall.
    static func scheduleDecideTomorrow(now: Date = .now, calendar: Calendar = .current) async {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 12
        let content = UNMutableNotificationContent()
        content.body = OnbCopy.string("onb.s12.headline")
        content.sound = .default
        content.userInfo = [routeKey: "paywall"]
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: Kind.decideTomorrow.rawValue, content: content, trigger: trigger))
    }

    // MARK: Trial reminder (S12 timeline: “In 2 days · We send a reminder”)

    static func scheduleTrialReminder(trialDays: Int, from start: Date = .now) async {
        let delay = TimeInterval(max(trialDays - 1, 1)) * 24 * 3600
        let parts = OnbCopy.parts("onb.home.card_trial")
        let content = UNMutableNotificationContent()
        content.title = parts.first ?? ""
        content.body = parts.dropFirst().first ?? ""
        content.sound = .default
        content.userInfo = [routeKey: "subscriptions"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: Kind.trialEnding.rawValue, content: content, trigger: trigger))
    }

    private static func minutesBefore(_ hour: Int, _ minutes: Int) -> (Int, Int) {
        let total = (hour * 60 - minutes + 24 * 60) % (24 * 60)
        return (total / 60, total % 60)
    }
}
