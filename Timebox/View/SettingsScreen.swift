//
//  SettingsScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 28/03/2022.
//

import SwiftUI
import UIKit
import MessageUI

struct SettingsScreen: View {
    @StateObject private var sessionModel = TaskSessionViewModel()
    @ObservedObject private var settingsModel = SettingsViewModel()
    @State private var showProfilePref = false
    @State private var showNotificationsPref = false
    @State private var showCalendarsPref = false
    @State private var sendEmail = false
    @State private var showCantSendEmail = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    
    // MARK: Core Data fetch requests
    @FetchRequest private var allCompletedTasks: FetchedResults<Task>
    @FetchRequest private var allTimeboxSessions: FetchedResults<TaskSession>
    
    init() {
        let predicate = NSPredicate(format: "isCompleted == true", [])
        
        _allCompletedTasks = FetchRequest(entity: Task.entity(), sortDescriptors: [], predicate: predicate)
        _allTimeboxSessions = FetchRequest(entity: TaskSession.entity(), sortDescriptors: [])
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Screen title...
                Text("Settings")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.backgroundPrimary)
                
                List {
                    ListSection {
                        // Profile Picture page...
                        NavigationLink(isActive: $showProfilePref) {
                            VStack(spacing: 24) {
                                UniversalCustomNavigationBar(screenTitle: "Avatar")
                                Text("Display Picture").frame(maxHeight: .infinity)
                            }
                            .navigationBarHidden(true)
                            .background(Color.backgroundPrimary)
                        } label: {
                            HStack(spacing: 32) {
                                // TODO: Replace dummy
                                Image("144083514_3832508416843992_8153494803557931190_n")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48)
                                    .clipShape(Circle())
                                
                                Text("Display Picture")
                                    .font(.subheading1())
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                            }
                        }.listRowSeparator(.hidden)
                        
                        TotalView().frame(maxWidth: .infinity)
                    }
                    
                    ListSection {
                        // Notifications page...
                        ListEntryView(selector: $showNotificationsPref, icon: Image("bell-f"),
                                      entryTitle: "Notifications",
                                      hideDefaultNavigationBar: true,
                                      iconIsDestructive: false,
                                      tagValue: settingsModel.getNotificationStatus()) {
                            if settingsModel.notificationsAllowed {
                                NotificationsPage()
                            } else {
                                NotificationsFallbackPage().padding(.horizontal)
                            }
                        }
                        
                        // Calendars page...
                        ListEntryView(selector: $showCalendarsPref,
                                      icon: Image("calendar-alt"),
                                      entryTitle: "Calendars",
                                      hideDefaultNavigationBar: true,
                                      iconIsDestructive: false,
                                      tagValue: nil) {
                            if settingsModel.syncCalendarsAllowed {
                                CalendarsPage()
                            } else {
                                CalendarsFallbackPage().padding(.horizontal)
                            }
                        }
                        
                        // White noise page...
                        ListItemPickerView(selectedItem: settingsModel.$selectedWhiteNoise,
                                   items: settingsModel.whiteNoises,
                                   screenTitle: "White Noise",
                                   hideDefaultNavigationBar: true,
                                   mainIcon: Image("volume-circle-f"),
                                   mainIconColor: .accent,
                                   mainLabel: "White Noise",
                                   innerIcon: nil,
                                   innerIconColor: nil,
                                   innerLabel: \.self,
                                   hideSelectedValue: false,
                                   hideRowSeparator: true)
                    }
                    
                    // Contact developer
                    ListSection {
                        ListButtonView(icon: Image("envelope-f"), entryTitle: "Contact Developer", iconIsDestructive: false) {
                            // Bring up email contact form...
                            if MFMailComposeViewController.canSendMail() {
                                self.sendEmail.toggle()
                            } else {
                                self.showCantSendEmail.toggle()
                            }
                        }
                    }
                    .sheet(isPresented: $sendEmail) {
                        MailView(isShowing: self.$sendEmail, result: self.$result)
                    }
                    .alert("Couldn't send email from this device",
                           isPresented: $showCantSendEmail,
                           actions: {},
                           message: {
                        Text("Your device is not capable of composing email, or is lack of an email client app to do so.")
                    })
                }
                .listStyle(.insetGrouped)
            }
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }

    private func ListSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Section {
            content()
        }
        .padding(8)
    }
    
    private func NotificationsFallbackPage() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            Image("request-notifications")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width - 64,
                       maxHeight: isSmallDevice ? 240 : 360)

            VStack(spacing: 16) {
                Text("We need your permission.")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 8) {
                    Text("Grant notification access to Timebox")
                        .fontWeight(.semibold)
                    Text("So we can keep you reminded all the time.")
                        .fontWeight(.semibold)
                }
                .font(.paragraphP1())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            }
            
            CTAButton(btnLabel: "Allow Access", btnFullSize: false, btnAction: {
                settingsModel.requestNotificationsPermission()
            }).offset(y: 16)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private func CalendarsFallbackPage() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            Image("request-calendars")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width - 64,
                       maxHeight: isSmallDevice ? 240 : 360)

            VStack(spacing: 16) {
                Text("We need your permission.")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 8) {
                    Text("Let us access your calendar")
                        .fontWeight(.semibold)
                    Text("To have your existing plans timeboxed.")
                        .fontWeight(.semibold)
                }
                .font(.paragraphP1())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            }
            
            CTAButton(btnLabel: "Allow Access", btnFullSize: false, btnAction: {
                settingsModel.requestCalendarPermission()
            }).offset(y: 16)
        }
    }
    
    private func NotificationsPage() -> some View {
        List {
            Group {
                ListSection {
                    Toggle(isOn: settingsModel.$notifyAtStart) {
                        Text("Notify me when task starts")
                    }
                }
                
                ListSection {
                    Toggle(isOn: settingsModel.$notifyAtEnd) {
                        Text("Notify me at the end of task")
                    }
                }
                
                ListSection {
                    Toggle(isOn: settingsModel.$notifyAllDay) {
                        Text("All-Day Tasks Notifications")
                    }
                }
            }
            .font(.paragraphP1().weight(.semibold))
            .foregroundColor(.textPrimary)
            .tint(.accent)
        }
    }
    
    private func CalendarsPage() -> some View {
        List {
            let calendars = settingsModel.calendarStore
            ForEach(calendars, id:\.self) { calendar in
                Text(calendar.title
                )
            }
        }
    }
    
    private func TotalView() -> some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                // Total tasks completed...
                Text("\(allCompletedTasks.count)")
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                
                Text("Tasks completed")
                    .fontWeight(.bold)
                    .foregroundColor(.textTertiary)
            }
            
            VStack(spacing: 4) {
                // Total hours focused...
                let totalDuration = allTimeboxSessions.reduce(0) { $0 + $1.focusedDuration }
                let formattedTotalDuration = sessionModel.formatTimeInterval(interval: TimeInterval(totalDuration), unitsStyle: .abbreviated, units: [.hour, .minute])
                
                Text(formattedTotalDuration)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                
                Text("Focused time")
                    .fontWeight(.bold)
                    .foregroundColor(.textTertiary)

            }
        }
        .font(.paragraphP1())
    }
    
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
