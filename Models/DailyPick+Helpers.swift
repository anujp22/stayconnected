import CoreData

// MARK: - DailyPick Helpers

extension DailyPick {
    static func fetchFor(
        date: Date,
        in ctx: NSManagedObjectContext
    ) throws -> DailyPick? {
        let req: NSFetchRequest<DailyPick> = DailyPick.fetchRequest()
        // we save normalized start-of-day; match exactly
        let day = date.startOfDayUTC as NSDate
        req.predicate = NSPredicate(format: "date == %@", day)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }

    static func upsertForToday(
        with contactIdentifiers: [String],
        in ctx: NSManagedObjectContext
    ) throws -> DailyPick {
        if let existing = try fetchFor(date: Date(), in: ctx) {
            existing.contactIdentifiers = contactIdentifiers as NSArray

            return existing
        }
        let d = DailyPick(context: ctx)

        d.id = UUID()
        d.date = Date().startOfDayUTC
        d.contactIdentifiers = contactIdentifiers as NSArray
        return d
    }
}
