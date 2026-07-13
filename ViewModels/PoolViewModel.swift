import CoreData
import Foundation
import os

@MainActor
final class PoolViewModel: ObservableObject {

    private static let logger = Logger(subsystem: "com.anujpatel.StayConnected", category: "Pool")

    // MARK: - Published
    @Published var people: [Person] = []
    @Published var searchText: String = ""

    // MARK: - Dependencies
    private let ctx: NSManagedObjectContext

    // MARK: - Initialization
    init(ctx: NSManagedObjectContext) {
        self.ctx = ctx
    }

    // MARK: - Public API
    func load() {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "isInPool == YES")

        req.sortDescriptors = [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "displayName", ascending: true)
        ]

        do {
            people = try ctx.fetch(req)
        } catch {
            people = []
            Self.logger.error("Pool fetch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Filtering
    var filteredPeople: [Person] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return people }

        return people.filter { person in
            let name = (person.displayName ?? "").lowercased()
            let id = (person.contactIdentifier ?? "").lowercased()

            return name.contains(q) || id.contains(q)
        }
    }
}
