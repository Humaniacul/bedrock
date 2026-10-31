//  OnboardingAnalytics.swift
//  Bedrock onboarding · PostHog events (Phase 4 F6, revised in Phase 7)
//
//  Add the PostHog package to the Bedrock app target in project.yml:
//    packages:
//      PostHog:
//        url: https://github.com/PostHog/posthog-ios.git
//        from: "3.0.0"
//  Check the config property names below against the SDK version you pin.
//
//  Privacy rules, enforced by the types in this file:
//  - Every property is an enum, a bool, a bucket or a duration. There is no free-text property.
//  - Never sent: answers, the word, the letter, app or site names, which hour bands or feelings
//    were chosen, anything typed. Counts only.
//  - Session replay off, autocapture off, automatic screen views off, no identify, no person profiles,
//    no advertising identifier. Project setting: discard client IP data. EU region.
//  - The persistent-ID question for the EU is open (RT-21 in OPEN_QUESTIONS.md). Until it's decided,
//    keep PostHog's own anonymous ID and don't link it to the server's device ID.

import Foundation
import PostHog

// MARK: - Setup

public enum OnboardingAnalytics {

    public static func configure(apiKey: String) {
        let config = PostHogConfig(apiKey: apiKey, host: "https://eu.i.posthog.com")
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        config.captureElementInteractions = false   // autocapture
        config.sessionReplay = false
        config.personProfiles = .never
        PostHogSDK.shared.setup(config)
    }

    /// The one entry point. Adds the common properties to every event.
    public static func track(_ event: OnboardingEvent, context: OnboardingContext) {
        var props = event.properties
        context.common.forEach { props[$0.key] = $0.value }
        PostHogSDK.shared.capture(event.name, properties: props)
    }
}

// MARK: - Common properties

public struct OnboardingContext {
    public var screen: ScreenID
    public var startedAt: Date
    public var iosMajor: Int
    public var strictSupported: Bool
    /// One entry per running test, e.g. ["ab_trial_length": "7d"]. Values come from feature flags.
    public var experiments: [String: String]

    public init(screen: ScreenID, startedAt: Date, iosMajor: Int, strictSupported: Bool, experiments: [String: String] = [:]) {
        self.screen = screen
        self.startedAt = startedAt
        self.iosMajor = iosMajor
        self.strictSupported = strictSupported
        self.experiments = experiments
    }

    var common: [String: Any] {
        var c: [String: Any] = [
            "flow_version": "first_light_1",
            "screen_id": screen.rawValue,
            "chapter": screen.chapter.rawValue,
            "elapsed_ms": Int(Date().timeIntervalSince(startedAt) * 1000),
            "local_hour_bucket": LocalHourBucket.now.rawValue,
            "ios_major": iosMajor,
            "strict_supported": strictSupported
        ]
        experiments.forEach { c[$0.key] = $0.value }
        return c
    }
}

public enum Chapter: String { case wall, you, lock, begin, branch, supporter }

public enum ScreenID: String {
    case s1, r1, s2, s2_d, b2, b9, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s12u, siwa
    case s13_1, s13_2b, s13_3b, s13_4b, s13_5a, s13_5b, s13_6, s13_7a, s13_7b, s13_2p
    case s14, s15, home, sp1, sp2, sp3, sp4

    public var chapter: Chapter {
        switch self {
        case .s1, .r1, .s2, .s2_d, .s3, .s4: return .wall
        case .s5, .s6, .s7, .s8: return .you
        case .s9, .s10, .s11, .s12, .s12u: return .lock
        case .b2, .b9: return .branch
        case .sp1, .sp2, .sp3, .sp4: return .supporter
        default: return .begin
        }
    }
}

/// The hour the event happens, never the hours they chose. Tests the 2am hypothesis without asking.
public enum LocalHourBucket: String {
    case night, morning, afternoon, evening
    static var now: LocalHourBucket {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0...5: return .night
        case 6...11: return .morning
        case 12...17: return .afternoon
        default: return .evening
        }
    }
}

// MARK: - Buckets

public enum CountBucket: String {
    case zero = "0", few = "1-3", some = "4-10", many = "11+"
    public init(_ n: Int) {
        switch n { case ..<1: self = .zero; case 1...3: self = .few; case 4...10: self = .some; default: self = .many }
    }
}

public enum LengthBucket: String {
    case short = "<40", medium = "40-120", long = "121-300", veryLong = "300+"
    public init(characters n: Int) {
        switch n { case ..<40: self = .short; case 40...120: self = .medium; case 121...300: self = .long; default: self = .veryLong }
    }
}

public enum GapBucket: String {
    case underHour = "<1", day = "1-24", week = "24-168", longer = "168+"
    public init(hours h: Double) {
        switch h { case ..<1: self = .underHour; case 1..<24: self = .day; case 24..<168: self = .week; default: self = .longer }
    }
}

// MARK: - Value sets

public enum StartSource: String { case organic, inviteLink = "invite_link", returning }
public enum OnbPath: String { case pro, free, noWall = "no_wall" }
public enum STResult: String { case approved, denied, restricted, unavailable }
public enum WallStage: String { case web, apps, schedule }
public enum WallTestResult: String { case held, opened, unverified }
public enum WordSource: String { case preset, custom }
public enum StoneMethod: String { case hold, tapFallback = "tap_fallback", voiceover }
public enum Holder: String { case bedrock, partner }
public enum PaywallVariant: String { case standard, lateNight = "late_night", noTrial = "no_trial", unsupported }
public enum Plan: String { case yearly, lifetime, weekly }
public enum PurchaseResult: String { case success, cancelled, failed, pending }
public enum FreeVia: String { case button, close }
public enum SIWAResult: String { case success, cancelled, skipped, error }
public enum WindowStep: String { case started, finished; case digit1 = "digit_1", digit2 = "digit_2", digit3 = "digit_3", digit4 = "digit_4", confirm1 = "confirm_1", confirm2 = "confirm_2", confirm3 = "confirm_3", confirm4 = "confirm_4" }
public enum PauseReason: String { case screenCaptured = "screen_captured", leftSettings = "left_settings" }
public enum CheckResult: String { case passed, failed }
public enum LockCheckResult: String { case asked, switchedOff = "switched_off" }
public enum InviteAction: String { case shared, copied }
public enum ShieldAction: String { case close, needMinute = "need_minute" }
public enum InterceptOutcome: String { case rodeItOut = "rode_it_out", calledPerson = "called_person", slipped }
public enum StrictEntry: String { case statusChip = "status_chip", card }

/// Fixed list of `onb_action` names. Add here; never send a free string.
public enum ScreenAction: String {
    case buildWall = "build_wall", support, continueWithoutWall = "continue_without_wall", tryAgain = "try_again", openSettings = "open_settings"
    case closeDoor = "close_door", remindAfterUpdate = "remind_after_update", keepFree = "keep_free"
    case practiceStarted = "practice_started", practiceSkipped = "practice_skipped", stuckOpened = "stuck_opened", help
}

// MARK: - Events

public enum OnboardingEvent {
    // Lifecycle
    case started(source: StartSource)
    case screenViewed
    case action(ScreenAction)
    case finishLater
    case finishLaterResumed
    case resumed(gap: GapBucket)
    case completed(path: OnbPath, strictSealed: Bool, totalMs: Int)
    // Wall
    case stPermissionPrompted
    case stPermissionResult(STResult, msToDecide: Int)
    case pickerOpened
    case pickerResult(apps: CountBucket, categories: CountBucket)
    case wallApplied(webFilter: Bool, schedule: Bool, apps: CountBucket, applyMs: Int)
    case wallApplyFailed(WallStage)
    case wallTestStarted
    case wallTestSkipped
    case wallTestResult(WallTestResult)
    // You
    case hoursSubmitted(count: Int, noPattern: Bool)
    case underneathSubmitted(count: Int, notSure: Bool)
    case wordSubmitted(WordSource)
    case stoneSet(method: StoneMethod, attempts: Int)
    case crisisOpened
    // Lock
    case gauntletStepOpened(step: Int)
    case limitsOpened
    case keyHolderSelected(Holder)
    case existingPasscodeInfoOpened
    // Paywall
    case paywallViewed(PaywallVariant, holder: Holder?, trialEligible: Bool)
    case planSelected(Plan)
    case otherPlansOpened
    case purchaseStarted(Plan)
    case purchaseResult(PurchaseResult, plan: Plan, trial: Bool)
    case restoreResult(found: Bool)
    case freePath(FreeVia)
    case decideTomorrow
    case siwaResult(SIWAResult)
    // Strict Mode setup
    case strictSetupStarted(Holder)
    case letterSaved(length: LengthBucket, defaultUsed: Bool)
    case practiceCompleted(errors: Int)
    case blindEntryStarted
    case blindEntryWindow(WindowStep)
    case blindEntryPaused(PauseReason)
    case blindEntryReturned
    case codeCheck(CheckResult)
    case lockCheck(LockCheckResult)
    case codeMismatch(attempt: Int)
    case lockNotSaved(attempt: Int)
    case partnerInvite(InviteAction)
    case strictSealed(Holder)
    // Begin
    case notifPrompted
    case notifResult(granted: Bool)
    case interceptRehearsed
    // Supporter
    case supStarted(source: StartSource)
    case supTermsViewed
    case supNotifResult(granted: Bool)
    case supCompleted
    // Day one
    case homeViewed(first: Bool, path: OnbPath)
    case homeStrictOpened(StrictEntry)
    case shieldAction(ShieldAction)            // counted on device, sent on next open
    case headsupOpened                         // Phase 7: no window property; the hour band is an answer
    case interceptOutcome(InterceptOutcome)

    public var name: String {
        switch self {
        case .started: return "onb_started"
        case .screenViewed: return "onb_screen_viewed"
        case .action: return "onb_action"
        case .finishLater: return "onb_finish_later"
        case .finishLaterResumed: return "onb_finish_later_resumed"
        case .resumed: return "onb_resumed"
        case .completed: return "onb_completed"
        case .stPermissionPrompted: return "onb_st_permission_prompted"
        case .stPermissionResult: return "onb_st_permission_result"
        case .pickerOpened: return "onb_picker_opened"
        case .pickerResult: return "onb_picker_result"
        case .wallApplied: return "onb_wall_applied"
        case .wallApplyFailed: return "onb_wall_apply_failed"
        case .wallTestStarted: return "onb_wall_test_started"
        case .wallTestSkipped: return "onb_wall_test_skipped"
        case .wallTestResult: return "onb_wall_test_result"
        case .hoursSubmitted: return "onb_hours_submitted"
        case .underneathSubmitted: return "onb_underneath_submitted"
        case .wordSubmitted: return "onb_word_submitted"
        case .stoneSet: return "onb_stone_set"
        case .crisisOpened: return "onb_crisis_opened"
        case .gauntletStepOpened: return "onb_gauntlet_step_opened"
        case .limitsOpened: return "onb_limits_opened"
        case .keyHolderSelected: return "onb_key_holder_selected"
        case .existingPasscodeInfoOpened: return "onb_existing_passcode_info_opened"
        case .paywallViewed: return "onb_paywall_viewed"
        case .planSelected: return "onb_plan_selected"
        case .otherPlansOpened: return "onb_other_plans_opened"
        case .purchaseStarted: return "onb_purchase_started"
        case .purchaseResult: return "onb_purchase_result"
        case .restoreResult: return "onb_restore_result"
        case .freePath: return "onb_free_path"
        case .decideTomorrow: return "onb_decide_tomorrow"
        case .siwaResult: return "onb_siwa_result"
        case .strictSetupStarted: return "onb_strict_setup_started"
        case .letterSaved: return "onb_letter_saved"
        case .practiceCompleted: return "onb_practice_completed"
        case .blindEntryStarted: return "onb_blind_entry_started"
        case .blindEntryWindow: return "onb_blind_entry_window"
        case .blindEntryPaused: return "onb_blind_entry_paused"
        case .blindEntryReturned: return "onb_blind_entry_returned"
        case .codeCheck: return "onb_code_check"
        case .lockCheck: return "onb_lock_check"
        case .codeMismatch: return "onb_code_mismatch"
        case .lockNotSaved: return "onb_lock_not_saved"
        case .partnerInvite: return "onb_partner_invite"
        case .strictSealed: return "onb_strict_sealed"
        case .notifPrompted: return "onb_notif_prompted"
        case .notifResult: return "onb_notif_result"
        case .interceptRehearsed: return "onb_intercept_rehearsed"
        case .supStarted: return "sup_started"
        case .supTermsViewed: return "sup_terms_viewed"
        case .supNotifResult: return "sup_notif_result"
        case .supCompleted: return "sup_completed"
        case .homeViewed: return "home_viewed"
        case .homeStrictOpened: return "home_strict_opened"
        case .shieldAction: return "shield_action"
        case .headsupOpened: return "headsup_opened"
        case .interceptOutcome: return "intercept_outcome"
        }
    }

    public var properties: [String: Any] {
        switch self {
        case .started(let s): return ["source": s.rawValue]
        case .action(let a): return ["action": a.rawValue]
        case .resumed(let g): return ["gap_hours_bucket": g.rawValue]
        case .completed(let p, let sealed, let ms): return ["path": p.rawValue, "strict_sealed": sealed, "total_ms": ms]
        case .stPermissionResult(let r, let ms): return ["result": r.rawValue, "ms_to_decide": ms]
        case .pickerResult(let a, let c): return ["apps_bucket": a.rawValue, "categories_bucket": c.rawValue]
        case .wallApplied(let w, let s, let a, let ms): return ["web_filter": w, "schedule": s, "apps_bucket": a.rawValue, "apply_ms": ms]
        case .wallApplyFailed(let st): return ["stage": st.rawValue]
        case .wallTestResult(let r): return ["result": r.rawValue]
        case .hoursSubmitted(let n, let none): return ["count": n, "no_pattern": none]
        case .underneathSubmitted(let n, let unsure): return ["count": n, "not_sure": unsure]
        case .wordSubmitted(let s): return ["source": s.rawValue]
        case .stoneSet(let m, let a): return ["method": m.rawValue, "attempts": a]
        case .gauntletStepOpened(let step): return ["step": step]
        case .keyHolderSelected(let h), .strictSetupStarted(let h), .strictSealed(let h): return ["holder": h.rawValue]
        case .paywallViewed(let v, let h, let t):
            var p: [String: Any] = ["variant": v.rawValue, "trial_eligible": t]
            if let h { p["holder"] = h.rawValue }
            return p
        case .planSelected(let p), .purchaseStarted(let p): return ["plan": p.rawValue]
        case .purchaseResult(let r, let p, let t): return ["result": r.rawValue, "plan": p.rawValue, "trial": t]
        case .restoreResult(let f): return ["found": f]
        case .freePath(let v): return ["via": v.rawValue]
        case .siwaResult(let r): return ["result": r.rawValue]
        case .letterSaved(let l, let d): return ["length_bucket": l.rawValue, "default_used": d]
        case .practiceCompleted(let e): return ["errors": e]
        case .blindEntryWindow(let s): return ["step": s.rawValue]
        case .blindEntryPaused(let r): return ["reason": r.rawValue]
        case .codeCheck(let r): return ["result": r.rawValue]
        case .lockCheck(let r): return ["result": r.rawValue]
        case .codeMismatch(let a), .lockNotSaved(let a): return ["attempt": a]
        case .partnerInvite(let a): return ["action": a.rawValue]
        case .notifResult(let g), .supNotifResult(let g): return ["granted": g]
        case .supStarted(let s): return ["source": s.rawValue]
        case .homeViewed(let f, let p): return ["first": f, "path": p.rawValue]
        case .homeStrictOpened(let e): return ["source": e.rawValue]
        case .shieldAction(let a): return ["action": a.rawValue]
        case .interceptOutcome(let o): return ["outcome": o.rawValue]
        default: return [:]
        }
    }
}

// MARK: - The main funnel, for the PostHog insight
// onb_started → onb_st_permission_result(approved) → onb_wall_applied → onb_wall_test_result
// → onb_stone_set → onb_paywall_viewed → onb_purchase_result(success) | onb_free_path
// → onb_strict_sealed (pro) → onb_completed → home_viewed
