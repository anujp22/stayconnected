import Foundation
import UserNotifications

// MARK: - Notifications Service

enum NotificationsService {

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
        center.removePendingNotificationRequests(withIdentifiers: ["daily.reminder"])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily.reminder",
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

    // MARK: - Cancellation

    static func cancelDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.reminder"])
    }
}
