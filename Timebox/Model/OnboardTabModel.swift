//
//  OnboardingCarousel.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct OnboardTab: Identifiable {
    var id = UUID().uuidString
    var carouselImg: String
    var title: String
    var description: String
}

// Carousels data for onboarding screen...
let onboardingTabs: [OnboardTab] = [
    OnboardTab(carouselImg: "onboarding1", title: "Bye, procrastinations.", description: "Be more productive with the Timeboxing practices."),
    OnboardTab(carouselImg: "onboarding2", title: "Organize your tasks.", description: "Combining to-do list and calendar eliminates clutter."),
    OnboardTab(carouselImg: "onboarding3", title: "Get things done timely.", description: "Pomodoro timer keeps you aware of time-sensitive tasks.")
]
