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
    @Published var eventStore: [Task] = []
    // Calendar permission - Default to false as we haven't get user consent
    @AppStorage("syncCalendarsAllowed") var syncCalendarsAllowed: Bool = false
    // So does the list of selected calendar
    @AppStorage("selectedCalendars") private var selectedCalendars: String = ""
    // A one-way toggle that allows first-time user to have all calendars selected
    // After first granted calendar pemrission
    @AppStorage("isfirstTimeSelect") private var isFirstTimeSelect = true
    // Singleton EventKit API accessor
    static let CalendarAccessor = EKEventStore()
    // MARK: Core Data shared context
    private var context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    init() {
        loadCalendarsPermission()
        loadCalendars()
        loadEvents()
    }
    
    private func loadCalendarsPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        DispatchQueue.main.async {
            self.syncCalendarsAllowed = EKAuthStatus == .authorized
        }
    }
    
    /// Request user's permission for calendars for once
    func requestCalendarAccessPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        if EKAuthStatus == .notDetermined {
            EventViewModel.CalendarAccessor.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.syncCalendarsAllowed = granted
                    // After granted permission first time we need to load the calendars again.
                    // So that the list isn't emptly selected
                    self.loadCalendars()
                }
            }
        } else if EKAuthStatus == .denied {
            DispatchQueue.main.async {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
    }
    
    func loadCalendars() {
        if self.syncCalendarsAllowed {
            // Initialise calendar store...
            // selectedCalendars is a delimited string sequence that contains all the calendar IDs
            self.calendarStore = self.isFirstTimeSelect ?
            EventViewModel.CalendarAccessor.calendars(for: .event) : self.decodeSelectedCalendars(self.selectedCalendars)
            
            // One-time tripping the toggle. Since the auth status will never be notDetermined again after permission granted
            self.isFirstTimeSelect = false
            
            // Remember the selected calendars...
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
        } else {
            // If user revokes calendar permission in the middle
            self.calendarStore = []
            self.selectedCalendars = ""
        }
    }
    
    func loadEvents() {
        if self.syncCalendarsAllowed && !self.calendarStore.isEmpty {
            // Initialise event store...
            let calendar = Calendar.current
            
            // Limit range to within this year
            var dateComponents = DateComponents()
            dateComponents.year = calendar.component(.year, from: Date())
            dateComponents.month = 1
            dateComponents.day = 1

            let currentYear = calendar.date(from: dateComponents)!
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: currentYear)!
            let predicate = EventViewModel.CalendarAccessor.predicateForEvents(withStart: currentYear, end: endOfYear, calendars: self.calendarStore)
            
            self.eventStore = EventViewModel.CalendarAccessor
                .events(matching: predicate)
                .map{self.EKEventMapper($0)}
        } else {
            self.eventStore = []
        }
    }
    
    func updateCalendarStore(put: Bool, selected: EKCalendar) {
        if put {
            self.calendarStore.append(selected)
            
            // Remember the selected calendars...
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
        } else {
            guard let index = self.calendarStore.firstIndex(of: selected) else {
                return
            }
            self.calendarStore.remove(at: index)
            
            // Remember the selected calendars...
            self.selectedCalendars = self.encodeSelectedCalendars(self.calendarStore)
        }
    }
    
    func updatePersistedEventStore(persistentTaskStore: [Task]) {
        if let newEvents = self.shouldAddNewEvents(persistentTaskStore) {
            self.addNewEventsToPersistent(newEvents)
            print("Added \(newEvents.count) events")
        }

        if let removedEvents = self.shouldRemoveEvents(persistentTaskStore) {
            self.removeEventsFromPersistent(removedEvents)
            print("Removed \(removedEvents.count) events")
        }

        if let updatedEvents = self.shouldUpdateEvents(persistentTaskStore) {
            self.updateEvents(persistedTaskStore: persistentTaskStore, updatedEvents: updatedEvents)
            print("Updated \(updatedEvents.count) events")
        }
    }
    
    private func shouldAddNewEvents(_ persistentTaskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from source of truth & persistent store
        let sourceOfTruth = self.eventStore
        let persistent = persistentTaskStore.filter{$0.ekeventID != nil}
        let addedEvents = sourceOfTruth.filter { (origin: Task) -> Bool in
            !persistent.contains { (existing: Task) -> Bool in
                existing.ekeventID == origin.ekeventID
            }
        }
        
        return addedEvents.isEmpty ? nil : addedEvents
    }
    
    private func addNewEventsToPersistent(_ events: [Task]) {
        events.forEach { event in
            let newTask = Task(context: self.context)
            
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
            
            self.context.insert(newTask)
        }
        
        // Save to Core Data
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    private func shouldRemoveEvents(_ persistentTaskStore: [Task]) -> [Task]? {
        // Finding the difference between sets from persistent & source of truth
        let sourceOfTruth = self.eventStore
        let persistent = persistentTaskStore.filter{$0.ekeventID != nil}
        let removedEvents = persistent.filter { (existing: Task) -> Bool in
            !sourceOfTruth.contains { (origin: Task) -> Bool in
                origin.ekeventID == existing.ekeventID
            }
        }

        return removedEvents.isEmpty ? nil : removedEvents
    }

    private func removeEventsFromPersistent(_ events: [Task]) {
        events.forEach { event in
            var removedTask = self.context.object(with: event.objectID) as! Task
            removedTask = event
            self.context.delete(removedTask)
        }
        
        // Save to Core Data
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    /// Detects if event(s) from calendar are modified. Returns the updated tasks if true, otherwise returns nil.
    private func shouldUpdateEvents(_ persistentTaskStore: [Task]) -> [Task]? {
        let sourceOfTruth = self.eventStore
        let persistent = persistentTaskStore.filter{$0.ekeventID != nil}
        let editedEvents = sourceOfTruth.filter { origin in
            persistent.contains{ (existing: Task) -> Bool in
                if existing.ekeventID == origin.ekeventID {
                    let hasModified = existing.taskTitle != origin.taskTitle
                                        || existing.taskLabel != origin.taskLabel
                                        || existing.color!.isEqualWithConversion(origin.color!)
                                        || existing.taskStartTime != origin.taskStartTime
                                        || existing.taskEndTime != origin.taskEndTime
                    
                    return hasModified
                } else {
                    return false
                }
            }
        }
        
        return editedEvents.isEmpty ? nil : editedEvents
    }

    private func updateEvents(persistedTaskStore: [Task], updatedEvents: [Task]) {
        // Note: <events> is the source of truth
        // Our target is to modify the persisted context
        persistedTaskStore.forEach { existing in
            updatedEvents.forEach { updated in
                if existing.ekeventID == updated.ekeventID {
                    guard let updatedTask = self.context.object(with: existing.objectID) as? Task else {
                        return
                    }
                    
                    updatedTask.taskTitle = updated.taskTitle
                    updatedTask.taskLabel = updated.taskLabel
                    updatedTask.color = updated.color
                    updatedTask.taskStartTime = updated.taskStartTime
                    updatedTask.taskEndTime = updated.taskEndTime
                }
            }
        }
        
        // Save to Core Data
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }

    private func EKEventMapper(_ event: EKEvent) -> Task {
        let mappedTask = Task(entity: Task.entity(), insertInto: nil)
        let calendar = Calendar.current
        
        // I extracted the second half of eventIdentifier string to use as the UUID
        // So the same event won't be mapped with random UUID everytime
        // Because my goal is to maintain the integrity between EK API & Core Data
        mappedTask.id = UUID()
        mappedTask.taskTitle = event.title
        mappedTask.subtask = []
        mappedTask.taskLabel = event.calendar.title
        
        mappedTask.color = UIColor(cgColor: event.calendar.cgColor)
        mappedTask.isImportant = event.hasAlarms
        
        mappedTask.taskStartTime = event.isAllDay ? calendar.startOfDay(for: event.startDate) : event.startDate
        mappedTask.taskEndTime = event.isAllDay ? calendar.date(bySettingHour: 23, minute: 59, second: 59, of: event.startDate) : event.endDate
        
        mappedTask.isCompleted = false
        mappedTask.ekeventID = event.eventIdentifier
        
        return mappedTask
    }
    
    func lookupCalendarEvent(_ id: String) -> EKEvent? {
        return EventViewModel.CalendarAccessor.event(withIdentifier: id)
    }
    
    /// Attempts to convert EKEvent's taskIdentifier to UUID. Returns randomly generated UUID if fails.
    private func generateUUIDFromEvent(from str: String) -> UUID {
        let indexStartOfText = str.index(str.startIndex, offsetBy: 37)
        let substr = String(str[indexStartOfText...])
        
        return UUID(uuidString: substr) ?? UUID()
    }
    
    private func encodeSelectedCalendars(_ calendars: [EKCalendar]) -> String {
        return calendars.map{$0.calendarIdentifier}.joined(separator: "&?")
    }
    
    private func decodeSelectedCalendars(_ code: String) -> [EKCalendar] {
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
