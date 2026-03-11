import CoreData
import Foundation

@MainActor
final class PoolViewModel: ObservableObject {

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
            print("Pool fetch failed:", error)
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
