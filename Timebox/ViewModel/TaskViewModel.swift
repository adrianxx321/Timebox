//
//  TaskViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI
import EventKit
import CoreData

class TaskViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    @Published var addNewTask: Bool = false
    @Published var editTask: Task?
    @Published var currentDay = Date()
    // MARK: Core Data shared context
    private var context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    // Get current week...
    init() {
        let today = Date()
        let calendar = Calendar.current
        
        // Because week ends at 00:00 of the Sunday (supposed to be 23:59)
        // Therefore we need to do some adjustment
        // So that this doesn't mistakenly return next week as current week
        // If current time is after 00:00 of the Sunday
        var week = calendar.dateInterval(of: .weekOfMonth, for: today)
        if today > (week?.start ?? today) {
            week = calendar.dateInterval(of: .weekOfMonth, for: calendar.date(byAdding: .day, value: -1, to: today)!)
        }
        
        // 2022-03-27 00:00:00
        guard let firstWeekDay = week?.start,
        let lastWeekDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: week!.end) else {
            return
        }
        
        (1...7).forEach { day in
            if let weekday = calendar.date(byAdding: .day, value: day, to: firstWeekDay) {
                currentWeek.append(weekday)
            }
        }
        // Replace so that week ends at 23:59 of Sunday
        currentWeek[currentWeek.count - 1] = lastWeekDay
    }
    
    func updateWeek(offset: Int) {
        let calendar = Calendar.current

        currentWeek = currentWeek.map {
            calendar.date(byAdding: .weekOfMonth, value: offset, to: $0)!
        }
    }
    
    func getAllTasks(query: FetchedResults<Task>) -> [Task] {
        return query.map{$0 as Task}
    }
    
    func filterAllCompletedTasks(data: [Task]) -> [Task] {
        return data.filter{ $0.isCompleted }
    }
    
    func filterScheduledTasks(data: [Task], hideCompleted: Bool) -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: self.currentDay)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        if data.isEmpty {
            return []
        } else {
            let filtered = data.filter {
                self.isScheduledTask($0)
            }.filter {
                $0.taskStartTime! >= today && $0.taskStartTime! < tomorrow
            }
            
            return hideCompleted ? filtered.filter{ !$0.isCompleted } : filtered
        }
    }
    
    func filterTimeboxedTasks(data: [Task]) -> [Task] {
        return data.filter { self.isTimeboxedTask($0) }
    }
    
    func filterAllDayTasks(data: [Task]) -> [Task] {
        return data.filter { self.isAllDayTask($0) }
    }
    
    func filterOngoingTasks(data: [Task]) -> [Task] {
        return data.filter {
            self.isOngoing($0)
        }
    }
    
    func addTask(id: UUID, _ taskTitle: String,
                 _ subtasks: [Subtask], _ taskLabel: String,
                 _ color: UIColor, _ isImportant: Bool,
                 _ taskStartTime: Date?, _ taskEndTime: Date?) {
        let task = Task(context: self.context)
        task.id = id
        task.taskTitle = taskTitle
        
        subtasks.forEach { subtask in
            let newSubtask = Subtask(context: self.context)
            newSubtask.subtaskTitle = subtask.subtaskTitle
            newSubtask.timestamp = subtask.timestamp
            newSubtask.isCompleted = subtask.isCompleted
            
            task.subtask = task.subtask?.adding(newSubtask) as NSSet?
        }
        
        task.taskLabel = (taskLabel == "") ? nil : taskLabel
        task.color = color
        task.isImportant = isImportant
        task.taskStartTime = taskStartTime
        task.taskEndTime = taskEndTime
        task.isCompleted = false
        // This is for imported event from Calendar API
        task.ekeventID = nil
        
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    func addSubtask() -> Subtask {
        let newSubtask = Subtask(context: context)
        newSubtask.subtaskTitle = ""
        newSubtask.timestamp = Date()
        newSubtask.isCompleted = false
        
        newSubtask.objectWillChange.send()
        return newSubtask
    }
    
    func updateTask(task: Task, _ taskTitle: String, _ subtasks: [Subtask],
                    _ taskLabel: String, _ color: UIColor, _ isImportant: Bool,
                    _ taskStartTime: Date?, _ taskEndTime: Date?) {
        task.taskTitle = taskTitle
        
        // Remove all old subtasks before reinserting new ones
        task.subtask = []
        subtasks.forEach { subtask in
            let editSubtask = Subtask(context: context)
            editSubtask.subtaskTitle = subtask.subtaskTitle
            editSubtask.timestamp = subtask.timestamp
            editSubtask.isCompleted = subtask.isCompleted
            
            task.subtask = task.subtask?.adding(editSubtask) as NSSet?
        }
        
        task.taskLabel = (taskLabel == "") ? nil : taskLabel
        task.color = color
        task.isImportant = isImportant
        task.taskStartTime = taskStartTime
        task.taskEndTime = taskEndTime
        
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    func deleteTask(task: Task) {
        context.delete(task)
        
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    func completeTask(_ task: Task) {
        task.isCompleted.toggle()
        
        // Save to Core Data
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    func completeSubtask(parentTask: Task, subtask: Subtask) {
        // We need this "magic" to overcome the fact that Core Data can't handle view update on to-many entities...
        parentTask.objectWillChange.send()
        subtask.isCompleted.toggle()
        
        // Automatically check parent task as completed
        // When all subtasks are done...
        parentTask.isCompleted = !parentTask.subtasks
            .contains(where: { !$0.isCompleted })
        
        // Save to Core Data...
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }

    func getTaskTimeRemaining(task: Task) -> String {
        var finalResult = ""
        
        if isTimeboxedTask(task) {
            let interval = (task.taskEndTime ?? Date()) - Date()
            let intervalString = Date.formatTimeDuration(interval, unitStyle: .short, units: [.hour, .minute]) 
            
            finalResult = "\(intervalString) left"
        } else if isAllDayTask(task) {
            let tasksLeft = task.subtasks.count - countCompletedSubtask(task.subtasks)
            
            finalResult = tasksLeft > 0 ? "\(tasksLeft) tasks left" : "Due today"
        }
        
        return finalResult
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
    
    func getCompletedTaskCount(_ tasks: [Task]) -> Int {
        return tasks.filter { $0.isCompleted }.count
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
    
    func isOngoing(_ task: Task) -> Bool {
        return task.taskStartTime ?? Date() <= Date() && task.taskEndTime ?? Date() > Date()
    }
    
    func isOverdue(_ task: Task) -> Bool {
        return task.taskEndTime ?? Date() < Date()
    }
}
