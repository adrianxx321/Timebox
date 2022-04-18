//
//  LoginScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI
import AuthenticationServices
import CloudKit

struct Login: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: ViewModels
    @StateObject private var loginData = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            // Hero banner...
            VStack(spacing: 24) {
                Image("Login")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Get Started with Timebox")
                        .foregroundColor(.textPrimary)
                        .font(.headingH1())
                        .fontWeight(.heavy)
                        .lineSpacing(6)
                    Text("Start managing your time with Timeboxing approaches.")
                        .foregroundColor(.textSecondary)
                        .font(.subheading1())
                        .fontWeight(.medium)
                        .lineSpacing(6)
                }
                .multilineTextAlignment(.leading)
            }
            
            // Login button...
            SignInWithAppleButton(
                // Use "Continue with" instead of "Sign in with"
                .continue,
                onRequest: { request in
                    // Request Apple ID credentials...
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    // If Apple ID validated...
                    case .success(let authUser):
                        print("success")
                        // Proceed to login with iCloud...
                        guard let credential = authUser.credential as? ASAuthorizationAppleIDCredential else {
                            print("error with cloudkit")
                            return
                        }
                        loginData.authenticate(authUser: credential)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: GLOBAL.isSmallDevice ? 50 : 56)
            .clipShape(Capsule())
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color.backgroundPrimary)
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
