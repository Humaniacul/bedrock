import Foundation
import Observation
import UIKit
import UserNotifications

/// Where a tapped notification should take the person (`Reminders.routeKey`):
/// “home” (a heads-up), “paywall” (decide tomorrow), “subscriptions” (trial).
@MainActor
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    /// The route from the last tap, cleared once RootView handles it.
    var pending: String?
    /// The APNs token (hex) once iOS hands it over; RootView sends it to the server.
    var deviceToken: String?

    func install() {
        UNUserNotificationCenter.current().delegate = self
        // Already allowed (an earlier S14 / SP3): refresh the push token.
        Task {
            if await NotificationPermission.status() == .authorized {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
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

/// Receives the APNs device token (SwiftUI has no hook for it).
final class BedrockAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in NotificationRouter.shared.deviceToken = hex }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}
