//
//  HomeScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/02/2022.
//

import SwiftUI
import AuthenticationServices

struct HomeScreen: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject private var account = AuthViewModel()
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .center, spacing: 24) {
                Text("Successfully logged in using Apple ID")
                
                
                Button {
                    // Redirect to home screen...
                    withAnimation {
                        isLoggedIn = false
                    }
                    
                    // Clearing stored UID after log out...
                    
                } label: {
                    Text("Log Out")
                        .font(.subheading1())
                        .bold()
                        .foregroundColor(.backgroundPrimary)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 40)
                        .background(Capsule()
                                        .foregroundColor(.accent)
                                        .shadow(radius: 12, x: 0, y: 3))
                }
            }
            
            Spacer()
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
