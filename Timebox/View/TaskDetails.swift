//
//  TaskDetails.swift
//  Timebox
//
//  Created by Lianghan Siew on 08/03/2022.
//

import SwiftUI
import CoreData

struct TaskDetails: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var selectedTask: Task
    @StateObject var taskModel = TaskViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView()
                .padding()
            
            // Content of task details...
            VStack(alignment: .leading, spacing: 40) {
                TaskHeaderView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Subtasks section...
                        TaskSectionView(sectionTitle: "Subtasks") {
                            // Subtasks breakdown, if any...
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(selectedTask.subtasks, id: \.id) { subtask in
                                    HStack(spacing: 12) {
                                        // Checkbox for subtask completion...
                                        Button {
                                            withAnimation {
                                                // We need this "magic" to overcome the fact that Core Data can't handle view update on to-many entities...
                                                selectedTask.objectWillChange.send()
                                                subtask.isCompleted.toggle()
                                                
                                                // TODO: Save to Core Data
                                            }
                                        } label: {
                                            Image(subtask.isCompleted ? "checked" : "unchecked")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 28)
                                                .foregroundColor(subtask.isCompleted ? .accent : .backgroundTertiary)
                                                .padding(.trailing, 8)
                                        }
                                        
                                        // Subtask title...
                                        Text(subtask.subtaskTitle)
                                            .font(.paragraphP1())
                                            .fontWeight(.semibold)
                                            .foregroundColor(subtask.isCompleted ? .textSecondary : .textPrimary)
                                            .if(subtask.isCompleted) { text in
                                                text.strikethrough()
                                            }
                                    }
                                }
                                
                                // Indicator for no subtask...
                                selectedTask.subtasks.count <= 0 ?
                                Text("This task doesn't have any subtask.")
                                    .font(.paragraphP1())
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary) : nil
                            }
                        }
                        
                        // Date & Time section...
                        TaskSectionView(sectionTitle: "Date & Time") {
                            VStack(alignment: .leading, spacing: 16) {
                                
                                // Task date...
                                HStack(spacing: 12) {
                                    Image("calendar-alt")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                        .foregroundColor(.accent)
                                        .padding(6)
                                        .background(Circle()
                                            .foregroundColor(.uiLightPurple))
                                    
                                    taskModel.isScheduledTask(selectedTask) ?
                                    Text(taskModel.formatDate(date: selectedTask.taskDate!, format: "EEEE, d MMMM yyyy"))
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    : Text("None")
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                // Task time & duration...
                                HStack(spacing: 12) {
                                    Image("clock")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                        .foregroundColor(.accent)
                                        .padding(6)
                                        .background(Circle()
                                            .foregroundColor(.uiLightPurple))
                                    
                                    // Complicated task duration calculation...
                                    let startTime = taskModel.formatDate(date: selectedTask.taskStartTime ?? Date(), format: "hh:mm a")
                                    
                                    let endTime = taskModel.formatDate(date: selectedTask.taskEndTime ?? Date(), format: "hh:mm a")
                                    
                                    let interval = taskModel.formatTimeInterval(startTime: selectedTask.taskStartTime ?? Date(), endTime: selectedTask.taskEndTime ?? Date(), unitStyle: .full, units: [.hour, .minute])
                                    
                                    selectedTask.taskStartTime != nil && selectedTask.taskEndTime != nil ?
                                        taskModel.isAllDayTask(selectedTask) ?
                                        Text("All-day")
                                            .font(.paragraphP1())
                                            .fontWeight(.semibold)
                                            .foregroundColor(.textPrimary)
                                        : Text("\(startTime) - \(endTime) (\(interval))")
                                            .font(.paragraphP1())
                                            .fontWeight(.semibold)
                                            .foregroundColor(.textPrimary)
                                    : Text("None")
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Button for start timeboxing for ongoing task...
            if taskModel.isScheduledTask(selectedTask) {
                if selectedTask.taskStartTime! >= Date() && selectedTask.taskEndTime! < Date() {
                    CTAButton(btnLabel: "Start Timeboxing", btnAction: {
                        
                    }, btnFullSize: true)
                    .frame(maxWidth: .infinity)
                }
            } else {
                // Button for adding backlog task to scheduled
                CTAButton(btnLabel: "Add to Scheduled", btnAction: {
                    // TODO: Bring up the edit task modal...
                    
                }, btnFullSize: true)
                .frame(maxWidth: .infinity)
            }
            
        }
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack {
            
            // Back button leading to previous screen...
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // Screen title...
            Text("Task Details")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // More options button...
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
        VStack(alignment: .leading , spacing: 8) {
            
            // Importance label if task is important...
            selectedTask.isImportant ?
            Text("!!! Important")
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .foregroundColor(.uiOrange)
            : nil
            
            // Task name...
            Text(selectedTask.taskTitle)
                .font(.headingH2())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            // Task label name & color, if any...
            selectedTask.taskLabel != nil ?
            Text(selectedTask.taskLabel!)
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundColor(.uiWhite)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule()
                    .foregroundColor(Color(selectedTask.color)))
                .padding(.top, 4)
            : nil
            
            // Indicate if task comes from imported calendar...
            selectedTask.isImported ?
            HStack(alignment: .top, spacing: 8) {
                Image("alert")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28)
                    .foregroundColor(.textSecondary)
                    .rotationEffect(Angle(degrees: 180))
                
                Group {
                    Text("This task/event comes from your")
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary) +
                    Text(" Google Calendar")
                        .fontWeight(.bold)
                        .foregroundColor(Color(selectedTask.color))
                }
                .font(.paragraphP1())
                .lineSpacing(4)
            }.padding(.top, 8)
            : nil
        }
    }
    
    private func TaskSectionView<Content: View>(sectionTitle: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                // Whatever content goes here...
                content()
                
            } header: {
                // Heading for the section...
                Text("\(sectionTitle)")
                    .font(.subheading1())
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
