//
//  TaskViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI
import EventKit

class TaskViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    @Published var addNewTask: Bool = false
    @Published var editTask: Task?
    // Subscribes to the source of truth
    @Published var settingsModel = SettingsViewModel()
    
    // Currently selected day...
    @Published var currentDay = Date()
    
    // MARK: Core Data environment
    @Environment(\.managedObjectContext) var context
    
    init() {
        getCurrentWeek()
    }
    
    func getCurrentWeek() {
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
    
    func importTasks() -> [Task] {
        let calendarStore = settingsModel.calendarStore
        var tasks = [Task]()
        
        if calendarStore.isEmpty {
            return tasks
        } else {
            let calendar = Calendar.current
            let eventStore = EKEventStore()
            let today = calendar.startOfDay(for: Date())
            let monthFromNow = calendar.date(byAdding: .month, value: 1, to: today)!
            let predicate = eventStore.predicateForEvents(withStart: today, end: monthFromNow, calendars: calendarStore)
            let events = eventStore.events(matching: predicate)
            
            events.forEach { event in
                let newTask = Task(context: context)
                newTask.id = UUID()
                newTask.taskTitle = event.title
                newTask.subtask = []
                newTask.taskLabel = event.calendar.title
                newTask.color = UIColor(cgColor: event.calendar.cgColor)
                newTask.isImportant = event.hasAlarms
                newTask.taskStartTime = event.isAllDay ? calendar.startOfDay(for: event.startDate) : event.startDate
                newTask.taskEndTime = event.isAllDay ? getOneMinToMidnight(event.startDate) : event.endDate
                newTask.isCompleted = false
                newTask.ekeventID = event.eventIdentifier
                
                tasks.append(newTask)
            }
        }
        
        return tasks
    }
    
    func lookupCalendarEvent(_ id: String) -> EKEvent? {
        let eventFinder = EKEventStore()
        
        return eventFinder.event(withIdentifier: id)
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
