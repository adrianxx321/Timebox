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
        HStack(spacing: 16) {
            
            // MARK: Task label color
            Capsule()
                .fill(Color(task.color))
                .frame(width: 6)
                .frame(minHeight: 32)
            
            // MARK: Task information
            VStack(alignment: .leading ,spacing: 8) {
                
                // Show the important label only if it's marked so
                if task.isImportant {
                    Text("!!! IMPORTANT")
                        .font(.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(.uiOrange)
                }
                
                Text(task.taskTitle)
                    .font(.paragraphP1())
                    .fontWeight(.semibold)
                    .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textPrimary)
                    .if(task.isCompleted) { text in
                        text.strikethrough()
                    }
                    .multilineTextAlignment(.leading)
                
                // Show the subtasks completed info if there's any subtask
                if task.subtasks.count > 0 {
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
                    .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textSecondary)
                }
                
                // Show the task duration if
                //      1. It has time constaint
                //      2. It is not all-day long
                if taskModel.isScheduledTask(task) && !taskModel.isAllDayTask(task) {
                    Text("\(taskModel.formatDate(date: task.taskStartTime!, format: "h:mm a")) - \(taskModel.formatDate(date: task.taskEndTime!, format: "h:mm a"))")
                        .font(.caption())
                        .fontWeight(.semibold)
                        .foregroundColor((task.isCompleted || (taskModel.isScheduledTask(task) && Date() > task.taskEndTime!)) ? .textTertiary : .textSecondary)
                }
            }
            
            Spacer()
            
            // MARK: Task checkmark
            if task.subtasks.count <= 0 {
                Image("check-circle-f")
                    .padding(.trailing, 8)
            }
        }
        .frame(width: UIScreen.main.bounds.width - 80, alignment: .leading)
        .padding(16)
        .background(Color.uiWhite)
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
