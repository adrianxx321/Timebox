//
//  OnboardingScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct OnboardingScreen: View {
    // Current pagination level of carousel, default to 0...
    @State private var offset = 0
    @State var goToLogin = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 32) {
                TabView(selection: $offset) {
                    ForEach((0..<carousels.count), id: \.self) { index in
                        OnboardingCard(carousel: carousels[index])
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 4) {
                    ForEach((0..<3), id: \.self) { offset in
                        Circle()
                            .fill(offset == self.offset ? Color.accent : Color.textTertiary)
                            .frame(width: 10, height: 10)

                    }
                }
            }
            Button {
                withAnimation {
                    goToLogin = true
                }
            } label: {
                Text("Get Started")
                    .font(.subheading1())
                    .bold()
                    .foregroundColor(.backgroundPrimary)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .background(Capsule()
                                    .foregroundColor(.accent)
                                    .shadow(radius: 12, x: 0, y: 3))
            }
            Spacer()
            Spacer()
        }
        .background(Color.backgroundPrimary)
        .overlay(
            Group {
                if goToLogin {
                    LoginScreen()
                        .transition(.move(edge: .trailing))
                }
            }
        )
    }
}

struct OnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen()
    }
}
