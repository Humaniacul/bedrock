import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import Observation

/// The real blocking core (§4). Drives FamilyControls authorization, applies
/// `ManagedSettings` shields via the shared `ShieldApplier`, and starts a daily
/// `DeviceActivity` schedule so the monitor extension re-applies shields if they
/// are ever cleared.
///
/// Screen Time is inert in the Simulator, so calls are guarded with
/// `targetEnvironment(simulator)` to keep dev builds runnable and honest
/// (the UI shows an `.unavailable` state rather than pretending to protect).
@MainActor
@Observable
final class LiveBlockingService: BlockingService {
    private(set) var authState: BlockingAuthState
    private(set) var isProtected: Bool

    var selection: FamilyActivitySelection {
        didSet {
            BlockingSelectionStore.save(selection)
            if isProtected { reapply() }
        }
    }

    var safariFilterEnabled: Bool {
        didSet {
            BlockingSelectionStore.safariFilterEnabled = safariFilterEnabled
            if isProtected { reapply() }
        }
    }

    init() {
        selection = BlockingSelectionStore.loadSelection()
        safariFilterEnabled = BlockingSelectionStore.safariFilterEnabled
        isProtected = BlockingSelectionStore.protectionActive
        authState = Self.currentAuthState()
    }

    func requestAuthorization() async throws {
        #if targetEnvironment(simulator)
        authState = .unavailable
        throw BlockingError.requiresDevice
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authState = Self.currentAuthState()
        } catch FamilyControlsError.restricted {
            authState = .restricted
            throw BlockingError.restricted
        } catch {
            authState = Self.currentAuthState()
            throw error
        }
        #endif
    }

    func refreshAuthState() {
        guard authState != .restricted else { return }
        authState = Self.currentAuthState()
    }

    func applyProtection() {
        reapply()
        startSchedule()
        isProtected = true
        BlockingSelectionStore.protectionActive = true
    }

    func applyStage(_ stage: WallStage) throws {
        switch stage {
        case .web:
            // The S4 test page goes behind the wall with everything else.
            var denylist = BlockingSelectionStore.denylist
            if !denylist.contains(WallTestPage.domain) {
                denylist.append(WallTestPage.domain)
                BlockingSelectionStore.denylist = denylist
            }
            safariFilterEnabled = true
            #if !targetEnvironment(simulator)
            ShieldApplier.applyWeb(safariFilterEnabled: true, denylist: denylist)
            #endif
        case .apps:
            #if !targetEnvironment(simulator)
            ShieldApplier.applyApps(selection: selection)
            #endif
        case .schedule:
            #if !targetEnvironment(simulator)
            try DeviceActivityCenter().startMonitoring(
                DeviceActivityName(AppGroup.Blocking.activityName),
                during: Self.dailySchedule
            )
            #endif
            isProtected = true
            BlockingSelectionStore.protectionActive = true
        }
    }

    func clearProtection() {
        #if !targetEnvironment(simulator)
        ShieldApplier.clear()
        stopSchedule()
        #endif
        isProtected = false
        BlockingSelectionStore.protectionActive = false
    }

    // MARK: - Internals

    private func reapply() {
        #if !targetEnvironment(simulator)
        ShieldApplier.apply(
            selection: selection,
            safariFilterEnabled: safariFilterEnabled,
            denylist: BlockingSelectionStore.denylist
        )
        #endif
    }

    /// A daily repeating interval wakes the monitor extension to re-apply shields
    /// (belt-and-suspenders against anything clearing them).
    private static var dailySchedule: DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }

    private func startSchedule() {
        #if !targetEnvironment(simulator)
        try? DeviceActivityCenter().startMonitoring(
            DeviceActivityName(AppGroup.Blocking.activityName),
            during: Self.dailySchedule
        )
        #endif
    }

    private func stopSchedule() {
        DeviceActivityCenter().stopMonitoring([DeviceActivityName(AppGroup.Blocking.activityName)])
    }

    private static func currentAuthState() -> BlockingAuthState {
        #if targetEnvironment(simulator)
        #if DEBUG
        // Lets us exercise the authorized Protection UI in the Simulator.
        if ProcessInfo.processInfo.environment["BEDROCK_DEMO_AUTH"] == "approved" { return .approved }
        #endif
        return .unavailable
        #else
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .approved: return .approved
        case .denied: return .denied
        case .approvedWithDataAccess: return .approved
        @unknown default: return .notDetermined
        }
        #endif
    }
}
