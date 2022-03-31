//
//  CTAButton.swift
//  Timebox
//
//  Created by Lianghan Siew on 05/03/2022.
//

import SwiftUI

struct CTAButton: View {
    let btnLabel: String
    let btnFullSize: Bool
    let btnAction: () -> Void
    

    var body: some View {
        Button {
            
            // MARK: Perform action using function passed
            btnAction()
        } label: {
            
            // MARK: Textual label of button
            Text("\(btnLabel)")
                .font(.subheading1())
                .bold()
                .foregroundColor(.backgroundPrimary)
                .padding(.vertical, 20)
                // MARK: Button length based on absolute horizontal padding
                .padding(.horizontal, btnFullSize ? nil : 40)
                // MARK: Button length based on screen width minus horizontal margins
                .frame(maxWidth: btnFullSize ? UIScreen.main.bounds.width - 64 : nil)
                // MARK: Gives capsule shape for the button
                .background(Capsule()
                                .foregroundColor(.accent))
        }
    }
}
