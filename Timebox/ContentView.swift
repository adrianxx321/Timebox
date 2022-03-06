//
//  ContentView.swift
//  Timebox
//
//  Created by Lianghan Siew on 23/02/2022.
//

import SwiftUI

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
        ScheduledTasks()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
