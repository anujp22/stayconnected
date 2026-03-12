import Contacts
import CoreData
import Foundation
import UIKit

@MainActor
final class TodayViewModel: ObservableObject {
    // MARK: - Published

    @Published var todayPicks: [Person] = []
    @Published var warningText: String?

    // MARK: - Dependencies

    private let ctx: NSManagedObjectContext
    private let selector = SelectionService()

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    // MARK: - Public API

    func monthRolloverIfNeeded() throws {
        let lastMonthKey = "lastMonthKey"
        let now = Date()
        let comps = Calendar.current.dateComponents([.year, .month], from: now)
        let nowKey = "\(comps.year!)-\(comps.month!)"

        let lastKey = UserDefaults.standard.string(forKey: lastMonthKey)
        guard lastKey != nowKey else { return }

        let req: NSFetchRequest<Person> = Person.fetchRequest()

        let people = try ctx.fetch(req)
        people.forEach { $0.timesPickedThisMonth = 0 }
        try ctx.save()

        UserDefaults.standard.set(nowKey, forKey: lastMonthKey)
    }

    func loadOrGenerateToday() throws {
        let settings = try AppSettings.fetchOrCreate(in: ctx)

        // fetch pool
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "isInPool == YES")
        let pool = try ctx.fetch(req)

        // soft warning if pool small
        if pool.count < Int(settings.minGapDays) * Int(settings.picksPerDay) {
            warningText = "Your pool may be too small to always enforce a \(settings.minGapDays)-day gap."
        } else {
            warningText = nil
        }

        // A) try to reuse an existing DailyPick
        if let existing = try DailyPick.fetchFor(date: Date(), in: ctx),
           let ids = existing.contactIdentifiers as? [String] {
            self.todayPicks = loadPersons(with: ids)
            return
        }

        // B) else generate new picks
        let picks = selector.pickToday(
            from: pool,
            picksPerDay: Int(settings.picksPerDay),
            minGapDays: Int(settings.minGapDays),
            today: Date()
        )

        self.todayPicks = picks

        // important: set lastPickedAt now so the 20-day rule applies even if user doesn't "Mark Called"
        let now = Date()
        picks.forEach { $0.lastPickedAt = now }

        // save DailyPick entity with identifiers
        let ids = picks.compactMap { $0.contactIdentifier }
        _ = try DailyPick.upsertForToday(with: ids, in: ctx)

        try ctx.save()
        Task {
            try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        }
    }

    // MARK: - Actions

    // Marking called updates lastCalledAt and the monthly count.
    func markCalled(_ person: Person) throws {
        let now = Date()
        person.lastCalledAt = now
        person.timesPickedThisMonth += 1
        if let identifier = person.contactIdentifier,
           !hasLoggedConnectionToday(for: identifier) {
            let event = ConnectionEvent(context: ctx)
            event.id = UUID()
            event.date = now
            event.contactIdentifier = identifier
            event.contactNameSnapshot = person.displayName
        }
        try ctx.save()
        Task {
            try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        }
    }

    func poolCount() throws -> Int {
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "isInPool == YES")

        return try ctx.count(for: req)
    }

    func resetTodayPicks() throws {
        if let dp = try DailyPick.fetchFor(date: Date(), in: ctx) {
            ctx.delete(dp)
            try ctx.save()
        }

        todayPicks = []
        Task {
            try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        }
    }

    func call(_ person: Person) {
        guard let identifier = person.contactIdentifier else { return }

        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]

        let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])

        guard
            let contact = try? store
                .unifiedContacts(matching: predicate, keysToFetch: keys)
                .first,
            let number = contact.phoneNumbers.first?.value.stringValue
        else {
            return
        }

        let cleaned = number
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private Helpers

    private func loadPersons(with ids: [String]) -> [Person] {
        // fetch by identifier list, preserving order as best we can
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "contactIdentifier IN %@", ids)

        let people = (try? ctx.fetch(req)) ?? []

        // order to match ids
        let dict = Dictionary(uniqueKeysWithValues: people.map { ($0.contactIdentifier ?? "", $0) })

        return ids.compactMap { dict[$0] }
    }

    private func hasLoggedConnectionToday(for identifier: String) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "contactIdentifier == %@ AND date >= %@ AND date < %@",
            identifier,
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        return ((try? ctx.count(for: request)) ?? 0) > 0
    }
}
