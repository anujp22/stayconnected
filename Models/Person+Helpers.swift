import CoreData

// MARK: - Person Helpers

extension Person {
    static func fetchByContactIdentifier(_ id: String, in ctx: NSManagedObjectContext) throws -> Person? {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "contactIdentifier == %@", id)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }

    /// Upsert (find or create) a Person for this contact.
    static func findOrCreate(
        id contactIdentifier: String,
        name displayName: String,
        in ctx: NSManagedObjectContext
    ) throws -> Person {
        if let existing = try fetchByContactIdentifier(contactIdentifier, in: ctx) {
            // keep existing name if you like; here we refresh from Contacts
            existing.displayName = displayName

            return existing
        }

        let p = Person(context: ctx)

        p.id = UUID()
        p.contactIdentifier = contactIdentifier
        p.displayName = displayName
        p.isInPool = false
        return p
    }
}
