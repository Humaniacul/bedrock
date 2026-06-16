import Foundation
import Observation

/// The gauntlet cooldown (§4 step 5). It must be honest about elapsed time, so
/// it measures against the monotonic system uptime (resists wall-clock
/// tampering) and **resets if the app is backgrounded** — you have to sit with
/// the urge, not walk away from the timer.
///
/// Phase 3 makes this server-validated (§10.5): `start`/`update` will reconcile
/// against trusted server time via a `TimeAuthority`. Until then, monotonic
/// uptime + a reboot/rollback guard is the local defense.
@MainActor
@Observable
final class CooldownEngine {
    private(set) var totalSeconds: Int = 0
    private(set) var remaining: Int = 0
    private(set) var isRunning = false
    private(set) var didComplete = false

    private var uptimeStart: TimeInterval?
    private var task: Task<Void, Never>?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remaining) / Double(totalSeconds)
    }

    func start(seconds: Int) {
        stop()
        totalSeconds = max(1, seconds)
        remaining = totalSeconds
        uptimeStart = ProcessInfo.processInfo.systemUptime
        isRunning = true
        didComplete = false
        task = Task { [weak self] in await self?.run() }
    }

    /// The user left the app — restart the clock (§4).
    func resetForBackground() {
        guard isRunning else { return }
        uptimeStart = ProcessInfo.processInfo.systemUptime
        remaining = totalSeconds
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    private func run() async {
        while isRunning {
            try? await Task.sleep(for: .seconds(1))
            guard isRunning, !Task.isCancelled else { break }
            update()
        }
    }

    private func update() {
        guard let start = uptimeStart else { return }
        let now = ProcessInfo.processInfo.systemUptime
        // Reboot (or clock rollback) → uptime went backwards → restart, don't credit.
        if now < start {
            uptimeStart = now
            remaining = totalSeconds
            return
        }
        let elapsed = Int(now - start)
        remaining = max(0, totalSeconds - elapsed)
        if remaining == 0 {
            isRunning = false
            didComplete = true
            stop()
        }
    }
}
