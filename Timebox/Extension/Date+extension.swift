//
//  Date+extension.swift
//  Timebox
//
//  Created by Lianghan Siew on 10/04/2022.
//

import Foundation

extension Date {
    /// Get date difference by directly subtracting one from another
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    
    /// Returns formatted time duration from TimeInterval
    static func formatTimeInterval(_ interval: TimeInterval,
                                   unitStyle: DateComponentsFormatter.UnitsStyle,
                                   units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.unitsStyle = unitStyle
        formatter.allowedUnits = units
        
        return formatter.string(from: interval) ?? "NaN"
    }
    
    /// Format a date using the formatter string provided
    func formatDateTime(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
    
    /// Returns the nearest hour from current time
    func getNearestHour() -> Date {
        var components = Calendar.current.dateComponents([.minute], from: self)
        let minute = components.minute ?? 0
        components.minute = minute >= 30 ? 60 - minute : -minute
        
        return Calendar.current.date(byAdding: components, to: self) ?? Date()
    }
    
    /// Returns the time which is 23:59:59 of the same day
    func getOneMinToMidnight() -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? Date()
    }
}
