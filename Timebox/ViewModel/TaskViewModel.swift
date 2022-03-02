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
        Task(isImported: false, taskTitle: "Discuss about the project ideation", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646092800), taskStartTime: .init(timeIntervalSince1970: 1646128800), taskEndTime: .init(timeIntervalSince1970: 1646131500), isCompleted: true, color: Color.blue, subtasks: []),
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
        Task(isImported: false, taskTitle: "Finish setting up staging server", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646092800), taskStartTime: nil, taskEndTime: nil, isCompleted: false, color: Color.blue, subtasks: []),
        Task(isImported: false, taskTitle: "Prepare user guide for completed website", isImportant: false, taskDate: .init(timeIntervalSince1970: 1646179200), taskStartTime: nil, taskEndTime: nil, isCompleted: false, color: Color.blue, subtasks: []),
    ]
    
    @Published var currentWeek: [Date] = []
    
    // MARK: Current day
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
        let toAddOrMinus = (offset < 0) ? -1 : 1
        let calendar = Calendar.current

        currentWeek = currentWeek.map { calendar.date(byAdding: .weekOfMonth, value: toAddOrMinus, to: $0)! }
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
}
