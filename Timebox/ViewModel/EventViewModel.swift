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
    @AppStorage("selectedCalendars") var selectedCalendars = ""
    
    init() {
        // Not sure if this check is needed...
        if syncCalendarsAllowed {
            // Initialise calendar store...
            // selectedCalendars is a delimited string sequence that contains all the calendar IDs
            self.calendarStore = self.selectedCalendars.count <= 0 ?
            EventViewModel.CalendarAccessor.calendars(for: .event) : self.decodeSelectedCalendars(self.selectedCalendars)
            
            // Remember the selected calendars...
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
            
            // Initialise event store...
            let calendar = Calendar.current
            // Limit range from 1 year ago to a year after
            let lastYear = calendar.date(byAdding: .year, value: -1, to: Date())!
            let oneYearLater = calendar.date(byAdding: .year, value: 2, to: lastYear)!
            let predicate = EventViewModel.CalendarAccessor.predicateForEvents(withStart: lastYear, end: oneYearLater, calendars: self.calendarStore)
            
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
    
    func updateCalendarStore(put: Bool, selected: EKCalendar) {
        if put {
            self.calendarStore.append(selected)
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
            print("selected calendar: \(selected)")
        } else {
            guard let index = self.calendarStore.firstIndex(of: selected) else {
                return
            }
            self.calendarStore.remove(at: index)
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
            print("unselected calendar: \(selected)")
        }
    }
    
    /// Detects if new event(s) are added into calendar. Returns true for insertions, false for deletion..
    func shouldAddNewEvents(taskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from source of truth & persistent store
        let originEK = self.eventStore.map{self.EKEventMapper($0)}
        let persistentEK = taskStore.filter{$0.ekeventID != nil}
        let addedEvents = originEK.filter { (origin: Task) -> Bool in
            !persistentEK.contains { (existing: Task) -> Bool in
                existing.ekeventID == origin.ekeventID
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
                origin.ekeventID == existing.ekeventID
            }
        }
        
        print("\(removedEvents.count) = \(persistentEK.count) - \(originEK.count)")
        
        return removedEvents.isEmpty ? nil : removedEvents
    }

    func removeEventsFromPersistent(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            var removedTask = context.object(with: event.objectID) as! Task
            removedTask = event
            context.delete(removedTask)
        }
        
        try? context.save()
    }
    
    /// Detects if event(s) from calendar are modified (includes addition, deletion and/or update). Returns the updated tasks if true, otherwise returns nil.
    func shouldUpdateEvents(taskStore: [Task]) -> [Task]? {
        var updatedTasks = [Task]()
        // Assumes both source of truth and persisted store have equal number of objects
        let sourceOfTruth = self.eventStore.map{self.EKEventMapper($0)}
        let persistentEvents = taskStore.filter{$0.ekeventID != nil}
        
        // Finding the differences between both arrays
        sourceOfTruth.forEach { event in
            persistentEvents.forEach { task in
                if event.ekeventID == task.ekeventID {
                    if task.taskTitle != event.taskTitle
                        || task.taskLabel != event.taskLabel
                        || task.color != event.color
                        || task.taskStartTime != event.taskEndTime
                        || task.taskEndTime != event.taskEndTime {
                        updatedTasks.append(task)
                    }
                }
            }
        }

        return updatedTasks.isEmpty ? nil : updatedTasks
    }

    /// Includes updates due to insertion, deletion &/ edit done from source of truth (Calendar app)
    func updateEvents(context: NSManagedObjectContext, events: [Task]) {
        events.forEach { event in
            let calendar = Calendar.current
            if let updatedEvent = EventViewModel.CalendarAccessor.event(withIdentifier: event.ekeventID!) {
                let updatedTask = context.object(with: event.objectID) as! Task
                updatedTask.taskTitle = updatedEvent.title
                updatedTask.taskLabel = updatedEvent.calendar.title
                updatedTask.color = UIColor(cgColor: updatedEvent.calendar.cgColor)
                updatedTask.taskStartTime = updatedEvent.isAllDay ? calendar.startOfDay(for: updatedEvent.startDate) : updatedEvent.startDate
                updatedTask.taskEndTime = updatedEvent.isAllDay ? calendar.date(bySettingHour: 23, minute: 59, second: 59, of: updatedEvent.startDate) : updatedEvent.endDate
            }
        }
        
        try? context.save()
    }

    func EKEventMapper(_ event: EKEvent) -> Task {
        let mappedTask = Task(entity: Task.entity(), insertInto: nil)
        let calendar = Calendar.current
        
        // I extracted the second half of eventIdentifier string to use as the UUID
        // So the same event won't be mapped with random UUID everytime
        mappedTask.id = self.generateUUIDFromEvent(from: event.eventIdentifier)
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
    
    func generateUUIDFromEvent(from str: String) -> UUID {
        let indexStartOfText = str.index(str.startIndex, offsetBy: 37)
        let substr = String(str[indexStartOfText...])
        
        return UUID(uuidString: substr) ?? UUID()
    }
    
    func encodeSelectedCalendars(_ calendars: [EKCalendar]) -> String {
        return calendars.map{$0.calendarIdentifier}.joined(separator: "&?")
    }
    
    func decodeSelectedCalendars(_ code: String) -> [EKCalendar] {
        var calendars: [EKCalendar] = []
        let identifiers = code.components(separatedBy: "&?")
        
        identifiers.forEach { id in
            guard let found = EventViewModel.CalendarAccessor.calendar(withIdentifier: id) else {
                return
            }
            calendars.append(found)
        }
        
        return calendars
    }
}
