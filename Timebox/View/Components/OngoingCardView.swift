//
//  OngoingCardView.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/03/2022.
//

import SwiftUI

struct OngoingCardView: View {
    @StateObject var taskModel = TaskViewModel()
    @ObservedObject var task: Task
    
    var body: some View {
        NavigationLink(destination: TaskDetails(selectedTask: task)) {
            HStack(spacing: 16) {
                // Task label color...
                Capsule()
                    .fill(Color(task.color ?? .accent))
                    .frame(width: 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Show the important label only if it's marked so...
                    task.isImportant ?
                    Text("!!! IMPORTANT")
                        .font(.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(.uiOrange)
                    : nil
                    
                    // Task title...
                    Text(task.taskTitle ?? "")
                        .font(.paragraphP1())
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        
                    // Task time remaining...
                    // If it's not timeboxed then show how many tasks left instead
                    Text(taskModel.getTimeRemaining(task: task))
                        .font(.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(.textTertiary)
                }
                .frame(maxWidth: 128)
                .fixedSize(horizontal: true, vertical: false)
            }
            
            // Circular progress bar for task completion...
            CircularProgressBar()
                .frame(width: 48, height: 48)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .background(Color.uiWhite)
        .cornerRadius(16)
    }
    
    private func CircularProgressBar() -> some View {
        ZStack {
            let completedSubtasks = taskModel.countCompletedSubtask(task.subtasks)
            let totalSubtasks = task.subtasks.count
            // Avoid division by 0
            let percent: Float = totalSubtasks != 0 ? Float(completedSubtasks / totalSubtasks) : 0
            
            Circle()
                .stroke(lineWidth: 6)
                .foregroundColor(.uiLightPurple)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(percent, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundColor(.uiPurple)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: percent)

            Text(String(format: "%.0f%%", min(percent, 1.0) * 100.0))
                .font(.caption())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
    }
}
