//
//  LoginScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI
import AuthenticationServices
import CloudKit

struct LoginScreen: View {
    @StateObject private var loginData = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero banner...
            VStack(spacing: 24) {
                Image("loginBanner")
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
            .padding(.horizontal, 32)
            
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
            .signInWithAppleButtonStyle(.black) // Button Style
            .frame(height: 50) // Set button size according to Apple Human Guidelines
            .clipShape(Capsule())
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .background(Color.backgroundPrimary)
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
