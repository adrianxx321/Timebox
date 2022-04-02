//
//  TaskSessionViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI

class TaskSessionViewModel: ObservableObject {
    // Some properties to be used by timer
    
    func getTotalTimeboxedHours(data: [TaskSession]) -> String {
        let total = data.reduce(0) { $0 + $1.focusedDuration }
        
        return self.formatTimeInterval(interval: TimeInterval(total), unitsStyle: .abbreviated, units: [.hour, .minute])
    }
    
    func analyseTimeboxByWeek(data: [TaskSession]) -> [(String, Int64)] {
        let defaultData: [(String, Int64)] = [("Mon", 0), ("Tue", 0), ("Wed", 0),
                                              ("Thu", 0), ("Fri", 0), ("Sat", 0),
                                              ("Sun", 0)]
        
        if data.isEmpty {
            return defaultData
        } else {
            // Aggregate by the day (Mon/Tue etc.) of completion
            let subset = Dictionary(grouping: data, by: {
                formatDate(date: $0.timestamp!, format: "EEE")
            }).map { key, value in
                (key, value.reduce(0) {
                    $0 + $1.focusedDuration
                })
            }
            
            return defaultData.map { (key, value) -> (String, Int64) in
                var temp = (key, value)
                subset.forEach { k, v in
                    temp = (key == k) ? (k, v) : temp
                }
                
                return temp
            }
        }
    }
    
    func analyseTimeboxByMonth(data: [TaskSession]) -> [(String, Int64)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentYear = components.year!
        let currentMonth = components.month!
        let defaultData: [(Int, Int64)] = [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
        
        // Aggregate by the week number of current month
        // given the completion date
        let subset = Dictionary(grouping: data, by: {
            calendar.component(.weekOfMonth, from: $0.timestamp!)
        }).map { key, value in
            (key, value.reduce(0) {
                $0 + $1.focusedDuration
            })
        }
        
        let secondPass = defaultData.map { (key, value) -> (Int, Int64)  in
            var temp = (key, value)
            subset.forEach { k, v in
                temp = (key == k) ? (k, v) : temp
            }
            
            return temp
        }
        
        
        return secondPass.map { (key, value) -> (String, Int64) in
            // Use weekday = 2 to tell use Monday as first weekday
            let newComponents = DateComponents(year: currentYear, month: currentMonth, weekday: 2, weekOfMonth: key) // nth week of March
            // Getting first & last day given weekOfMonth
            let firstWeekday = calendar.date(from: newComponents)!
            let startDate = formatDate(date: firstWeekday, format: "d/M")
            
            return ("\(startDate) -", value)
        }
    }
    
    func compareProductivity(current: [TaskSession], previous: [TaskSession]) -> Int {
        let currentTotal = current.reduce(0) { $0 + $1.focusedDuration }
        let previousTotal = previous.reduce(0) { $0 + $1.focusedDuration }
        
        let delta = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 0
        
        return Int(delta)
    }
    
    func formatDate(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
    
    func formatTimeInterval(interval: TimeInterval, unitsStyle: DateComponentsFormatter.UnitsStyle, units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.unitsStyle = unitsStyle
        formatter.allowedUnits = units
        
        return formatter.string(from: interval) ?? ""
    }
}
