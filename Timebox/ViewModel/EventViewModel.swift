//
//  EventViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/04/2022.
//

import SwiftUI
import EventKit
import CoreData

class EventViewModel: ObservableObject {
    // This is the store for all calendar entities retrieved from your calendar
    @Published var calendarStore = [EKCalendar]()
    // This is the store for events from all calendars
    @Published var eventStore: [EKEvent] = []
    // Singleton EventKit API accessor
    static let CalendarAccessor = EKEventStore()
    @AppStorage("syncCalendarsAllowed") var syncCalendarsAllowed = false
    
    init() {
        // Not sure if this check is needed...
        if syncCalendarsAllowed {
            // Initialise calendar store...
            self.calendarStore = EventViewModel.CalendarAccessor.calendars(for: .event)
            
            // Initialise event store...
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let monthFromNow = calendar.date(byAdding: .month, value: 1, to: today)!
            let predicate = EventViewModel.CalendarAccessor.predicateForEvents(withStart: today, end: monthFromNow, calendars: calendarStore)
            
            self.eventStore = EventViewModel.CalendarAccessor.events(matching: predicate)
        }
    }
    
    /// Request user's permission for calendars for once
    func requestCalendarAccessPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        if EKAuthStatus == .notDetermined {
            EventViewModel.CalendarAccessor.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.syncCalendarsAllowed = granted
                }
            }
        } else if EKAuthStatus == .denied {
            DispatchQueue.main.async {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
    }

    /// Detects if new event(s) are added into calendar. Returns true for insertions, false for deletion..
    func shouldAddNewEvents(taskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from source of truth & persistent store
        let originEK = self.eventStore.map{self.EKEventMapper($0)}
        let persistentEK = taskStore.filter{$0.ekeventID != nil}
        let addedEvents = originEK.filter { (origin: Task) -> Bool in
            !persistentEK.contains { (existing: Task) -> Bool in
                existing.id == origin.id
            }
        }
        print("\(originEK.count) - \(persistentEK.count) = \(addedEvents.count)")
        
        return addedEvents.isEmpty ? nil : addedEvents
    }
    
    func addNewEventsToPersistent(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            let newTask = Task(context: context)
            
            newTask.id = event.id
            newTask.taskTitle = event.taskTitle
            newTask.taskLabel = event.taskLabel
            newTask.color = event.color
            newTask.taskStartTime = event.taskStartTime
            newTask.taskEndTime = event.taskEndTime
            newTask.ekeventID = event.ekeventID
            
            newTask.subtask = event.subtask
            newTask.isImportant = event.isImportant
            newTask.isCompleted = event.isCompleted
            
            context.insert(newTask)
        }
        
        try? context.save()
    }
    
    /// Detects if some events are removed from calendar. Returns the mapped to-be-removed tasks if true, otherwise returns nil.
    func shouldRemoveEvents(taskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from persistent & source of truth
        let originEK = self.eventStore.map{self.EKEventMapper($0)}
        let persistentEK = taskStore.filter{$0.ekeventID != nil}
        let removedEvents = persistentEK.filter { (existing: Task) -> Bool in
            !originEK.contains { (origin: Task) -> Bool in
                origin.id == existing.id
            }
        }
        
        print("\(removedEvents.count) = \(persistentEK.count) - \(originEK.count)")
        
        return removedEvents.isEmpty ? nil : removedEvents
    }

    func removeEventsFromPersistent(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            var removedTask = Task(context: context)
            removedTask = event
            context.delete(removedTask)
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
                // Check if same event has been modified externally
                // Except for user-defineable properties
                if existingEvent.ekeventID == updatedEvent.ekeventID {
                    existingEvent.taskTitle = updatedEvent.taskTitle
                    existingEvent.taskLabel = updatedEvent.taskLabel
                    existingEvent.color = updatedEvent.color
                    existingEvent.taskStartTime = updatedEvent.taskStartTime
                    existingEvent.taskEndTime = updatedEvent.taskEndTime
                    
                    updatedTasks.append(existingEvent)
                }
            }
        }
        
        return updatedTasks.isEmpty ? nil : updatedTasks
    }

    /// Includes updates due to insertion, deletion &/ edit done from source of truth (Calendar app)
    func updateEvents(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            var updatedTask = context.object(with: event.objectID)
            updatedTask = event
        }
        
        try? context.save()
    }

    func EKEventMapper(_ event: EKEvent) -> Task {
        let mappedTask = Task(entity: Task.entity(), insertInto: nil)
        let calendar = Calendar.current
        
        // I extracted the second half of eventIdentifier string to use as the UUID
        // So the same event won't be mapped with random UUID everytime
        mappedTask.id = UUID(uuidString: "\(self.generateUUIDFromEvent(from: event.eventIdentifier)!)")
        mappedTask.taskTitle = event.title
        mappedTask.subtask = []
        mappedTask.taskLabel = event.calendar.title
        mappedTask.color = UIColor(cgColor: event.calendar.cgColor)
        mappedTask.isImportant = event.hasAlarms
        
        // MARK: This guy is probably causing the trouble
        // Because original calendar allows event to be spanned across days
        // But our app design doesn't allow that
        mappedTask.taskStartTime = event.isAllDay ? calendar.startOfDay(for: event.startDate) : event.startDate
        mappedTask.taskEndTime = event.isAllDay ? calendar.date(bySettingHour: 23, minute: 59, second: 59, of: event.startDate) : event.endDate
        
        mappedTask.isCompleted = false
        mappedTask.ekeventID = event.eventIdentifier
        
        return mappedTask
    }
    
    func lookupCalendarEvent(_ id: String) -> EKEvent? {
        return EventViewModel.CalendarAccessor.event(withIdentifier: id)
    }
    
    func generateUUIDFromEvent(from str: String) -> UUID? {
        let indexStartOfText = str.index(str.startIndex, offsetBy: 37)
        let substr = String(str[indexStartOfText...])
        
        return UUID(uuidString: substr)
    }
}
