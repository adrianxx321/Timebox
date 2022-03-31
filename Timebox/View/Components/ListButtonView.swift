//
//  ListButtonView.swift
//  Timebox
//
//  Created by Lianghan Siew on 31/03/2022.
//

import SwiftUI

struct ListButtonView: View {
    var icon: Image
    var entryTitle: String
    var iconIsDestructive: Bool
    var action: () -> ()
    
    
    var body: some View {
        Button {
            action()
        } label: { EntryLabel(image: Image("envelope-f"), title: "Contact Developer", isDestructive: false, tag: nil) }
    }
    
    private func EntryLabel(image: Image, title: String, isDestructive: Bool, tag: String?) -> some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
                .foregroundColor(isDestructive ? .uiRed : .accent)
            
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(isDestructive ? .uiRed : .textPrimary)
            
            Spacer()
            
            Text(tag ?? "")
                .fontWeight(.semibold)
                .foregroundColor(.textTertiary)
        }.font(.paragraphP1())
    }
}
