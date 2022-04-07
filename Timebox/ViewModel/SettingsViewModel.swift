//
//  SettingsViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 29/03/2022.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var whiteNoiseList: [String] = []
    @Published var avatarList: [String] = []
    
    // UserDefaults persistent store...
    @AppStorage("whiteNoise") var selectedWhiteNoise = "Ticking"
    @AppStorage("avatar") var avatar = "Avatar-1"
    
    init() {
        loadWhiteNoises()
        loadAvatars()
    }
    
    func loadWhiteNoises() {
        guard let path = Bundle.main.url(forResource: "WhiteNoise", withExtension: "plist")
            else {
                print("Error loading assets: WhiteNoise.plist not found")
                return
            }
        
        let data = NSDictionary(contentsOf: path) as? [String: String] ?? [:]
        // Sorting array since dictionary/plist is originally unsorted
        self.whiteNoiseList = Array(data.keys).sorted { $0 < $1 }
    }
    
    func loadAvatars() {
        guard let path = Bundle.main.url(forResource: "Avatar", withExtension: "plist")
            else {
                print("Error loading assets: Avatar.plist not found")
                return
            }
        
        let data = NSDictionary(contentsOf: path) as? [String: String] ?? [:]
        // Sorting array since dictionary/plist is originally unsorted
        self.avatarList = Array(data.keys).sorted { $0 < $1 }
    }
}
