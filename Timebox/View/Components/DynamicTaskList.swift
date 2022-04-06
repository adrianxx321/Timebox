//
//  DynamicTaskList.swift
//  Timebox
//
//  Created by Lianghan Siew on 06/03/2022.
//

import SwiftUI
import CoreData

struct DynamicTaskList: View {
    private var isBacklog: Bool
    @StateObject var taskModel = TaskViewModel()
    
    // MARK: Core Data Request for fetching tasks
    @FetchRequest var request: FetchedResults<Task>
    
    /// Fetch  scheduled tasks
    init(dateToFilter: Date, hideCompleted: Bool) {
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: dateToFilter)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: dateToFilter)!
        
        // Building compound predicate based on inputs
        let p1 = NSPredicate(format: "taskStartTime >= %@ AND taskStartTime < %@", argumentArray: [today, tomorrow])
        let p2 = NSPredicate(format: "isCompleted == false", argumentArray: [hideCompleted])
        let predicate = hideCompleted ? [p1, p2] : [p1]
        
        // Initializing query using NSCompoundPredicate
        _request = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: false)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicate)
        )
        
        self.isBacklog = false
    }
    
    /// Fetch backlog tasks
    init(dateToFilter: Date?, hideCompleted: Bool) {
        // Building compound predicate based on inputs
        let p1 = NSPredicate(format: "taskStartTime == nil", argumentArray: [])
        let p2 = NSPredicate(format: "isCompleted == false", argumentArray: [hideCompleted])
        let predicate = hideCompleted ? [p1, p2] : [p1]

        // Initializing query using NSPredicate
        _request = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.isImportant, ascending: false)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicate)
        )

        self.isBacklog = true
    }
    
    var body: some View {
        
        // List for backlog screen...
        if isBacklog {
            if request.isEmpty {
                // Fallback screen...
                FallBackView(title: "Your untimed to-do's",
                             caption1: "Task with no specific date goes here.",
                             caption2: "Schedule them to create timeboxed tasks.",
                             isBacklog: isBacklog)
                
            } else {
                VStack(spacing: 16) {
                    ForEach(request, id: \.id) { task in
                        TaskCardView(task: task)
                    }
                }
            }
        }
        
        // List for scheduled screen...
        else {
            if request.isEmpty {
                // Fallback screen...
                FallBackView(title: "No scheduled task",
                             caption1: "You don't have any schedule for today.",
                             caption2: "Tap the plus button to create a new task.",
                             isBacklog: isBacklog)
                
            } else {
                // Split fetched tasks into timeboxed and all-day...
                let timeboxed = request.filter { task in
                    !taskModel.isAllDayTask(task)
                }.sorted {
                    // Sort by task commence time...
                    $0.taskStartTime! < $1.taskEndTime!
                }
                
                let allDay = request.filter { task in
                    taskModel.isAllDayTask(task)
                }
                
                VStack(spacing: 32) {
                    // Show time-constrained task if any...
                    if timeboxed.count > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Section {
                                // Timeboxed task cards...
                                ForEach(timeboxed, id: \.id) { task in
                                    TaskCardView(task: task)
                                }
                            } header: {
                                // Heading for time-constrained tasks...
                                HStack(spacing: 12) {
                                    Image("clock")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.textPrimary)
                                        .frame(width: 28)

                                    Text("Timeboxed")
                                        .font(.subheading1())
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                    
                    // Show all-day task if any...
                    if allDay.count > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Section {
                                // All-day task cards...
                                ForEach(allDay, id: \.id) { task in
                                    TaskCardView(task: task)
                                }
                            } header: {
                                // Heading for all-day tasks...
                                HStack(spacing: 12) {
                                    Image("checkmark")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.textPrimary)
                                        .frame(width: 28)

                                    Text("To-do Anytime")
                                        .font(.subheading1())
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func FallBackView(title: String, caption1: String, caption2: String, isBacklog: Bool) -> some View {
        VStack {
            Image(isBacklog ? "backlog" : "no-task")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width - 64,
                       maxHeight: isSmallDevice ? 240 : 360)
                // For some reason the illustration for backlog screen lacks of bottom padding
                .padding(.vertical, isBacklog ? 16 : 0)

            VStack(spacing: 16) {
                Text("\(title)")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 8) {
                    Text("\(caption1)")
                        .fontWeight(.semibold)
                    Text("\(caption2)")
                        .fontWeight(.semibold)
                }
                .font(.paragraphP1())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            }
        }
    }
}