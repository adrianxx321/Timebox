//
//  OnboardingScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct Onboarding: View {
    // MARK: ViewModels
    @StateObject private var onboardingModel = OnboardingViewModel()
    // MARK: UI States
    @State private var currentIndex = 0
    @State private var viewDismissed = false
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                // Carousels...
                VStack(spacing: 32) {
                    TabView(selection: self.$currentIndex) {
                        ForEach(onboardingModel.carousels.indices, id: \.self) { page in
                            // There's only 1 key-value pair in each level of the array
                            if let keyValue = onboardingModel.carousels[page].first {
                                CarouselTab(Image(keyValue.key), title: keyValue.key, caption: keyValue.value)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                    }
                    .frame(maxHeight: geometry.size.height / 2)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))

                    // Indicator...
                    HStack(spacing: 4) {
                        ForEach((0..<onboardingModel.carousels.count), id: \.self) { offset in
                            Circle()
                                .fill(offset == self.currentIndex ? Color.accent : Color.textTertiary)
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    self.currentIndex < (onboardingModel.carousels.count - 1) ?
                    // Next tab button
                    CTAButton(btnLabel: "Next", btnFullSize: false, action: {
                        withAnimation {
                            self.currentIndex += 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }) :
                    // Go to login page
                    CTAButton(btnLabel: "Get Started", btnFullSize: false, action: {
                        withAnimation {
                            viewDismissed = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    })
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color.backgroundPrimary)
        .overlay(
            Group {
                if viewDismissed {
                    Login()
                        .transition(.move(edge: .trailing))
                }
            }
        )
    }

    private func CarouselTab(_ image: Image, title: String, caption: String) -> some View {
        VStack(spacing: 24) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            VStack(spacing: 24) {
                Text(title)
                    .foregroundColor(.textPrimary)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                Text(caption)
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
        Onboarding()
    }
}
