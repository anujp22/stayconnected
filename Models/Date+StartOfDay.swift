import Foundation

// MARK: - Date Helpers

extension Date {
    /// Returns the start of the day for the current date using `Calendar.current`.
    var startOfDayUTC: Date {
        Calendar.current.startOfDay(for: self)
    }
}
