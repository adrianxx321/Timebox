//
//  ContentView.swift
//  Timebox
//
//  Created by Lianghan Siew on 23/02/2022.
//

import SwiftUI

// MARK: Global Variables
class GlobalVariables: ObservableObject {
    /// Global variable to indicate if iPhone is X or later...
    var isNotched: Bool {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first

        return (window?.safeAreaInsets.bottom)! > 0
    }

    /// Global variable to indicate if it's a small device (e.g. iPhone SE/8)...
    var isSmallDevice: Bool {
        return UIScreen.main.bounds.height < 750
    }
}

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @StateObject var globalModel = GlobalVariables()
    
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
