import Foundation
import Observation

/// Drives the First Light onboarding (SPEC.md): which screen is showing, the
/// back stack, the branches, resume, and analytics. One instance per
/// presentation. Every state change is saved to the App Group.
@MainActor
@Observable
final class FirstLightFlow {
    enum Mode: Equatable {
        /// S1 → Home. Resumes at the saved screen.
        case firstRun
        /// From Home's status chip or a premium feature: S10 → S12, then setup.
        case upgrade
        /// The “decide tomorrow” reminder: straight to S12, then setup.
        case paywall
        /// After a purchase whose setup isn't finished: S13.1 (or S13.5A).
        case finishSetup
        /// The person who holds the key: SP1 → SP4.
        case supporter(code: String?)
        /// From Home when the wall isn't up: S2 → S4, then Home.
        case rebuildWall
    }

    enum Ending { case home, supporterHome, cancelled }

    let mode: Mode
    private let onFinish: (Ending) -> Void
    /// Side runs (upgrade, setup, supporter, rebuild) borrow the saved state and
    /// hand the person's own place in first run back when they end.
    private let firstRunPlace: (screen: String, history: [String])?

    private(set) var state: FirstLightState {
        didSet { if state != oldValue { state.save() } }
    }

    // Presentation state (not persisted)
    var goingForward = true
    var toast: String?
    var showsFinishLater = false
    var showsCrisis = false
    /// A screen can lift the horizon above its Dawn level (S3 once the wall is up).
    var dawnOverride: Double?
    /// The invite code typed on SP1 when the supporter came from S1's link.
    var supporterCode: String?

    init(mode: Mode, onFinish: @escaping (Ending) -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        var loaded = FirstLightState.load() ?? FirstLightState()
        let now = Date.now
        firstRunPlace = mode == .firstRun ? nil : (loaded.screen, loaded.history)

        switch mode {
        case .firstRun:
            if loaded.startedAt == nil {
                loaded.startedAt = now
            } else if let screen = Self.resumeScreen(for: loaded, now: now) {
                // Resuming: say so once, under the Dynamic Island.
                loaded.screen = screen.rawValue
                if screen != .s1 { toast = OnbCopy.string("onb.resume.toast") }
                if let last = loaded.lastActiveAt {
                    Analytics.track(.resumed(gap: GapBucket(hours: now.timeIntervalSince(last) / 3600)),
                                    screen: screen, startedAt: loaded.startedAt)
                }
            }
            if loaded.finishedLater {
                loaded.finishedLater = false
                Analytics.track(.finishLaterResumed, screen: loaded.current, startedAt: loaded.startedAt)
            }
        case .upgrade:
            loaded.history = []
            loaded.screen = ScreenID.s10.rawValue
        case .paywall:
            loaded.history = []
            loaded.screen = (RemoteConfig.strictModeSupported ? ScreenID.s12 : .s12u).rawValue
        case .finishSetup:
            loaded.history = []
            loaded.screen = (loaded.realRunStarted ? ScreenID.s13_5a : .s13_1).rawValue
        case .supporter(let code):
            loaded.history = []
            loaded.screen = ScreenID.sp1.rawValue
            supporterCode = code
        case .rebuildWall:
            loaded.history = []
            loaded.screen = ScreenID.s2.rawValue
        }
        #if DEBUG
        // Open at one screen for testing: SIMCTL_CHILD_BEDROCK_DEBUG_SCREEN=s13_6.
        if let raw = ProcessInfo.processInfo.environment["BEDROCK_DEBUG_SCREEN"], ScreenID(rawValue: raw) != nil {
            unsetenv("BEDROCK_DEBUG_SCREEN")
            loaded.screen = raw
            toast = nil
            // BEDROCK_DEBUG_SEED=1: answers and history as if walked here from S1.
            if ProcessInfo.processInfo.environment["BEDROCK_DEBUG_SEED"] == "1" {
                Self.seed(&loaded, upTo: raw)
            }
        }
        #endif
        loaded.lastActiveAt = now
        state = loaded
        state.save()
    }

    #if DEBUG
    /// A typical first run reaching `screen`: the screens before it in history,
    /// the wall up after S3, answers after S5–S7, the stone after S8, Bedrock
    /// holding the key after S11.
    private static func seed(_ state: inout FirstLightState, upTo screen: String) {
        let order: [ScreenID] = [.s1, .s2, .s3, .s4, .s5, .s6, .s7, .s8, .s9, .s10, .s11, .s12,
                                 .s13_1, .s13_2b, .s13_3b, .s13_4b, .s13_5a, .s13_5b, .s13_6, .s14, .s15]
        guard let target = ScreenID(rawValue: screen), let index = order.firstIndex(of: target) else { return }
        let before = Set(order.prefix(index))
        state.history = order.prefix(index).map(\.rawValue)
        state.startedAt = .now
        if before.contains(.s3) { state.wallUp = true }
        if before.contains(.s5) { state.hours = [.lateNight] }
        if before.contains(.s6) { state.feelings = [.tired] }
        if before.contains(.s7) { state.word = "steady" }
        if before.contains(.s8) { state.stoneSetAt = .now }
        if before.contains(.s10) { state.pathPlayed = true }
        if before.contains(.s11) { state.keyHolder = .bedrock }
        if before.contains(.s12) { state.paywallOutcome = .purchased }
        if before.contains(.s13_1) { state.letterSaved = true }
    }
    #endif

    var current: ScreenID { state.current }
    var canGoBack: Bool { !state.history.isEmpty }

    // MARK: Navigation

    func go(_ screen: ScreenID) {
        goingForward = true
        dawnOverride = nil
        state.history.append(state.screen)
        state.screen = screen.rawValue
        state.lastActiveAt = .now
        track(.screenViewed, on: screen)
    }

    /// Back to the previous screen. From the first screen of an upgrade or
    /// supporter run, back leaves the flow.
    func back() {
        guard let previous = state.history.popLast() else {
            if mode != .firstRun { end(.cancelled) }
            return
        }
        goingForward = false
        dawnOverride = nil
        state.screen = previous
    }

    private func end(_ ending: Ending) {
        if let firstRunPlace {
            state.screen = firstRunPlace.screen
            state.history = firstRunPlace.history
        }
        onFinish(ending)
    }

    func update(_ change: (inout FirstLightState) -> Void) {
        change(&state)
    }

    /// After S4: on to the You chapter, or Home when only the wall was being rebuilt.
    func afterWallTest() {
        if mode == .rebuildWall { end(.home) } else { go(.s5) }
    }

    /// After S2-D's “Continue without the wall” or B2.
    func withoutWall() {
        if mode == .rebuildWall { end(.cancelled) } else { go(.s5) }
    }

    /// Where the person goes after S8: the Lock chapter, or straight Home when
    /// there's no wall to lock (S2-D, B2).
    func afterStone() {
        if state.hasNoWall { finish() } else { go(.s9) }
    }

    /// After S11: the paywall, or the honest version gate (S12U).
    func toPaywall() {
        go(RemoteConfig.strictModeSupported ? .s12 : .s12u)
    }

    /// After the paywall's free path (S12 or S12U).
    func afterFreeChoice() {
        if mode == .upgrade || mode == .paywall { end(.home); return }
        toNotificationsOrRehearsal()
    }

    /// After setup is sealed (S13.6).
    func afterSealed() {
        switch mode {
        case .upgrade, .paywall, .finishSetup: end(.home)
        default: toNotificationsOrRehearsal()
        }
    }

    /// S14 is skipped when notifications were already granted (late-night reminder).
    func toNotificationsOrRehearsal() {
        Task { @MainActor in
            let status = await NotificationPermission.status()
            go(status == .notDetermined ? .s14 : .s15)
        }
    }

    /// The end of first run: Home.
    func finish() {
        let path: OnbPath = state.hasNoWall ? .noWall : (state.paywallOutcome == .purchased ? .pro : .free)
        let total = state.startedAt.map { Int(Date.now.timeIntervalSince($0) * 1000) } ?? 0
        track(.completed(path: path, strictSealed: state.strictSealed, totalMs: total))
        state.completed = true
        state.completedAt = .now
        state.history = []
        state.screen = ScreenID.home.rawValue
        AppGroup.defaults.set(true, forKey: AppGroup.Key.onboardingComplete)
        end(.home)
    }

    /// Finish later (S4–S11): save the place and go Home with a card to come back.
    func finishLater() {
        track(.finishLater)
        state.finishedLater = true
        state.lastActiveAt = .now
        end(.home)
    }

    func endSupporter() {
        state.supporterPaired = true
        end(.supporterHome)
    }

    /// Leave an upgrade, setup or supporter run without finishing it (close, or back from its first screen).
    func leave() {
        end(mode == .firstRun ? .home : .cancelled)
    }

    // MARK: Analytics

    func track(_ event: OnboardingEvent, on screen: ScreenID? = nil) {
        Analytics.track(event, screen: screen ?? current, startedAt: state.startedAt)
    }

    // MARK: Resume rules (SPEC.md › RESUME)

    private static func resumeScreen(for state: FirstLightState, now: Date) -> ScreenID? {
        let screen = state.current
        if state.completed { return nil }
        // Left after the real run started: back to the check, same code.
        if state.realRunStarted && !state.strictSealed { return .s13_5a }
        // Bought but setup not started.
        if state.paywallOutcome == .purchased && !state.strictSealed && screen.isBeforeSetup { return .s13_1 }
        // Away more than 7 days: the start of the current chapter.
        if let last = state.lastActiveAt, now.timeIntervalSince(last) > 7 * 24 * 3600 {
            return screen.chapterStart
        }
        // An interrupted iOS sheet is re-asked from its pre-screen.
        return screen
    }
}

// MARK: - Screen helpers

extension ScreenID {
    /// The first screen of this screen's chapter (resume after a long gap).
    var chapterStart: ScreenID {
        switch chapter {
        case .wall: .s1
        case .you: .s5
        case .lock: .s9
        case .begin: self.isStrictSetup ? .s13_1 : .s14
        case .branch, .supporter: self
        }
    }

    var isStrictSetup: Bool {
        switch self {
        case .s13_1, .s13_2b, .s13_3b, .s13_4b, .s13_5a, .s13_5b, .s13_6, .s13_7a, .s13_7b, .s13_2p: true
        default: false
        }
    }

    var isBeforeSetup: Bool {
        switch self {
        case .s12, .s12u, .siwa: true
        default: chapter == .wall || chapter == .you || chapter == .lock
        }
    }

    /// The ChapterBar and its fill (SPEC.md layouts). nil = no chapter bar.
    var chapterBar: (chapter: Chapter, progress: Double)? {
        switch self {
        case .s2, .s2_d, .b2, .b9: (.wall, 0.25)
        case .s3: (.wall, 0.6)
        case .s4: (.wall, 1)
        case .s5: (.you, 0.25)
        case .s6: (.you, 0.5)
        case .s7: (.you, 0.75)
        case .s8: (.you, 1)
        case .s9: (.lock, 0.25)
        case .s10: (.lock, 0.5)
        case .s11: (.lock, 0.75)
        case .siwa: (.begin, 0.1)
        case .s13_1: (.begin, 0.3)
        case .s13_2p: (.begin, 0.35)
        case .s13_2b: (.begin, 0.4)
        case .s13_3b: (.begin, 0.45)
        case .s13_4b: (.begin, 0.5)
        case .s13_5a, .s13_7a: (.begin, 0.55)
        case .s13_5b, .s13_7b: (.begin, 0.6)
        case .s13_6: (.begin, 0.65)
        case .s14: (.begin, 0.8)
        case .s15: (.begin, 1)
        default: nil
        }
    }

    /// Finish later shows as a text button from S4 until S11 (SPEC.md S4).
    var showsFinishLater: Bool {
        switch self {
        case .s4, .s5, .s6, .s7, .s8, .s9, .s10, .s11: true
        default: false
        }
    }
}
