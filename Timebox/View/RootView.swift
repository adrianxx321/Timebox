//
//  BaseView.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI

struct RootView: View {
    // Using icon name to identify tab...
    @State var currentTab = "home"
    @StateObject var taskModel = TaskViewModel()
    
    // Hiding native one...
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab View...
            TabView(selection: $currentTab) {
                HomeScreen()
                    .tag("home")
                
                ScheduledTasks()
                    .tag("tasks")
                
                Text("Timer")
                    .tag("timer")
                
                SettingsScreen()
                    .tag("more")
            }
            
            // Custom Tab Bar...
            TabBarView()
        }
        .padding(.bottom, isNotched ? 32 : 8)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func TabBarView() -> some View {
        HStack {
            Spacer()
            Group {
                TabButton(icon: "home")
                Spacer()
                TabButton(icon: "tasks")
            }
            
            Spacer()
            
            // Center Add Button...
            ZStack {
                Hexagon(radius: 8)
                    .aspectRatio((7/8), contentMode: .fit)
                    .frame(maxHeight: 64)
                    .foregroundColor(.accent)
                
                Button {
                    taskModel.addNewTask.toggle()
                } label: {
                    Image("add")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36)
                        .foregroundColor(.uiWhite)
                }
            }
            Spacer()
            
            Group {
                TabButton(icon: "timer")
                Spacer()
                TabButton(icon: "more")
            }
            Spacer()
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .background(Color.uiWhite
            .shadow(color: .backgroundQuarternary, radius: 4, x: 0, y: 0)
            // Cover up the unwanted top shadow
            .mask(Rectangle().padding(.top, -8)))
        .sheet(isPresented: $taskModel.addNewTask) {
            // Clearing Edit Data
            taskModel.editTask = nil
        } content: {
            TaskModal()
                .environmentObject(taskModel)
        }
    }
    
    private func TabButton(icon: String) -> some View {
        Button {
            withAnimation {
                currentTab = icon
            }
        } label: {
            VStack(spacing: 4) {
                Image(currentTab == icon ? "\(icon)-f" : icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
                
                Text(icon.capitalized)
                    .font(.caption())
                    .fontWeight(.semibold)
            }.foregroundColor(currentTab == icon ? .accent : .textSecondary)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}