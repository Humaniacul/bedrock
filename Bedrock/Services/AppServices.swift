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
    let supportContact: SupportContactStore
    let nudges: NudgeScheduler
    let streak: StreakStore
    let paywall: PaywallService

    /// Set by the app root; called after a data wipe so the app can rebuild a
    /// fresh service graph and return to onboarding.
    @ObservationIgnored var onWipe: (() -> Void)?

    init(
        blocking: BlockingService,
        strictMode: StrictModeService,
        passcode: PasscodeVault,
        commitment: CommitmentStore,
        accountability: AccountabilityService,
        heartbeat: HeartbeatService,
        triggers: TriggerEngine,
        supportContact: SupportContactStore,
        nudges: NudgeScheduler,
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
        self.supportContact = supportContact
        self.nudges = nudges
        self.streak = streak
        self.paywall = paywall
    }

    /// App Store Guideline 5.1.1(v): delete the account + all data — on the
    /// server and on this device — then reset the app to a fresh state.
    func deleteAccountAndData() async {
        blocking.clearProtection()
        await accountability.deleteAccount()
        passcode.clearCode()
        DeviceIdentity.reset()
        // Wipe every on-device store (streak, strict config, commitment,
        // triggers, support contact, onboarding flag, entitlement, …) at once.
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.identifier)
        onWipe?()
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
            supportContact: SupportContactStore(),
            nudges: NudgeScheduler(),
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
            triggers: TriggerEngine.preview(),
            supportContact: SupportContactStore(persist: false),
            nudges: NudgeScheduler(useNotificationCenter: false),
            streak: StreakStore.preview(),
            paywall: PaywallService()
        )
    }
}
