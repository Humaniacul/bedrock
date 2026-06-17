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
    case onboarding(why: String)
    case gate(PremiumFeature)
}

/// The conversion screen (§8). Shown as the climax of onboarding (value-first,
/// skippable) and as a sheet when a free user reaches a premium feature.
/// Converts on belief — framed around the user's own stated "why" — never on
/// pressure or dark patterns.
struct PaywallView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let context: PaywallContext
    /// Onboarding passes this to advance to the commit step on success or skip.
    var onContinue: (() -> Void)? = nil

    @State private var selectedPlanID: String?
    @State private var showError = false

    private var plans: [PaywallService.Plan] { services.paywall.plans }
    private var selectedPlan: PaywallService.Plan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    private let pillars: [(icon: String, title: String)] = [
        ("lock.fill", "Strict Mode — a lock you can't undo in a weak moment"),
        ("person.2.fill", "An accountability partner who's got your back"),
        ("eye.fill", "Insight that sees your danger windows coming"),
    ]

    var body: some View {
        ZStack {
            StoneBackground(emberGlow: 0.3)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        if case .onboarding(let why) = context {
                            onboardingHeader(why: why)
                            planCards
                            cyclePromise
                        } else {
                            header
                            pillarList
                            planCards
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.md)
                }
                bottomBar
            }
        }
        .onAppear { if selectedPlanID == nil { selectedPlanID = plans.first?.id } }
        .alert("Couldn't start the trial", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("In-app purchases aren't available yet on this build. You can keep going with basic blocking.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(headline)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let sub = subhead {
                Text(sub)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .riseIn(0, reduceMotion: reduceMotion)
    }

    private var headline: String {
        switch context {
        case .onboarding: "Willpower got you here.\nIt won't get you out."
        case .gate(let feature): feature.headline
        }
    }

    private var subhead: String? {
        switch context {
        case .onboarding(let why):
            let trimmed = why.trimmingCharacters(in: .whitespacesAndNewlines)
            if let firstLine = trimmed.split(separator: "\n").first, !firstLine.isEmpty {
                return "You wrote: “\(firstLine)” — give it a foundation that holds when you can't."
            }
            return "Give your resolve a foundation that holds when you can't."
        case .gate(let feature):
            return feature.blurb
        }
    }

    // MARK: - Onboarding "threshold" header (§5 — mission, not features)

    private func onboardingHeader(why: String) -> some View {
        let trimmed = why.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = trimmed.split(separator: "\n").first.map(String.init)
        return VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            FoundationMonolith(foundationDays: 1, hasCrack: false)
                .frame(maxHeight: 150)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if let reason {
                    Text("“\(reason)”")
                        .font(.system(.title3, design: .serif, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(reason == nil
                     ? "Make your decision unbreakable."
                     : "Let's make sure nothing takes it from you again.")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("From tonight, you don't have to white-knuckle this alone. We've got the door — you just have to walk forward.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Your subscription doesn't make us rich — it keeps the lights on so the next man doesn't have to fight alone. You'd be joining something.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .riseIn(0, reduceMotion: reduceMotion)
    }

    private var cyclePromise: some View {
        Text("You've deleted blockers before. This is the one you keep.")
            .font(.system(.body, design: .serif, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Pillars

    private var pillarList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(Array(pillars.enumerated()), id: \.offset) { index, pillar in
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
                .riseIn(0.1 + Double(index) * 0.1, reduceMotion: reduceMotion)
            }
        }
    }

    // MARK: - Plans

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

    // MARK: - Bottom bar (CTA + trust + escape)

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

            HStack(spacing: Theme.Spacing.lg) {
                Button(secondaryTitle) { skip() }
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                Button("Restore") { Task { _ = await services.paywall.restore(); resolveIfPremium() } }
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
        // Reduce Transparency → solid surface instead of the glass material (§10).
        .background(reduceTransparency ? AnyShapeStyle(BedrockColor.basalt) : AnyShapeStyle(.ultraThinMaterial))
    }

    private var ctaTitle: String {
        guard let plan = selectedPlan else { return "Continue" }
        if let trial = plan.trialText { return "Start my \(trial)" }
        if plan.isLifetime { return "Unlock Lifetime — \(plan.price)" }
        return "Subscribe — \(plan.price)\(plan.unit)"
    }

    private var trustLine: String {
        guard let plan = selectedPlan else { return "Cancel anytime." }
        if let trial = plan.trialText { return "\(trial), then \(plan.price)\(plan.unit). Cancel anytime." }
        if plan.isLifetime { return "One-time \(plan.price). Yours forever." }
        return "\(plan.price)\(plan.unit). Cancel anytime."
    }

    private var secondaryTitle: String {
        if case .onboarding = context { return "Continue with basic blocking" }
        return "Not now"
    }

    // MARK: - Actions

    private func purchase() {
        guard let plan = selectedPlan else { return }
        Task {
            let ok = await services.paywall.purchase(plan)
            if ok {
                BedrockHaptics.milestone()
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

#Preview("Onboarding") {
    PaywallView(context: .onboarding(why: "To be present for my kids."))
        .environment(AppServices.makeStub())
}

#Preview("Gate") {
    PaywallView(context: .gate(.strictMode))
        .environment(AppServices.makeStub())
}
