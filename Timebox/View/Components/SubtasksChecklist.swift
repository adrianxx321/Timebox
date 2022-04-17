//
//  SubtasksChecklist.swift
//  Timebox
//
//  Created by Lianghan Siew on 09/04/2022.
//

import SwiftUI

struct SubtasksChecklist: View {
    // MARK: ViewModels
    @ObservedObject private var taskModel = TaskViewModel()
    // MARK: Dependency (CD Object)
    @ObservedObject var parentTask: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(self.parentTask.subtasks, id: \.id) { subtask in
                HStack(spacing: 12) {
                    // Checkbox for subtask completion...
                    Button {
                        withAnimation {
                            taskModel.completeSubtask(parentTask: self.parentTask, subtask: subtask)
                        }
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(subtask.isCompleted ? "checked" : "unchecked")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28)
                            .foregroundColor(.accent)
                            .padding(.trailing, 8)
                    }
                    
                    // Subtask title...
                    Text(subtask.subtaskTitle ?? "")
                        .font(.paragraphP1())
                        .fontWeight(.bold)
                        .foregroundColor(subtask.isCompleted ? .textSecondary : .textPrimary)
                        .if(subtask.isCompleted) { text in
                            text.strikethrough()
                        }
                }
            }
            
            // Indicator for no subtask...
            self.parentTask.subtasks.count <= 0 ?
            Text("This task doesn't have any subtask.")
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary) : nil
        }
    }
}
