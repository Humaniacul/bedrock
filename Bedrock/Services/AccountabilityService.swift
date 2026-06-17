import Foundation
import Observation

// Partner / accountability (§4). The partner uses the app free — the viral loop
// and retention engine, never the buyer. Alerts are always SUPPORTIVE-framed
// ("reach out"), never "caught". The live implementation is API-backed (§3);
// the stub keeps the app fully functional with no backend.

struct SupportedPerson: Identifiable {
    let id: String
    let name: String?
    let protectionActive: Bool
    let strictEnabled: Bool
    let lastHeartbeat: Date?
}

struct PendingApproval: Identifiable {
    let id: String
    let name: String?
    let reason: String?
    let createdAt: Date?
}

struct InviteInfo {
    let code: String
    let url: String
}

enum ApprovalOutcome {
    case pending, approved, denied
}

enum TamperKind: String {
    case shieldCleared = "shield_cleared"
    case screenTimeOff = "screen_time_off"
    case appDark = "app_dark"
    case uninstallLockOff = "uninstall_lock_off"
}

@MainActor
protocol AccountabilityService: AnyObject {
    var isConfigured: Bool { get }
    var hasPartner: Bool { get }
    var partnerName: String? { get }
    /// People this user supports (the partner-role dashboard).
    var supporting: [SupportedPerson] { get }
    /// Approval requests awaiting this user's decision (partner-role inbox).
    var pendingApprovals: [PendingApproval] { get }

    func refresh() async
    func createInvite() async -> InviteInfo?
    func acceptInvite(code: String) async -> Bool
    func sendDisableReason(_ message: String)
    func reportTamper(_ kind: TamperKind)

    // Gauntlet step 6.
    func requestApproval() async -> [String]
    func pollApproval(ids: [String]) async -> ApprovalOutcome
    func respondToApproval(id: String, approve: Bool) async

    // Server-validated cooldown (§10.5). Returns nil / true when no backend, so
    // the gauntlet falls back to the local (monotonic) timer.
    func startServerCooldown(seconds: Int) async -> String?
    func serverCooldownComplete(id: String) async -> Bool

    /// Delete all server-side data for this device (App Store Guideline 5.1.1(v)).
    func deleteAccount() async
}

/// No-backend stub — keeps the app running solo. No partner, no network.
@MainActor
@Observable
final class StubAccountabilityService: AccountabilityService {
    var isConfigured: Bool { false }
    var hasPartner: Bool { false }
    var partnerName: String? { nil }
    var supporting: [SupportedPerson] { [] }
    var pendingApprovals: [PendingApproval] { [] }

    func refresh() async {}
    func createInvite() async -> InviteInfo? { nil }
    func acceptInvite(code: String) async -> Bool { false }
    func sendDisableReason(_ message: String) {}
    func reportTamper(_ kind: TamperKind) {}
    func requestApproval() async -> [String] { [] }
    func pollApproval(ids: [String]) async -> ApprovalOutcome { .pending }
    func respondToApproval(id: String, approve: Bool) async {}
    func startServerCooldown(seconds: Int) async -> String? { nil }
    func serverCooldownComplete(id: String) async -> Bool { true }
    func deleteAccount() async {}
}

/// API-backed accountability (§3).
@MainActor
@Observable
final class LiveAccountabilityService: AccountabilityService {
    private let api: APIClient
    private var lastDisableReason = ""

    private(set) var partnerName: String?
    private(set) var supporting: [SupportedPerson] = []
    private(set) var pendingApprovals: [PendingApproval] = []

    init(api: APIClient) { self.api = api }

    var isConfigured: Bool { true }
    var hasPartner: Bool { partnerName != nil }

    func refresh() async {
        do {
            try await api.ensureRegistered(displayName: nil)
            let status = try await api.partnerStatus()
            partnerName = status.partners.first?.name ?? (status.partners.isEmpty ? nil : "Your partner")
            supporting = status.supporting.map {
                SupportedPerson(
                    id: $0.id, name: $0.name,
                    protectionActive: $0.protectionActive, strictEnabled: $0.strictEnabled,
                    lastHeartbeat: $0.lastHeartbeatAt.flatMap(Self.parseDate)
                )
            }
            let pending = try await api.pendingApprovals()
            pendingApprovals = pending.pending.map {
                PendingApproval(id: $0.id, name: $0.name, reason: $0.reason, createdAt: $0.createdAt.flatMap(Self.parseDate))
            }
        } catch {
            // Best-effort — leave the last known state on failure.
        }
    }

    func createInvite() async -> InviteInfo? {
        do {
            try await api.ensureRegistered(displayName: nil)
            let r = try await api.createInvite(kind: "partner")
            return InviteInfo(code: r.code, url: r.url)
        } catch { return nil }
    }

    func acceptInvite(code: String) async -> Bool {
        do {
            try await api.ensureRegistered(displayName: nil)
            _ = try await api.acceptInvite(code: code)
            await refresh()
            return true
        } catch { return false }
    }

    func sendDisableReason(_ message: String) {
        lastDisableReason = message
    }

    func reportTamper(_ kind: TamperKind) {
        Task { [api] in
            try? await api.ensureRegistered(displayName: nil)
            try? await api.reportTamper(kind: kind.rawValue)
        }
    }

    func requestApproval() async -> [String] {
        do {
            try await api.ensureRegistered(displayName: nil)
            let r = try await api.requestApproval(reason: lastDisableReason)
            return r.requestIds
        } catch { return [] }
    }

    func pollApproval(ids: [String]) async -> ApprovalOutcome {
        guard !ids.isEmpty else { return .pending }
        do {
            let r = try await api.approvalStatus(ids: ids)
            if r.approved { return .approved }
            if r.denied { return .denied }
            return .pending
        } catch { return .pending }
    }

    func respondToApproval(id: String, approve: Bool) async {
        try? await api.respondApproval(id: id, approve: approve)
        await refresh()
    }

    func startServerCooldown(seconds: Int) async -> String? {
        do {
            try await api.ensureRegistered(displayName: nil)
            return try await api.startCooldown(seconds: seconds).id
        } catch { return nil }
    }

    func serverCooldownComplete(id: String) async -> Bool {
        do { return try await api.checkCooldown(id: id).complete } catch { return false }
    }

    func deleteAccount() async {
        try? await api.ensureRegistered(displayName: nil)
        try? await api.deleteAccount()
    }

    private static func parseDate(_ s: String) -> Date? {
        ISO8601DateFormatter().date(from: s) ?? {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: s)
        }()
    }
}
