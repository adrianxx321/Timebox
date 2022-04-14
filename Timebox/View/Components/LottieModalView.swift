//
//  TestLottieView.swift
//  Timebox
//
//  Created by Lianghan Siew on 14/04/2022.
//

import SwiftUI

struct LottieModalView: View {
    @Binding var isPresent: Bool
    var lottieFile: String
    var loop: Bool = false
    var playbackSpeed: CGFloat = 1
    var caption: String
    
    var body: some View {
        self.isPresent ?
        ZStack {
            VStack {
                Text(self.caption)
                    .font(.paragraphP1())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                LottieAnimationView(animation: self.lottieFile, loop: self.loop, playbackSpeed: self.playbackSpeed)
                    .frame(width: 224, height: 224)
                
                CTAButton(btnLabel: "Dismiss", btnFullSize: false, action: {
                    withAnimation {
                        self.isPresent.toggle()
                    }
                })
            }
            .padding(.vertical, 32)
            .padding(.horizontal)
            .background(Color.backgroundQuarternary)
            .cornerRadius(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((Color.uiBlack).opacity(0.6)) : nil
    }
}
