import Foundation

/// Thin async REST client for the Bedrock API (§3). Plain URLSession — the app
/// holds no Supabase keys, only a bearer token from `/api/register`. All calls
/// are best-effort; failures throw `APIError` and callers degrade gracefully.
struct APIClient {
    let baseURL: URL

    enum APIError: LocalizedError {
        case http(Int, String)
        case decoding
        case notRegistered

        var errorDescription: String? {
            switch self {
            case let .http(code, msg): "Server error \(code): \(msg)"
            case .decoding: "Couldn’t read the server’s response."
            case .notRegistered: "This device isn’t registered yet."
            }
        }
    }

    // MARK: Registration / auth

    /// Ensure we have a bearer token, registering the device if needed.
    func ensureRegistered(displayName: String?) async throws {
        if DeviceIdentity.token != nil { return }
        let response: RegisterResponse = try await send(
            "/api/register", method: "POST",
            body: ["deviceId": DeviceIdentity.deviceId, "displayName": displayName],
            authed: false
        )
        DeviceIdentity.token = response.token
    }

    // MARK: Endpoints

    func serverNow() async throws -> Date {
        let r: TimeResponse = try await send("/api/time", method: "GET", authed: false)
        return Date(timeIntervalSince1970: r.nowMs / 1000)
    }

    func heartbeat(protectionActive: Bool, strictEnabled: Bool) async throws {
        try await sendVoid("/api/heartbeat", method: "POST",
                           body: ["protectionActive": protectionActive, "strictEnabled": strictEnabled])
    }

    func reportTamper(kind: String) async throws {
        try await sendVoid("/api/tamper", method: "POST", body: ["kind": kind])
    }

    func createInvite(kind: String) async throws -> InviteResponse {
        try await send("/api/partner/invite", method: "POST", body: ["kind": kind])
    }

    func acceptInvite(code: String) async throws -> AcceptResponse {
        try await send("/api/partner/accept", method: "POST", body: ["code": code])
    }

    func partnerStatus() async throws -> PartnerStatusResponse {
        try await send("/api/partner/status", method: "GET")
    }

    func requestApproval(reason: String) async throws -> ApprovalRequestResponse {
        try await send("/api/approval/request", method: "POST", body: ["reason": reason])
    }

    func approvalStatus(ids: [String]) async throws -> ApprovalStatusResponse {
        try await send("/api/approval/status?ids=\(ids.joined(separator: ","))", method: "GET")
    }

    func pendingApprovals() async throws -> PendingResponse {
        try await send("/api/approval/pending", method: "GET")
    }

    func respondApproval(id: String, approve: Bool) async throws {
        try await sendVoid("/api/approval/respond", method: "POST",
                           body: ["id": id, "decision": approve ? "approved" : "denied"])
    }

    func startCooldown(seconds: Int) async throws -> CooldownStartResponse {
        try await send("/api/cooldown/start", method: "POST", body: ["seconds": seconds])
    }

    func checkCooldown(id: String) async throws -> CooldownCheckResponse {
        try await send("/api/cooldown/check?id=\(id)", method: "GET")
    }

    // MARK: Transport

    private func send<T: Decodable>(_ path: String, method: String,
                                    body: [String: Any?]? = nil, authed: Bool = true) async throws -> T {
        let data = try await perform(path, method: method, body: body, authed: authed)
        guard let value = try? JSONDecoder().decode(T.self, from: data) else { throw APIError.decoding }
        return value
    }

    private func sendVoid(_ path: String, method: String,
                          body: [String: Any?]? = nil, authed: Bool = true) async throws {
        _ = try await perform(path, method: method, body: body, authed: authed)
    }

    private func perform(_ path: String, method: String,
                         body: [String: Any?]?, authed: Bool) async throws -> Data {
        // Build from the full string so query strings survive (appendingPathComponent escapes them).
        let urlString = baseURL.absoluteString.trimmingTrailingSlash() + (path.hasPrefix("/") ? path : "/" + path)
        guard let url = URL(string: urlString) else { throw APIError.http(0, "bad url") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        }
        if authed {
            guard let token = DeviceIdentity.token else { throw APIError.notRegistered }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.http(0, "no response") }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http(http.statusCode, message)
        }
        return data
    }
}

private extension String {
    func trimmingTrailingSlash() -> String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}

// MARK: - DTOs

struct RegisterResponse: Decodable { let userId: String; let token: String }
struct TimeResponse: Decodable { let nowMs: Double }
struct InviteResponse: Decodable { let code: String; let url: String }
struct AcceptResponse: Decodable { let supportedUserId: String; let kind: String }
struct ApprovalRequestResponse: Decodable { let requestIds: [String] }
struct ApprovalStatusResponse: Decodable { let approved: Bool; let denied: Bool }
struct CooldownStartResponse: Decodable { let id: String; let startedAtMs: Double; let durationSeconds: Int; let nowMs: Double }
struct CooldownCheckResponse: Decodable { let remainingMs: Double; let complete: Bool }

struct PartnerStatusResponse: Decodable {
    let partners: [PartnerDTO]
    let supporting: [SupportingDTO]

    struct PartnerDTO: Decodable { let id: String; let kind: String; let name: String? }
    struct SupportingDTO: Decodable {
        let id: String
        let kind: String
        let name: String?
        let protectionActive: Bool
        let strictEnabled: Bool
        let lastHeartbeatAt: String?
    }
}

struct PendingResponse: Decodable {
    let pending: [PendingDTO]
    struct PendingDTO: Decodable { let id: String; let reason: String?; let createdAt: String?; let name: String? }
}
