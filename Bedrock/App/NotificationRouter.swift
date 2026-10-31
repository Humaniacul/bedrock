import Foundation
import Observation
import UserNotifications

/// Where a tapped notification should take the person (`Reminders.routeKey`):
/// “home” (a heads-up), “paywall” (decide tomorrow), “subscriptions” (trial).
@MainActor
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    /// The route from the last tap, cleared once RootView handles it.
    var pending: String?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let route = response.notification.request.content.userInfo[Reminders.routeKey] as? String
        await MainActor.run { self.pending = route ?? "home" }
    }

    /// Shown while Bedrock is open, too: the copy is discreet by design.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
