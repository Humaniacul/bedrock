import FamilyControls
import Foundation
import Observation

/// Authorization state, decoupled from the FamilyControls enum so screens don't
/// branch on framework types (and so we can express `.unavailable` for Simulator).
enum BlockingAuthState: Equatable {
    case notDetermined
    case approved
    case denied
    case unavailable // Simulator / no Screen Time — protection can't run here
}

enum BlockingError: LocalizedError {
    case requiresDevice

    var errorDescription: String? {
        "Protection runs on a real iPhone — Screen Time isn't available in the Simulator."
    }
}

/// The OS blocking surface (§4 Blocking core). Live `FamilyControls` /
/// `ManagedSettings` implementation swaps in for the stub without touching
/// screens; previews use the stub.
@MainActor
protocol BlockingService: AnyObject {
    var authState: BlockingAuthState { get }
    /// Whether shields are currently applied.
    var isProtected: Bool { get }
    /// The picker selection — bound directly by `FamilyActivityPicker`.
    var selection: FamilyActivitySelection { get set }
    /// Whether the Safari adult-content filter layer is on.
    var safariFilterEnabled: Bool { get set }
    /// Apps + categories + web domains chosen to block.
    var blockedItemCount: Int { get }

    func requestAuthorization() async throws
    /// Apply shields + start the re-apply schedule.
    func applyProtection()
    /// Lift shields + stop the schedule.
    func clearProtection()
}

extension BlockingService {
    var blockedItemCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }
}

/// Preview/Simulator stub — in-memory, touches no OS APIs. Defaults to
/// `.approved` so the Protection UI's configured state is previewable.
@MainActor
@Observable
final class StubBlockingService: BlockingService {
    var authState: BlockingAuthState = .approved
    private(set) var isProtected = false
    var selection = FamilyActivitySelection()
    var safariFilterEnabled = true

    func requestAuthorization() async throws { authState = .approved }
    func applyProtection() { isProtected = true }
    func clearProtection() { isProtected = false }
}
