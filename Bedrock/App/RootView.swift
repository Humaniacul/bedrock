import Foundation
import SwiftUI

enum AppTab: Hashable {
    case foundation, protection, partner, insights, settings
}

/// The root: First Light until it's finished (or left with Finish later), the
/// supporter home for someone who only holds a key, then the native `TabView`
/// with the Liquid Glass tab bar. Handles invite links (thebedrock.app/join/CODE)
/// and notification taps, and refreshes the streak on foreground.
struct RootView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = RootView.initialTab
    @State private var route: Route = RootView.currentRoute()
    /// A flow over whatever is showing: an invite link, the “decide tomorrow” reminder.
    @State private var launch: FlowLaunch?
    @State private var notifications = NotificationRouter.shared
    /// “I need a minute” from the shield opens the urge flow.
    @State private var showIntercept = false

    enum Route: Equatable { case onboarding, supporter, app }

    var body: some View {
        app
    }

    private var app: some View {
        ZStack {
            switch route {
            case .onboarding:
                FirstLightView(mode: .firstRun) { _ in refreshRoute() }
                    .transition(.opacity)
            case .supporter:
                SupporterHomeView(standalone: true,
                                  onBuildWall: startOwnWall,
                                  onAddPerson: { launch = FlowLaunch(mode: .supporter(code: nil)) })
                    .transition(.opacity)
            case .app:
                mainTabs
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.dawn, value: route)
        .fullScreenCover(item: $launch, onDismiss: refreshRoute) { launch in
            FirstLightView(mode: launch.mode) { _ in self.launch = nil }
                .environment(services)
        }
        .fullScreenCover(isPresented: $showIntercept) { InterceptView().environment(services) }
        .onOpenURL(perform: open)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { open(url) }
        }
        .onChange(of: notifications.deviceToken) { _, token in
            guard let token else { return }
            Task { await services.accountability.registerPushToken(token) }
        }
        .onChange(of: notifications.pending) { _, pending in
            guard let pending else { return }
            notifications.pending = nil
            handleNotification(pending)
        }
        .task {
            #if DEBUG
            // Open a side flow directly for testing: SIMCTL_CHILD_BEDROCK_DEBUG_FLOW=
            // upgrade | paywall | finishSetup | rebuildWall | supporter.
            if let flow = ProcessInfo.processInfo.environment["BEDROCK_DEBUG_FLOW"] {
                unsetenv("BEDROCK_DEBUG_FLOW")
                switch flow {
                case "upgrade": launch = FlowLaunch(mode: .upgrade)
                case "paywall": launch = FlowLaunch(mode: .paywall)
                case "finishSetup": launch = FlowLaunch(mode: .finishSetup)
                case "rebuildWall": launch = FlowLaunch(mode: .rebuildWall)
                case "supporter": launch = FlowLaunch(mode: .supporter(code: nil))
                default: break
                }
            }
            #endif
            await services.accountability.refresh()
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "square.3.layers.3d.down.right", value: AppTab.foundation) {
                HomeView()
            }
            Tab("Protection", systemImage: "shield.fill", value: AppTab.protection) {
                ProtectionView()
            }
            // Accountability + insights are premium (§8); the wall itself is free.
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
            ShieldStats.flush()
            Task {
                await services.paywall.refresh()
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
        }
    }

    // MARK: Routing

    private func refreshRoute() {
        route = Self.currentRoute()
    }

    /// First run until it's finished or left with Finish later. Someone who only
    /// came to hold a key (paired, never started their own) gets the supporter home.
    static func currentRoute() -> Route {
        #if DEBUG
        // Force the first-run flow for testing: SIMCTL_CHILD_BEDROCK_FORCE_ONBOARDING=1.
        if ProcessInfo.processInfo.environment["BEDROCK_FORCE_ONBOARDING"] == "1" {
            FirstLightState.clear()
            unsetenv("BEDROCK_FORCE_ONBOARDING")
            return .onboarding
        }
        #endif
        if FirstLightState.isComplete { return .app }
        guard let state = FirstLightState.load() else { return .onboarding }
        if state.finishedLater { return .app }
        let ownStarted = state.history.contains { $0 != ScreenID.s1.rawValue && !$0.hasPrefix("sp") }
        if state.supporterPaired && !ownStarted { return .supporter }
        return .onboarding
    }

    /// The supporter wants a wall of their own: first run from S1.
    private func startOwnWall() {
        var state = FirstLightState.load() ?? FirstLightState()
        state.screen = ScreenID.s1.rawValue
        state.history = []
        state.save()
        route = .onboarding
    }

    /// thebedrock.app/join/CODE (universal link) or bedrock://join/CODE.
    private func open(_ url: URL) {
        let parts = url.pathComponents.filter { $0 != "/" }
        let joinIndex = url.scheme == "bedrock" ? (url.host() == "join" ? -1 : nil) : parts.firstIndex(of: "join")
        guard let joinIndex else { return }
        let codeIndex = joinIndex + 1
        let code = parts.indices.contains(codeIndex) ? parts[codeIndex] : nil
        launch = FlowLaunch(mode: .supporter(code: code?.uppercased()))
    }

    private func handleNotification(_ route: String) {
        switch route {
        case "paywall":
            guard self.route == .app, !services.paywall.isPremium else { return }
            launch = FlowLaunch(mode: .paywall)
        case "subscriptions":
            UIApplication.shared.open(Legal.subscriptions)
        case "intercept":
            guard self.route == .app else { return }
            selection = .foundation
            showIntercept = true
        default:
            selection = .foundation
            if self.route == .app {
                Analytics.track(.headsupOpened, screen: .home, startedAt: FirstLightState.load()?.startedAt)
            }
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
