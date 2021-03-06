//
//  TaskDetails.swift
//  Timebox
//
//  Created by Lianghan Siew on 08/03/2022.
//

import SwiftUI
import CoreData
import EventKit

struct TaskDetails: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    // MARK: ViewModels
    @ObservedObject var selectedTask: Task
    @ObservedObject private var eventModel = EventViewModel()
    @StateObject private var taskModel = TaskViewModel()
    // MARK: UI States
    @State var showMoreOptions = false
    @State var showDeleteDialog = false
    
    // MARK: Convenient derived properties
    var canDelete: Bool {
        get {
            selectedTask.ekeventID == nil
        }
    }
    var canEdit: Bool {
        get {
            !taskModel.isOverdue(self.selectedTask)
        }
    }
    var taskDateFormatted: String {
        get {
            guard let startTime = self.selectedTask.taskStartTime else {
                return "None"
            }
            
            return "\(startTime.formatDateTime(format: "EEEE, d MMMM yyyy"))"
        }
    }
    var intervalDuration: String {
        get {
            guard let startTime = self.selectedTask.taskStartTime, let endTime = self.selectedTask.taskEndTime else {
                return "None"
            }
            
            if taskModel.isAllDayTask(self.selectedTask) {
                return "All-day"
            } else {
                let startTimeFormatted = startTime.formatDateTime(format: "hh:mm a")
                let endTimeFormatted = endTime.formatDateTime(format: "hh:mm a")
                let duration = endTime - startTime
                let intervalFormated = Date.formatTimeDuration(duration, unitStyle: .full,
                                                               units: [.hour, .minute], padding: nil)
                
                return "\(startTimeFormatted) - \(endTimeFormatted) (\(intervalFormated))"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavBarView()
                .padding()
            
            // Content of task details...
            VStack(alignment: .leading, spacing: 40) {
                TaskHeaderView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Subtasks section...
                        TaskSectionView(sectionTitle: "Subtasks") {
                            // Subtasks breakdown, if any...
                            if self.selectedTask.subtasks.count > 0 {
                                SubtasksChecklist(parentTask: self.selectedTask)
                            } else {
                                Text("This task doesn't have contain any subtask.")
                                    .font(.paragraphP1())
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
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
                                    
                                    Text(self.taskDateFormatted)
                                        .font(.paragraphP1())
                                        .fontWeight(.bold)
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
                                    
                                    Text("\(self.intervalDuration)")
                                        .font(.paragraphP1())
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // TODO: Move this to task card instead
            // Button for start timeboxing for ongoing task...
            if taskModel.isScheduledTask(selectedTask) {
                if selectedTask.taskStartTime! >= Date() && selectedTask.taskEndTime! < Date() {
                    CTAButton(btnLabel: "Start Timeboxing", btnFullSize: true, action: {
                        
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, GLOBAL.isNotched ? 0 : 15)
                }
            }
        }
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
        .sheet(isPresented: $taskModel.addNewTask) {
            // Do nothing
        } content: {
            TaskModal()
                .environmentObject(taskModel)
        }
    }
    
    private func NavBarView() -> some View {
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
            self.canEdit || self.canDelete ?
            Menu {
                // Bring up the edit task modal...
                self.canEdit ?
                Button {
                    taskModel.addNewTask.toggle()
                    taskModel.editTask = selectedTask
                } label: {
                    taskModel.isScheduledTask(selectedTask) ?
                    Label("Edit Task", image: "pencil") : Label("Add to Scheduled", image: "clock")
                }.foregroundColor(.textPrimary) : nil
                
                // Delete this task...
                self.canDelete ?
                Button(role: .destructive) {
                    showDeleteDialog.toggle()
                } label: {
                    Label("Delete Task", image: "trash")
                } : nil
            } label: {
                Image("more-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
            .font(.paragraphP1().weight(.medium))
            .confirmationDialog("Are you sure you want to delete this task?",
                                isPresented: $showDeleteDialog,
                                titleVisibility: .visible) {
                Button("Delete Task", role: .destructive) {
                    taskModel.deleteTask(task: selectedTask)
                    // Go back to previous screen after deletion...
                    presentationMode.wrappedValue.dismiss()
                }
            } : nil
        }
        .foregroundColor(.textPrimary)
    }
    
    private func TaskHeaderView() -> some View {
        VStack(alignment: .leading , spacing: 8) {
            
            // Importance label if task is important...
            selectedTask.isImportant ?
            Text("!!! Important")
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(.uiOrange)
            : nil
            
            // Task name...
            Text(selectedTask.taskTitle ?? "")
                .font(.headingH2())
                .fontWeight(.heavy)
                .foregroundColor(.textPrimary)
            
            // Task label name & color, if any...
            selectedTask.taskLabel != nil ?
            Text(selectedTask.taskLabel!)
                .font(.paragraphP1())
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(.uiWhite)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule()
                    .foregroundColor(Color(selectedTask.color ?? .accent)))
                .padding(.top, 4)
            : nil
            
            // Indicate if task comes from imported calendar...
            if let ekEventID = selectedTask.ekeventID {
                let foundEvent = eventModel.lookupCalendarEvent(ekEventID)
                let foundCalendarSource = foundEvent?.calendar.source.title ?? "Unknown Calendar"
                
                HStack(spacing: 8) {
                    Image("alert")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28)
                        .foregroundColor(.textSecondary)
                        .rotationEffect(Angle(degrees: 180))
                    
                    Group {
                        Text("This task/event comes from: ")
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary) +
                        Text("\(foundCalendarSource) Calendar")
                            .fontWeight(.bold)
                            .foregroundColor(Color(selectedTask.color ?? .accent))
                    }
                    .font(.paragraphP1())
                    .lineSpacing(4)
                }.padding(.top, 8)
            }
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
