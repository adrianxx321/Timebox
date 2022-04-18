//
//  LottieAnimationView.swift
//  Timebox
//
//  Created by Lianghan Siew on 14/04/2022.
//

import SwiftUI
import Lottie

struct LottieAnimationView: UIViewRepresentable {
    typealias UIViewType = UIView
    var animation: String
    var loop: Bool = false
    var playbackSpeed: CGFloat = 1.0
    
    func makeUIView(context: Context) -> UIView {
        let view = UIViewType(frame: .zero)
        
        let animationView = AnimationView()
        let animation = Animation.named(animation)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.animationSpeed = self.playbackSpeed
        animationView.loopMode = self.loop ? .loop : .playOnce
        
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
