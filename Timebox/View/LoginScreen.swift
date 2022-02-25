//
//  LoginScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct LoginScreen: View {
    // Special environment variable that stores the previous view used for navigation...
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack(spacing: 32) {
            
            OnboardingCard(carousel: loginBanner)
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
