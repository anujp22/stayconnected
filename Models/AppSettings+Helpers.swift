import CoreData

// MARK: - AppSettings Helpers

extension AppSettings {
    /// Returns the existing singleton without creating or saving anything.
    /// Use this on read-only paths (previews, warnings, background reminder
    /// sync) so we don't trigger a context save as a side effect of a read.
    static func fetch(in ctx: NSManagedObjectContext) throws -> AppSettings? {
        let req: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        req.fetchLimit = 1
        return try ctx.fetch(req).first
    }

    /// Returns the singleton, creating and saving it once if it doesn't exist.
    /// Only call this from an explicit write path (e.g. saving settings); read
    /// paths should prefer `fetch(in:)`.
    static func fetchOrCreate(
        in ctx: NSManagedObjectContext
    ) throws -> AppSettings {
        if let existing = try fetch(in: ctx) {
            return existing
        }

        let s = AppSettings(context: ctx)
        s.id = UUID()
        s.picksPerDay = 2
        s.minGapDays = 20

        try ctx.save()

        return s
    }

    /// The effective settings for read-only computation: the persisted singleton
    /// if present, otherwise the in-memory defaults — never touching the store.
    static func effective(in ctx: NSManagedObjectContext) throws -> (picksPerDay: Int, minGapDays: Int, remindersEnabled: Bool, reminderTime: Date?) {
        if let s = try fetch(in: ctx) {
            return (Int(s.picksPerDay), Int(s.minGapDays), s.remindersEnabled, s.reminderTime)
        }
        return (2, 20, false, nil)
    }
}
