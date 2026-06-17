import Foundation
import SwiftUI

enum AppTab: Hashable {
    case foundation, protection, partner, insights, settings
}

/// The root tab shell. Uses the native `TabView`, which gets the Liquid Glass
/// tab bar from the platform on the iOS 26 SDK (§6.3). Refreshes the streak on
/// foreground so clean days accrue while the app was closed.
struct RootView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = RootView.initialTab
    @State private var onboardingDone = RootView.startsOnboarded

    var body: some View {
        if onboardingDone {
            mainTabs
        } else {
            OnboardingView { withAnimation(.smooth) { onboardingDone = true } }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selection) {
            Tab("Foundation", systemImage: "square.3.layers.3d.down.right", value: AppTab.foundation) {
                FoundationView()
            }
            Tab("Protection", systemImage: "shield.fill", value: AppTab.protection) {
                ProtectionView()
            }
            // Accountability + insights are premium (§8); basic blocking is free.
            Tab("Partner", systemImage: "person.2.fill", value: AppTab.partner) {
                PartnerView().premiumGated(.accountability)
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: AppTab.insights) {
                InsightsView().premiumGated(.insights)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            services.streak.refreshForToday()
            Task {
                await services.heartbeat.sync(
                    protectionActive: services.blocking.isProtected,
                    strictEnabled: services.strictMode.isEnabled
                )
                await services.accountability.refresh()
            }
        }
        .task {
            #if DEBUG
            // Seed a realistic urge pattern so Insights can be explored on a
            // fresh install: SIMCTL_CHILD_BEDROCK_DEMO_SEED_TRIGGERS=1.
            if ProcessInfo.processInfo.environment["BEDROCK_DEMO_SEED_TRIGGERS"] == "1",
               services.triggers.events.isEmpty {
                services.triggers.debugSeedSamples()
            }
            #endif
            // Initial sync on launch.
            await services.heartbeat.sync(
                protectionActive: services.blocking.isProtected,
                strictEnabled: services.strictMode.isEnabled
            )
            await services.accountability.refresh()
        }
    }

    private static var startsOnboarded: Bool {
        #if DEBUG
        // Force the first-run flow for testing: SIMCTL_CHILD_BEDROCK_FORCE_ONBOARDING=1.
        if ProcessInfo.processInfo.environment["BEDROCK_FORCE_ONBOARDING"] == "1" { return false }
        #endif
        return OnboardingModel.isComplete
    }

    private static var initialTab: AppTab {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["BEDROCK_DEMO_TAB"] {
        case "protection": return .protection
        case "partner": return .partner
        case "insights": return .insights
        case "settings": return .settings
        default: return .foundation
        }
        #else
        return .foundation
        #endif
    }
}

#Preview {
    RootView().environment(AppServices.makeStub())
}
