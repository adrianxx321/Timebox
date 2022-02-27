//
//  LoginScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct LoginScreen: View {
    var body: some View {
        VStack(spacing: 32) {
            // Hero banner...
            VStack(spacing: 24) {
                Image("loginBanner")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack(spacing: 24) {
                    Text("Get started on Timebox.")
                        .foregroundColor(.textPrimary)
                        .font(.headingH2())
                        .fontWeight(.heavy)
                    Text("Sign in to start getting hands on Timeboxing appproaches.")
                        .foregroundColor(.textSecondary)
                        .font(.paragraphP1())
                        .fontWeight(.medium)
                        .lineSpacing(6)
                }
                .multilineTextAlignment(.center)
            }
            // Login button...
            VStack(spacing: 24) {
                Button {} label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                        Text("Continue with Apple")
                            .font(.paragraphP2())
                            .bold()
                    }
                    .foregroundColor(.backgroundPrimary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Capsule()
                                .foregroundColor(.uiBlack))
                }
                Button {} label: {
                    Text("Other Sign Up Options")
                        .font(.paragraphP2())
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
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
