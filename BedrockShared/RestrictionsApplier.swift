import ManagedSettings

/// The Strict Mode uninstall lock (§4). `denyAppRemoval` is a device-wide
/// restriction — it blocks deleting **all** apps, not just Bedrock (Apple gives
/// no app-specific option, so this must be disclosed honestly in the UI).
///
/// Applied by the app on enable and re-asserted by the monitor extension on
/// schedule, so it survives the user clearing the store. Shares the same named
/// `ManagedSettingsStore` as the shields.
enum RestrictionsApplier {
    private static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(AppGroup.Blocking.storeName))
    }

    static func applyUninstallLock(_ enabled: Bool) {
        store.application.denyAppRemoval = enabled ? true : nil
    }
}
