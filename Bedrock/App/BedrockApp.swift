import SwiftUI

@main
struct BedrockApp: App {
    @State private var services = AppServices.makeLive()
    // Bumped after an account wipe to rebuild the whole view tree from a fresh
    // (empty) service graph — which lands the user back in onboarding.
    @State private var resetToken = UUID()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
                .id(resetToken)
                .preferredColorScheme(.dark) // Bedrock is dark by design (§6)
                .tint(Theme.accent)
                .task {
                    // RevenueCat tagged with our device id so the webhook can map
                    // entitlement back to the Supabase user (§3). No key → no-op.
                    services.paywall.configure(appUserID: DeviceIdentity.deviceId)
                    services.onWipe = { resetApp() }
                }
        }
    }

    /// Rebuild the service graph from scratch after a data wipe.
    private func resetApp() {
        services = AppServices.makeLive()
        resetToken = UUID()
    }
}
