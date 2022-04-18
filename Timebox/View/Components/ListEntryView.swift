//
//  ListEntryView.swift
//  Timebox
//
//  Created by Lianghan Siew on 31/03/2022.
//

import SwiftUI

struct ListEntryView<Content: View>: View {
    @Binding var selector: Bool
    var icon: Image
    var customIconColor: Color?
    var entryTitle: String
    var hideDefaultNavigationBar: Bool
    var iconIsDestructive: Bool
    var tagValue: String?
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        NavigationLink(isActive: $selector) {
            VStack(spacing: 32) {
                hideDefaultNavigationBar ? UniversalCustomNavigationBar(screenTitle: entryTitle, hasBackButton: true) : nil
                
                content()
            }
            .navigationTitle(entryTitle)
            .navigationBarHidden(hideDefaultNavigationBar)
            .background(Color.backgroundPrimary)
        } label: {
            EntryLabel(image: icon, title: entryTitle, isDestructive: iconIsDestructive, tag: tagValue)
        }.listRowSeparator(.hidden)
    }
    
    private func EntryLabel(image: Image, title: String, isDestructive: Bool, tag: String?) -> some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
                .foregroundColor(isDestructive ? .uiRed : customIconColor ?? .accent)
            
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(isDestructive ? .uiRed : .textPrimary)
            
            Spacer()
            
            Text(tag ?? "")
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }.font(.paragraphP1())
    }
}
