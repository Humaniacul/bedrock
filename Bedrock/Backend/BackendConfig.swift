import Foundation

/// Where the Bedrock API lives (§3). Set `BEDROCK_API_BASE_URL` in Info.plist
/// (or via a gitignored Secrets.xcconfig) to point at your Railway deployment.
/// When empty, the app runs in **stub mode** — no backend, accountability
/// features show an honest "not connected" state and everything else works.
enum BackendConfig {
    static var baseURL: URL? {
        #if DEBUG
        if let env = ProcessInfo.processInfo.environment["BEDROCK_API_BASE_URL"],
           let url = URL(string: env), !env.isEmpty {
            return url
        }
        #endif
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "BEDROCK_API_BASE_URL") as? String,
            !value.isEmpty,
            let url = URL(string: value)
        else { return nil }
        return url
    }

    static var isConfigured: Bool { baseURL != nil }
}
