//
//  SettingsViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 29/03/2022.
//

// This is where all settings-related configurations
// Will be initialized/handled
// Calendar syncing, loading preset white noises, notification permission etc.
import SwiftUI
import UserNotifications
import EventKit

class SettingsViewModel: ObservableObject {
    @Published var whiteNoises: [String] = []
    // This is the store for all calendar entities retrieved from your calendar
    @Published var calendarStore = [EKCalendar]()
    // This is the store for events from all calendars
    @Published var eventStore = [EKEvent]()
    
    @AppStorage("notificationsAllowed") public var notificationsAllowed = false
    @AppStorage("notifyAtStart") public var notifyAtStart = true
    @AppStorage("notifyAtEnd") public var notifyAtEnd = true
    @AppStorage("notifyAllDay") public var notifyAllDay = false
    @AppStorage("syncCalendarsAllowed") public var syncCalendarsAllowed = false
    @AppStorage("whiteNoise") public var selectedWhiteNoise = "Ticking"
    
    // This is the accessor for all your calendars
    let calendarAccessor = EKEventStore()
    let notificationAccessor = UNUserNotificationCenter.current()
    
    init() {
        loadWhiteNoises()
        loadNotificationsPermission()
        loadCalendars()
    }
    
    func loadWhiteNoises() {
        guard let path = Bundle.main.url(forResource: "WhiteNoise", withExtension: "plist")
            else {
                print("Error loading assets: WhiteNoise.plist not found")
                return
            }
        
        let data = NSDictionary(contentsOf: path) as? [String: String] ?? [:]
        // Sorting array since dictionary/plist is originally unsorted
        self.whiteNoises = Array(data.keys).sorted { $0 < $1 }
    }
    
    func loadNotificationsPermission() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = settings.authorizationStatus == .authorized
            }
        })
    }
    
    func getNotificationStatus() -> String {
        if notificationsAllowed {
            return notifyAtStart || notifyAtEnd || notifyAllDay ? "On" : "Off"
        } else {
            return ""
        }
    }
    
    func loadCalendars() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        if EKAuthStatus == .authorized {
            self.calendarStore = self.calendarAccessor.calendars(for: .event)
        }
    }

    /// Request user's permission for notifications for once
    func requestNotificationsPermission() {
        self.notificationAccessor.getNotificationSettings(completionHandler: { [self] settings in
            if settings.authorizationStatus == .notDetermined {
                self.notificationAccessor.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, _ in
                    DispatchQueue.main.async {
                        withAnimation {
                            self.notificationsAllowed = granted
                        }
                    }
                })
            } else if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        })
    }
    
    /// Request user's permission for calendars for once
    func requestCalendarAccessPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        if EKAuthStatus == .notDetermined {
            self.calendarAccessor.requestAccess(to: .event) { granted, _ in
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
}

