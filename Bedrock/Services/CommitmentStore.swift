import Foundation
import Observation

/// Holds the words the user commits to: the "letter from your committed self"
/// shown unskippably at the start of the gauntlet, and the passage they must
/// hand-type (§4). Phase 4/5 add a recorded future-self video/voice note that
/// plays here instead of the letter.
@MainActor
@Observable
final class CommitmentStore {
    var letter: String {
        didSet { AppGroup.defaults.set(letter, forKey: AppGroup.Key.commitmentLetter) }
    }

    var passage: [String] {
        didSet { AppGroup.defaults.set(passage, forKey: AppGroup.Key.commitmentPassage) }
    }

    init() {
        letter = AppGroup.defaults.string(forKey: AppGroup.Key.commitmentLetter) ?? Self.defaultLetter
        passage = AppGroup.defaults.stringArray(forKey: AppGroup.Key.commitmentPassage) ?? Self.defaultPassage
    }

    var hasLetter: Bool { !letter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    static let defaultLetter = """
    Read this with a clear head.

    You set this lock on purpose, when you were thinking straight — because you \
    decided the man you're building is worth more than the next few minutes. The \
    urge you feel right now is real, but it is not you, and it passes. You have \
    ridden it out before. Ride it out again. Future you is watching.
    """

    static let defaultPassage = [
        "I chose this lock with a clear head.",
        "The urge I feel now is temporary, and it will pass.",
        "I am building something that matters more than this moment.",
        "Future me is counting on me to hold the line.",
    ]
}
