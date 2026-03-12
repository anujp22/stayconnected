import CoreData
import Foundation
import UserNotifications

// MARK: - Notifications Service

enum NotificationsService {
    private static let reminderIdentifier = "daily.reminder"

    // MARK: - Authorization

    static func requestPermissionIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .denied:
            return false

        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])

        @unknown default:
            return false
        }
    }

    // MARK: - Scheduling

    static func scheduleDailyReminder(
        at time: Date,
        title: String = "Today’s picks are ready",
        body: String = "Open StayConnected to see who to call today."
    ) async throws {
        let center = UNUserNotificationCenter.current()

        // Replace existing reminder (same identifier)
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Reminder Copy

    static func reminderMessage(
        hasCompletedConnectionToday: Bool,
        currentStreak: Int,
        picksCount: Int
    ) -> (title: String, body: String) {
        if hasCompletedConnectionToday {
            return (
                title: "You’re all set for today",
                body: "Nice work staying connected. Come back tomorrow for a fresh set of picks."
            )
        }

        if currentStreak > 0 {
            return (
                title: "Your streak is at risk",
                body: "Reach out to one of today’s picks to keep your \(currentStreak)-day streak alive."
            )
        }

        if picksCount > 0 {
            let noun = picksCount == 1 ? "pick" : "picks"
            return (
                title: "Today’s picks are ready",
                body: "You have \(picksCount) \(noun) waiting in StayConnected."
            )
        }

        return (
            title: "Stay connected today",
            body: "Open StayConnected and check in with someone important to you."
        )
    }

    static func reminderPreview(
        in ctx: NSManagedObjectContext,
        now: Date = Date()
    ) throws -> (title: String, body: String) {
        let state = try reminderState(in: ctx, now: now)

        if state.poolCount == 0 {
            return (
                title: "Build your pool first",
                body: "Add a few contacts so StayConnected can generate thoughtful daily picks."
            )
        }

        if state.hasCompletedConnectionToday {
            let noun = state.completedConnectionsToday == 1 ? "connection" : "connections"
            return (
                title: "You’re all set for today",
                body: "You’ve already logged \(state.completedConnectionsToday) \(noun). Come back tomorrow for a fresh nudge."
            )
        }

        if state.picksCount == 0 {
            return (
                title: "Today’s picks are waiting to be generated",
                body: "Open StayConnected to create today’s list and keep your routine moving."
            )
        }

        if state.currentStreak >= 3 {
            return (
                title: "Keep your \(state.currentStreak)-day streak alive",
                body: "Reach out to one of today’s \(state.picksCount == 1 ? "pick" : "picks") to stay on track."
            )
        }

        if state.daysSinceLastConnection >= 3 {
            return (
                title: "It’s been a few days",
                body: "A quick check-in today keeps important relationships from going cold."
            )
        }

        if state.picksCount == 1 {
            return (
                title: "One person is ready for a check-in",
                body: "Open StayConnected and make one small connection today."
            )
        }

        return (
            title: "Today’s picks are ready",
            body: "You have \(state.picksCount) people waiting in StayConnected."
        )
    }

    static func syncReminderIfNeeded(
        in ctx: NSManagedObjectContext,
        now: Date = Date()
    ) async throws {
        let settings = try AppSettings.fetchOrCreate(in: ctx)

        guard settings.remindersEnabled else {
            await cancelDailyReminder()
            return
        }

        let reminderTime = settings.reminderTime
            ?? Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: now)
            ?? now
        let preview = try reminderPreview(in: ctx, now: now)
        try await scheduleDailyReminder(
            at: reminderTime,
            title: preview.title,
            body: preview.body
        )
    }

    // MARK: - Cancellation

    static func cancelDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    // MARK: - Private Helpers

    private static func reminderState(
        in ctx: NSManagedObjectContext,
        now: Date
    ) throws -> ReminderState {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        let poolRequest: NSFetchRequest<Person> = Person.fetchRequest()
        poolRequest.predicate = NSPredicate(format: "isInPool == YES")
        let poolCount = try ctx.count(for: poolRequest)

        let todayEventsRequest: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        todayEventsRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfToday as NSDate,
            startOfTomorrow as NSDate
        )
        let completedConnectionsToday = try ctx.count(for: todayEventsRequest)

        let allEventsRequest: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        allEventsRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let allEvents = try ctx.fetch(allEventsRequest)

        let picksCount: Int
        if let dailyPick = try DailyPick.fetchFor(date: now, in: ctx) {
            let identifiers = dailyPick.contactIdentifiers as? [String]
            picksCount = identifiers?.count ?? 0
        } else {
            picksCount = 0
        }

        let daysSinceLastConnection: Int
        if let latest = allEvents.compactMap(\.date).max() {
            daysSinceLastConnection = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: latest),
                to: startOfToday
            ).day ?? 0
        } else {
            daysSinceLastConnection = Int.max
        }

        return ReminderState(
            poolCount: poolCount,
            picksCount: picksCount,
            completedConnectionsToday: completedConnectionsToday,
            hasCompletedConnectionToday: completedConnectionsToday > 0,
            currentStreak: currentStreak(from: allEvents, calendar: calendar, today: startOfToday),
            daysSinceLastConnection: daysSinceLastConnection
        )
    }

    private static func currentStreak(
        from events: [ConnectionEvent],
        calendar: Calendar,
        today: Date
    ) -> Int {
        let uniqueDays = Set(
            events.compactMap(\.date).map { calendar.startOfDay(for: $0) }
        )

        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = today

        if !uniqueDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  uniqueDays.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        while uniqueDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }
}

private struct ReminderState {
    let poolCount: Int
    let picksCount: Int
    let completedConnectionsToday: Int
    let hasCompletedConnectionToday: Bool
    let currentStreak: Int
    let daysSinceLastConnection: Int
}
