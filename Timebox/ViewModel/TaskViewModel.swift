//
//  TaskViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI
import CoreData

class TaskViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    @Published var currentMonth: [Date] = []
    @Published var addNewTask: Bool = false
    @Published var editTask: Task?
    
    // Currently selected day...
    @Published var currentDay = Date()
    
    init() {
        getCurrentWeek()
    }
    
    func getCurrentWeek() {
        let today = Date()
        let calendar = Calendar.current
        
        let week = calendar.dateInterval(of: .weekOfMonth, for: today)
        
        guard let firstWeekDay = week?.start else {
            return
        }
        
        (1...7).forEach { day in
            if let weekday = calendar.date(byAdding: .day, value: day, to: firstWeekDay) {
                currentWeek.append(weekday)
            }
        }
    }
    
    func getWeek(_ forWeek: Date) -> [Date] {
        var week: [Date] = []
        let calendar = Calendar.current
        
        let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: forWeek)
        
        guard let firstWeekDay = weekInterval?.start else {
            return week
        }
        
        (1...7).forEach { day in
            if let weekday = calendar.date(byAdding: .day, value: day, to: firstWeekDay) {
                week.append(weekday)
            }
        }
        
        return week
    }
    
    func getCurrentMonth() {
        let today = Date()
        let calendar = Calendar.current
        
        let month = calendar.dateInterval(of: .month, for: today)
        
        guard let firstMonthDay = month?.start, let lastMonthDay = month?.end else {
            return
        }
        
        repeat {
            var day = 1
            if let monthday = calendar.date(byAdding: .day, value: day, to: firstMonthDay) {
                currentMonth.append(monthday)
            }
            
            day += 1
        } while currentMonth.last! <= lastMonthDay
    }
    
    func updateWeek(offset: Int) {
        let calendar = Calendar.current

        currentWeek = currentWeek.map {
            calendar.date(byAdding: .weekOfMonth, value: offset, to: $0)!
        }
    }
    
    func formatDate(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
    
    func formatTimeInterval(startTime: Date,
                            endTime: Date,
                            unitStyle: DateComponentsFormatter.UnitsStyle,
                            units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        let interval = DateInterval(start: startTime, end: endTime).duration
        
        formatter.unitsStyle = unitStyle
        formatter.allowedUnits = units
        
        return formatter.string(from: interval) ?? ""
    }
    
    func formatTimeInterval(interval: TimeInterval, unitsStyle: DateComponentsFormatter.UnitsStyle, units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.unitsStyle = unitsStyle
        formatter.allowedUnits = units
        
        return formatter.string(from: interval) ?? ""
    }
    
    func getTimeRemaining(task: Task) -> String {
        var finalResult = ""
        
        if isTimeboxedTask(task) {
            let interval = formatTimeInterval(startTime: task.taskStartTime!,
                                             endTime: task.taskEndTime!,
                                             unitStyle: .full,
                                             units: [.hour, .minute])
            
            finalResult = "\(interval) left"
        } else if isAllDayTask(task) {
            let tasksLeft = task.subtasks.count - countCompletedSubtask(task.subtasks)
            
            finalResult = tasksLeft > 0 ? "\(tasksLeft) tasks left" : "Due today"
        }
        
        return finalResult
    }
    
    func getNearestHour(_ time: Date) -> Date {
        var components = Calendar.current.dateComponents([.minute], from: time)
        let minute = components.minute ?? 0
        components.minute = minute >= 30 ? 60 - minute : -minute
        
        return Calendar.current.date(byAdding: components, to: time) ?? Date()
    }
    
    func getOneMinToMidnight(_ forDay: Date) -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: forDay) ?? Date()
    }
    
    func isCurrentDay(date: Date) -> Bool {
        let calendar = Calendar.current
        
        return calendar.isDate(currentDay, inSameDayAs: date)
    }
    
    func countCompletedSubtask(_ subtasks: [Subtask]) -> Int {
        var completedCount = 0
        
        for subtask in subtasks {
            completedCount += (subtask.isCompleted) ? 1 : 0
        }
        
        return completedCount
    }
    
    func analyseTaskDoneByWeek(data: FetchedResults<Task>) -> [(String, Int64)] {
        let defaultData: [(String, Int64)] = [("Mon", 0), ("Tue", 0), ("Wed", 0),
                                              ("Thu", 0), ("Fri", 0), ("Sat", 0),
                                              ("Sun", 0)]
        
        if data.isEmpty {
            return defaultData
        } else {
            // Aggregate by the day (Mon/Tue etc.) of completion
            let subset = Dictionary(grouping: data, by: {
                formatDate(date: $0.completedTime!, format: "EEE")
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
    
    func analyseTaskDoneByMonth(data: FetchedResults<Task>) -> [(String, Int64)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentYear = components.year!
        let currentMonth = components.month!
        let defaultData: [(Int, Int64)] = [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
        
        // Aggregate by the week number of current month
        // given the completion date
        let subset = Dictionary(grouping: data, by: {
            calendar.component(.weekOfMonth, from: $0.completedTime!)
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
    
    func compareProductivity(current: FetchedResults<Task>, previous: FetchedResults<Task>) -> Int {
        let currentTotal = current.reduce(0) { $0 + $1.focusedDuration }
        let previousTotal = previous.reduce(0) { $0 + $1.focusedDuration }
        
        let delta = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 0
        
        return Int(delta)
    }
    
    func isTimeboxedTask(_ task: Task) -> Bool {
        return isScheduledTask(task) && !isAllDayTask(task)
    }
    
    func isAllDayTask(_ task: Task) -> Bool {
        // MARK: Calculate if duration is 24hrs
        if isScheduledTask(task) {
            return DateInterval(start: task.taskStartTime!, end: task.taskEndTime!).duration >= 86399 ? true : false
        } else {
            return false
        }
    }
    
    func isScheduledTask(_ task: Task) -> Bool {
        return task.taskStartTime != nil && task.taskEndTime != nil
    }
}
