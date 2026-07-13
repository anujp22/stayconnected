import Contacts
import CoreData
import Foundation
import UIKit

@MainActor
final class TodayViewModel: ObservableObject {
    // MARK: - Published

    @Published var todayPicks: [Person] = []

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

    func loadTodayPicks() throws -> [Person] {
        guard let existing = try DailyPick.fetchFor(date: Date(), in: ctx),
              let ids = existing.contactIdentifiers as? [String] else {
            return []
        }

        return loadPersons(with: ids)
    }

    @discardableResult
    func generateTodayPicks() throws -> [Person] {
        let settings = try AppSettings.fetchOrCreate(in: ctx)
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "isInPool == YES")
        let pool = try ctx.fetch(req)

        let picks = try generateTodayPicks(from: pool, settings: settings)
        todayPicks = picks
        return picks
    }

    func person(for identifier: String) throws -> Person? {
        try Person.fetchByContactIdentifier(identifier, in: ctx)
    }

    /// Saves a one-line context note for a person ("last talked: her interview").
    /// An empty note clears it. Kept intentionally to a single free-text line —
    /// this is a memory jog, not a notes database.
    func setNote(_ note: String, forContactIdentifier identifier: String) throws {
        guard let person = try person(for: identifier) else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        person.note = trimmed.isEmpty ? nil : trimmed
        try ctx.save()
    }

    private func generateTodayPicks(
        from pool: [Person],
        settings: AppSettings
    ) throws -> [Person] {
        let picks = selector.pickToday(
            from: pool,
            picksPerDay: Int(settings.picksPerDay),
            minGapDays: Int(settings.minGapDays),
            today: Date()
        )

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

        return picks
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

    /// Returns a soft warning when the pool is too small to reliably enforce
    /// the configured gap, or `nil` when the pool is empty or large enough.
    func poolWarning() throws -> String? {
        let settings = try AppSettings.fetchOrCreate(in: ctx)
        let count = try poolCount()

        guard count > 0,
              count < Int(settings.minGapDays) * Int(settings.picksPerDay) else {
            return nil
        }

        return "Your pool may be too small to always enforce a \(settings.minGapDays)-day gap."
    }

    func resetTodayPicks() throws {
        if let dp = try DailyPick.fetchFor(date: Date(), in: ctx) {
            // Clear lastPickedAt for today's picks so a fresh Generate can
            // surface them again instead of demoting them to the fallback
            // pool because they're still inside the min-gap window.
            if let ids = dp.contactIdentifiers as? [String] {
                loadPersons(with: ids).forEach { $0.lastPickedAt = nil }
            }

            ctx.delete(dp)
            try ctx.save()
        }

        todayPicks = []
        Task {
            try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        }
    }

    /// Gently defers a single pick: marks the person snoozed until `until`,
    /// removes them from today's list, and swaps in the best available
    /// replacement (if the pool has one) so the day still feels complete.
    @discardableResult
    func snoozePick(_ person: Person, until: Date) throws -> [Person] {
        person.snoozedUntil = until

        var picks = try loadTodayPicks().filter { $0.objectID != person.objectID }

        // Find one replacement from the pool, excluding people already picked
        // today and (via SelectionService) anyone currently snoozed.
        let settings = try AppSettings.fetchOrCreate(in: ctx)
        let req: NSFetchRequest<Person> = Person.fetchRequest()
        req.predicate = NSPredicate(format: "isInPool == YES")
        let pool = try ctx.fetch(req)

        let alreadyPicked = Set(picks.map { $0.objectID } + [person.objectID])
        let candidates = pool.filter { !alreadyPicked.contains($0.objectID) }

        if let replacement = selector.pickToday(
            from: candidates,
            picksPerDay: 1,
            minGapDays: Int(settings.minGapDays),
            today: Date()
        ).first {
            replacement.lastPickedAt = Date()
            picks.append(replacement)
        }

        let ids = picks.compactMap { $0.contactIdentifier }
        _ = try DailyPick.upsertForToday(with: ids, in: ctx)
        try ctx.save()

        todayPicks = picks
        Task {
            try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        }

        return picks
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

        if let url = PhoneLink.url(.tel, number: number) {
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
