import Foundation
import Observation

/// Periodic check-in with the backend (§4): keeps the partner's view current and
/// feeds the missed-heartbeat sweep. Also flushes any tamper events the monitor
/// extension queued while the app was closed. No-ops cleanly without a backend.
@MainActor
@Observable
final class HeartbeatService {
    private let api: APIClient?

    init(api: APIClient?) { self.api = api }

    func sync(protectionActive: Bool, strictEnabled: Bool) async {
        guard let api else { return }
        try? await api.ensureRegistered(displayName: nil)
        try? await api.heartbeat(protectionActive: protectionActive, strictEnabled: strictEnabled)
        await flushTamper()
    }

    private func flushTamper() async {
        guard let api else { return }
        for kind in BlockingSelectionStore.drainTamper() {
            try? await api.reportTamper(kind: kind)
        }
    }
}
