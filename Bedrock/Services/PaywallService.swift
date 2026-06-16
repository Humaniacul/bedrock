import Observation

/// Entitlement / monetization state (§8). Live implementation uses StoreKit 2 via
/// RevenueCat; basic protection stays free forever, premium unlocks Strict Mode,
/// AI, accountability, and the program.
///
/// Phase 5 wires RevenueCat (offerings, purchase, restore) and the paywall;
/// Phase 0 defaults to free with the premium gate closed.
@MainActor
@Observable
final class PaywallService {
    enum Entitlement: Equatable {
        case free
        case premium
    }

    private(set) var entitlement: Entitlement = .free
    var isPremium: Bool { entitlement == .premium }

    func refresh() async {
        // Phase 5: read RevenueCat customer info / entitlements.
    }
}
