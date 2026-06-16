import DeviceActivity

/// DeviceActivityMonitor extension (§3, §4 Blocking core). The OS wakes this on
/// the daily schedule started by `LiveBlockingService`. It re-applies the saved
/// shields from the App Group so protection survives the user clearing the
/// ManagedSettings store. Phase 2 adds tamper detection on the same hooks.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        reapplyShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Re-assert around the day boundary so there's no unshielded gap.
        reapplyShields()
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        // Phase 2/4: feed the TriggerEngine; tighten protection proactively.
    }

    private func reapplyShields() {
        // Re-assert the Strict Mode uninstall lock independently of the shields
        // (it can be on even when protection is briefly paused).
        RestrictionsApplier.applyUninstallLock(BlockingSelectionStore.uninstallLockOn)

        guard BlockingSelectionStore.protectionActive else { return }
        let selection = BlockingSelectionStore.loadSelection()

        // Tamper detection (§4): if protection should be on but the shields were
        // wiped, queue an event for the app to report to the partner.
        if ShieldApplier.appearsCleared(expecting: selection) {
            BlockingSelectionStore.enqueueTamper("shield_cleared")
        }

        ShieldApplier.apply(
            selection: selection,
            safariFilterEnabled: BlockingSelectionStore.safariFilterEnabled,
            denylist: BlockingSelectionStore.denylist
        )
    }
}
