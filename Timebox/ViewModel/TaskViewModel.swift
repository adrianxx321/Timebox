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
        Task(isImported: false, taskTitle: "Lorem ipsum dolor sit amet", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646092800), taskStartTime: .init(timeIntervalSince1970: 1646128800), taskEndTime: .init(timeIntervalSince1970: 1646131500), isCompleted: true, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Get started on learning WordPress development", isImportant: true, taskDate: .init(timeIntervalSince1970: 1646092800), taskStartTime: .init(timeIntervalSince1970: 1646131500), taskEndTime: .init(timeIntervalSince1970: 1646136900), isCompleted: false, color: Color.orange, subtasks: [
            Subtask(subtaskTitle: "Understanding WordPress anatomy", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Posts and pages", isSubtaskComplete: false)
        ]),
        Task(isImported: false, taskTitle: "Research how to migrate from Wix to WordPress", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646132600), taskStartTime: .init(timeIntervalSince1970: 1646226000), taskEndTime: .init(timeIntervalSince1970: 1646231400), isCompleted: false, color: Color.blue, subtasks: [
            Subtask(subtaskTitle: "Go through the documentation", isSubtaskComplete: true),
            Subtask(subtaskTitle: "Try it out", isSubtaskComplete: false)
        ]),
        

        // Anytime
        Task(isImported: false, taskTitle: "Cut hair for my dog", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646092800), taskStartTime: .init(timeIntervalSince1970: 1646092800), taskEndTime: .init(timeIntervalSince1970: 1646179199), isCompleted: true, color: Color.orange, subtasks: []),
        Task(isImported: false, taskTitle: "Cut hair for my cat", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646179200), taskStartTime: .init(timeIntervalSince1970: 1646179200), taskEndTime: .init(timeIntervalSince1970: 1646265599), isCompleted: true, color: Color.blue, subtasks: []),
        
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
        // MARK: If no date is provided, check whether there is backlog task; otherwise, check for scheduled tasks.
        if date != nil {
            if filterTasks(tasks, date: date!, isAllDay: true, hideCompleted: false).count > 0 || filterTasks(tasks, date: date!, isAllDay: false, hideCompleted: false).count > 0 {
                return true
            } else {
                return false
            }
        } else {
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
                (task.taskDate != nil) ? calendar.isDate(task.taskDate!, inSameDayAs: date!) : false
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
        guard (task.taskStartTime != nil && task.taskEndTime != nil) else {
            return false
        }
        
        return (DateInterval(start: task.taskStartTime!, end: task.taskEndTime!).duration >= 86399) ? true : false
    }
}
