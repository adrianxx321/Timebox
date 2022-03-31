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
    // MARK: Source of truths
    @Published var whiteNoises: [String] = []
    @Published var calendarStore = EKEventStore()
    @AppStorage("notificationsAllowed") public var notificationsAllowed = false
    @AppStorage("notifyAtStart") public var notifyAtStart = true
    @AppStorage("notifyAtEnd") public var notifyAtEnd = true
    @AppStorage("notifyAllDay") public var notifyAllDay = false
    @AppStorage("syncCalendarsAllowed") public var syncCalendarsAllowed = false
    @AppStorage("whiteNoise") public var selectedWhiteNoise = "Ticking"
    
    init() {
        loadWhiteNoises()
        checkNotificationPermission()
        checkCalendarPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = settings.authorizationStatus == .authorized
            }
        })
    }
    
    func checkCalendarPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        DispatchQueue.main.async {
            self.syncCalendarsAllowed = EKAuthStatus == .authorized
        }
    }
    
    /// Request user's permission for notifications for once
    func requestNotificationsPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation {
                        self.notificationsAllowed = true
                    }
                } else {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        })
    }
    
    /// Request user's permission for calendars for once
    func requestCalendarAccessPermission() {
        self.calendarStore.requestAccess(to: .event) { granted, denied in
            DispatchQueue.main.async {
                if granted {
                    self.syncCalendarsAllowed = true
                } else {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        }
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
    
    func getNotificationStatus() -> String {
        if notificationsAllowed {
            return notifyAtStart || notifyAtEnd || notifyAllDay ? "On" : "Off"
        } else {
            return ""
        }
    }
}
