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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HeaderView()
                        .padding(.top, isNotched ? 47: 20)
                        .background(Color.uiWhite)
                    
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
                            DynamicAnalyticsView(forWeek: Date())
                        }
                        
                        SectionView(title: "Achievements") {
                            
                        }
                    }
                    .padding(.horizontal, isSmallDevice ? 16 : 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        VStack(spacing: 12) {
            // TODO: Profile picture
            Image("144083514_3832508416843992_8153494803557931190_n")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 78)
                .clipShape(Circle())
                .padding(8)
                // TODO: Circular progress bar
                .overlay(Circle()
                    .stroke(Color.accent, lineWidth: 2))
            
            VStack(spacing: 4) {
                // TODO: Username
                Group {
                    Text("Lianghan Siew")
                        .foregroundColor(.textPrimary) +
                    // TODO: User's points
                    Text(" (880 pts)")
                        .foregroundColor(.accent)
                }.font(.subheading1().weight(.heavy))
                
                // TODO: User's current rank (medal) & next rank
                Text("Silver | Next rank: Gold")
                    .font(.paragraphP1())
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.uiWhite)
        .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
        .shadow(radius: 12, x: 0, y: 3)
        // Cover up the unwanted top shadow
        .mask(Rectangle().padding(.bottom, -24))
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
