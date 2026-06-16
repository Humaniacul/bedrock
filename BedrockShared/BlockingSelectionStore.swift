import FamilyControls
import Foundation

/// Persists the blocking configuration to the App Group so the monitor extension
/// can re-apply it. We store the opaque `FamilyActivitySelection` blob — never
/// the app/site identities behind the tokens (§4).
enum BlockingSelectionStore {
    static func loadSelection() -> FamilyActivitySelection {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.selection),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    static func save(_ selection: FamilyActivitySelection) {
        let data = try? JSONEncoder().encode(selection)
        AppGroup.defaults.set(data, forKey: AppGroup.Key.selection)
    }

    /// Whether the Safari adult-content filter layer is on. Defaults to `true` —
    /// the filter is the safest baseline and costs the user nothing.
    static var safariFilterEnabled: Bool {
        get { (AppGroup.defaults.object(forKey: AppGroup.Key.safariFilterEnabled) as? Bool) ?? true }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.Key.safariFilterEnabled) }
    }

    /// Whether the user currently has protection applied (gates the monitor's
    /// re-apply so we don't fight a deliberately paused state).
    static var protectionActive: Bool {
        get { AppGroup.defaults.bool(forKey: AppGroup.Key.protectionActive) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.Key.protectionActive) }
    }

    /// Whether the Strict Mode uninstall lock (`denyAppRemoval`) is on, so the
    /// monitor re-asserts it on schedule (Strict Mode, §4).
    static var uninstallLockOn: Bool {
        get { AppGroup.defaults.bool(forKey: AppGroup.Key.uninstallLock) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.Key.uninstallLock) }
    }

    /// Custom web denylist layered on top of the system `.auto` adult filter.
    /// Phase 6 (DNS) expands and remote-updates this; here it ships a small seed.
    static var denylist: [String] {
        get { AppGroup.defaults.stringArray(forKey: AppGroup.Key.webDenylist) ?? WebDenylist.seed }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.Key.webDenylist) }
    }

    /// Tamper events the monitor extension recorded (it can't make network calls
    /// reliably); the app uploads them on its next heartbeat (§4 tamper detection).
    static func enqueueTamper(_ kind: String) {
        var queue = AppGroup.defaults.stringArray(forKey: AppGroup.Key.tamperQueue) ?? []
        queue.append(kind)
        AppGroup.defaults.set(queue, forKey: AppGroup.Key.tamperQueue)
    }

    static func drainTamper() -> [String] {
        let queue = AppGroup.defaults.stringArray(forKey: AppGroup.Key.tamperQueue) ?? []
        AppGroup.defaults.removeObject(forKey: AppGroup.Key.tamperQueue)
        return queue
    }
}

/// Seed denylist — a small reinforcement of the system `.auto` adult-content
/// filter. Intentionally short; the real protection is the `.auto` filter plus
/// the Phase 6 DNS layer.
enum WebDenylist {
    static let seed: [String] = [
        "pornhub.com",
        "xvideos.com",
        "xnxx.com",
        "xhamster.com",
        "redtube.com",
        "onlyfans.com",
    ]
}
