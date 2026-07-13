import CoreData

// MARK: - Person Helpers

extension Person {
    static func fetchByContactIdentifier(_ id: String, in ctx: NSManagedObjectContext) throws -> Person? {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "contactIdentifier == %@", id)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }
}
