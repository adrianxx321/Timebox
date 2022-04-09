//
//  SubtasksChecklist.swift
//  Timebox
//
//  Created by Lianghan Siew on 09/04/2022.
//

import SwiftUI

struct SubtasksChecklist: View {
    // MARK: Core Data environment
    @Environment(\.managedObjectContext) var context
    // MARK: ViewModels
    @ObservedObject private var taskModel = TaskViewModel()
    // MARK: Dependency (CD Object)
    @ObservedObject var selectedTask: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(selectedTask.subtasks, id: \.id) { subtask in
                HStack(spacing: 12) {
                    // Checkbox for subtask completion...
                    Button {
                        withAnimation {
                            taskModel.completeSubtask(parentTask: self.selectedTask, subtask: subtask, context: self.context)
                        }
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
            selectedTask.subtasks.count <= 0 ?
            Text("This task doesn't have any subtask.")
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary) : nil
        }
    }
}
