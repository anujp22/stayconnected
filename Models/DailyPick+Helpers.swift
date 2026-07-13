import CoreData

// MARK: - DailyPick Helpers

extension DailyPick {
    /// Separator for the joined identifier string. Contact identifiers never
    /// contain a newline, so this is a safe delimiter.
    private static let identifierSeparator = "\n"

    /// The ordered contact identifiers for this pick, stored as a single
    /// newline-joined string so the attribute is CloudKit-compatible
    /// (unlike the old Transformable NSArray).
    var contactIdentifierList: [String] {
        get {
            guard let raw = contactIdentifiersRaw, !raw.isEmpty else { return [] }
            return raw.components(separatedBy: Self.identifierSeparator)
        }
        set {
            contactIdentifiersRaw = newValue.joined(separator: Self.identifierSeparator)
        }
    }

    static func fetchFor(
        date: Date,
        in ctx: NSManagedObjectContext
    ) throws -> DailyPick? {
        let req: NSFetchRequest<DailyPick> = DailyPick.fetchRequest()
        // we save normalized start-of-day; match exactly
        let day = date.startOfDay as NSDate
        req.predicate = NSPredicate(format: "date == %@", day)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }

    static func upsertForToday(
        with contactIdentifiers: [String],
        in ctx: NSManagedObjectContext
    ) throws -> DailyPick {
        if let existing = try fetchFor(date: Date(), in: ctx) {
            existing.contactIdentifierList = contactIdentifiers

            return existing
        }
        let d = DailyPick(context: ctx)

        d.id = UUID()
        d.date = Date().startOfDay
        d.contactIdentifierList = contactIdentifiers
        return d
    }
}
