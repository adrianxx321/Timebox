//
//  AvatarView.swift
//  Timebox
//
//  Created by Lianghan Siew on 07/04/2022.
//

import SwiftUI

struct AvatarView: View {
    var size: CGFloat
    var avatar: Image
    
    var body: some View {
        ZStack {
            Circle()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.size)
                .foregroundColor(.uiLightPurple)
            
            avatar
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.size)
                .clipShape(Circle())
                
        }
    }
}
