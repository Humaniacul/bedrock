import Foundation
import Observation

/// The one person the user calls in a hard moment (§4 "call your person").
/// Stored on-device only (App Group) — a phone number never touches the
/// backend, and this works whether or not an accountability partner is linked.
@MainActor
@Observable
final class SupportContactStore {
    struct Contact: Codable, Equatable {
        var name: String
        var phone: String
    }

    private(set) var contact: Contact?
    private let persist: Bool

    var hasContact: Bool { contact != nil }

    init(persist: Bool = true) {
        self.persist = persist
        if persist { contact = Self.load() }
    }

    func set(name: String, phone: String) {
        contact = Contact(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        save()
    }

    func clear() {
        contact = nil
        if persist { AppGroup.defaults.removeObject(forKey: AppGroup.Key.supportContact) }
    }

    /// A `tel:` URL with non-dialable characters stripped (keeps `+` for intl).
    var callURL: URL? {
        guard let phone = contact?.phone else { return nil }
        let dialable = phone.filter { "+0123456789".contains($0) }
        guard !dialable.isEmpty else { return nil }
        return URL(string: "tel://\(dialable)")
    }

    // MARK: - Persistence (App Group JSON — on-device only, §10.6)

    private func save() {
        guard persist, let data = try? JSONEncoder().encode(contact) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.supportContact)
    }

    private static func load() -> Contact? {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Key.supportContact) else { return nil }
        return try? JSONDecoder().decode(Contact.self, from: data)
    }
}
