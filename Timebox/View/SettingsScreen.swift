//
//  SettingsScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 28/03/2022.
//

import SwiftUI

public enum NotificationOptions: String {
    case fiveMins = "5 minutes before"
    case tenMins = "10 minutes before"
    case fifteenMins = "15 minutes before"
    case halfHour = "30 minutes before"
}

struct SettingsScreen: View {
    @State private var showPreferences = false
    // We can't turn on notification by default for granted
    // Since we need to respect user's privacy & get their consent before doing so
    @AppStorage("allowedNotifications") private var isNotificationAllowed = false
    @AppStorage("enabledNotification") private var isNotificationActive = false
    @AppStorage("notificationOpts") private var notificationOptions = NotificationOptions.fiveMins
    // TODO: EventKit object
    
    @AppStorage("whiteNoise") private var selectedWhiteNoise = "ticking"
    
    init() {
        UITableView.appearance().backgroundColor = .backgroundPrimary
    }
    
    var body: some View {
        NavigationView {
            List {
                ListSection {
                    NavigationLink {
                        // TODO: Predefined portrait pictures
                    } label: {
                        HStack(spacing: 32) {
                            // TODO: Replace dummy
                            Image("144083514_3832508416843992_8153494803557931190_n")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48)
                                .clipShape(Circle())
                            
                            Text("Display Picture")
                                .font(.paragraphP1())
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .listRowSeparator(.hidden)
                    
                    TotalView().frame(maxWidth: .infinity)
                }
                
                ListSection {
                    NavigationLink {
                        // Notifications page...
                    } label: { PickerLabel(image: Image("bell-f"), title: "Notifications", isDestructive: false) }
                        .listRowSeparator(.hidden)
                    
                    NavigationLink {
                        
                    } label: { PickerLabel(image: Image("calendar-alt"), title: "Calendars", isDestructive: false) }
                        .listRowSeparator(.hidden)
                    
                    NavigationLink {
                        
                    } label: { PickerLabel(image: Image("volume-circle-f"), title: "White Noise", isDestructive: false) }
                        .listRowSeparator(.hidden)
                }
                
                ListSection {
                    Button {
                        // Bring up email form...
                    } label: { PickerLabel(image: Image("envelope-f"), title: "Contact Developer", isDestructive: false) }
                }
                
                ListSection {
                    Button {
                        // Bring up email form...
                    } label: { PickerLabel(image: Image("trash"), title: "Delete Account", isDestructive: true) }
                }
                
                ListSection {
                    Button {
                        // Bring up email form...
                    } label: { PickerLabel(image: Image("log-out"), title: "Sign Out", isDestructive: false) }
                }
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
    
    private func TotalView() -> some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                // TODO: Replace dummy
                Text("12")
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                
                Text("Tasks completed")
                    .fontWeight(.bold)
                    .foregroundColor(.textTertiary)
            }
            
            VStack(spacing: 4) {
                // TODO: Replace dummy
                Text("1h 2m")
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                
                Text("Focused time")
                    .fontWeight(.bold)
                    .foregroundColor(.textTertiary)

            }
        }
        .font(.paragraphP1())
    }
    
    private func PickerLabel(image: Image, title: String, isDestructive: Bool) -> some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
                .foregroundColor(isDestructive ? .uiRed : .accent)
            
            Text(title)
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(isDestructive ? .uiRed : .textPrimary)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
