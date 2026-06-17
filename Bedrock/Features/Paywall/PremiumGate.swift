import SwiftUI

/// Wraps a premium-only surface (§8). Free users see a locked state that opens
/// the paywall; premium users see the content. This only ever gates *viewing*
/// or *turning on* premium features — it never traps a user out of an off-switch.
struct PremiumGate: ViewModifier {
    @Environment(AppServices.self) private var services
    let feature: PremiumFeature
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if services.paywall.isPremium {
            content
        } else {
            PremiumLocked(feature: feature) { showPaywall = true }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(context: .gate(feature))
                }
        }
    }
}

extension View {
    func premiumGated(_ feature: PremiumFeature) -> some View {
        modifier(PremiumGate(feature: feature))
    }
}

/// The locked stand-in for a premium feature.
struct PremiumLocked: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let feature: PremiumFeature
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            StoneBackground()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text(feature.headline)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(feature.blurb)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Unlock with Premium") { onUnlock() }
                    .buttonStyle(.bedrockPrimary)
                    .padding(.top, Theme.Spacing.sm)
                Text("Basic blocking stays free, always.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
