//
//  GloabalVariables.swift
//  Timebox
//
//  Created by Lianghan Siew on 09/04/2022.
//

import SwiftUI

// MARK: Global Variables
struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

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
