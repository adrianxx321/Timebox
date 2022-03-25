//
//  HomeScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/03/2022.
//

import SwiftUI
import AuthenticationServices

struct HomeScreen: View {
    @StateObject var taskModel = TaskViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    
                    // MARK: Contents
                    VStack(alignment: .leading, spacing: 40) {
                        // Ongoing Tasks...
                        SectionView(title: "Ongoing Tasks") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                DynamicTaskList(timeNow: Date())
                                    .frame(maxHeight: 128)
                            }
                        }
                        
                        SectionView(title: "Statistics") {
                            
                        }
                        
                        SectionView(title: "Achievements") {
                            
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func SectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                content()
            } header: {
                Text(title)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
