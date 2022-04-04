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
    @ObservedObject var task: Task
    @StateObject var taskModel = TaskViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var showDeleteDialog = false
    @GestureState private var isDragging = false
    
    // MARK: Core Data environment
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
        ZStack {
            // Swipe to action buttons...
            HStack(spacing: 8) {
                Spacer()
                
                // Edit...
                SwipeToButton(isDestructive: false, action: {
                    // Brings up edit modal...
                    taskModel.addNewTask.toggle()
                    taskModel.editTask = task
                })
                
                // Delete...
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
                            context.delete(task)
                            try? context.save()
                        }
                    }
                }
                
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
                        taskModel.isScheduledTask(task) && !taskModel.isAllDayTask(task) ?
                        Text("\(taskModel.formatDate(date: task.taskStartTime!, format: "h:mm a")) - \(taskModel.formatDate(date: task.taskEndTime!, format: "h:mm a"))")
                            .font(.caption())
                            .fontWeight(.semibold)
                            // Text color varies depending on overdue and/or completion status...
                            .foregroundColor((task.isCompleted || taskModel.isOverdue(task)) ? .textTertiary : .textSecondary)
                        : nil
                    }
                    
                    Spacer()
                    
                    // Task checkmark, for task with no subtask...
                    task.subtasks.count <= 0 ?
                    Button {
                        withAnimation() {
                            // Perform update onto Core Data...
                            task.isCompleted.toggle()
                            
                            // Save to Core Data
                            try? context.save()
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
                            dragOffset = value.translation.width <= -50 ? -130 : 0
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
            TaskModal()
                .environmentObject(taskModel)
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
