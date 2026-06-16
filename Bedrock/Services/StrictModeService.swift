import Foundation
import Observation

/// Configures Strict Mode and runs the disable gauntlet (§4).
///
/// Ethics guardrail (§9): the gauntlet ALWAYS eventually releases — there is no
/// inescapable state. For Model B the code is revealed after the cooldown; for
/// Model A the partner approves. Strict Mode never traps a user in crisis.
@MainActor
@Observable
final class StrictModeService {
    private(set) var config: StrictConfig
    private(set) var isUninstallLockOn: Bool

    var isEnabled: Bool { config.enabled }

    init() {
        config = StrictConfig.load()
        isUninstallLockOn = BlockingSelectionStore.uninstallLockOn
    }

    // MARK: Configuration

    func enable(model: PasscodeModel) {
        config.enabled = true
        config.passcodeModel = model
        persist()
        setUninstallLock(true)
    }

    func updateConfig(_ transform: (inout StrictConfig) -> Void) {
        transform(&config)
        persist()
    }

    func setUninstallLock(_ on: Bool) {
        isUninstallLockOn = on
        BlockingSelectionStore.uninstallLockOn = on
        #if !targetEnvironment(simulator)
        RestrictionsApplier.applyUninstallLock(on)
        #endif
    }

    /// Can a disable even begin right now? (Sleep-on-it window, §4 P1.)
    func canBeginDisable(now: Date = .now) -> Bool {
        config.sleepWindow.isOpen(at: now)
    }

    // MARK: The gauntlet

    /// Build a fresh gauntlet sized to the current escalation + partner state.
    func makeGauntlet(hasPartner: Bool) -> GauntletCoordinator {
        GauntletCoordinator(
            hasPartner: hasPartner,
            cooldownSeconds: cooldownSeconds,
            requiredSentences: config.requiredCommitmentSentences
        )
    }

    /// Called when the gauntlet completes — escalate friction and lift the lock.
    func completeDisable() {
        config.disableCount += 1
        config.enabled = false
        persist()
        setUninstallLock(false)
    }

    private var cooldownSeconds: Int {
        #if DEBUG
        // Fast cooldown for testing the flow without watching a 30-minute clock.
        if ProcessInfo.processInfo.environment["BEDROCK_FAST_COOLDOWN"] == "1" {
            return 8
        }
        #endif
        return config.effectiveCooldownMinutes * 60
    }

    private func persist() { config.save() }
}
