import Observation

/// The ordered steps of the disable gauntlet (§4). Partner steps are present
/// only when an accountability partner is configured; solo users (Model B) run
/// the shorter path and the cooldown is their final gate.
enum GauntletStep: Identifiable, Hashable, CaseIterable {
    case futureSelf      // 1. read the letter from your committed self, in full
    case urgeSurf        // 2. breathe + rate the urge (the Intercept Moment)
    case commitment      // 3. hand-type the commitment passage (no paste)
    case partnerMessage  // 4. write a "why" that sends to your partner
    case cooldown        // 5. server-validated cooldown, resets on backgrounding
    case partnerApproval // 6. partner taps Approve

    var id: Self { self }

    var title: String {
        switch self {
        case .futureSelf:      "From your committed self"
        case .urgeSurf:        "Ride it out"
        case .commitment:      "Type your commitment"
        case .partnerMessage:  "Tell your partner why"
        case .cooldown:        "Sit with it"
        case .partnerApproval: "Partner approval"
        }
    }
}

/// Drives one run of the gauntlet. Holds step position and the cooldown engine;
/// the view performs side effects (sending the message, the final release) using
/// the app's services as steps complete.
@MainActor
@Observable
final class GauntletCoordinator {
    let steps: [GauntletStep]
    let cooldownSeconds: Int
    let requiredSentences: Int
    let hasPartner: Bool

    let cooldown = CooldownEngine()

    private(set) var index = 0
    private(set) var isComplete = false

    init(hasPartner: Bool, cooldownSeconds: Int, requiredSentences: Int) {
        self.hasPartner = hasPartner
        self.cooldownSeconds = cooldownSeconds
        self.requiredSentences = requiredSentences

        var steps: [GauntletStep] = [.futureSelf, .urgeSurf, .commitment]
        if hasPartner { steps.append(.partnerMessage) }
        steps.append(.cooldown)
        if hasPartner { steps.append(.partnerApproval) }
        self.steps = steps
    }

    var current: GauntletStep? { index < steps.count ? steps[index] : nil }
    var stepNumber: Int { index + 1 }
    var progress: Double { steps.isEmpty ? 0 : Double(index) / Double(steps.count) }

    func completeCurrent() {
        guard !isComplete else { return }
        if index < steps.count - 1 {
            index += 1
        } else {
            isComplete = true
        }
    }
}
