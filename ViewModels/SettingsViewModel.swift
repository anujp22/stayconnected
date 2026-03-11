import CoreData
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var picksPerDay: Int = 2
    @Published var minGapDays: Int = 20
    @Published var remindersEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()

    // MARK: - Dependencies

    private let ctx: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    // MARK: - Public API

    func load() throws {
        let s = try AppSettings.fetchOrCreate(in: ctx)
        picksPerDay = Int(s.picksPerDay)
        minGapDays = Int(s.minGapDays)

        remindersEnabled = s.remindersEnabled
        if let t = s.reminderTime {
            reminderTime = t
        }
    }

    func save() throws {
        let s = try AppSettings.fetchOrCreate(in: ctx)
        s.picksPerDay = Int16(picksPerDay)
        s.minGapDays = Int16(minGapDays)

        s.remindersEnabled = remindersEnabled
        s.reminderTime = reminderTime
        try ctx.save()

        // Update reminder schedule after saving settings
        try scheduleReminderIfNeeded()
    }
    
    func clearTodayIfNeeded() throws {
        if let dp = try DailyPick.fetchFor(date: Date(), in: ctx) {
            ctx.delete(dp)
            try ctx.save()
        }
    }

    // MARK: - Private Helpers

    private func scheduleReminderIfNeeded() throws {
        if remindersEnabled {
            let (title, body) = try computeReminderMessage()

            Task {
                try? await NotificationsService.scheduleDailyReminder(
                    at: reminderTime,
                    title: title,
                    body: body
                )
            }
        } else {
            Task {
                await NotificationsService.cancelDailyReminder()
            }
        }
    }

    private func computeReminderMessage() throws -> (String, String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Did user complete a connection today?
        let eventRequest: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        eventRequest.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        let eventsToday = try ctx.count(for: eventRequest)

        // How many picks exist today?
        let picksCount: Int
        if let dp = try DailyPick.fetchFor(date: Date(), in: ctx) {
            let rawIdentifiers: Any = dp.contactIdentifiers as Any

            if let identifiers = rawIdentifiers as? [String] {
                picksCount = identifiers.count
            } else if let identifiers = rawIdentifiers as? NSArray {
                picksCount = identifiers.count
            } else {
                picksCount = 0
            }
        } else {
            picksCount = 0
        }

        // Streak calculation placeholder (can be improved later)
        let currentStreak = 0

        let message = NotificationsService.reminderMessage(
            hasCompletedConnectionToday: eventsToday > 0,
            currentStreak: currentStreak,
            picksCount: picksCount
        )

        return (message.title, message.body)
    }

    // MARK: - Derived Values

    // 👇 This is the math users will see
    var recommendedPoolSize: Int {
        picksPerDay * minGapDays
    }
}
