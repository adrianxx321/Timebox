//
//  ContentView.swift
//  Timebox
//
//  Created by Lianghan Siew on 23/02/2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var globalModel = GlobalVariables()
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    init() {
        // Globally define UIKit appearances that suits my app's theme
        UITableView.appearance().showsVerticalScrollIndicator = false
        UITableView.appearance().backgroundColor = .backgroundPrimary
        UINavigationBar.appearance().tintColor = .accent
        UITableView.appearance().contentInset.top = -16
    }
    
    var body: some View {
        if isLoggedIn {
            Root().environmentObject(self.globalModel)
        } else {
            Onboarding()
                .transition(.move(edge: .trailing))
                .environmentObject(self.globalModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
