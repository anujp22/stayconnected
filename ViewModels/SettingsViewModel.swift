import CoreData
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var picksPerDay: Int = 2
    @Published var minGapDays: Int = 20
    @Published var remindersEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var reminderPreviewTitle = "Today’s picks are ready"
    @Published var reminderPreviewBody = "Open StayConnected to see who to call today."

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
        try refreshReminderPreview()
    }

    func save() throws {
        let s = try AppSettings.fetchOrCreate(in: ctx)
        s.picksPerDay = Int16(picksPerDay)
        s.minGapDays = Int16(minGapDays)

        s.remindersEnabled = remindersEnabled
        s.reminderTime = reminderTime
        try ctx.save()
        try refreshReminderPreview()
    }
    
    func clearTodayIfNeeded() throws {
        if let dp = try DailyPick.fetchFor(date: Date(), in: ctx) {
            ctx.delete(dp)
            try ctx.save()
        }
    }

    func refreshReminderPreview() throws {
        let preview = try NotificationsService.reminderPreview(in: ctx)
        reminderPreviewTitle = preview.title
        reminderPreviewBody = preview.body
    }

    // MARK: - Derived Values

    // 👇 This is the math users will see
    var recommendedPoolSize: Int {
        picksPerDay * minGapDays
    }
}
