//
//  PlannedTasks.swift
//  Timebox
//
//  Created by Lianghan Siew on 03/03/2022.
//

import SwiftUI

struct BacklogTasks: View {
    // MARK: Core Data stuff
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @FetchRequest var fetchedBacklog: FetchedResults<Task>
    @StateObject var taskModel = TaskViewModel()
    @State private var hideCompletedTasks = false
    
    // MARK: Tasks prepared from CD fetch
    var backlogTasks: [Task] {
        get {
            let tasks = self.fetchedBacklog.map { $0 as Task }
            
            return hideCompletedTasks ? tasks.filter{ !$0.isCompleted } : tasks
        }
    }
    
    init() {
        let predicate = NSPredicate(format: "taskStartTime == nil AND taskEndTime == nil", argumentArray: [])

        _fetchedBacklog = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.isImportant, ascending: false)],
            predicate: predicate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HeaderView()
                    .padding()
                
                // Scrollview showing list of backlog tasks...
                ScrollView(.vertical, showsIndicators: false) {
                    if backlogTasks.isEmpty {
                        ScreenFallbackView(title: "Your untimed to-do's",
                                           image: Image("backlog"),
                                           caption1: "Task with no specific date goes here.",
                                           caption2: "")
                    } else {
                        VStack(spacing: 16) {
                            ForEach(backlogTasks, id: \.id) { task in
                                TaskCardView(task: task)
                            }
                        }.padding(.bottom, 32)
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack() {
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
            Text("Backlog")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // Hide/Show completed tasks...
            Button {
                withAnimation {
                    hideCompletedTasks.toggle()
                }
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

struct BacklogTasks_Previews: PreviewProvider {
    static var previews: some View {
        BacklogTasks()
    }
}
