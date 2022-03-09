//
//  TaskDetails.swift
//  Timebox
//
//  Created by Lianghan Siew on 08/03/2022.
//

import SwiftUI

struct TaskDetails: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var selectedTask: Task
    @StateObject var taskModel = TaskViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HeaderView()
                    .padding()
                
                // MARK: Content of task details
                VStack(spacing: 32) {
                    TaskHeaderView()
                    
                    // MARK: Subtasks breakdown, if any
                    selectedTask.subtasks.count > 0 ?
                    TaskSectionView(sectionTitle: "Subtasks") {
                        ForEach(selectedTask.subtasks, id: \.id) {subtask in
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image("check")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28)
                                    
                                    Text(subtask.subtaskTitle)
                                        .font(.paragraphP1())
                                        .fontWeight(subtask.isCompleted ? .medium : .semibold)
                                        .foregroundColor(subtask.isCompleted ? .textPrimary : .textSecondary)
                                        .if(subtask.isCompleted) { text in
                                            text.strikethrough()
                                        }
                                }
                            }
                        }
                    } : nil
                    
                    // MARK: Task date & time for scheduled task
                    taskModel.isScheduledTask(selectedTask) ?
                    TaskSectionView(sectionTitle: "Date & Time") {
                        VStack(spacing: 16) {
                            
                            // MARK: Date
                            HStack(spacing: 12) {
                                Image("calendar-alt")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                    .foregroundColor(.accent)
                                    .background(Circle()
                                        .padding(6)
                                        .foregroundColor(.uiLightPurple))
                                
                                Text(taskModel.formatDate(date: selectedTask.taskDate!, format: "EEE, MMM d. yyyy"))
                            }
                            
                            // MARK: Time
                            HStack(spacing: 12) {
                                Image("clock")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                    .foregroundColor(.accent)
                                    .background(Circle()
                                        .padding(6)
                                        .foregroundColor(.uiLightPurple))
                                
                                // MARK: Complicated task duration calculation
                                let startTime = taskModel.isAllDayTask(selectedTask) ?
                                "" : taskModel.formatDate(date: selectedTask.taskStartTime!, format: "hh:mm a")
                                
                                let endTime = taskModel.isAllDayTask(selectedTask) ?
                                "" : taskModel.formatDate(date: selectedTask.taskEndTime!, format: "hh:mm a")
                                
                                let interval = taskModel.isAllDayTask(selectedTask) ?
                                "" : taskModel.formatTimeInterval(startTime: selectedTask.taskStartTime!, endTime: selectedTask.taskEndTime!, unitStyle: .full, units: [.hour, .minute])
                                
                                taskModel.isAllDayTask(selectedTask) ?
                                Text("All-day") : Text("\(startTime) - \(endTime) (\(interval)")
                            }
                        }
                    } : nil
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack() {
            
            // MARK: Back button leading to previous screen
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // MARK: Title header
            Text("Task Details")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // MARK: More options button
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
    
    private func TaskHeaderView() -> some View {
        VStack(spacing: 8) {
            
            // MARK: Importance label if task is important
            selectedTask.isImportant ?
            Text("!!! Important")
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .foregroundColor(.uiOrange)
            : nil
            
            // MARK: Task name
            Text(selectedTask.taskTitle)
                .font(.headingH2())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            selectedTask.taskLabel != nil ?
            Text(selectedTask.taskLabel!)
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundColor(.uiWhite)
                .background(Capsule()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundColor(Color(selectedTask.color)))
                .padding(.top, 4)
            : nil
        }
    }
    
    private func TaskSectionView<Content: View>(sectionTitle: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        Section {
            // MARK: Content goes here
            content()
            
        } header: {
            // MARK: Heading for the section
            Text("\(sectionTitle)")
                .font(.subheading1())
                .fontWeight(.bold)
                .foregroundColor(.textSecondary)
        }
    }
}
