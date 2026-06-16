import Observation

/// Holds the Screen Time passcode for Strict Mode (§4). iOS gives no API to set
/// the Screen Time passcode, so this vault only *generates and stores* the code
/// (Model B) — the user enters it into Settings via the guided blind-entry flow,
/// and the gauntlet reveals it again on release. Model A stores nothing (the
/// partner sets and holds the code).
@MainActor
protocol PasscodeVault: AnyObject {
    /// Whether an app-generated code is stored (Model B).
    var hasStoredCode: Bool { get }

    /// Generate a new random 4-digit code, store it, and return it for the
    /// blind-entry flow.
    @discardableResult
    func generateCode() -> String

    /// The stored code — revealed during blind-entry setup and on gauntlet
    /// release so the user can change/remove the passcode in Settings.
    func storedCode() -> String?

    func clearCode()
}

/// Live vault — stores the code in the Keychain (`WhenUnlockedThisDeviceOnly`).
@MainActor
@Observable
final class KeychainPasscodeVault: PasscodeVault {
    var hasStoredCode: Bool { storedCode() != nil }

    @discardableResult
    func generateCode() -> String {
        let code = String(format: "%04d", Int.random(in: 0...9999))
        Keychain.set(code, for: Keychain.Account.screenTimePasscode)
        return code
    }

    func storedCode() -> String? {
        Keychain.get(Keychain.Account.screenTimePasscode)
    }

    func clearCode() {
        Keychain.delete(Keychain.Account.screenTimePasscode)
    }
}

/// Preview stub — in-memory, no Keychain.
@MainActor
@Observable
final class StubPasscodeVault: PasscodeVault {
    private var code: String?
    var hasStoredCode: Bool { code != nil }

    @discardableResult
    func generateCode() -> String {
        let new = String(format: "%04d", Int.random(in: 0...9999))
        code = new
        return new
    }

    func storedCode() -> String? { code }
    func clearCode() { code = nil }
}
