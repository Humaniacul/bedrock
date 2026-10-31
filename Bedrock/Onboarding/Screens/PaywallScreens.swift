import AuthenticationServices
import SwiftUI

// Paywall · Remove the door, the version gate, Sign in with Apple (SPEC.md S12,
// S12U, SIWA). Prices are StoreKit's localized strings through RevenueCat, never
// literals; trial copy shows only when StoreKit says the account is eligible.

// MARK: - S12 · Remove the door

struct PaywallScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL

    typealias StrictPlan = PaywallService.StrictPlan

    enum Notice: Equatable { case failed, pending }

    @State private var plan: StrictPlan = .yearly
    @State private var notice: Notice?
    @State private var otherPlansShown = false
    @State private var succeeded = false
    @State private var restoring = false
    @State private var viewedTracked = false

    private var paywall: PaywallService { services.paywall }
    private var holder: KeyHolder { flow.state.keyHolder ?? .bedrock }
    private var yearly: PaywallService.StrictOffer? { paywall.offers[.yearly] }
    private var lifetime: PaywallService.StrictOffer? { paywall.offers[.lifetime] }
    private var weekly: PaywallService.StrictOffer? { paywall.offers[.weekly] }
    private var selectedOffer: PaywallService.StrictOffer? { paywall.offers[plan] }
    private var trialDays: Int? { plan == .yearly ? yearly?.trialDays : nil }
    private var inlineCTA: Bool { dynamicTypeSize.isAccessibilitySize }

    /// 22:00–04:59 local time.
    private var isLateNight: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour >= BedrockTiming.lateNightStart || hour < BedrockTiming.lateNightEnd
    }

    var body: some View {
        ZStack {
            OnboardingScaffold(.s12, flow: flow, back: false,
                               onClose: { keepFree(.close) },
                               closeLabel: OnbCopy.string("onb.s12.free_path")) {
                content
            } footer: {
                if !inlineCTA { ctaGroup }
            }
            if succeeded {
                SuccessMoment()
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.reducedFade, value: succeeded)
        .bedrockSheet(isPresented: $otherPlansShown, title: otherPlansParts.first ?? "") {
            otherPlansSheet
        }
        .task {
            await paywall.loadOffers()
            trackViewed()
        }
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: Space.s6) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.s12.eyebrow"),
                          headline: OnbCopy.string("onb.s12.headline"),
                          text: OnbCopy.string(holder == .partner ? "onb.s12.subhead_b" : "onb.s12.subhead_a"))
            outcomes
            plans
            if trialDays != nil, plan == .yearly, let yearly { timeline(yearly) }
            if inlineCTA { ctaGroup }
            Text(OnbCopy.string("onb.s12.trust_line"))
                .font(BedrockFont.footnote)
                .foregroundStyle(BedrockColor.inkTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            if isLateNight { lateNight }
            legal
            links
            CrisisLink { flow.showsCrisis = true }
                .frame(maxWidth: .infinity)
        }
    }

    private var outcomes: some View {
        let keys = ["onb.s12.outcome_1", "onb.s12.outcome_2",
                    holder == .partner ? "onb.s12.outcome_3_b" : "onb.s12.outcome_3_a", "onb.s12.outcome_4"]
        let glyphs = ["figure.walk", "trash.slash", holder == .partner ? "person.2" : "lock", "clock"]
        return VStack(alignment: .leading, spacing: Space.s3) {
            ForEach(keys.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
                    Image(systemName: glyphs[index])
                        .font(BedrockFont.subhead.weight(.semibold))
                        .foregroundStyle(BedrockColor.emberGlow)
                        .frame(width: BedrockSize.outcomeGlyph)
                        .accessibilityHidden(true)
                    Text(OnbCopy.string(keys[index]))
                        .font(BedrockFont.body)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .bedrockAppear(.strata(index: index), delay: 0.1)
            }
        }
    }

    @ViewBuilder private var plans: some View {
        switch paywall.offersState {
        case .loading:
            ProgressView()
                .tint(BedrockColor.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: BedrockSize.planCardMinHeight)
        case .unavailable:
            NoticeText(text: OnbCopy.string("onb.s12.error_offline"))
        case .ready:
            VStack(spacing: Space.s3) {
                let layout = inlineCTA
                    ? AnyLayout(VStackLayout(spacing: Space.s5))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: Space.s3))
                layout {
                    if let yearly { yearlyCard(yearly) }
                    if let lifetime { lifetimeCard(lifetime) }
                }
                .padding(.top, BedrockSize.badgeOverlap)
                if plan == .weekly, let weekly { weeklyRow(weekly) }
                if weekly != nil {
                    LinkButton(title: OnbCopy.string("onb.s12.link"), tone: .secondary) {
                        flow.track(.otherPlansOpened)
                        otherPlansShown = true
                    }
                }
            }
        }
    }

    private func yearlyCard(_ offer: PaywallService.StrictOffer) -> some View {
        let price = fill("onb.s12.yearly_price", offer)
        let subline = offer.trialDays != nil ? fill("onb.s12.yearly_trial", offer) : fill("onb.s12.yearly_plain", offer)
        let badge = offer.trialDays != nil ? fill("onb.s12.yearly_badge", offer) : nil
        let title = OnbCopy.string("onb.s12.yearly_title")
        return PlanCard(title: title, price: price, subline: subline, badge: badge,
                        isSelected: plan == .yearly,
                        accessibilityText: planLabel(title, price, badge ?? subline)) { select(.yearly) }
    }

    private func lifetimeCard(_ offer: PaywallService.StrictOffer) -> some View {
        let title = OnbCopy.string("onb.s12.lifetime_title")
        let detail = OnbCopy.string("onb.s12.lifetime_detail")
        return PlanCard(title: title, price: offer.price, subline: detail,
                        badge: OnbCopy.string("onb.s12.lifetime_badge"),
                        isSelected: plan == .lifetime,
                        accessibilityText: planLabel(title, offer.price, detail)) { select(.lifetime) }
    }

    /// The selected weekly plan, as a row under the two cards (both unselected).
    private func weeklyRow(_ offer: PaywallService.StrictOffer) -> some View {
        let parts = fill("onb.s12.weekly_selected", offer).components(separatedBy: " · ")
        return HStack {
            Text(parts.first ?? "")
                .font(BedrockFont.headline)
            Spacer()
            Text(parts.last ?? "")
                .font(BedrockFont.subhead.weight(.semibold))
                .monospacedDigit()
                .transaction { $0.animation = nil }
        }
        .foregroundStyle(BedrockColor.inkPrimary)
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous).fill(BedrockColor.emberWash))
        .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
            .strokeBorder(BedrockColor.ember, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSelected)
    }

    /// Today · In 2 days · In 3 days. Read as one sentence.
    private func timeline(_ offer: PaywallService.StrictOffer) -> some View {
        let days = offer.trialDays ?? 0
        var rows: [[String]] = [OnbCopy.parts("onb.s12.timeline_today")]
        if days - 1 > 1 {
            rows.append(OnbCopy.string("onb.s12.timeline_reminder")
                .replacingOccurrences(of: "{n}", with: "\(days - 1)").components(separatedBy: " · "))
        } else if days - 1 == 1 {
            rows.append(OnbCopy.parts("onb.s12.timeline_reminder_tomorrow"))
        }
        rows.append(fill("onb.s12.timeline_end", offer).components(separatedBy: " · "))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: Space.s3) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == 0 ? BedrockColor.ember : BedrockColor.bgRaised)
                            .overlay(Circle().strokeBorder(BedrockColor.emberGlow, lineWidth: 1))
                            .frame(width: BedrockSize.timelineDot, height: BedrockSize.timelineDot)
                            .padding(.top, Space.s1)
                        if index < rows.count - 1 {
                            Rectangle().fill(BedrockColor.lineStrong).frame(width: 1).frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rows[index].first ?? "")
                            .font(BedrockFont.footnote.weight(.semibold))
                            .foregroundStyle(BedrockColor.emberGlow)
                        Text(rows[index].dropFirst().joined(separator: " · "))
                            .font(BedrockFont.subhead)
                            .foregroundStyle(BedrockColor.inkPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transaction { $0.animation = nil }
                    }
                    .padding(.bottom, Space.s3)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var ctaGroup: some View {
        VStack(spacing: Space.s2) {
            if let notice {
                VStack(spacing: Space.s1) {
                    NoticeText(text: OnbCopy.string(notice == .failed ? "onb.s12.error_failed" : "onb.s12.error_pending"))
                }
            }
            PrimaryButton(title: notice == .failed ? OnbCopy.string("onb.s12.error_retry") : ctaTitle,
                          isEnabled: paywall.offersState == .ready && selectedOffer != nil,
                          isLoading: paywall.isPurchasing) { buy() }
                .contentTransition(.opacity)
                .animation(BedrockMotion.ctaCrossfade, value: plan)
            Text(OnbCopy.string("onb.s12.under_cta"))
                .font(BedrockFont.footnote)
                .foregroundStyle(BedrockColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            TextButton(title: OnbCopy.string("onb.s12.free_path"), fullWidth: true) { keepFree(.button) }
        }
    }

    private var ctaTitle: String {
        guard let offer = selectedOffer else { return OnbCopy.string("onb.s12.yearly_title") }
        switch plan {
        case .yearly: return offer.trialDays != nil ? fill("onb.s12.cta_trial", offer) : fill("onb.s12.cta_yearly", offer)
        case .lifetime: return fill("onb.s12.cta_lifetime", offer)
        case .weekly: return fill("onb.s12.cta_weekly", offer)
        }
    }

    private var lateNight: some View {
        let parts = OnbCopy.parts("onb.s12.late_night")
        return VStack(alignment: .leading, spacing: Space.s3) {
            Text(parts.first ?? "")
                .font(BedrockFont.titleS)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
            TextButton(title: parts.last ?? "", fullWidth: true) { remindTomorrow() }
                .background(Capsule().strokeBorder(BedrockColor.lineStrong))
        }
        .padding(Space.s5)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(OnbCopy.string("onb.s12.statement_line"))
            if let offer = selectedOffer { Text(legalText(offer)) }
        }
        .font(BedrockFont.footnote)
        .foregroundStyle(BedrockColor.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .transaction { $0.animation = nil }
    }

    private var links: some View {
        let parts = OnbCopy.parts("onb.s12.links")
        return HStack(spacing: Space.s4) {
            LinkButton(title: parts.first ?? "", tone: .secondary) { restore() }
                .disabled(restoring)
            if parts.count > 1 {
                LinkButton(title: parts[1], tone: .secondary) { openURL(Legal.terms) }
            }
            if parts.count > 2 {
                LinkButton(title: parts[2], tone: .secondary) { openURL(Legal.privacy) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var otherPlansParts: [String] {
        guard let weekly else { return OnbCopy.parts("onb.s12.other_plans_sheet") }
        return fill("onb.s12.other_plans_sheet", weekly).components(separatedBy: " · ")
    }

    @ViewBuilder private var otherPlansSheet: some View {
        let parts = otherPlansParts
        let item: (Int) -> String = { parts.indices.contains($0) ? parts[$0] : "" }
        VStack(alignment: .leading, spacing: Space.s1) {
            HStack {
                Text(item(1)).font(BedrockFont.headline)
                Spacer()
                Text(item(2)).font(BedrockFont.subhead.weight(.semibold)).monospacedDigit()
            }
            .foregroundStyle(BedrockColor.inkPrimary)
            Text(item(3))
                .font(BedrockFont.footnote)
                .foregroundStyle(BedrockColor.inkSecondary)
        }
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
        .accessibilityElement(children: .combine)
        VStack(spacing: Space.s2) {
            PrimaryButton(title: item(4)) {
                select(.weekly)
                otherPlansShown = false
            }
            TextButton(title: item(5), fullWidth: true) { otherPlansShown = false }
        }
        .padding(.top, Space.s3)
    }

    // MARK: Helpers

    /// A template with this offer's StoreKit values in place.
    private func fill(_ key: String, _ offer: PaywallService.StrictOffer) -> String {
        OnbCopy.string(key)
            .replacingOccurrences(of: "{price}", with: offer.price)
            .replacingOccurrences(of: "{monthly}", with: offer.monthly ?? offer.price)
            .replacingOccurrences(of: "{days}", with: "\(offer.trialDays ?? 0)")
    }

    private func legalText(_ offer: PaywallService.StrictOffer) -> String {
        switch offer.plan {
        case .yearly: fill(offer.trialDays != nil ? "onb.s12.legal_trial" : "onb.s12.legal_yearly", offer)
        case .lifetime: fill("onb.s12.legal_lifetime", offer)
        case .weekly: fill("onb.s12.legal_weekly", offer)
        }
    }

    private func planLabel(_ title: String, _ price: String, _ detail: String) -> String {
        OnbCopy.string("onb.s12.a11y_plan")
            .replacingOccurrences(of: "{title}", with: title)
            .replacingOccurrences(of: "{price}", with: price)
            .replacingOccurrences(of: "{detail}", with: detail)
    }

    // MARK: Actions

    private func select(_ choice: StrictPlan) {
        guard plan != choice else { return }
        plan = choice
        notice = nil
        flow.track(.planSelected(choice.analytics))
    }

    private func trackViewed() {
        guard !viewedTracked else { return }
        viewedTracked = true
        let variant: PaywallVariant = isLateNight ? .lateNight : (yearly?.trialDays == nil ? .noTrial : .standard)
        flow.track(.paywallViewed(variant, holder: holder.analytics, trialEligible: yearly?.trialDays != nil))
    }

    private func buy() {
        notice = nil
        let chosen = plan
        flow.track(.purchaseStarted(chosen.analytics))
        Task {
            switch await paywall.buy(chosen) {
            case .success(let trial):
                flow.track(.purchaseResult(.success, plan: chosen.analytics, trial: trial != nil))
                BedrockHaptics.purchased()
                flow.update { $0.paywallOutcome = .purchased }
                if let trial { await Reminders.scheduleTrialReminder(trialDays: trial) }
                succeeded = true
                try? await Task.sleep(for: .seconds(SuccessMoment.duration))
                flow.go(services.auth.isSignedIn ? .s13_1 : .siwa)
            case .cancelled:
                flow.track(.purchaseResult(.cancelled, plan: chosen.analytics, trial: false))
            case .pending:
                flow.track(.purchaseResult(.pending, plan: chosen.analytics, trial: false))
                notice = .pending
            case .failed:
                flow.track(.purchaseResult(.failed, plan: chosen.analytics, trial: false))
                notice = .failed
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            let outcome = await paywall.restorePurchases()
            restoring = false
            flow.track(.restoreResult(found: outcome == .found))
            switch outcome {
            case .found:
                flow.toast = OnbCopy.string("onb.s12.restore_found")
                flow.update { $0.paywallOutcome = .purchased }
                if !flow.state.strictSealed { flow.go(.s13_1) }
            case .none:
                flow.toast = OnbCopy.string("onb.s12.restore_none")
            case .failed:
                flow.toast = OnbCopy.string("onb.s12.error_offline")
            }
        }
    }

    private func remindTomorrow() {
        flow.track(.decideTomorrow)
        Task {
            await NotificationPermission.request()
            await Reminders.scheduleDecideTomorrow()
            flow.update { $0.paywallOutcome = .remindTomorrow }
            flow.toast = OnbCopy.string("onb.s12.toast")
            flow.afterFreeChoice()
        }
    }

    private func keepFree(_ via: FreeVia) {
        flow.track(.freePath(via))
        flow.update { $0.paywallOutcome = .free }
        flow.afterFreeChoice()
    }
}

/// “You're in.” Carves in over first light and holds 1.2s.
private struct SuccessMoment: View {
    static let duration = 0.6 + BedrockTiming.successHold

    var body: some View {
        ZStack {
            OnboardingBackdrop(level: 1)
            CarveText(OnbCopy.string("onb.s12.success"), font: BedrockFont.displayXL)
                .foregroundStyle(BedrockColor.inkPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .onAppear { AccessibilityNotification.Announcement(OnbCopy.string("onb.s12.success")).post() }
    }
}

/// A short inline notice (purchase errors, offers unavailable).
private struct NoticeText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(BedrockFont.subhead)
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Space.s3)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
    }
}

/// Terms and privacy, on thebedrock.app.
enum Legal {
    static let terms = URL(string: "https://thebedrock.app/terms")!
    static let privacy = URL(string: "https://thebedrock.app/privacy")!
    static let subscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

// MARK: - S12U · Not ready on this iPhone

struct NotReadyScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        OnboardingScaffold(.s12u, flow: flow) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.s12u.eyebrow"),
                          headline: OnbCopy.string("onb.s12u.headline"),
                          text: OnbCopy.string("onb.s12u.body"))
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s12u.primary")) {
                    flow.track(.action(.remindAfterUpdate))
                    flow.update { $0.paywallOutcome = .waitingForUpdate }
                    flow.afterFreeChoice()
                }
                TextButton(title: OnbCopy.string("onb.s12u.secondary"), fullWidth: true) {
                    flow.track(.action(.keepFree))
                    flow.update { $0.paywallOutcome = .free }
                    flow.afterFreeChoice()
                }
            }
        }
        .task { flow.track(.paywallViewed(.unsupported, holder: flow.state.keyHolder?.analytics, trialEligible: false)) }
    }
}

// MARK: - SIWA · Keep it if you change phones

struct SignInScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    var body: some View {
        OnboardingScaffold(.siwa, flow: flow, back: false) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.siwa.eyebrow"),
                          headline: OnbCopy.string("onb.siwa.headline"),
                          text: OnbCopy.string("onb.siwa.body"))
        } footer: {
            VStack(spacing: Space.s2) {
                // The opaque Apple user identifier only: no name, no email.
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = []
                } onCompletion: { result in
                    Task { await signedIn(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: BedrockSize.primaryHeight)
                .clipShape(Capsule())
                TextButton(title: OnbCopy.string("onb.siwa.secondary"), fullWidth: true) {
                    flow.track(.siwaResult(.skipped))
                    flow.go(.s13_1)
                }
            }
        }
    }

    private func signedIn(_ result: Result<ASAuthorization, Error>) async {
        if case .failure(let error) = result, (error as? ASAuthorizationError)?.code == .canceled {
            flow.track(.siwaResult(.cancelled))
        } else {
            let ok = await services.auth.handle(result)
            flow.track(.siwaResult(ok ? .success : .error))
        }
        // Cancelled or failed: on to setup, silently.
        flow.go(.s13_1)
    }
}
