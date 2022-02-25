//
//  OnboardingCard.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/02/2022.
//

import SwiftUI

struct OnboardingCard: View {
    // Carousel object from previous view gets passed to here...
    let carousel: Carousel
    
    var body: some View {
        VStack(spacing: 24) {
            Image("\(carousel.carouselImg)")
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack(spacing: 24) {
                Text("\(carousel.title)")
                    .foregroundColor(.textPrimary)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                Text("\(carousel.description)")
                    .foregroundColor(.textSecondary)
                    .font(.paragraphP1())
                    .fontWeight(.medium)
                    .lineSpacing(6)
            }
            .multilineTextAlignment(.center)
        }
    }
}
