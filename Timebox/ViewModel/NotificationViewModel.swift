//
//  NotificationViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/04/2022.
//

import SwiftUI
import UserNotifications

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
    
    func sendTaskStartsNotification(task: Task) {
        if self.notifyAtStart {
            let content = UNMutableNotificationContent()
            let calendar = Calendar.current
            content.title = task.taskTitle!
            content.subtitle = "Howdy, your task has started. Get them done now!"
            content.sound = .default
            
            var date = DateComponents()
            date.hour = calendar.component(.hour, from: task.taskStartTime!)
            date.minute = calendar.component(.minute, from: task.taskStartTime!)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            NotificationViewModel.NotificationAccessor.add(request)
        }
    }
    
    func sendTaskEndsNotification(task: Task) {
        if self.notifyAtEnd {
            let content = UNMutableNotificationContent()
            let calendar = Calendar.current
            let endDateFormatted = task.taskEndTime!.formatDateTime(format: "h mm: a")
            content.title = task.taskTitle!
            content.subtitle = "Your task has just ended on \(endDateFormatted)."
            content.sound = .default
            
            let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.taskEndTime!)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            NotificationViewModel.NotificationAccessor.add(request)
        }
    }
    
    func sendAllDayTaskNotification(task: Task) {
        if self.notifyAllDay {
            let content = UNMutableNotificationContent()
            content.title = task.taskTitle!
            content.subtitle = "Here is the task of your day. Get them done before midnight!"
            content.sound = .default
            
            var date = DateComponents()
            date.hour = 9
            date.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
