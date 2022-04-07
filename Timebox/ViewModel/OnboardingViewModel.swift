//
//  OnboardingCarousel.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

class OnboardingViewModel: ObservableObject {
    // MARK: Key-value pair from Onboarding.plist
    // Carousel image title uses the key, caption uses the value
    @Published var carousels: [[String: String]] = []
    
    init() {
        loadCarousels()
    }
    
    private func loadCarousels()  {
        guard let path = Bundle.main.url(forResource: "Onboarding", withExtension: "plist")
            else {
                print("Error loading assets: Onboarding.plist not found")
                return
            }
        
        self.carousels = NSArray(contentsOf: path) as? Array<Dictionary<String, String>> ?? []
    }
}
