import SwiftUI
import UIKit

/// Home (SPEC.md › Home): the last screen of onboarding and the first of the
/// product, in the same world. Full daylight, the date and a status chip, their
/// stone with the word and the day, the urge button, and at most two cards.
/// No paywall pop-ups, ever: on the free wall the status chip is the quiet way
/// back to Strict Mode.
struct HomeView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var state = FirstLightState.load() ?? FirstLightState()
    @State private var launch: FlowLaunch?
    @State private var showIntercept = false
    @State private var notifications: NotificationAuthorization = .unknown
    @State private var firstAppearance = !AppGroup.defaults.bool(forKey: AppGroup.Key.homeHeadlineShown)
    @State private var dismissedTrialCard = false

    private var streak: StreakStore { services.streak }
    private var word: String { state.word ?? AppGroup.defaults.string(forKey: AppGroup.Key.userWord) ?? "" }
    /// Preview mode (B9: Simulator, App Review) simulates the wall, as the flow does.
    private var wallUp: Bool { services.blocking.isProtected || state.previewMode }

    var body: some View {
        ZStack(alignment: .top) {
            OnboardingBackdrop(level: 1)
            ScrollView {
                VStack(spacing: Space.s6) {
                    header
                    if firstAppearance && streak.foundationDays <= 1 { headline }
                    stone
                    UrgeButton(title: OnbCopy.string("onb.home.intercept"), style: .capsule,
                               accessibilityHint: OnbCopy.string("onb.s15.a11y_button")) {
                        showIntercept = true
                    }
                    cards
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["BEDROCK_DEBUG_STRIP"] == "1" { debugStrip }
                    #endif
                }
                .padding(.horizontal, Space.s6)
                .padding(.top, Space.s4)
                .padding(.bottom, Space.s8)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .privacyCover()
        .fullScreenCover(isPresented: $showIntercept) { InterceptView() }
        .fullScreenCover(item: $launch, onDismiss: reload) { launch in
            FirstLightView(mode: launch.mode) { _ in self.launch = nil }
                .environment(services)
        }
        .task {
            await refreshNotifications()
            streak.refreshForToday()
            let path: OnbPath = state.hasNoWall || !wallUp ? .noWall : (services.strictMode.isEnabled ? .pro : .free)
            Analytics.track(.homeViewed(first: firstAppearance, path: path), screen: .home, startedAt: state.startedAt)
        }
        .onDisappear {
            if firstAppearance {
                AppGroup.defaults.set(true, forKey: AppGroup.Key.homeHeadlineShown)
                firstAppearance = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            reload()
            Task { await refreshNotifications() }
        }
    }

    // MARK: Top

    /// The date and the status chip side by side; stacked when they don't fit
    /// (large text sizes).
    private var header: some View {
        let date = Text(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            .bedrockEyebrow()
            .lineLimit(1)
        let chip = StatusChip(status: status, action: statusAction)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Space.s3) {
                date
                Spacer(minLength: Space.s2)
                chip.fixedSize()
            }
            VStack(alignment: .leading, spacing: Space.s3) {
                date
                chip
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var status: StatusChip.Status {
        if services.strictMode.isEnabled { return .pro }
        return wallUp ? .free : .noWall
    }

    /// Free wall: S10 then S12. No wall: S2. Managed devices omit Strict Mode entirely.
    private var statusAction: (() -> Void)? {
        switch status {
        case .pro:
            return nil
        case .free:
            guard !state.restricted else { return nil }
            return {
                Analytics.track(.homeStrictOpened(.statusChip), screen: .home, startedAt: state.startedAt)
                launch = FlowLaunch(mode: .upgrade)
            }
        case .noWall:
            guard !state.restricted else { return nil }
            return { launch = FlowLaunch(mode: .rebuildWall) }
        }
    }

    private var headline: some View {
        CarveText(OnbCopy.string(wallUp ? "onb.home.first_headline" : "onb.home.headline_no_wall"),
                  font: BedrockFont.title)
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    private var stone: some View {
        VStack(spacing: Space.s3) {
            StoneView(word: word, day: max(streak.foundationDays, 1),
                      phase: streak.hasCrack ? .cracked(repaired: false) : .set(carve: false),
                      size: dynamicTypeSize.isAccessibilitySize ? BedrockSize.stoneHome : BedrockSize.stoneRegular)
                .bedrockAppear(.settle)
            if streak.hasCrack {
                let crack = OnbCopy.parts("onb.home.crack")
                VStack(spacing: Space.s1) {
                    Text(crack.first ?? "")
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .multilineTextAlignment(.center)
                    LinkButton(title: crack.last ?? "", tone: .secondary) {
                        BedrockHaptics.lock()
                        streak.repairCrack()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.s4)
    }

    // MARK: Cards

    private var cards: some View {
        VStack(spacing: Space.s3) {
            ForEach(Array(activeCards.prefix(2))) { card in
                HomeCard(title: card.title, subtitle: card.subtitle,
                         action: card.action, onDismiss: card.dismiss)
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.reducedFade, value: activeCards.map(\.id))
    }

    private var activeCards: [Card] {
        var list: [Card] = []
        let premium = services.paywall.isPremium

        // Finish setting up: the only way back, so it can't be dismissed.
        if state.finishedLater && !state.completed {
            list.append(Card(id: "later", key: "onb.fl.home_card") { launch = FlowLaunch(mode: .firstRun) })
        }
        if premium && !state.strictSealed && !services.strictMode.isEnabled && state.paywallOutcome == .purchased
            && RemoteConfig.strictModeSupported {
            list.append(Card(id: "setup", key: "onb.home.card_setup") { launch = FlowLaunch(mode: .finishSetup) })
        }
        if !wallUp && !state.restricted && !state.previewMode {
            list.append(Card(id: "noWall", key: "onb.home.card_no_wall") { launch = FlowLaunch(mode: .rebuildWall) })
        }
        if let ends = services.paywall.trialEndsAt, !dismissedTrialCard,
           ends.timeIntervalSinceNow < 36 * 3600, ends > .now {
            list.append(Card(id: "trial", key: "onb.home.card_trial",
                             action: { openURL(Legal.subscriptions) },
                             dismiss: { dismissedTrialCard = true }))
        }
        if state.keyHolder == .partner && services.strictMode.isEnabled && !services.accountability.hasPartner {
            let canResend = state.inviteSentAt.map { Date.now.timeIntervalSince($0) > 24 * 3600 } ?? true
            list.append(Card(id: "partner", key: "onb.home.card_partner",
                             action: canResend && state.inviteURL != nil ? { resendInvite() } : nil))
        }
        if state.paywallOutcome == .waitingForUpdate && !premium && RemoteConfig.strictModeSupported {
            list.append(Card(id: "ready", key: "onb.s12u.home_card_later") {
                launch = FlowLaunch(mode: .upgrade)
            })
        }
        // The free card follows a decision on S12, appears once and stays dismissed.
        if (state.paywallOutcome == .free || state.paywallOutcome == .remindTomorrow)
            && !premium && !state.freeCardDismissed && !state.restricted && wallUp {
            list.append(Card(id: "free", key: "onb.home.card_free",
                             action: {
                                 Analytics.track(.homeStrictOpened(.card), screen: .home, startedAt: state.startedAt)
                                 launch = FlowLaunch(mode: .upgrade)
                             },
                             dismiss: { dismiss { $0.freeCardDismissed = true } }))
        }
        if let headsUp = headsUpCard { list.append(headsUp) }
        return list
    }

    private var headsUpCard: Card? {
        guard !state.headsUpCardDismissed, state.hours.contains(where: { $0.window != nil }) else { return nil }
        let dismissAction = { dismiss { $0.headsUpCardDismissed = true } }
        switch notifications {
        case .denied:
            let parts = OnbCopy.parts("onb.home.heads_up_off")
            return Card(id: "headsUp", title: parts.first ?? "", subtitle: parts.last ?? "",
                        action: { openNotificationSettings() }, dismiss: dismissAction)
        case .notDetermined:
            return Card(id: "headsUp", title: OnbCopy.string("onb.home.heads_up_title"),
                        subtitle: nextHeadsUpText,
                        action: {
                            Task {
                                if await NotificationPermission.request() {
                                    await Reminders.scheduleHeadsUps(for: state.hours)
                                }
                                await refreshNotifications()
                            }
                        },
                        dismiss: dismissAction)
        case .allowed:
            return Card(id: "headsUp", title: OnbCopy.string("onb.home.heads_up_title"),
                        subtitle: nextHeadsUpText, action: nil, dismiss: dismissAction)
        case .unknown:
            return nil
        }
    }

    /// “Tonight at 9:45 PM”, “Tomorrow at 7:45 AM”, “Saturday at 5:45 PM”.
    private var nextHeadsUpText: String {
        guard let next = Reminders.nextHeadsUp(for: state.hours) else { return "" }
        let calendar = Calendar.current
        let time = next.formatted(date: .omitted, time: .shortened)
        let key: String
        if calendar.isDateInToday(next) {
            key = calendar.component(.hour, from: next) >= 18 ? "onb.home.heads_up_tonight" : "onb.home.heads_up_today"
        } else if calendar.isDateInTomorrow(next) {
            key = "onb.home.heads_up_tomorrow"
        } else {
            key = "onb.home.heads_up_day"
        }
        return OnbCopy.string(key)
            .replacingOccurrences(of: "{time}", with: time)
            .replacingOccurrences(of: "{day}", with: next.formatted(.dateTime.weekday(.wide)))
    }

    // MARK: Actions

    private func reload() {
        state = FirstLightState.load() ?? FirstLightState()
    }

    private func dismiss(_ change: (inout FirstLightState) -> Void) {
        var updated = FirstLightState.load() ?? state
        change(&updated)
        updated.save()
        state = updated
    }

    private func refreshNotifications() async {
        switch await NotificationPermission.status() {
        case .denied: notifications = .denied
        case .notDetermined: notifications = .notDetermined
        default: notifications = .allowed
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
    }

    private func resendInvite() {
        guard let link = state.inviteURL else { return }
        let message = OnbCopy.string("onb.s13_2p.share_message").replacingOccurrences(of: "{link}", with: link)
        let controller = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            Task { @MainActor in dismiss { $0.inviteSentAt = .now } }
        }
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first?
            .topmostPresented
            .present(controller, animated: true)
    }

    #if DEBUG
    private var debugStrip: some View {
        HStack(spacing: Space.s3) {
            Button("+ Day") { streak.debugAdvanceDay() }
            Button("Slip") { streak.recordRelapse() }
            Button("Reset") { streak.debugReset() }
        }
        .font(BedrockFont.footnote)
        .foregroundStyle(BedrockColor.inkTertiary)
        .buttonStyle(.plain)
    }
    #endif
}

/// A flow presented from Home or the app (upgrade, finish setup, rebuild, resume).
struct FlowLaunch: Identifiable {
    let id = UUID()
    let mode: FirstLightFlow.Mode
}

private enum NotificationAuthorization { case unknown, notDetermined, denied, allowed }

private struct Card: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    var action: (() -> Void)?
    var dismiss: (() -> Void)?

    init(id: String, title: String, subtitle: String, action: (() -> Void)? = nil, dismiss: (() -> Void)? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.dismiss = dismiss
    }

    /// A card whose copy is “Title · Subtitle” in the catalog.
    init(id: String, key: String, action: (() -> Void)? = nil, dismiss: (() -> Void)? = nil) {
        let parts = OnbCopy.parts(key)
        self.init(id: id, title: parts.first ?? "", subtitle: parts.dropFirst().joined(separator: " · "),
                  action: action, dismiss: dismiss)
    }
}

extension UIViewController {
    /// The controller currently on top, to present the share sheet from.
    var topmostPresented: UIViewController {
        presentedViewController?.topmostPresented ?? self
    }
}

#Preview {
    HomeView().environment(AppServices.makeStub())
}
