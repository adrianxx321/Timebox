//
//  OnboardingCarousel.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct Carousel: Identifiable {
    var id = UUID().uuidString
    var carouselImg: String
    var title: String
    var description: String
}

// Onboarding screen carousels data...
let carousels: [Carousel] = [
    Carousel(carouselImg: "onboarding1", title: "Goodbye, procrastinations.", description: "Be more productive with the Timeboxing practices."),
    Carousel(carouselImg: "onboarding2", title: "Organize your tasks.", description: "Combining to-do list and calendar eliminates clutter."),
    Carousel(carouselImg: "onboarding3", title: "Get things done timely.", description: "Pomodoro timer keeps you aware of time-sensitive tasks.")
]
// Illustration used on login screen...
let loginBanner = Carousel(carouselImg: "loginBanner", title: "Get started on Timebox.", description: "Sign in to start getting hands on Timeboxing appproaches.")
