import CoreData

// MARK: - Contact Cadence

/// How often the user wants to stay in touch with a person. Kept to a few warm
/// presets on purpose — the goal is a soft rhythm, not a precise scheduler.
enum ContactCadence: Int16, CaseIterable, Identifiable {
    case close = 0
    case regular = 1
    case occasional = 2

    var id: Int16 { rawValue }

    /// Approximate target gap between connections, in days.
    var days: Int {
        switch self {
        case .close: return 14
        case .regular: return 30
        case .occasional: return 90
        }
    }

    var label: String {
        switch self {
        case .close: return "Close"
        case .regular: return "Regular"
        case .occasional: return "Occasional"
        }
    }

    var subtitle: String {
        switch self {
        case .close: return "About every 2 weeks"
        case .regular: return "About monthly"
        case .occasional: return "Every few months"
        }
    }
}

// MARK: - Person Helpers

extension Person {
    static func fetchByContactIdentifier(_ id: String, in ctx: NSManagedObjectContext) throws -> Person? {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "contactIdentifier == %@", id)
        req.fetchLimit = 1

        return try ctx.fetch(req).first
    }

    /// The person's chosen cadence, defaulting to `.regular`.
    var contactCadence: ContactCadence {
        get { ContactCadence(rawValue: cadence) ?? .regular }
        set { cadence = newValue.rawValue }
    }

    /// True while the person is snoozed (their `snoozedUntil` is in the future).
    /// Snoozed people are skipped by the daily selection so a user can gently
    /// defer someone for a day or a week without removing them from the pool.
    func isSnoozed(asOf date: Date = Date()) -> Bool {
        guard let until = snoozedUntil else { return false }
        return until > date
    }
}
