import Foundation

/// v1 identity (see backend lib/auth.ts): a stable device id kept in the
/// Keychain, plus the server-issued bearer token. Sign in with Apple / Supabase
/// Auth is the documented production upgrade.
enum DeviceIdentity {
    private enum Account {
        static let deviceId = "com.thebedrock.app.deviceId"
        static let token = "com.thebedrock.app.apiToken"
    }

    static var deviceId: String {
        if let existing = Keychain.get(Account.deviceId) { return existing }
        let new = UUID().uuidString
        Keychain.set(new, for: Account.deviceId)
        return new
    }

    static var token: String? {
        get { Keychain.get(Account.token) }
        set {
            if let value = newValue { Keychain.set(value, for: Account.token) }
            else { Keychain.delete(Account.token) }
        }
    }
}
