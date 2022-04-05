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
    @AppStorage("whiteNoise") public var selectedWhiteNoise = "Ticking"
    
    init() {
        loadWhiteNoises()
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
    
}

