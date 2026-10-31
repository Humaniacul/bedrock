import Foundation
import ManagedSettings
import UserNotifications

/// Taps on the shield's buttons. Close shuts the shield; “I need a minute”
/// sends a quiet local notification that opens Bedrock's urge flow (an
/// extension can't open the app itself). Both are counted on the device and
/// sent as `shield_action` the next time Bedrock opens. Nothing here ever lifts
/// protection.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    private func respond(to action: ShieldAction, _ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            count(AppGroup.Key.shieldCloses)
            completionHandler(.close)
        case .secondaryButtonPressed:
            count(AppGroup.Key.shieldMinutes)
            // Answer once the notification is queued (the extension may end after).
            nonisolated(unsafe) let finish = completionHandler
            sendMinuteNotification { finish(.close) }
        default:
            completionHandler(.none)
        }
    }

    private func count(_ key: String) {
        let defaults = AppGroup.defaults
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    /// “Take a minute. · Tap to breathe it through.” Opens the urge flow.
    private func sendMinuteNotification(then done: @escaping @Sendable () -> Void) {
        let parts = Bundle.main.localizedString(forKey: "onb.shield.minute_notification", value: nil, table: nil)
            .components(separatedBy: " · ")
        let content = UNMutableNotificationContent()
        content.title = parts.first ?? ""
        content.body = parts.count > 1 ? parts[1] : ""
        content.userInfo = ["bedrock.route": "intercept"]
        let request = UNNotificationRequest(identifier: "bedrock.minute", content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request) { _ in done() }
    }
}
