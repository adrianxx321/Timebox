//
//  ContentView.swift
//  Timebox
//
//  Created by Lianghan Siew on 23/02/2022.
//

import SwiftUI

// Global variable to indicate if iPhone is X or later...
public var isNotched: Bool {
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let window = windowScene?.windows.first

    return (window?.safeAreaInsets.bottom)! > 0
}

// Global variable to indicate if it's a small device (e.g. iPhone SE/8)...
public var isSmallDevice: Bool {
    return UIScreen.main.bounds.height < 750
}

struct ContentView: View {
    // If UID presents, set is logged in...
    @AppStorage("isLoggedIn") private var isLoggedIn = (UserDefaults.standard.string(forKey: "loggedInUID") != nil) ? true : false
    
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
//        if isLoggedIn {
//            HomeScreen()
//        } else {
//            OnboardingScreen()
//                .transition(.move(edge: .trailing))
//        }
        HomeScreen()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
