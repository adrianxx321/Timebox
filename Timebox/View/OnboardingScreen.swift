//
//  OnboardingScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct OnboardingScreen: View {
    @State private var viewDismissed = false
    
    // Current pagination level of carousel, default to 0...
    @State private var offset = 0

    var body: some View {
        
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 32) {
                
                TabView(selection: $offset) {
                    ForEach((0..<onboardingTabs.count), id: \.self) { index in
                        OnboardingTabView(onboardingTabs[index])
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
                    viewDismissed = true
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
                if viewDismissed {
                    LoginScreen()
                        .transition(.move(edge: .trailing))
                }
            }
        )
    }
    
    private func OnboardingTabView(_ tab: OnboardTab) -> some View {
        VStack(spacing: 24) {
            Image("\(tab.carouselImg)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 16)
            VStack(spacing: 24) {
                Text("\(tab.title)")
                    .foregroundColor(.textPrimary)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                Text("\(tab.description)")
                    .foregroundColor(.textSecondary)
                    .font(.subheading1())
                    .fontWeight(.medium)
                    .lineSpacing(6)
                    .padding(.horizontal, 16)
            }
            .multilineTextAlignment(.center)
        }
    }
}

struct OnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen()
    }
}
