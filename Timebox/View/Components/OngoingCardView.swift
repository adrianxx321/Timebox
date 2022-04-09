//
//  OngoingCardView.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/03/2022.
//

import SwiftUI

struct OngoingCardView: View {
    // MARK: Dependencies (CD object)
    @ObservedObject var task: Task
    // MARK: ViewModels
    @StateObject var taskModel = TaskViewModel()
    
    // MARK: Derived properties
    // Numbers needed for circular progress bar presentation
    var percentage: Float {
        get {
            let completed = taskModel.countCompletedSubtask(task.subtasks)
            // Avoid division by 0
            let total = self.task.subtasks.count != 0 ? Float(self.task.subtasks.count) : 1
            
            return (Float(completed) / Float(total))
        }
    }
    
    var body: some View {
        NavigationLink(destination: TaskDetails(selectedTask: self.task)) {
            HStack {
                // Task label color...
                Capsule()
                    .fill(Color(task.color ?? .accent))
                    .frame(width: 6)
                    .padding(.trailing, 4)
                
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
            // Don't show for task without subtask...
            task.subtasks.count > 0 ?
            CircularProgressBar()
                .frame(width: 48, height: 48)
            : nil
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 144, maxHeight: 128, alignment: .leading)
        .padding(16)
        .background(Color.uiWhite)
        .cornerRadius(16)
    }
    
    private func CircularProgressBar() -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .foregroundColor(.uiLightPurple)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.percentage, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundColor(.uiPurple)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: self.percentage)

            Text(String(format: "%.0f%%", min(self.percentage, 1.0) * 100.0))
                .font(.caption())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
    }
}
