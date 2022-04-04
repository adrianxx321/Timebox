//
//  UniversalCustomNavigationBar.swift
//  Timebox
//
//  Created by Lianghan Siew on 31/03/2022.
//

import SwiftUI

struct UniversalCustomNavigationBar: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var screenTitle: String
    
    var body: some View {
        HStack {
            // Back button leading to previous screen...
            Button {
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // Screen title...
            Text(screenTitle)
                .font(.headingH2())
                .fontWeight(.heavy)
                .padding(.trailing, 36)
                
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 20)
        .foregroundColor(.textPrimary)
        .background(Color.backgroundPrimary)
    }
}
