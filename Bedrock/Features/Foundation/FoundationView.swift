import SwiftUI

/// The home screen (§7). The monolith + carved day count over stone, with a
/// floating glass HUD for status and SOS. The hero number is `foundationDays`
/// — the bedrock you've built, which never shrinks (§6.4).
struct FoundationView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Hero numerals scale with Dynamic Type via @ScaledMetric (§6.2 / quality bar).
    @ScaledMetric(relativeTo: .largeTitle) private var counterSize = Theme.Typography.Size.counter

    private var streak: StreakStore { services.streak }

    var body: some View {
        ZStack(alignment: .top) {
            StoneBackground(emberGlow: glow)
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: Theme.Spacing.xl)
                FoundationMonolith(foundationDays: streak.foundationDays, hasCrack: streak.hasCrack)
                counter
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.xl)

            #if DEBUG
            debugStrip
            #endif
        }
        // Float the HUD in the bottom safe-area inset so it clears the Liquid
        // Glass tab bar (which content otherwise scrolls behind).
        .safeAreaInset(edge: .bottom) {
            statusHUD
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.sm)
        }
        .onAppear { streak.refreshForToday() }
        .onChange(of: streak.foundationDays) { oldValue, newValue in
            if newValue > oldValue { BedrockHaptics.set() }
        }
        .onChange(of: streak.currentMilestone?.day) { oldValue, newValue in
            if let newValue, newValue != oldValue { BedrockHaptics.milestone() }
        }
    }

    // Brighten the molten core as the foundation rises.
    private var glow: Double {
        min(0.10 + Double(streak.foundationDays) * 0.008, 0.28)
    }

    private var counter: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(streak.foundationDays)")
                .font(.system(size: counterSize, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(streak.foundationDays == 1 ? "DAY ON BEDROCK" : "DAYS ON BEDROCK")
                .font(Theme.Typography.monoCaption)
                .tracking(2)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak.foundationDays) \(streak.foundationDays == 1 ? "day" : "days") on Bedrock")
    }

    private var statusHUD: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(services.blocking.isProtected ? "Protection active" : "Protection off")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(milestoneLine)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: Theme.Spacing.md)
                    Button {
                        // Phase 4: opens the Intercept / Panic flow.
                    } label: {
                        Text("SOS").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bedrockGlass)
                    .frame(width: 96)
                    .accessibilityLabel("SOS — open an urge-surf session")
                }
                if streak.hasCrack {
                    crackBanner
                }
            }
        }
    }

    private var milestoneLine: String {
        if let next = streak.nextMilestone {
            let toGo = next.day - streak.foundationDays
            return "Next: \(next.name) · \(toGo) \(toGo == 1 ? "day" : "days") to go"
        }
        return "Every layer named. Keep building."
    }

    private var crackBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bandage.fill").foregroundStyle(Theme.accent)
            Text("A layer cracked. The foundation holds.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Spacing.sm)
            Button("Repair") { streak.repairCrack() }
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    #if DEBUG
    private var debugStrip: some View {
        HStack(spacing: Theme.Spacing.sm) {
            debugButton("+ Day") { streak.debugAdvanceDay() }
            debugButton("Relapse") { streak.recordRelapse() }
            debugButton("Repair") { streak.repairCrack() }
            debugButton("Reset") { streak.debugReset() }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Capsule().fill(BedrockColor.slate.opacity(0.85)))
        .padding(.top, 52)
    }

    private func debugButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Theme.textSecondary)
            .buttonStyle(.plain)
    }
    #endif
}

#Preview {
    FoundationView().environment(AppServices.makeStub())
}
