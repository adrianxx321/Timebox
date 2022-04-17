//
//  PlannedTasks.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct Backlog: View {
    // MARK: Core Data fetch request
    @FetchRequest var fetchedBacklog: FetchedResults<Task>
    // MARK: ViewModels
    @StateObject var taskModel = TaskViewModel()
    // MARK: UI States
    @State private var hideCompletedTasks = false
    @Binding var isPresent: Bool
    
    // MARK: Tasks prepared from CD fetch
    var backlogTasks: [Task] {
        get {
            let tasks = self.taskModel.getAllTasks(query: self.fetchedBacklog)
                // Sort by name first
                .sorted(by: {$0.taskTitle! < $1.taskTitle! })
                // Then importance
                .sorted(by: {$0.isImportant && !$1.isImportant })
            
            return hideCompletedTasks ? tasks.filter{ !$0.isCompleted } : tasks
        }
    }
    
    init(isPresent: Binding<Bool>) {
        let predicate = NSPredicate(format: "taskStartTime == nil AND taskEndTime == nil", argumentArray: [])

        _fetchedBacklog = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.isImportant, ascending: false)],
            predicate: predicate)
        
        self._isPresent = isPresent
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HeaderView()
                    .padding()
                
                // Scrollview showing list of backlog tasks...
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if backlogTasks.isEmpty {
                            ScreenFallbackView(title: "Your untimed to-do's",
                                               image: Image("backlog"),
                                               caption1: "Task with no specific date goes here.",
                                               caption2: "")
                        } else {
                            ForEach(backlogTasks, id: \.id) { task in
                                TaskCardView(task: task)
                            }
                        }
                    }.padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack() {
            // Back button leading to previous screen...
            Button {
                self.isPresent.toggle()
            } label: {
                Image("chevron-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // Screen title...
            Text("Backlog")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // Hide/Show completed tasks...
            Button {
                withAnimation {
                    hideCompletedTasks.toggle()
                }
                
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(hideCompletedTasks ? "eye-close" : "eye")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
        }
        .foregroundColor(.textPrimary)
    }
}

