import FamilyControls
import ManagedSettings

/// The single routine that turns a saved configuration into live Screen Time
/// shields. Used identically by the app (on enable) and the monitor extension
/// (re-apply on schedule), so blocking behaves the same wherever it's set.
enum ShieldApplier {
    private static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(AppGroup.Blocking.storeName))
    }

    /// Apply app/category/web shields from the opaque selection, plus the Safari
    /// adult-content filter and denylist.
    static func apply(
        selection: FamilyActivitySelection,
        safariFilterEnabled: Bool,
        denylist: [String]
    ) {
        applyWeb(safariFilterEnabled: safariFilterEnabled, denylist: denylist)
        applyApps(selection: selection)
    }

    /// The web layer: Safari's adult-content filter plus our denylist (S3 row 1).
    static func applyWeb(safariFilterEnabled: Bool, denylist: [String]) {
        // `.auto`'s first set is *blocked* (our denylist); `except` is the
        // allow-list. Verified against the ManagedSettings 26.2 interface.
        if safariFilterEnabled {
            let blocked = Set(denylist.map { WebDomain(domain: $0) })
            store.webContent.blockedByFilter = .auto(blocked, except: [])
        } else {
            store.webContent.blockedByFilter = nil
        }
    }

    /// The app layer: app, category and web-domain shields from the picker (S3 row 2).
    static func applyApps(selection: FamilyActivitySelection) {
        let store = store
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    /// Lift every shield in the Bedrock store (gauntlet release / pause).
    static func clear() {
        store.clearAllSettings()
    }

    /// True when protection should be active (the selection is non-empty) but the
    /// shields have been wiped — i.e. someone cleared the store. Used by the
    /// monitor to detect tampering before it re-applies.
    static func appearsCleared(expecting selection: FamilyActivitySelection) -> Bool {
        let hasSelection = !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
        guard hasSelection else { return false }

        let store = store
        let noApps = (store.shield.applications ?? []).isEmpty
        let noCategories = store.shield.applicationCategories == nil
        let noWeb = (store.shield.webDomains ?? []).isEmpty
        return noApps && noCategories && noWeb
    }
}
