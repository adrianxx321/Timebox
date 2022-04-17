//
//  TaskCardView.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct TaskCardView: View {
    // MARK: Dependencies (CD object)
    @ObservedObject var task: Task
    // MARK: ViewModels
    @ObservedObject var taskModel = TaskViewModel()
    // MARK: UI States
    @State private var dragOffset: CGFloat = 0
    @State private var showDeleteDialog = false
    @GestureState private var isDragging = false
    
    // MARK: Convenient derived properties
    var canDelete: Bool {
        get {
            task.ekeventID == nil
        }
    }
    var canEdit: Bool {
        get {
            !taskModel.isOverdue(self.task)
        }
    }
    var interval: String? {
        get {
            guard let startTime = self.task.taskStartTime, let endTime = self.task.taskEndTime else {
                return nil
            }
            
            if taskModel.isAllDayTask(self.task) {
                return nil
            } else {
                let startTimeFormatted = startTime.formatDateTime(format: "h:mm a")
                let endTimeFormatted = endTime.formatDateTime(format: "h:mm a")
                
                return "\(startTimeFormatted) - \(endTimeFormatted)"
            }
        }
    }
    // See how many actions can be performed on the task
    // Some may be edited & deleted, some only one, some totally none
    var swipeBtnSpace: CGFloat {
        get {
            self.canEdit && self.canDelete ? 130 : self.canEdit || self.canDelete ? 65 : 0
        }
    }
    
    var body: some View {
        ZStack {
            // Swipe to action buttons...
            HStack(spacing: 8) {
                Spacer()
                
                // Edit...
                self.canEdit ?
                SwipeToButton(isDestructive: false, action: {
                    // Brings up edit modal...
                    taskModel.addNewTask.toggle()
                    taskModel.editTask = task
                }) : nil
                
                // Delete...
                self.canDelete ?
                SwipeToButton(isDestructive: true, action: {
                    // Perform task deletion...
                    showDeleteDialog.toggle()
                })
                .confirmationDialog("Are you sure you want to delete this task?",
                                    isPresented: $showDeleteDialog,
                                    titleVisibility: .visible) {
                    Button("Delete Task", role: .destructive) {
                        withAnimation {
                            dragOffset = 0
                            taskModel.deleteTask(task: self.task)
                        }
                    }
                } : nil
            }
            
            // Clickable task card which leads to Task Details screen...
            NavigationLink(destination: TaskDetails(selectedTask: task)) {
                HStack(spacing: 16) {
                    // Task label color...
                    Capsule()
                        .fill(Color(task.color ?? .accent))
                        .frame(width: 6)
                        .frame(minHeight: 32)
                    
                    // Task information...
                    VStack(alignment: .leading, spacing: 8) {
                        // Show the important label only if it's marked so...
                        task.isImportant ?
                        Text("!!! IMPORTANT")
                            .font(.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(.uiOrange)
                        : nil
                        
                        // Task title...
                        // Overdue task's title will be greyed out
                        Text(task.taskTitle ?? "")
                            .font(.paragraphP1())
                            .fontWeight(.semibold)
                            .foregroundColor((task.isCompleted || taskModel.isOverdue(task)) ? .textTertiary : .textPrimary)
                            .if(task.isCompleted) { text in
                                text.strikethrough()
                            }
                            .multilineTextAlignment(.leading)
                        
                        // Show the subtasks completion info if there's any...
                        task.subtasks.count > 0 ?
                        HStack(spacing: 8) {
                            Image("branch")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24)
                                .rotationEffect(.degrees(90))

                            Text("\(taskModel.countCompletedSubtask(task.subtasks))/\(task.subtasks.count) completed")
                                .font(.caption())
                                .fontWeight(.semibold)
                        }
                        // Text color varies depending on overdue and/or completion status...
                        .foregroundColor((task.isCompleted || taskModel.isOverdue(task)) ? .textTertiary : .textSecondary)
                        : nil
                        
                        // Show the task duration if
                        // 1. It has time constaint
                        // 2. It is not all-day long
                        if let interval = self.interval {
                            Text(interval)
                                .font(.caption())
                                .fontWeight(.semibold)
                                // Text color varies depending on overdue and/or completion status...
                                .foregroundColor((task.isCompleted || taskModel.isOverdue(task)) ? .textTertiary : .textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Task checkmark, for task with no subtask...
                    task.subtasks.count <= 0 ?
                    Button {
                        withAnimation() {
                            // Perform update onto Core Data...
                            taskModel.completeTask(self.task)
                        }
                    } label: {
                        Image(task.isCompleted ? "checked" : "unchecked")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28)
                            .foregroundColor(task.isCompleted ? .accent : .backgroundTertiary)
                            .padding(.trailing, 8)
                    }
                    : nil
                }
                .padding(16)
                .background(Color.uiWhite)
                .cornerRadius(16)
                // Swipe gesture...
                .offset(x: dragOffset)
                .gesture(DragGesture()
                    .updating($isDragging) { (_, state, _) in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = isDragging && value.translation.width < 0 ? value.translation.width : dragOffset
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            dragOffset = value.translation.width <= -50 ? -self.swipeBtnSpace : 0
                        }
                    })
            }
            .buttonStyle(FlatLinkStyle.init())
        }
        .frame(width: UIScreen.main.bounds.width - 48, alignment: .leading)
        .sheet(isPresented: $taskModel.addNewTask) {
            withAnimation {
                dragOffset = 0
            }
        } content: {
            TaskModal().environmentObject(taskModel)
        }
    }
    
    func SwipeToButton(isDestructive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Image(isDestructive ? "trash" : "pencil")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
                .foregroundColor(isDestructive ? .uiRed : .textSecondary)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(Color(isDestructive ? .uiPink : .backgroundTertiary))
        .cornerRadius(16)
    }
}
