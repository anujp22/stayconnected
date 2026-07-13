import Foundation

// MARK: - Date Helpers

extension Date {
    /// Returns the start of the day in the user's current time zone using
    /// `Calendar.current`. (This is intentionally local time, not UTC — daily
    /// picks are keyed to the user's own day boundary.)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
