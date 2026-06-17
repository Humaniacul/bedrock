import Foundation
import Observation
import RevenueCat

/// Entitlement / monetization (§3, §8). Subscriptions run through **RevenueCat**
/// (StoreKit 2 under the hood). Prices and tiers come live from the current
/// RevenueCat offering — the dashboard is the source of truth, not hardcoded
/// strings — and entitlement state syncs server-side via RevenueCat webhooks →
/// Supabase (see backend `/api/webhooks/revenuecat`).
///
/// `appUserID` is set to the device id so the webhook can map a RevenueCat
/// `app_user_id` back to our Supabase user (`users.device_id`).
///
/// With no API key configured the service runs in a local fallback (free, with
/// a DEBUG-only grant so the gated experience stays testable); release builds
/// never fake-unlock.
@MainActor
@Observable
final class PaywallService {
    /// RevenueCat entitlement identifier — create an entitlement named this in
    /// the RevenueCat dashboard and attach the products to it.
    static let entitlementID = "premium"

    enum Entitlement: Equatable { case free, premium }

    /// A purchasable tier, display-ready. `package == nil` means fallback/dev.
    struct Plan: Identifiable, Equatable {
        let id: String
        let title: String
        let price: String
        let unit: String        // "/year", "/week", "" for lifetime
        let caption: String
        let badge: String?
        let perWeek: String?
        let trialText: String?  // e.g. "3 days free" — nil if no intro trial
        let isLifetime: Bool
        let rank: Int           // display order; annual first
        let package: Package?

        var hasTrial: Bool { trialText != nil }

        static func == (lhs: Plan, rhs: Plan) -> Bool { lhs.id == rhs.id }
    }

    private(set) var entitlement: Entitlement
    private(set) var plans: [Plan]
    private(set) var isPurchasing = false
    private(set) var isConfigured = false
    var isPremium: Bool { entitlement == .premium }

    private var streamTask: Task<Void, Never>?

    init() {
        entitlement = AppGroup.defaults.bool(forKey: AppGroup.Key.premiumEntitlement) ? .premium : .free
        plans = Self.fallbackPlans
    }

    // MARK: - Configure

    /// Configure RevenueCat once, tagging the user with their device id so the
    /// webhook can reconcile entitlement into Supabase. No key → local fallback.
    func configure(appUserID: String) {
        guard !isConfigured, let key = Self.apiKey else { return }
        if Purchases.isConfigured {
            // Process already configured (e.g. after an account wipe rebuilt the
            // service graph) — switch the RevenueCat user instead of reconfiguring.
            Task { _ = try? await Purchases.shared.logIn(appUserID) }
        } else {
            Purchases.logLevel = .warn
            Purchases.configure(withAPIKey: key, appUserID: appUserID)
        }
        isConfigured = true
        observeCustomerInfo()
        Task {
            await loadOfferings()
            await refresh()
        }
    }

    func refresh() async {
        guard isConfigured else { return }
        if let info = try? await Purchases.shared.customerInfo() { apply(info) }
    }

    private func loadOfferings() async {
        guard isConfigured,
              let offering = try? await Purchases.shared.offerings().current,
              !offering.availablePackages.isEmpty
        else { return }
        plans = offering.availablePackages
            .map(Self.plan(from:))
            .sorted { $0.rank < $1.rank }
    }

    // MARK: - Purchase / restore

    @discardableResult
    func purchase(_ plan: Plan) async -> Bool {
        guard !isPurchasing else { return isPremium }
        isPurchasing = true
        defer { isPurchasing = false }

        if let package = plan.package, isConfigured {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                if result.userCancelled { return false }
                apply(result.customerInfo)
                return isPremium
            } catch {
                return false
            }
        }
        return await devGrant()
    }

    @discardableResult
    func restore() async -> Bool {
        guard isConfigured else { return isPremium }
        if let info = try? await Purchases.shared.restorePurchases() { apply(info) }
        return isPremium
    }

    // MARK: - Entitlement state

    private func observeCustomerInfo() {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
    }

    private func apply(_ info: CustomerInfo) {
        grant(info.entitlements[Self.entitlementID]?.isActive == true ? .premium : .free)
    }

    private func grant(_ entitlement: Entitlement) {
        self.entitlement = entitlement
        AppGroup.defaults.set(entitlement == .premium, forKey: AppGroup.Key.premiumEntitlement)
    }

    private func devGrant() async -> Bool {
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(650))
        grant(.premium)
        return true
        #else
        return false // no RevenueCat key + release build → honest no-op
        #endif
    }

    // MARK: - Config

    private static var apiKey: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Package → Plan mapping

    private static func plan(from package: Package) -> Plan {
        let product = package.storeProduct
        let type = package.packageType
        let isLifetime = type == .lifetime
        let trial = trialLabel(product)
        let unit = unitLabel(type)
        let price = product.localizedPriceString

        let caption: String
        if let trial {
            caption = "\(trial), then \(price)\(unit)"
        } else if isLifetime {
            caption = "One-time purchase"
        } else {
            caption = "\(price)\(unit)"
        }

        return Plan(
            id: package.identifier,
            title: title(for: type, product: product),
            price: price,
            unit: unit,
            caption: caption,
            badge: badge(for: type),
            perWeek: perWeekString(for: type, product: product),
            trialText: trial,
            isLifetime: isLifetime,
            rank: rank(for: type),
            package: package
        )
    }

    private static func title(for type: PackageType, product: StoreProduct) -> String {
        switch type {
        case .annual:   "Annual"
        case .monthly:  "Monthly"
        case .weekly:   "Weekly"
        case .lifetime: "Lifetime"
        default:        product.localizedTitle
        }
    }

    private static func unitLabel(_ type: PackageType) -> String {
        switch type {
        case .annual:  "/year"
        case .monthly: "/month"
        case .weekly:  "/week"
        default:       ""
        }
    }

    private static func badge(for type: PackageType) -> String? {
        switch type {
        case .annual:   "BEST VALUE"
        case .lifetime: "ALL-IN"
        default:        nil
        }
    }

    private static func rank(for type: PackageType) -> Int {
        switch type {
        case .annual:   0
        case .weekly:   1
        case .lifetime: 2
        case .monthly:  3
        default:        4
        }
    }

    private static func trialLabel(_ product: StoreProduct) -> String? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        let unit: String
        switch period.unit {
        case .day:   unit = "day"
        case .week:  unit = "week"
        case .month: unit = "month"
        case .year:  unit = "year"
        @unknown default: unit = "day"
        }
        return "\(period.value) \(unit)\(period.value == 1 ? "" : "s") free"
    }

    /// "~$1.34/week" for an annual plan, using the product's own price formatter.
    private static func perWeekString(for type: PackageType, product: StoreProduct) -> String? {
        guard type == .annual, let formatter = product.priceFormatter else { return nil }
        let weekly = product.price / 52
        guard let s = formatter.string(from: weekly as NSDecimalNumber) else { return nil }
        return "just ~\(s)/week"
    }

    // MARK: - Fallback (no RevenueCat key; matches the §8 ladder for display)

    static let fallbackPlans: [Plan] = [
        Plan(id: "annual", title: "Annual", price: "$69.99", unit: "/year",
             caption: "3 days free, then $69.99/year", badge: "BEST VALUE",
             perWeek: "just ~$1.34/week", trialText: "3 days free", isLifetime: false, rank: 0, package: nil),
        Plan(id: "weekly", title: "Weekly", price: "$5.99", unit: "/week",
             caption: "$5.99/week, billed weekly", badge: nil,
             perWeek: nil, trialText: nil, isLifetime: false, rank: 1, package: nil),
        Plan(id: "lifetime", title: "Lifetime", price: "$149", unit: "",
             caption: "One-time purchase", badge: "ALL-IN",
             perWeek: nil, trialText: nil, isLifetime: true, rank: 2, package: nil),
    ]

    #if DEBUG
    func debugSetPremium(_ on: Bool) { grant(on ? .premium : .free) }
    #endif
}
