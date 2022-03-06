//
//  TaskViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    
    // MARK: Current (selected) day
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
    
    func isCurrentDay(date: Date) -> Bool {
        let calendar = Calendar.current
        
        return calendar.isDate(currentDay, inSameDayAs: date)
    }
    
    func hasTask(_ tasks: [Task], date: Date?) -> Bool {
        // MARK: If no date is provided, check whether there is backlog task
        if date != nil {
            if filterTasks(tasks, date: date!, isAllDay: true, hideCompleted: false).count > 0 || filterTasks(tasks, date: date!, isAllDay: false, hideCompleted: false).count > 0 {
                return true
            } else {
                return false
            }
        }
        
        // MARK: Otherwise, check for scheduled tasks.
        else {
            return (tasks.filter { task in
                task.taskDate == nil
            }.count > 0) ? true : false
        }
    }
    
    func filterTasks(_ tasks: [Task], date: Date?, isAllDay: Bool, hideCompleted: Bool) -> [Task] {
        let calendar = Calendar.current
        var filteredTasks: [Task]
        
        // MARK: (1st pass) -> Scheduled or backlog tasks
        if date != nil {
            filteredTasks = tasks.filter { task in
                (isScheduledTask(task)) ? calendar.isDate(task.taskDate!, inSameDayAs: date!) : false
            }
        } else {
            filteredTasks = tasks.filter { task in
                task.taskDate == nil
            }
        }
        
        // MARK: (2nd pass) -> Tasks with all-day long (or not)
        filteredTasks = isAllDay ? filteredTasks.filter { task in
            isAllDayTask(task)
        } : filteredTasks.filter { task in
            !isAllDayTask(task)
        }
        
        // MARK: (Last pass) -> Exclude completed tasks (or not)
        return hideCompleted ? filteredTasks.filter { task in
            !task.isCompleted
        } : filteredTasks
    }
    
    func countCompletedSubtask(_ subtasks: [Subtask]) -> Int {
        var completedCount = 0
        
        for subtask in subtasks {
            completedCount += (subtask.isCompleted) ? 1 : 0
        }
        
        return completedCount
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
        return task.taskDate != nil ? true : false
    }
}
