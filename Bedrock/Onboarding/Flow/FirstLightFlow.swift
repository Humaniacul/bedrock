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
        loaded.lastActiveAt = now
        state = loaded
        state.save()
    }

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
            if mode != .firstRun { onFinish(.cancelled) }
            return
        }
        goingForward = false
        dawnOverride = nil
        state.screen = previous
    }

    func update(_ change: (inout FirstLightState) -> Void) {
        change(&state)
    }

    /// After S4: on to the You chapter, or Home when only the wall was being rebuilt.
    func afterWallTest() {
        if mode == .rebuildWall { onFinish(.home) } else { go(.s5) }
    }

    /// After S2-D's “Continue without the wall” or B2.
    func withoutWall() {
        if mode == .rebuildWall { onFinish(.cancelled) } else { go(.s5) }
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
        if mode == .upgrade { onFinish(.home); return }
        toNotificationsOrRehearsal()
    }

    /// After setup is sealed (S13.6).
    func afterSealed() {
        switch mode {
        case .upgrade, .finishSetup: onFinish(.home)
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
        onFinish(.home)
    }

    /// Finish later (S4–S11): save the place and go Home with a card to come back.
    func finishLater() {
        track(.finishLater)
        state.finishedLater = true
        state.lastActiveAt = .now
        onFinish(.home)
    }

    func endSupporter() {
        state.supporterPaired = true
        onFinish(.supporterHome)
    }

    /// Leave an upgrade, setup or supporter run without finishing it (close, or back from its first screen).
    func leave() {
        onFinish(mode == .firstRun ? .home : .cancelled)
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
        case .s3: (.wall, 0.5)
        case .s4: (.wall, 0.75)
        case .s5: (.you, 0.25)
        case .s6: (.you, 0.5)
        case .s7: (.you, 0.75)
        case .s8: (.you, 1)
        case .s9: (.lock, 0.34)
        case .s10: (.lock, 0.67)
        case .s11: (.lock, 1)
        case .s13_1: (.begin, 0.25)
        case .s14: (.begin, 0.75)
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
