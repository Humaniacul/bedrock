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

    /// 22:00–04:59 local time.
    private var isLateNight: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour >= BedrockTiming.lateNightStart || hour < BedrockTiming.lateNightEnd
    }

    var body: some View {
        ZStack {
            OnboardingScaffold(.s12, flow: flow, back: false, top: ProtoLayout.topWithChapter,
                               bottom: ProtoLayout.bottomTight,
                               onClose: { keepFree(.close) },
                               closeLabel: OnbCopy.string("onb.s12.free_path")) {
                content
            }
            if succeeded {
                SuccessMoment()
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.reducedFade, value: succeeded)
        .bedrockSheet(isPresented: $otherPlansShown, title: otherPlansParts.first ?? "", titleGap: 18) {
            otherPlansSheet
        }
        .task {
            await paywall.loadOffers()
            trackViewed()
        }
    }

    // MARK: Content

    /// The whole page scrolls, the CTA included, as the prototype has it.
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: OnbCopy.string("onb.s12.eyebrow"), color: BedrockColor.emberGlow)
                .padding(.bottom, Space.s3)
            Text(OnbCopy.string("onb.s12.headline"))
                .ptype(.display)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 10)
            Text(OnbCopy.string(holder == .partner ? "onb.s12.subhead_b" : "onb.s12.subhead_a"))
                .ptype(.body)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
            outcomes
                .padding(.bottom, 22)
            plans
            if trialDays != nil, plan == .yearly, let yearly {
                timeline(yearly)
                    .padding(.top, 2)
                    .padding(.bottom, 18)
            }
            ctaGroup
            if isLateNight { lateNight.padding(.top, 6) }
            Text(OnbCopy.string("onb.s12.trust_line"))
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 10)
            legal
                .padding(.bottom, 10)
            links
            CrisisLink(type: .captionPlain, height: 36) { flow.showsCrisis = true }
                .frame(maxWidth: .infinity)
                .padding(.top, Space.s1)
        }
    }

    /// Four outcomes, each behind a small ember diamond.
    private var outcomes: some View {
        let keys = ["onb.s12.outcome_1", "onb.s12.outcome_2",
                    holder == .partner ? "onb.s12.outcome_3_b" : "onb.s12.outcome_3_a", "onb.s12.outcome_4"]
        return VStack(alignment: .leading, spacing: Space.s3) {
            ForEach(keys.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: Space.s3) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(BedrockColor.ember)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                        .padding(.top, 5)
                        .frame(width: 22, alignment: .leading)
                        .accessibilityHidden(true)
                    Text(OnbCopy.string(keys[index]))
                        .ptype(.bodyM)
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
            VStack(spacing: 0) {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: Space.s5))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
                layout {
                    if let yearly { yearlyCard(yearly) }
                    if let lifetime { lifetimeCard(lifetime) }
                }
                if plan == .weekly, let weekly {
                    weeklyRow(weekly)
                        .padding(.top, 10)
                }
                if weekly != nil {
                    LinkButton(title: OnbCopy.string("onb.s12.link"), tone: .secondary, height: 36) {
                        flow.track(.otherPlansOpened)
                        otherPlansShown = true
                    }
                    .padding(.top, 6)
                    .padding(.bottom, Space.s1)
                }
            }
            .frame(maxWidth: .infinity)
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
                        badge: OnbCopy.string("onb.s12.lifetime_badge"), badgeStyle: .deep,
                        isSelected: plan == .lifetime,
                        accessibilityText: planLabel(title, offer.price, detail)) { select(.lifetime) }
    }

    /// The selected weekly plan, as a row under the two cards (both unselected).
    private func weeklyRow(_ offer: PaywallService.StrictOffer) -> some View {
        Text(fill("onb.s12.weekly_selected", offer))
            .ptype(.subheadPlain)
            .foregroundStyle(BedrockColor.inkPrimary)
            .transaction { $0.animation = nil }
            .padding(.horizontal, 14)
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.emberWash))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(BedrockColor.ember, lineWidth: 1.5))
            .accessibilityAddTraits(.isSelected)
    }

    /// Today · In 2 days · In 3 days: a 10pt dot, a 90pt label, the line.
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
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(alignment: .center, spacing: 10) {
                    timelineDot(index == 0 ? .filled : (index == rows.count - 1 ? .end : .ring))
                        .frame(width: 16, alignment: .leading)
                    Text(rows[index].first ?? "")
                        .ptype(PType(face: .sans, size: 14, line: nil, weight: .semibold, relativeTo: .footnote))
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .frame(width: 90, alignment: .leading)
                    Text(rows[index].dropFirst().joined(separator: " · "))
                        .ptype(.notePlain)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transaction { $0.animation = nil }
                }
            }
        }
        .padding(.leading, Space.s1)
        .accessibilityElement(children: .combine)
    }

    private enum DotStyle { case filled, ring, end }

    private func timelineDot(_ style: DotStyle) -> some View {
        Circle()
            .fill(style == .filled ? BedrockColor.ember : .clear)
            .overlay {
                if style != .filled {
                    Circle().strokeBorder(style == .ring ? BedrockColor.ember : BedrockColor.inkTertiary, lineWidth: 1.5)
                }
            }
            .frame(width: 10, height: 10)
            .accessibilityHidden(true)
    }

    private var ctaGroup: some View {
        VStack(spacing: 0) {
            if let notice {
                NoticeText(text: OnbCopy.string(notice == .failed ? "onb.s12.error_failed" : "onb.s12.error_pending"))
                    .padding(.bottom, Space.s3)
            }
            PrimaryButton(title: notice == .failed ? OnbCopy.string("onb.s12.error_retry") : ctaTitle,
                          isEnabled: paywall.offersState == .ready && selectedOffer != nil,
                          isLoading: paywall.isPurchasing) { buy() }
                .contentTransition(.opacity)
                .animation(BedrockMotion.ctaCrossfade, value: plan)
            Text(OnbCopy.string("onb.s12.under_cta"))
                .ptype(.footnote)
                .foregroundStyle(BedrockColor.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            TextButton(title: OnbCopy.string("onb.s12.free_path"), type: .calloutMedium, height: 48) { keepFree(.button) }
                .padding(.top, Space.s1)
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

    /// 22:00–04:59: “It's late. You don't have to decide tonight.” and a pill.
    private var lateNight: some View {
        let parts = OnbCopy.parts("onb.s12.late_night")
        return VStack(alignment: .leading, spacing: 10) {
            Text(parts.first ?? "")
                .ptype(.quote)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
            PillButton(title: parts.last ?? "", height: 40, padding: Space.s4) { remindTomorrow() }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Space.s4, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Space.s4, style: .continuous).strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
    }

    /// “Your bank statement shows Apple.” and the plan's terms: 11.5/16 Ash.
    private var legal: some View {
        let statement = OnbCopy.string("onb.s12.statement_line")
        let terms = selectedOffer.map(legalText) ?? ""
        return Text(terms.isEmpty ? statement : "\(statement) \(terms)")
            .ptype(.legal)
            .foregroundStyle(BedrockColor.inkTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .transaction { $0.animation = nil }
    }

    /// Restore purchases · Terms · Privacy: 12.5pt Limestone, dots in #4A4540.
    private var links: some View {
        let parts = OnbCopy.parts("onb.s12.links")
        let actions: [() -> Void] = [restore, { openURL(Legal.terms) }, { openURL(Legal.privacy) }]
        return HStack(spacing: Space.s1) {
            ForEach(parts.indices, id: \.self) { index in
                if index > 0 {
                    Text(verbatim: "·")
                        .ptype(.captionPlain)
                        .foregroundStyle(BedrockColor.lineMuted)
                        .accessibilityHidden(true)
                }
                Button(action: actions.indices.contains(index) ? actions[index] : {}) {
                    Text(parts[index])
                        .ptype(.captionPlain)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .padding(.horizontal, Space.s2)
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressOpacityStyle())
                .disabled(index == 0 && restoring)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var otherPlansParts: [String] {
        guard let weekly else { return OnbCopy.parts("onb.s12.other_plans_sheet") }
        return fill("onb.s12.other_plans_sheet", weekly).components(separatedBy: " · ")
    }

    /// One card (Slate, radius 18, a 1.5pt Fault edge), Choose weekly, Close.
    @ViewBuilder private var otherPlansSheet: some View {
        let parts = otherPlansParts
        let item: (Int) -> String = { parts.indices.contains($0) ? parts[$0] : "" }
        VStack(alignment: .leading, spacing: Space.s1) {
            Text(item(1))
                .ptype(.subheadSemibold)
                .foregroundStyle(BedrockColor.inkPrimary)
            Text(item(2))
                .ptype(.option)
                .foregroundStyle(BedrockColor.inkPrimary)
            Text(item(3))
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.inkSecondary)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous).fill(BedrockColor.bgRaised))
        .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
            .strokeBorder(BedrockColor.lineStrong, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        PrimaryButton(title: item(4)) {
            select(.weekly)
            otherPlansShown = false
        }
        .padding(.top, 22)
        TextButton(title: item(5)) { otherPlansShown = false }
            .padding(.top, ProtoLayout.buttonGap)
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

/// “You're in.”: serif 52 carved on Obsidian; holds 1.2s.
private struct SuccessMoment: View {
    static let duration = 0.6 + BedrockTiming.successHold

    var body: some View {
        ZStack {
            BedrockColor.bgBase.ignoresSafeArea()
            CarveText(OnbCopy.string("onb.s12.success"))
                .ptype(PType(face: .serif, size: 52, line: nil, relativeTo: .largeTitle))
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
            .ptype(.note)
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
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
        OnboardingScaffold(.s12u, flow: flow, back: false,
                           onClose: keepFree, closeLabel: OnbCopy.string("onb.s12u.secondary")) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.s12u.eyebrow"),
                          eyebrowColor: BedrockColor.emberGlow,
                          headline: OnbCopy.string("onb.s12u.headline"),
                          text: OnbCopy.string("onb.s12u.body"))
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s12u.primary")) {
                    flow.track(.action(.remindAfterUpdate))
                    flow.update { $0.paywallOutcome = .waitingForUpdate }
                    flow.afterFreeChoice()
                }
                TextButton(title: OnbCopy.string("onb.s12u.secondary"), action: keepFree)
            }
        }
        .task { flow.track(.paywallViewed(.unsupported, holder: flow.state.keyHolder?.analytics, trialEligible: false)) }
    }

    private func keepFree() {
        flow.track(.action(.keepFree))
        flow.update { $0.paywallOutcome = .free }
        flow.afterFreeChoice()
    }
}

// MARK: - SIWA · Keep it if you change phones

struct SignInScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    var body: some View {
        OnboardingScaffold(.siwa, flow: flow, back: false) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.siwa.eyebrow"),
                          eyebrowColor: BedrockColor.emberGlow,
                          headline: OnbCopy.string("onb.siwa.headline"),
                          text: OnbCopy.string("onb.siwa.body"))
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                // The opaque Apple user identifier only: no name, no email.
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = []
                } onCompletion: { result in
                    Task { await signedIn(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: BedrockSize.primaryHeight)
                .clipShape(Capsule())
                TextButton(title: OnbCopy.string("onb.siwa.secondary")) {
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
