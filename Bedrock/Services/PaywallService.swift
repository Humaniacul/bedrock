import Foundation
import Observation
import RevenueCat

/// Entitlement / monetization (§3, §8). Subscriptions run through **RevenueCat**
/// (StoreKit 2 under the hood). Prices, the per-month figure and trial
/// eligibility come live from StoreKit through the current RevenueCat offering
/// (“default”) — never hard-coded (SPEC.md S12). Entitlement state syncs
/// server-side via RevenueCat webhooks → Supabase.
///
/// `appUserID` is the device id so the webhook can map a RevenueCat
/// `app_user_id` back to our Supabase user (`users.device_id`).
///
/// With no API key, or no products available, release builds show S12's honest
/// “can't reach the App Store” state. DEBUG builds fill in the spec's example
/// prices so the screens can be walked in the Simulator; release never does.
@MainActor
@Observable
final class PaywallService {
    /// RevenueCat entitlement identifier (the dashboard entitlement is "pro").
    static let entitlementID = "pro"

    enum Entitlement: Equatable { case free, premium }

    /// The three ways to buy Strict Mode (S12): two cards and “Other plans”.
    enum StrictPlan: String, CaseIterable {
        case yearly, lifetime, weekly

        var analytics: Plan {
            switch self {
            case .yearly: .yearly
            case .lifetime: .lifetime
            case .weekly: .weekly
            }
        }
    }

    /// One plan, ready to display. Strings are StoreKit's own localized prices.
    struct StrictOffer {
        let plan: StrictPlan
        let price: String
        /// Yearly only: the local price ÷ 12, formatted by the product's own formatter.
        let monthly: String?
        /// Only when StoreKit says this Apple Account is eligible for the intro offer.
        let trialDays: Int?
        fileprivate let package: Package?
    }

    enum OffersState: Equatable { case loading, ready, unavailable }

    enum PurchaseOutcome: Equatable {
        case success(trialDays: Int?)
        case cancelled
        case pending
        case failed
    }

    enum RestoreOutcome { case found, none, failed }

    private(set) var entitlement: Entitlement
    private(set) var offers: [StrictPlan: StrictOffer] = [:]
    private(set) var offersState: OffersState = .loading
    private(set) var isPurchasing = false
    private(set) var isConfigured = false
    /// When the current entitlement is a free trial, when it ends (Home's trial card).
    private(set) var trialEndsAt: Date?
    var isPremium: Bool { entitlement == .premium }

    private var streamTask: Task<Void, Never>?

    init() {
        entitlement = AppGroup.defaults.bool(forKey: AppGroup.Key.premiumEntitlement) ? .premium : .free
    }

    // MARK: - Configure

    /// Configure RevenueCat once, tagging the user with their device id so the
    /// webhook can reconcile entitlement into Supabase. No key → no store.
    func configure(appUserID: String) {
        guard !isConfigured, let key = Self.apiKey else {
            if Self.apiKey == nil { applyFallbackOffers() }
            return
        }
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
            await loadOffers()
            await refresh()
        }
    }

    func refresh() async {
        guard isConfigured else { return }
        if let info = try? await Purchases.shared.customerInfo() { apply(info) }
    }

    /// Fetch the current offering and this account's trial eligibility (S12).
    func loadOffers() async {
        guard isConfigured else { applyFallbackOffers(); return }
        if offers.isEmpty { offersState = .loading }
        guard let offering = try? await Purchases.shared.offerings().current,
              !offering.availablePackages.isEmpty
        else {
            applyFallbackOffers()
            return
        }

        let packages = offering.availablePackages
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: packages)

        var built: [StrictPlan: StrictOffer] = [:]
        for package in packages {
            guard let plan = Self.plan(for: package.packageType) else { continue }
            let product = package.storeProduct
            let eligible = eligibility[package]?.status == .eligible
            built[plan] = StrictOffer(
                plan: plan,
                price: product.localizedPriceString,
                monthly: plan == .yearly ? product.localizedPricePerMonth : nil,
                trialDays: eligible ? Self.trialDays(product) : nil,
                package: package)
        }
        offers = built
        offersState = built[.yearly] != nil || built[.lifetime] != nil ? .ready : .unavailable
    }

    // MARK: - Purchase / restore

    func buy(_ plan: StrictPlan) async -> PurchaseOutcome {
        guard !isPurchasing, let offer = offers[plan] else { return .failed }
        isPurchasing = true
        defer { isPurchasing = false }

        guard let package = offer.package, isConfigured else {
            return await devGrant(trialDays: offer.trialDays)
        }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            apply(result.customerInfo)
            return isPremium ? .success(trialDays: offer.trialDays) : .failed
        } catch let error as ErrorCode where error == .paymentPendingError {
            return .pending
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            return .cancelled
        } catch {
            return .failed
        }
    }

    func restorePurchases() async -> RestoreOutcome {
        guard isConfigured else { return isPremium ? .found : .failed }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            return isPremium ? .found : .none
        } catch {
            return .failed
        }
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
        let pro = info.entitlements[Self.entitlementID]
        grant(pro?.isActive == true ? .premium : .free)
        trialEndsAt = (pro?.isActive == true && pro?.periodType == .trial) ? pro?.expirationDate : nil
    }

    private func grant(_ entitlement: Entitlement) {
        self.entitlement = entitlement
        AppGroup.defaults.set(entitlement == .premium, forKey: AppGroup.Key.premiumEntitlement)
    }

    private func devGrant(trialDays: Int?) async -> PurchaseOutcome {
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(650))
        grant(.premium)
        return .success(trialDays: trialDays)
        #else
        return .failed // no store in a release build → honest failure, free wall stays
        #endif
    }

    // MARK: - Config

    private static var apiKey: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func plan(for type: PackageType) -> StrictPlan? {
        switch type {
        case .annual: .yearly
        case .lifetime: .lifetime
        case .weekly: .weekly
        default: nil
        }
    }

    private static func trialDays(_ product: StoreProduct) -> Int? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return nil
        }
    }

    /// No store available. Release: S12 says it can't reach the App Store. DEBUG:
    /// the spec's example prices, so every screen can be walked in the Simulator.
    private func applyFallbackOffers() {
        #if DEBUG
        offers = [
            .yearly: StrictOffer(plan: .yearly, price: "$69.99", monthly: "$5.83", trialDays: 3, package: nil),
            .lifetime: StrictOffer(plan: .lifetime, price: "$149", monthly: nil, trialDays: nil, package: nil),
            .weekly: StrictOffer(plan: .weekly, price: "$5.99", monthly: nil, trialDays: nil, package: nil),
        ]
        offersState = .ready
        #else
        offers = [:]
        offersState = .unavailable
        #endif
    }

    #if DEBUG
    func debugSetPremium(_ on: Bool) { grant(on ? .premium : .free) }
    #endif
}
