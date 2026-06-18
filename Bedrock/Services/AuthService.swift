import Foundation
import Observation
import AuthenticationServices
import RevenueCat

/// Sign in with Apple (§3 identity upgrade). Optional and placed *after* the
/// paywall: the entitlement is tied to the account via RevenueCat `logIn`, and
/// the Apple identity is linked to the Supabase user so the entitlement webhook
/// keeps mirroring and accountability can follow the account later. Skippable —
/// a user can keep going on the anonymous device identity.
@MainActor
@Observable
final class AuthService {
    private(set) var appleUserID: String?
    private(set) var displayName: String?
    private(set) var email: String?

    var isSignedIn: Bool { appleUserID != nil }

    private let api: APIClient?
    private static let keychainAccount = "com.thebedrock.app.appleUserID"

    init(api: APIClient?) {
        self.api = api
        appleUserID = Keychain.get(Self.keychainAccount)
        displayName = AppGroup.defaults.string(forKey: AppGroup.Key.authDisplayName)
        email = AppGroup.defaults.string(forKey: AppGroup.Key.authEmail)
    }

    /// Scopes to request on the Sign in with Apple button.
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    /// Handle a completed Sign in with Apple authorization. Returns whether the
    /// sign-in itself succeeded (backend linking is best-effort and never blocks).
    @discardableResult
    func handle(_ result: Result<ASAuthorization, Error>) async -> Bool {
        guard
            case let .success(authorization) = result,
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let identityToken = String(data: tokenData, encoding: .utf8)
        else { return false }

        appleUserID = credential.user
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        if !name.isEmpty { displayName = name }
        if let credentialEmail = credential.email { email = credentialEmail }
        persist()

        // Tie the entitlement to the account so it restores on any device.
        if Purchases.isConfigured {
            _ = try? await Purchases.shared.logIn(credential.user)
        }

        // Link the Apple identity to our Supabase user (best-effort).
        if let api {
            try? await api.ensureRegistered(displayName: displayName)
            try? await api.linkApple(identityToken: identityToken, displayName: displayName)
        }
        return true
    }

    func signOut() async {
        appleUserID = nil
        displayName = nil
        email = nil
        Keychain.delete(Self.keychainAccount)
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.authDisplayName)
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.authEmail)
        if Purchases.isConfigured { _ = try? await Purchases.shared.logOut() }
    }

    private func persist() {
        if let appleUserID { Keychain.set(appleUserID, for: Self.keychainAccount) }
        if let displayName { AppGroup.defaults.set(displayName, forKey: AppGroup.Key.authDisplayName) }
        if let email { AppGroup.defaults.set(email, forKey: AppGroup.Key.authEmail) }
    }
}
