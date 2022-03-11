//
//  TaskCardView.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct TaskCardView: View {
    @StateObject var taskModel = TaskViewModel()
    @ObservedObject var task: Task
    @GestureState private var isDragging = false
    
    var body: some View {
        ZStack {
            // Swipe to action buttons...
            HStack(spacing: 8) {
                Spacer()
                
                // Edit...
                SwipeToButton(isDestructive: false, action: {
                    // TODO: Brings up edit modal...
                })
                
                // Delete...
                SwipeToButton(isDestructive: true, action: {
                    // TODO: Perform task deletion...
                })
            }.opacity(task.offset == 0 ? 0 : 1)
            
            // Clickable task card which leads to Task Details screen...
            NavigationLink(destination: TaskDetails(selectedTask: task)) {
                HStack(spacing: 16) {
                    // Task label color...
                    Capsule()
                        .fill(Color(task.color))
                        .frame(width: 6)
                        .frame(minHeight: 32)
                    
                    // Task information...
                    VStack(alignment: .leading ,spacing: 8) {
                        // Show the important label only if it's marked so...
                        task.isImportant ?
                        Text("!!! IMPORTANT")
                            .font(.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(.uiOrange)
                        : nil
                        
                        // Task title...
                        Text(task.taskTitle)
                            .font(.paragraphP1())
                            .fontWeight(.semibold)
                            .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textPrimary)
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
                        .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textSecondary)
                        : nil
                        
                        // Show the task duration if
                        // 1. It has time constaint
                        // 2. It is not all-day long
                        taskModel.isScheduledTask(task) && !taskModel.isAllDayTask(task) ?
                        Text("\(taskModel.formatDate(date: task.taskStartTime!, format: "h:mm a")) - \(taskModel.formatDate(date: task.taskEndTime!, format: "h:mm a"))")
                            .font(.caption())
                            .fontWeight(.semibold)
                            // Text color varies depending on overdue and/or completion status...
                            .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textSecondary)
                        : nil
                    }
                    
                    Spacer()
                    
                    // Task checkmark, for task with no subtask...
                    task.subtasks.count <= 0 ?
                    Button {
                        withAnimation {
                            // Perform update onto Core Data...
                            task.isCompleted.toggle()
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
                .offset(x: CGFloat(task.offset))
                .gesture(DragGesture()
                            .updating($isDragging, body: { (value, state, _) in
                                // so we can validate for correct drag
                                state = true
                                onChanged(value: value)
                            }).onEnded({ (value) in
                                onEnd(value: value)
                            }))
            }
            .buttonStyle(FlatLinkStyle())
        }
        .frame(width: UIScreen.main.bounds.width - 48, alignment: .leading)
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
        .background(Color(isDestructive ? .uiPink : .uiWhite))
        .cornerRadius(16)
    }
    
    func onChanged(value: DragGesture.Value) {
        if value.translation.width < 0 && isDragging {
            task.offset = Float(value.translation.width)
        }
    }

    func onEnd(value: DragGesture.Value) {
        withAnimation {
            // 65 + 65 = 130
            if -value.translation.width >= 100 {
                task.offset = -130
            } else {
                task.offset = 0
            }
        }
    }
}

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
