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

public enum NotificationOptions: String {
    case fiveMins = "5 minutes before"
    case tenMins = "10 minutes before"
    case fifteenMins = "15 minutes before"
    case halfHour = "30 minutes before"
}

class SettingsViewModel: ObservableObject {
    // MARK: Source of truths
    @Published var whiteNoises: [String] = []
    @AppStorage("whiteNoise") public var selectedWhiteNoise = "Ticking"
    @AppStorage("notificationsAllowed") public var notificationsAllowed = false
    @AppStorage("notifyAtStart") public var notifyAtStart = true
    @AppStorage("notifyAtEnd") public var notifyAtEnd = true
    @AppStorage("notifyAllDay") public var notifyAllDay = false
    
    // TODO: EventKit object
    
    init() {
        loadWhiteNoises()
        
        // Initialise notifications authorisation status
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                UserDefaults.standard.set(true, forKey: "notificationsAllowed")
            } else {
                UserDefaults.standard.set(false, forKey: "notificationsAllowed")
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
            return "Permission Required"
        }
    }
}
