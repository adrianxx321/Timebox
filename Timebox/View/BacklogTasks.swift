//
//  PlannedTasks.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct BacklogTasks: View {
    @StateObject var taskModel = TaskViewModel()
    @Binding var showBacklog: Bool
    @State var hideCompletedTasks = false
    
    var body: some View {
        if showBacklog {
            
            VStack(spacing: 16) {
                HeaderView()
                    .padding()
                
                // MARK: Scrollview showing list of backlog tasks
                TasksView()
                    .transition(.slide)
                
                Spacer()
                
                // MARK: Create task button
                CTAButton(btnLabel: "Create a Task", btnAction: {}, btnFullSize: true)
            }
            .padding(.top, 48)
            .edgesIgnoringSafeArea(.top)
            .background(Color.backgroundPrimary)
        } else {
            
            // MARK: Go to scheduled
            ScheduledTasks()
        }
    }
    
    private func HeaderView() -> some View {
        HStack() {
            
            // MARK: Menu button leading to Planned Tasks
            Button {
                withAnimation {
                    showBacklog.toggle()
                }
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // MARK: Header title
            Text("Backlog")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // MARK: Hide/Show completed tasks
            Button {
                
            } label: {
                Image("more-horizontal-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
        }
        .foregroundColor(.textPrimary)
    }
    
    private func TasksView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            // MARK: Show if there's any backlog task
            if taskModel.hasTask(taskModel.storedTasks, date: nil) {
                VStack(spacing: 16) {
                    ForEach(taskModel.filterTasks(taskModel.storedTasks, date: nil, isAllDay: false, hideCompleted: hideCompletedTasks), id: \.self.id) { task in
                        TaskCardView(task: task)
                    }
                }
            }
            
            // MARK: Fallback screen for zero backlog tasks
            else {
                VStack {
                   Image("no-task")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                    
                    Text("No backlog task")
                        .font(.headingH2())
                        .fontWeight(.heavy)
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 16)
                    
                    VStack(spacing: 8) {
                        Text("You don’t have anything planned so far.")
                            .fontWeight(.semibold)
                        Text("Tap the button below to create a new task.")
                            .fontWeight(.semibold)
                    }
                    .font(.paragraphP1())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct BacklogTasks_Previews: PreviewProvider {
    static var previews: some View {
        BacklogTasks(showBacklog: .constant(true))
    }
}
