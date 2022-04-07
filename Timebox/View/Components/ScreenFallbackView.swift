//
//  ScreenFallbackView.swift
//  Timebox
//
//  Created by Lianghan Siew on 02/04/2022.
//

import SwiftUI

struct ScreenFallbackView: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    var title: String
    var image: Image
    var caption1: String
    var caption2: String
    
    var body: some View {
        VStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width - 64,
                       maxHeight: GLOBAL.isSmallDevice ? 240 : 360)

            VStack(spacing: 16) {
                Text("\(title)")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 8) {
                    Text(caption1)
                        .fontWeight(.semibold)
                    Text(caption2)
                        .fontWeight(.semibold)
                }
                .font(.paragraphP1())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 32)
    }
}
