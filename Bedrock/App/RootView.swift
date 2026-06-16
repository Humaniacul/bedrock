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

    var body: some View {
        TabView(selection: $selection) {
            Tab("Foundation", systemImage: "square.3.layers.3d.down.right", value: AppTab.foundation) {
                FoundationView()
            }
            Tab("Protection", systemImage: "shield.fill", value: AppTab.protection) {
                ProtectionView()
            }
            Tab("Partner", systemImage: "person.2.fill", value: AppTab.partner) {
                PartnerView()
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: AppTab.insights) {
                PlaceholderScreen(title: "Insights", phase: "Phase 4")
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                PlaceholderScreen(title: "Settings", phase: "Phase 0+")
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
            // Initial sync on launch.
            await services.heartbeat.sync(
                protectionActive: services.blocking.isProtected,
                strictEnabled: services.strictMode.isEnabled
            )
            await services.accountability.refresh()
        }
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
