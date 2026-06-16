import ManagedSettings

/// ShieldAction extension (§3, §4). Handles taps on the shield buttons. The
/// primary button ("Open Bedrock") closes the shield so the app can take over
/// with the Intercept flow; nothing here silently lifts protection.
///
/// Phase 1/4 fill in: deep-link into the Intercept Moment on primary tap.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(response(for: action))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(response(for: action))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(response(for: action))
    }

    private func response(for action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            return .close // Phase 4: open Bedrock into the Intercept Moment.
        case .secondaryButtonPressed:
            return .defer
        @unknown default:
            return .none
        }
    }
}
