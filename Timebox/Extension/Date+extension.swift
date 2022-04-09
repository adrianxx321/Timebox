//
//  Date+extension.swift
//  Timebox
//
//  Created by Lianghan Siew on 10/04/2022.
//

import Foundation

extension Date {
    func getNearestHour(_ time: Date) -> Date {
        var components = Calendar.current.dateComponents([.minute], from: time)
        let minute = components.minute ?? 0
        components.minute = minute >= 30 ? 60 - minute : -minute
        
        return Calendar.current.date(byAdding: components, to: time) ?? Date()
    }
    
    func getOneMinToMidnight(_ forDay: Date) -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: forDay) ?? Date()
    }
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
