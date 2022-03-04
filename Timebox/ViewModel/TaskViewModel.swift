//
//  TaskViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

class TaskViewModel: ObservableObject {
    // Dummy tasks
    @Published var storedTasks: [Task] = [
        // Timeboxed
        // Today
        Task(isImported: false, taskTitle: "Discuss about the project ideation", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646409600), taskStartTime: .init(timeIntervalSince1970: 1646445600), taskEndTime: .init(timeIntervalSince1970: 1646448300), isCompleted: true, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Get started on learning WordPress development", isImportant: true, taskDate: .init(timeIntervalSince1970: 1646409600), taskStartTime: .init(timeIntervalSince1970: 1646450100), taskEndTime: .init(timeIntervalSince1970: 1646453700), isCompleted: false, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Understanding WordPress anatomy", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Posts and pages", isSubtaskComplete: false)
        ]),
        Task(isImported: false, taskTitle: "Research how to migrate from Wix to WordPress", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646409600), taskStartTime: .init(timeIntervalSince1970: 1646456400), taskEndTime: .init(timeIntervalSince1970: 1646461800), isCompleted: false, color: Color.blue, subtasks: [
            Subtask(subtaskTitle: "Go through the documentation", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Try it out", isSubtaskComplete: false)
        ]),
        // Yesterday
        Task(isImported: false, taskTitle: "Reproduce React Native design to SwiftUI", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646323200), taskStartTime: .init(timeIntervalSince1970: 1646359200), taskEndTime: .init(timeIntervalSince1970: 1646366400), isCompleted: false, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Reverse engineer the whole thing", isSubtaskComplete: false),
            Subtask(subtaskTitle: "Good luck boi", isSubtaskComplete: false)
        ]),
        Task(isImported: false, taskTitle: "App ideation for dog hair cutter", isImportant: true, taskDate: .init(timeIntervalSince1970: 1646323200), taskStartTime: .init(timeIntervalSince1970: 1646330400), taskEndTime: .init(timeIntervalSince1970: 1646375400), isCompleted: false, color: Color.blue, subtasks: []),
        
        // Anytime
        // Today
        Task(isImported: false, taskTitle: "Cut and groom hair for my dog", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646409600), taskStartTime: .init(timeIntervalSince1970: 1646409600), taskEndTime: .init(timeIntervalSince1970: 1646495999), isCompleted: true, color: Color.orange, subtasks: []),
        Task(isImported: false, taskTitle: "Create COVID-19 vaccination card using PKPASS", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646409600), taskStartTime: .init(timeIntervalSince1970: 1646409600), taskEndTime: .init(timeIntervalSince1970: 1646495999), isCompleted: true, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Go through the documentation", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Try it out", isSubtaskComplete: false)
        ]),
        // Yesterday
        Task(isImported: false, taskTitle: "Get ready for interview", isImportant: true, taskDate: .init(timeIntervalSince1970: 1646323200), taskStartTime: .init(timeIntervalSince1970: 1646352000), taskEndTime: .init(timeIntervalSince1970: 1646409599), isCompleted: false, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Continue learning WordPress development", isImportant: true, taskDate: .init(timeIntervalSince1970: 1646323200), taskStartTime: .init(timeIntervalSince1970: 1646352000), taskEndTime: .init(timeIntervalSince1970: 1646409599), isCompleted: false, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Understanding WordPress anatomy", isSubtaskComplete: false),
            Subtask(subtaskTitle: "Posts and pages", isSubtaskComplete: false)
        ]),
        Task(isImported: false, taskTitle: "DB migration (Firebase -> CloudKit)", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646352000), taskStartTime: .init(timeIntervalSince1970: 1646352000), taskEndTime: .init(timeIntervalSince1970: 1646409599), isCompleted: false, color: Color.blue, subtasks: [
            Subtask(subtaskTitle: "Go through the documentation", isSubtaskComplete: false),
            Subtask(subtaskTitle: "Try it out", isSubtaskComplete: false)
        ]),
        
        // Planned
        Task(isImported: false, taskTitle: "Finish setting up staging server", isImportant: true, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: false, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Prepare user guide for completed website", isImportant: false, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: false, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Clean up database after AWS bulk upload", isImportant: false, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: true, color: Color.orange, subtasks: []),
        Task(isImported: false, taskTitle: "Continue learning React.JS", isImportant: true, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: false, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Go through the documentation", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Try it out", isSubtaskComplete: false)
        ]),
        Task(isImported: false, taskTitle: "Fix distorted image in the email builder", isImportant: false, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: true, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Prepare user guide for completed website", isImportant: false, taskDate: nil, taskStartTime: nil, taskEndTime: nil, isCompleted: true, color: Color.orange, subtasks: []),
    ]
    
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
            completedCount += (subtask.isSubtaskComplete) ? 1 : 0
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
