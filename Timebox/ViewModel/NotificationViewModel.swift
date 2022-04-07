//
//  NotificationViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/04/2022.
//

import SwiftUI

class NotificationViewModel: ObservableObject {
    // Singleton notification center object...
    static let NotificationAccessor = UNUserNotificationCenter.current()
    // Notification permission - Default to false as we haven't get user consent
    @AppStorage("notificationsAllowed") public var notificationsAllowed = false
    @AppStorage("notifyAtStart") public var notifyAtStart = true
    @AppStorage("notifyAtEnd") public var notifyAtEnd = true
    @AppStorage("notifyAllDay") public var notifyAllDay = false
    
    init() {
        loadNotificationsPermission()
    }
    
    func loadNotificationsPermission() {
        NotificationViewModel.NotificationAccessor.getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = settings.authorizationStatus == .authorized
            }
        })
    }
    
    /// Request user's permission for notifications for once
    func requestNotificationsPermission() {
        NotificationViewModel.NotificationAccessor.getNotificationSettings(completionHandler: { settings in
            if settings.authorizationStatus == .notDetermined {
                NotificationViewModel.NotificationAccessor.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, _ in
                    DispatchQueue.main.async {
                        self.notificationsAllowed = granted
                    }
                })
            } else if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
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
}
