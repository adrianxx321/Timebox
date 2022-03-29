//
//  SettingsScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 28/03/2022.
//

import SwiftUI
import UIKit

public enum NotificationOptions: String {
    case fiveMins = "5 minutes before"
    case tenMins = "10 minutes before"
    case fifteenMins = "15 minutes before"
    case halfHour = "30 minutes before"
}

struct SettingsScreen: View {
    // We can't turn on notification by default for granted
    // Since we need to respect user's privacy & get their consent before doing so
    @AppStorage("allowedNotifications") private var isNotificationAllowed = false
    @AppStorage("enabledNotification") private var isNotificationActive = false
    @AppStorage("notificationOpts") private var notificationOptions = NotificationOptions.fiveMins
    // TODO: EventKit object
    //                    //
    @AppStorage("whiteNoise") private var selectedWhiteNoise = "ticking"
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showNotificationsPref = false
    @State private var showCalendarsPref = false
    @State private var showWhiteNoisePref = false
    
    var body: some View {
        NavigationView {
            List {
                ListSection {
                    SettingsEntry {
                        // Profile Picture page...
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
                    }
                    
                    TotalView().frame(maxWidth: .infinity)
                }
                
                ListSection {
                    SettingsEntry {
                        // Profile Picture page...
                    } label: {
                        PickerLabel(image: Image("bell-f"), title: "Notifications", isDestructive: false)
                    }
                    
                    SettingsEntry {
                        // Profile Picture page...
                    } label: {
                        PickerLabel(image: Image("calendar-alt"), title: "Calendars", isDestructive: false)
                    }
                    
                    SettingsEntry {
                        // Profile Picture page...
                    } label: {
                        PickerLabel(image: Image("volume-circle-f"), title: "White Noise", isDestructive: false)
                    }
                }
                
                // Bring up email contact form...
                ListSection {
                    Button {
                        
                    } label: { PickerLabel(image: Image("envelope-f"), title: "Contact Developer", isDestructive: false) }
                }
                
                // Perform actions to delete account...
                ListSection {
                    Button {
                        
                    } label: { PickerLabel(image: Image("trash"), title: "Delete Account", isDestructive: true) }
                }
                
                // Perform action to sign out...
                ListSection {
                    Button {
                        
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
    
    private func SettingsEntry<Content: View, Label: View>(@ViewBuilder content: () -> Content, label: () -> Label) -> some View {
        NavigationLink {
            content()
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        } label: { label() }
            .listRowSeparator(.hidden)
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
