import CoreData

// MARK: - Person Helpers

extension Person {
    static func fetchByContactIdentifier(_ id: String, in ctx: NSManagedObjectContext) throws -> Person? {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "contactIdentifier == %@", id)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }

    /// True while the person is snoozed (their `snoozedUntil` is in the future).
    /// Snoozed people are skipped by the daily selection so a user can gently
    /// defer someone for a day or a week without removing them from the pool.
    func isSnoozed(asOf date: Date = Date()) -> Bool {
        guard let until = snoozedUntil else { return false }
        return until > date
    }
}
