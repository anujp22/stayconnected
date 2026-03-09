//
//  Date+StartOfDay.swift
//  StayConnected
//
//  Created by Anuj Patel on 9/28/25.
//

import Foundation

// MARK: - Date Helpers

extension Date {
    /// Returns the start of the day for the current date using `Calendar.current`.
    var startOfDayUTC: Date {
        Calendar.current.startOfDay(for: self)
    }
}
