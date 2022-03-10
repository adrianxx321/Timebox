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
            
            // MARK: Content of task details
            VStack(alignment: .leading, spacing: 40) {
                TaskHeaderView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        
                        // MARK: Subtasks breakdown, if any
                        selectedTask.subtasks.count > 0 ?
                        TaskSectionView(sectionTitle: "Subtasks") {
                            
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(selectedTask.subtasks, id: \.id) { subtask in
                                    
                                    HStack(spacing: 12) {
                                        Image("check-circle-f")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 28)
                                        
                                        Text(subtask.subtaskTitle)
                                            .font(.paragraphP1())
                                            .fontWeight(subtask.isCompleted ? .medium : .semibold)
                                            .foregroundColor(subtask.isCompleted ? .textSecondary : .textPrimary)
                                            .if(subtask.isCompleted) { text in
                                                text.strikethrough()
                                            }
                                    }
                                }
                            }
                        } : nil
                        
                        // MARK: Task date & time for scheduled task
                        TaskSectionView(sectionTitle: "Date & Time") {
                            VStack(alignment: .leading, spacing: 16) {
                                
                                // MARK: Task date
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
                                    Text(taskModel.formatDate(date: selectedTask.taskDate!, format: "EEE, d MMMM yyyy"))
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    : Text("None")
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                // MARK: Task time & duration
                                HStack(spacing: 12) {
                                    Image("clock")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                        .foregroundColor(.accent)
                                        .padding(6)
                                        .background(Circle()
                                            .foregroundColor(.uiLightPurple))
                                    
                                    // MARK: Complicated task duration calculation
                                    let startTime = taskModel.isAllDayTask(selectedTask) ?
                                    "" : taskModel.formatDate(date: selectedTask.taskStartTime!, format: "hh:mm a")
                                    
                                    let endTime = taskModel.isAllDayTask(selectedTask) ?
                                    "" : taskModel.formatDate(date: selectedTask.taskEndTime!, format: "hh:mm a")
                                    
                                    let interval = taskModel.isAllDayTask(selectedTask) ?
                                    "" : taskModel.formatTimeInterval(startTime: selectedTask.taskStartTime!, endTime: selectedTask.taskEndTime!, unitStyle: .full, units: [.hour, .minute])
                                    
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
            
            // MARK: Button for start timeboxing for ongoing task
            if taskModel.isScheduledTask(selectedTask) {
                
                if selectedTask.taskStartTime! >= Date() && selectedTask.taskEndTime! < Date() {
                    CTAButton(btnLabel: "Start Timeboxing", btnAction: {
                        
                    }, btnFullSize: true)
                    .frame(maxWidth: .infinity)
                }
            } else {
                
                // MARK: Button for adding backlog task to scheduled
                // This will bring up the edit task modal...
                CTAButton(btnLabel: "Add to Scheduled", btnAction: {
                    
                }, btnFullSize: true)
                .frame(maxWidth: .infinity)
            }
            
        }
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack {
            
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
        VStack(alignment: .leading , spacing: 8) {
            
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule()
                    .foregroundColor(Color(selectedTask.color)))
                .padding(.top, 4)
            : nil
            
            // MARK: Indicate if task comes from imported calendar
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
}

struct TaskDetails_Previews: PreviewProvider {
    static var previews: some View {
        
        // MARK: Test data for preview
        let context = PersistenceController.shared.container.viewContext
        let aTask = Task(context: context)
        let subtask1 = Subtask(context: context)
        let subtask2 = Subtask(context: context)
        aTask.id = UUID()
        aTask.color = UIColor.blue
        aTask.isCompleted = false
        aTask.isImportant = true
        aTask.isImported = true
        aTask.taskDate = Date(timeIntervalSince1970: 1646784000)
        aTask.taskLabel = "Work Stuff"
        aTask.taskEndTime = Date(timeIntervalSince1970: 1646827200)
        aTask.taskStartTime = Date(timeIntervalSince1970: 1646816400)
        aTask.taskTitle = "Get started on learning WordPress development"
        subtask1.isCompleted = true
        subtask1.subtaskTitle = "Testing 1"
        subtask1.order = 1
        subtask1.isCompleted = false
        subtask1.subtaskTitle = "Try it out hahahaha XDDD"
        subtask1.order = 2
        aTask.subtask = aTask.subtask?.adding(subtask1) as NSSet?
        aTask.subtask = aTask.subtask?.adding(subtask2) as NSSet?
        
        return TaskDetails(selectedTask: aTask)
    }
}
