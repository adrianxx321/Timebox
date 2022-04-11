//
//  TaskSessionViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI
import CoreData

class TaskSessionViewModel: ObservableObject {
    @Published var currentSession: TaskSession?
    
    private var context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    func getAllTaskSessions(query: FetchedResults<TaskSession>) -> [TaskSession] {
        return query.map{$0 as TaskSession}
    }
    
    func getTotalTimeboxedHours(data: [TaskSession]) -> String {
        let total = data.reduce(0) { $0 + $1.focusedDuration }
        
        return Date.formatTimeInterval(TimeInterval(total), unitStyle: .abbreviated, units: [.hour, .minute])
    }
    
    func presentGraphByWeek(data: [TaskSession]) -> [(String, Double)] {
        let defaultData: [(String, Double)] = [("Mon", 0), ("Tue", 0), ("Wed", 0),
                                              ("Thu", 0), ("Fri", 0), ("Sat", 0),
                                              ("Sun", 0)]
        
        if data.isEmpty {
            return defaultData
        } else {
            // Aggregate by the day (Mon/Tue etc.) of completion
            let subset = Dictionary(grouping: data, by: {
                $0.timestamp!.formatDateTime(format: "EEE")
            }).map { key, value in
                (key, value.reduce(0) {
                    $0 + $1.focusedDuration
                })
            }
            
            return defaultData.map { (key, value) -> (String, Double) in
                var temp = (key, value)
                subset.forEach { k, v in
                    temp = (key == k) ? (k, v) : temp
                }
                
                return temp
            }
        }
    }
    
    func presentGraphByMonth(data: [TaskSession]) -> [(String, Double)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentYear = components.year!
        let currentMonth = components.month!
        let defaultData: [(Int, Double)] = [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
        
        // Aggregate by the week number of current month
        // given the completion date
        let subset = Dictionary(grouping: data, by: {
            calendar.component(.weekOfMonth, from: $0.timestamp!)
        }).map { key, value in
            (key, value.reduce(0) {
                $0 + $1.focusedDuration
            })
        }
        
        let secondPass = defaultData.map { (key, value) -> (Int, Double)  in
            var temp = (key, value)
            subset.forEach { k, v in
                temp = (key == k) ? (k, v) : temp
            }
            
            return temp
        }
        
        return secondPass.map { (key, value) -> (String, Double) in
            // Use weekday = 2 to tell use Monday as first weekday
            let newComponents = DateComponents(year: currentYear, month: currentMonth, weekday: 2, weekOfMonth: key) // nth week of March
            // Getting first & last day given weekOfMonth
            let firstWeekday = calendar.date(from: newComponents)!
            let startDate = firstWeekday.formatDateTime(format: "d/M")
            
            return ("\(startDate) -", value)
        }
    }
    
    func compareProductivity(current: [TaskSession], previous: [TaskSession]) -> Int {
        let currentTotal = current.reduce(0) { $0 + $1.focusedDuration }
        let previousTotal = previous.reduce(0) { $0 + $1.focusedDuration }
        
        let delta = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 0
        
        return Int(delta)
    }
}
