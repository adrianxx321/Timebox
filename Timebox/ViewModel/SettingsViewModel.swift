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
    
    // UserDefaults persistent store...
    @AppStorage("notificationsAllowed") public var notificationsAllowed = false
    @AppStorage("notifyAtStart") public var notifyAtStart = true
    @AppStorage("notifyAtEnd") public var notifyAtEnd = true
    @AppStorage("notifyAllDay") public var notifyAllDay = false
    @AppStorage("syncCalendarsAllowed") var syncCalendarsAllowed = false
    @AppStorage("whiteNoise") public var selectedWhiteNoise = "Ticking"
    
    init() {
        loadWhiteNoises()
        loadNotificationsPermission()
        loadCalendarsPermission()
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
    
    func loadCalendarsPermission() {
        let EKAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        DispatchQueue.main.async {
            self.syncCalendarsAllowed = EKAuthStatus == .authorized
        }
    }
    
    func getNotificationStatus() -> String {
        if notificationsAllowed {
            return notifyAtStart || notifyAtEnd || notifyAllDay ? "On" : "Off"
        } else {
            return ""
        }
    }
}

