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
    // Subscribes to the source of truth
    @Published var settingsModel = SettingsViewModel()
    // This is the store for events from all calendars
    // It is dependent on EKCalendar store from settings
    @Published var eventStore: [EKEvent] = []
    // Currently selected day...
    @Published var currentDay = Date()
    
    init() {
        getCurrentWeek()
        importCalendarEvents()
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
    
    func importCalendarEvents() {
        let calendarStore = settingsModel.calendarStore
        
        if calendarStore.isEmpty {
            return
        } else {
            // Dependency on Settings' ViewModel EKEvent accessor
            let eventStore = settingsModel.calendarAccessor
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let monthFromNow = calendar.date(byAdding: .month, value: 1, to: today)!
            let predicate = eventStore.predicateForEvents(withStart: today, end: monthFromNow, calendars: calendarStore)
            
            self.eventStore  = eventStore.events(matching: predicate)
        }
    }

    /// Detects if new event(s) are added into calendar. Returns the new mapped task if true, otherwise returns nil.
    func shouldAddNewEvents(taskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from source of truth & persistent store
        let originEK = Set(self.eventStore.map{self.EKEventMapper($0)})
        print(originEK.count)
        let persistentEK = Set(taskStore.filter{$0.ekeventID != nil})
        print(persistentEK.count)
        let addedEK = Array(originEK.subtracting(persistentEK))
        print(addedEK.count)
        
        return addedEK.isEmpty ? nil : addedEK
    }
    
    func addNewEventsToPersistent(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            let newTask = Task(context: context)
            
            newTask.id = event.id
            newTask.taskTitle = event.taskTitle
            newTask.subtask = []
            newTask.taskLabel = event.taskLabel
            newTask.color = event.color
            newTask.isImportant = event.isImportant
            newTask.taskStartTime = event.taskStartTime
            newTask.taskEndTime = event.taskEndTime
            newTask.isCompleted = false
            newTask.ekeventID = event.ekeventID
            
            context.insert(newTask)
        }
        
        try? context.save()
    }
    
    /// Detects if some events are removed from calendar. Returns the mapped to-be-removed tasks if true, otherwise returns nil.
    func shouldRemoveEvents(taskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from persistent & source of truth
        let originEK = Set(self.eventStore).map{self.EKEventMapper($0)}
        let persistentEK = Set(taskStore.filter{$0.ekeventID != nil})
        let removedEK = Array(persistentEK.subtracting(originEK))
        
        return removedEK.isEmpty ? nil : removedEK
    }
    
    func removeEventsFromPersistent(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            context.delete(event)
        }
        
        try? context.save()
    }
    
    /// Detects if event(s) from calendar are modified (includes addition, deletion and/or update). Returns the updated tasks if true, otherwise returns nil.
    func shouldUpdateEvents(taskStore: [Task]) -> [Task]? {
        var updatedTasks = [Task]()
        // Source of truth: The EKEvent instances loaded from API
        let sourceOfTruth = self.eventStore.map{self.EKEventMapper($0)}
        let persistentEvents = taskStore.filter{$0.ekeventID != nil}
        // Finding the differences between both arrays
        let difference = sourceOfTruth.difference(from: persistentEvents)
        let updatedEventStore = sourceOfTruth.applying(difference) ?? []
        
        // Return the subset of modified events
        for existingEvent in persistentEvents {
            for updatedEvent in updatedEventStore {
                let mutableUpdatedEvent = updatedEvent
                
                // Check if same event has been modified externally
                // Except for user-defineable properties
                if existingEvent.ekeventID == mutableUpdatedEvent.ekeventID
                    && (existingEvent.taskTitle != mutableUpdatedEvent.taskTitle
                    || existingEvent.taskLabel != mutableUpdatedEvent.taskLabel
                    || existingEvent.color != mutableUpdatedEvent.color
                    || existingEvent.taskStartTime != mutableUpdatedEvent.taskStartTime
                    || existingEvent.taskEndTime != mutableUpdatedEvent.taskEndTime)
                {
                    // We want to make sure while imported events changed
                    // The subtasks/completion status defined by user aren't affected
                    mutableUpdatedEvent.subtask = existingEvent.subtask
                    mutableUpdatedEvent.isCompleted = existingEvent.isCompleted
                    updatedTasks.append(mutableUpdatedEvent)
                }
            }
        }
        
        return updatedTasks.isEmpty ? nil : updatedTasks
    }

    /// Includes updates due to insertion, deletion &/ edit done from source of truth (Calendar app)
    func updateEvents(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            var task = context.object(with: event.objectID)
            task = event
        }
        
        try? context.save()
    }

    func EKEventMapper(_ event: EKEvent) -> Task {
        let mappedTask = Task(entity: Task.entity(), insertInto: nil)
        let calendar = Calendar.current
        
        // I extracted the second half of eventIdentifier string to use as the UUID
        // So the same event won't be mapped with random UUID everytime
        mappedTask.id = UUID(uuidString: "\(self.generateUUID(from: event.eventIdentifier)!)")
        mappedTask.taskTitle = event.title
        mappedTask.subtask = []
        mappedTask.taskLabel = event.calendar.title
        mappedTask.color = UIColor(cgColor: event.calendar.cgColor)
        mappedTask.isImportant = event.hasAlarms
        
        // MARK: This guy is probably causing the trouble
        // Because original calendar allows event to be spanned across days
        // But our app design doesn't allow that
        mappedTask.taskStartTime = event.isAllDay ? calendar.startOfDay(for: event.startDate) : event.startDate
        mappedTask.taskEndTime = event.isAllDay ? self.getOneMinToMidnight(event.startDate) : event.endDate
        
        mappedTask.isCompleted = false
        mappedTask.ekeventID = event.eventIdentifier
        
        return mappedTask
    }
    
    func lookupCalendarEvent(_ id: String) -> EKEvent? {
        return settingsModel.calendarAccessor.event(withIdentifier: id)
    }
    
    func getOngoingTasks(data: [Task]) -> [Task] {
        return data.filter {
            self.isOngoing($0)
        }
    }
    
    func getScheduledTasks(data: [Task], hideCompleted: Bool) -> [Task] {
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
    
    func generateUUID(from str: String) -> UUID? {
        let indexStartOfText = str.index(str.startIndex, offsetBy: 37)
        let substr = String(str[indexStartOfText...])
        
        return UUID(uuidString: substr)
    }
}
