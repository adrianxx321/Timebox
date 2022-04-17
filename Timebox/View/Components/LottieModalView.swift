//
//  TestLottieView.swift
//  Timebox
//
//  Created by Lianghan Siew on 14/04/2022.
//

import SwiftUI

struct LottieModalView: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    @Environment(\.presentationMode) var presentationMode
    var lottieFile: String
    var loop: Bool = false
    var playbackSpeed: CGFloat = 1
    var caption: String
    
    var body: some View {
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
                        self.presentationMode.wrappedValue.dismiss()
                    }
                })
            }
            .padding(.vertical, 32)
            .padding(.horizontal, GLOBAL.isSmallDevice ? 16 : 32)
            .background(Color.backgroundTertiary)
            .cornerRadius(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundBlurView())
    }
}

// Helper
struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .uiBlack.withAlphaComponent(0.6)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
