import Foundation

/// Onboarding copy, looked up by catalog key. Every onboarding string lives in
/// Resources/Localizable.xcstrings (keys `onb.<screen>.<label>`), so views never
/// hold literal copy.
///
/// Where one catalog value packs several UI strings (a sheet's title, body and
/// buttons; a chip list), they're separated by " · " — see the SPEC.md header.
/// Use `parts(_:)` for those. Values that show a literal middle dot on screen
/// (the status chip, the trust line) are read with `string(_:)` and never split.
enum OnbCopy {
    static func string(_ key: String) -> String {
        let value = Bundle.main.localizedString(forKey: key, value: missing, table: nil)
        guard value != missing else {
            #if DEBUG
            print("[OnbCopy] Missing catalog key: \(key)")
            #endif
            return key // visible on screen, so a typo can't hide
        }
        return value
    }

    /// The distinct UI strings packed into one catalog value.
    static func parts(_ key: String) -> [String] {
        string(key).components(separatedBy: separator)
    }

    /// A catalog value with format arguments (e.g. `onb.common.chapter_a11y`).
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: .current, arguments: arguments)
    }

    private static let separator = " · "
    private static let missing = "\u{1}missing"
}
