import Foundation
import Observation

/// On-device trigger intelligence (§4, §10.6). ALL analysis runs locally —
/// nothing leaves the phone. Logs urges/relapses with context and surfaces
/// personal danger windows.
///
/// Phase 4 fills in: Core ML / on-device model, danger-window inference,
/// proactive pre-emptive tightening + supportive check-ins.
@MainActor
@Observable
final class TriggerEngine {
    struct Event: Identifiable {
        let id = UUID()
        let date: Date
        let weekday: Int
        let originatingApp: String?
        let moodTag: String?
        let urgeIntensity: Int? // 1–10
    }

    private(set) var events: [Event] = []

    func log(_ event: Event) {
        events.append(event)
    }

    /// Phase 4: inferred high-risk windows (e.g. "Sun 23:00 after Instagram").
    var dangerWindows: [String] { [] }
}
