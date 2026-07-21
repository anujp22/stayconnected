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

    // MARK: - Birthday

    /// Builds a storable birthday `Date` from Contacts date components. The
    /// address book often omits the year, so we substitute a neutral placeholder
    /// — everything that reads `birthday` compares on month/day only.
    static func birthdayDate(from components: DateComponents?) -> Date? {
        guard let components, let month = components.month, let day = components.day else {
            return nil
        }
        var comps = DateComponents()
        comps.year = components.year ?? 2000
        comps.month = month
        comps.day = day
        comps.hour = 12
        return Calendar.current.date(from: comps)
    }

    /// The birthday's month and day, ignoring the (often unknown) stored year.
    /// Birthdays are compared by month/day only so reminders recur every year.
    var birthdayMonthDay: (month: Int, day: Int)? {
        guard let birthday else { return nil }
        let comps = Calendar.current.dateComponents([.month, .day], from: birthday)
        guard let month = comps.month, let day = comps.day else { return nil }
        return (month, day)
    }

    /// True when today is this person's birthday (matched on month/day).
    func isBirthdayToday(asOf date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let md = birthdayMonthDay else { return false }
        let today = calendar.dateComponents([.month, .day], from: date)
        return today.month == md.month && today.day == md.day
    }

    /// Whole days until the next occurrence of this birthday (0 == today).
    func daysUntilBirthday(from date: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let next = nextBirthday(from: date, calendar: calendar) else { return nil }
        let start = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: next).day
    }

    /// The next calendar date this birthday lands on, at start of day (today if
    /// it's today). Returns nil when no birthday is set.
    func nextBirthday(from date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard let md = birthdayMonthDay else { return nil }
        let start = calendar.startOfDay(for: date)
        var comps = DateComponents()
        comps.month = md.month
        comps.day = md.day
        // `nextDate` with `.forward` returns the next match; include today by
        // searching from the start of today minus a moment.
        return calendar.nextDate(
            after: start.addingTimeInterval(-1),
            matching: comps,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }

    /// A short, calm birthday label for rows/profile, e.g. "Today", "in 3 days",
    /// or "Jul 20". Returns nil when no birthday is set.
    func birthdayShortLabel(from date: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let birthday, let days = daysUntilBirthday(from: date, calendar: calendar) else { return nil }
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case 2...6: return "in \(days) days"
        default: return birthday.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}
