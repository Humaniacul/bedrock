import SwiftUI

/// A premium-only surface, used to frame the paywall when a free user reaches it.
enum PremiumFeature {
    case strictMode, accountability, insights, general

    var headline: String {
        switch self {
        case .strictMode: "Make it unbreakable."
        case .accountability: "Don't do this alone."
        case .insights: "See it coming."
        case .general: "Unlock the full foundation."
        }
    }
    var blurb: String {
        switch self {
        case .strictMode: "Strict Mode locks protection behind a wall even you can't tear down in a weak moment."
        case .accountability: "Bring in a partner who's quietly got your back — and a gauntlet that calls them when it counts."
        case .insights: "Bedrock learns your danger windows and helps you get ahead of them."
        case .general: "Strict Mode, an accountability partner, and the intelligence that sees your danger windows coming."
        }
    }
}

enum PaywallContext {
    /// Onboarding S27 — the ask as the conclusion of the commitment ladder.
    case onboarding(why: String, bestSelfWord: String)
    case gate(PremiumFeature)
}

/// The crossing (spec S27). Reached only after the user has built a foundation
/// with his own hands — outcomes, trust, price on one screen. NO fake timers,
/// NO fake discounts, NO countdowns: the trust built across the flow is the
/// lever. Also shown as a sheet when a free user reaches a premium feature.
struct PaywallView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let context: PaywallContext
    /// Onboarding passes this to advance on success or honest skip.
    var onContinue: (() -> Void)? = nil

    @State private var selectedPlanID: String?
    @State private var showError = false
    @State private var emberFlood = false

    private var plans: [PaywallService.Plan] { services.paywall.plans }
    private var selectedPlan: PaywallService.Plan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    /// What becomes possible — outcomes, NOT features (the user infers).
    private let outcomes: [String] = [
        "The wall stays up — even at 2am, even when you'd take it down.",
        "When the urge hits, your own words meet it.",
        "You watch the groove fill in, day by day.",
        "On the hard days, you're not holding the line alone.",
        "Mornings that start with you.",
    ]

    /// Dissolves the two real objections: exposure and scam.
    private let trustRow: [(icon: String, text: String)] = [
        ("iphone.and.arrow.forward.inward", "Private by design — your data never leaves your device."),
        ("heart.fill", "No shame, ever — slip up and Bedrock holds the line."),
        ("checkmark.seal", "Cancel anytime. No tricks, no countdowns."),
    ]

    private let gatePillars: [(icon: String, title: String)] = [
        ("lock.fill", "Strict Mode — a lock you can't undo in a weak moment"),
        ("person.2.fill", "An accountability partner who's got your back"),
        ("eye.fill", "Insight that sees your danger windows coming"),
    ]

    var body: some View {
        ZStack {
            StoneBackground(emberGlow: 0.28)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        switch context {
                        case .onboarding(let why, let word):
                            crossingHeader(why: why, bestSelfWord: word)
                            outcomeList
                            trustList
                            statPills
                            planCards
                        case .gate:
                            gateHeader
                            gatePillarList
                            planCards
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.md)
                }
                bottomBar
            }
            // On purchase: ember floods the foundation — permanent now.
            if emberFlood {
                RadialGradient(colors: [BedrockColor.emberGlow.opacity(0.5), Theme.accent.opacity(0.25), .clear],
                               center: .bottom, startRadius: 20, endRadius: 700)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { if selectedPlanID == nil { selectedPlanID = plans.first?.id } }
        .alert("Couldn't complete the purchase", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("In-app purchases aren't available right now. You can keep going with basic blocking and upgrade later.")
        }
    }

    // MARK: - S27 header — the finished foundation, crowned

    private func crossingHeader(why: String, bestSelfWord: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            FoundationWall(blocks: 5, capstone: bestSelfWord)
                .frame(maxWidth: .infinity)
                .breath(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Make the foundation permanent.")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !why.trimmingCharacters(in: .whitespaces).isEmpty,
                   let firstLine = why.split(separator: "\n").first {
                    Text("“\(firstLine)” — your words, carved this morning. Here's what keeps them standing.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .settleIn(reduceMotion: reduceMotion)
    }

    private var outcomeList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(Array(outcomes.enumerated()), id: \.offset) { index, outcome in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
                    Rectangle()
                        .fill(Theme.accent.opacity(0.8))
                        .frame(width: 3, height: 18)
                        .clipShape(Capsule())
                    Text(outcome)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(BedrockColor.slate.opacity(0.45)))
                .strata(index, reduceMotion: reduceMotion) // each rises as a lit stratum
            }
        }
    }

    private var trustList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(Array(trustRow.enumerated()), id: \.offset) { _, item in
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 20)
                    Text(item.text)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// ⚠️ MOCK values (OnboardingStat) — // VERIFY BEFORE LAUNCH or remove.
    private var statPills: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach([OnboardingStat.rating, OnboardingStat.rebuilding, OnboardingStat.holding], id: \.self) { stat in
                Text(stat)
                    .font(Theme.Typography.monoCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
            }
        }
    }

    // MARK: - Gate header (unchanged behavior)

    private var gateHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if case .gate(let feature) = context {
                Text(feature.headline)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(feature.blurb)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .settleIn(reduceMotion: reduceMotion)
    }

    private var gatePillarList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(Array(gatePillars.enumerated()), id: \.offset) { index, pillar in
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: pillar.icon)
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                    Text(pillar.title)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .strata(index, reduceMotion: reduceMotion)
            }
        }
    }

    // MARK: - Plans (live from RevenueCat; honest fallbacks)

    private var planCards: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(plans) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: PaywallService.Plan) -> some View {
        let selected = selectedPlanID == plan.id
        return Button {
            BedrockHaptics.selection()
            selectedPlanID = plan.id
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(plan.title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.textPrimary)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(.caption2, design: .monospaced).weight(.bold))
                                .tracking(1)
                                .foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent))
                        }
                    }
                    Text(plan.caption)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(plan.price)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.textPrimary)
                    if let perWeek = plan.perWeek {
                        Text(perWeek)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(BedrockColor.slate.opacity(selected ? 0.8 : 0.4)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.title), \(plan.price)\(plan.unit). \(plan.caption)")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Bottom bar (CTA + honest exit + legal)

    private var bottomBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: purchase) {
                Group {
                    if services.paywall.isPurchasing {
                        ProgressView().tint(Theme.onAccent)
                    } else {
                        Text(ctaTitle).frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bedrockPrimary)
            .disabled(services.paywall.isPurchasing)

            Text(trustLine)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            if isOnboarding, let plan = selectedPlan {
                // The honest anchor — no urgency theater.
                Text("\(plan.price) — less than a month of the hours you're getting back.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Theme.Spacing.lg) {
                Button(secondaryTitle) { skip() }
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                Button("Restore") { Task { _ = await services.paywall.restore(); resolveIfPremium() } }
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 2)

            PaywallLegalFooter()
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
        // Reduce Transparency → solid surface instead of the glass material (§10).
        .background(reduceTransparency ? AnyShapeStyle(BedrockColor.basalt) : AnyShapeStyle(.ultraThinMaterial))
    }

    private var isOnboarding: Bool {
        if case .onboarding = context { return true }
        return false
    }

    private var ctaTitle: String {
        guard let plan = selectedPlan else { return "Continue" }
        if plan.hasTrial { return "Start my free trial" }
        if plan.isLifetime { return "Decide once — \(plan.price)" }
        return "Begin — \(plan.price)\(plan.unit)"
    }

    private var trustLine: String {
        guard let plan = selectedPlan else { return "Cancel anytime." }
        if let trial = plan.trialText { return "\(trial), then \(plan.price)\(plan.unit). Cancel in two taps." }
        if plan.isLifetime { return "One-time \(plan.price). Yours forever." }
        return "\(plan.price)\(plan.unit). Cancel in two taps."
    }

    private var secondaryTitle: String {
        // Honest soft exit — no guilt copy.
        if isOnboarding { return "Continue with basic blocking — free, forever" }
        return "Not now"
    }

    // MARK: - Actions

    private func purchase() {
        guard let plan = selectedPlan else { return }
        Task {
            let ok = await services.paywall.purchase(plan)
            if ok {
                BedrockHaptics.milestone()
                withAnimation(.easeIn(duration: reduceMotion ? 0 : 0.5)) { emberFlood = true }
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 900))
                resolveSuccess()
            } else {
                showError = true
            }
        }
    }

    private func resolveIfPremium() {
        if services.paywall.isPremium { resolveSuccess() }
    }

    private func resolveSuccess() {
        if let onContinue { onContinue() } else { dismiss() }
    }

    private func skip() {
        if let onContinue { onContinue() } else { dismiss() }
    }
}

/// Auto-renew terms + the links Apple expects — quiet, complete, honest.
struct PaywallLegalFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Subscriptions auto-renew until cancelled; your Apple Account is charged at confirmation. Manage or cancel in Settings → Subscriptions.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            HStack(spacing: Theme.Spacing.md) {
                Link("Terms", destination: URL(string: "https://thebedrock.app/terms")!)
                Link("Privacy", destination: URL(string: "https://thebedrock.app/privacy")!)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 2)
    }
}

#Preview("Onboarding") {
    PaywallView(context: .onboarding(why: "To be present for my kids.", bestSelfWord: "present"))
        .environment(AppServices.makeStub())
}

#Preview("Gate") {
    PaywallView(context: .gate(.strictMode))
        .environment(AppServices.makeStub())
}
