import Contacts

// MARK: - Supporting Types

/// A lightweight contact DTO for UI
struct ContactBasic: Identifiable, Hashable {
    let id: String        // CNContact.identifier
    let name: String
}

// MARK: - Contacts Service

final class ContactsService {
    // MARK: - Properties

    private let store = CNContactStore()

    // MARK: - Public API

    /// Requests access if needed. Returns true if authorized.
    func requestAccessIfNeeded() async throws -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            return true
        }

        return try await store.requestAccess(for: .contacts)
    }

    /// Fetches minimal contact info (identifier + formatted name).
    func fetchAllBasics() throws -> [ContactBasic] {
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]
        let req = CNContactFetchRequest(keysToFetch: keys)
        req.unifyResults = true

        var results: [ContactBasic] = []
        try store.enumerateContacts(with: req) { c, _ in
            let name = CNContactFormatter.string(from: c, style: .fullName) ?? "Unnamed"
            results.append(.init(id: c.identifier, name: name))
        }
        return results.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
