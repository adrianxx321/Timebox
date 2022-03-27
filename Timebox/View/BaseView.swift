//
//  BaseView.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI

struct BaseView: View {
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
                
                Text("Settings")
                    .tag("more")
            }
            
            // Custom Tab Bar...
            TabBarView()
        }
    }
    
    private func TabBarView() -> some View {
        HStack(spacing: 32) {
            // Tab Buttons...
            HStack(spacing: 40) {
                TabButton(icon: "home")
                TabButton(icon: "tasks")
            }
            
            // Center Add Button...
            Button {
                taskModel.addNewTask.toggle()
            } label: {
                ZStack {
                    Hexagon()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.accent)
                    
                    Image(systemName: "plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .foregroundColor(.uiWhite)
                }
            }
            
            HStack(spacing: 40) {
                TabButton(icon: "timer")
                TabButton(icon: "more")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.uiWhite)
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

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        BaseView()
    }
}

// BG Modifier...
struct BGModifier: ViewModifier{
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
