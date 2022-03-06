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
    
    // MARK: Core Data Request for fetching tasks
    @FetchRequest var request: FetchedResults<Task>
    
    /// Fetch  scheduled tasks
    init(taskDate: Date, showCompleted: Bool) {
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: taskDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: taskDate)!
        
        // Building compound predicate based on inputs
        let p1 = NSPredicate(format: "taskDate >= %@ AND taskDate < %@", argumentArray: [today, tomorrow])
        let p2 = NSPredicate(format: "isCompleted == %@ ", argumentArray: [showCompleted])
        let predicate = [p1, p2]
        
        // Initializing query using NSCompoundPredicate
        _request = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskDate, ascending: false)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicate)
        )
        
        self.isBacklog = false
    }
    
    /// Fetch backlog tasks
    init(taskDate: Date?, showCompleted: Bool) {
        // Query predicate
        let predicate = NSPredicate(format: "taskDate == nil AND isCompleted == %@", argumentArray: [showCompleted])

        // Initializing query using NSPredicate
        _request = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.isImportant, ascending: true)],
            predicate: predicate
        )

        self.isBacklog = true
    }
    
    var body: some View {
        
        // MARK: List for backlog screen
        if isBacklog {
            if request.isEmpty {
                
                // Fallback screen...
                fallBackView(title: "No backlog task", caption1: "You don’t have anything planned so far.", caption2: "Tap the button below to create one.")
                
            } else {
                
                ForEach(request, id: \.id) { object in
                    TaskCardView(task: object)
                }
            }
        }
        
        // MARK: List for scheduled screen
        else {
            if request.isEmpty {
                
                // Fallback screen...
                fallBackView(title: "No scheduled task", caption1: "You don't have any schedule for today.", caption2: "Tap the plus button to create a new task.")
                
            } else {
                
                // Split fetched tasks into timeboxed and all-day
                let timeboxed = request.filter { task in
                    task.taskStartTime != nil && task.taskEndTime != nil
                }
                let allDay = request.filter { task in
                    task.taskStartTime == nil && task.taskEndTime == nil
                }
                
                // MARK: Show time-constrained task if any
                if timeboxed.count > 0 {
                    VStack(alignment: .leading, spacing: 16) {

                        Section {
                            
                            // MARK: Timeboxed task cards
                            ForEach(timeboxed, id: \.self.id) { task in
                                TaskCardView(task: task)
                            }
                            
                        } header: {
                            
                            // MARK: Heading for time-constrained tasks
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
                
                // MARK: Show all-day task if any
                if allDay.count > 0 {
                    VStack(alignment: .leading, spacing: 16) {

                        Section {
                            
                            // MARK: All-day task cards
                            ForEach(allDay, id: \.self.id) { task in
                                TaskCardView(task: task)
                            }
                            
                        } header: {
                            
                            // MARK: Heading for all-day tasks
                            HStack(spacing: 12) {
                                Image("check")
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
    
    func fallBackView(title: String, caption1: String, caption2: String) -> some View {
        VStack {
           Image("no-task")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 320)

            Text("\(title)")
                .font(.headingH2())
                .fontWeight(.heavy)
                .foregroundColor(.textPrimary)
                .padding(.vertical, 16)

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
