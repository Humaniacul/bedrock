import Observation

/// The service container, injected once at the app root and read via
/// `@Environment(AppServices.self)`. MV + service layer (§3): screens stay thin,
/// logic lives here. Live implementations swap in per phase behind the same
/// surfaces.
@MainActor
@Observable
final class AppServices {
    let blocking: BlockingService
    let strictMode: StrictModeService
    let passcode: PasscodeVault
    let commitment: CommitmentStore
    let accountability: AccountabilityService
    let heartbeat: HeartbeatService
    let triggers: TriggerEngine
    let streak: StreakStore
    let paywall: PaywallService

    init(
        blocking: BlockingService,
        strictMode: StrictModeService,
        passcode: PasscodeVault,
        commitment: CommitmentStore,
        accountability: AccountabilityService,
        heartbeat: HeartbeatService,
        triggers: TriggerEngine,
        streak: StreakStore,
        paywall: PaywallService
    ) {
        self.blocking = blocking
        self.strictMode = strictMode
        self.passcode = passcode
        self.commitment = commitment
        self.accountability = accountability
        self.heartbeat = heartbeat
        self.triggers = triggers
        self.streak = streak
        self.paywall = paywall
    }

    /// The live graph used by the app. Blocking, streak, Strict Mode + passcode
    /// are real (Phases 1–2); accountability is live when a backend URL is set
    /// (Phase 3), else a stub so the app still runs solo.
    static func makeLive() -> AppServices {
        let api = BackendConfig.baseURL.map { APIClient(baseURL: $0) }
        let accountability: AccountabilityService = api.map { LiveAccountabilityService(api: $0) } ?? StubAccountabilityService()
        return AppServices(
            blocking: LiveBlockingService(),
            strictMode: StrictModeService(),
            passcode: KeychainPasscodeVault(),
            commitment: CommitmentStore(),
            accountability: accountability,
            heartbeat: HeartbeatService(api: api),
            triggers: TriggerEngine(),
            streak: StreakStore.live(),
            paywall: PaywallService()
        )
    }

    /// In-memory graph for previews — no OS APIs, no persistence, no backend.
    static func makeStub() -> AppServices {
        AppServices(
            blocking: StubBlockingService(),
            strictMode: StrictModeService(),
            passcode: StubPasscodeVault(),
            commitment: CommitmentStore(),
            accountability: StubAccountabilityService(),
            heartbeat: HeartbeatService(api: nil),
            triggers: TriggerEngine(),
            streak: StreakStore.preview(),
            paywall: PaywallService()
        )
    }
}
