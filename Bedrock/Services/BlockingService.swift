import FamilyControls
import Foundation
import Observation

/// Authorization state, decoupled from the FamilyControls enum so screens don't
/// branch on framework types (and so we can express `.unavailable` for Simulator).
enum BlockingAuthState: Equatable {
    case notDetermined
    case approved
    case denied
    case restricted  // Screen Time is managed by a parent, school or company (B2)
    case unavailable // Simulator / no Screen Time — protection can't run here
}

enum BlockingError: LocalizedError {
    case requiresDevice
    case restricted

    var errorDescription: String? {
        switch self {
        case .requiresDevice: "Protection runs on a real iPhone — Screen Time isn't available in the Simulator."
        case .restricted: "Screen Time is managed on this iPhone."
        }
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
    /// Re-read the authorization status (on return from Settings, S2-D / S13.5B).
    func refreshAuthState()
    /// Apply shields + start the re-apply schedule.
    func applyProtection()
    /// Write one stage of the wall (S3): each course lands as its write returns.
    func applyStage(_ stage: WallStage) throws
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

/// The page S4 opens to prove the wall holds. Its domain is added to the web
/// filter on S3 (SPEC.md S3/S4). Configured in Info.plist (`BEDROCK_WALL_TEST_URL`)
/// so it can move to test.thebedrock.app without a code change.
enum WallTestPage {
    static var url: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "BEDROCK_WALL_TEST_URL") as? String
        return raw.flatMap(URL.init(string:)) ?? URL(string: "https://test.thebedrock.app")!
    }

    static var domain: String { url.host() ?? "test.thebedrock.app" }
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
    func refreshAuthState() {}
    func applyProtection() { isProtected = true }
    func applyStage(_ stage: WallStage) throws { if stage == .schedule { isProtected = true } }
    func clearProtection() { isProtected = false }
}
