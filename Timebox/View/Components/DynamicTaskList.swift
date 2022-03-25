//
//  DynamicTaskList.swift
//  Timebox
//
//  Created by Lianghan Siew on 06/03/2022.
//

import SwiftUI
import CoreData

private enum ListType {
    case ongoing, scheduled, backlog
}

struct DynamicTaskList: View {
    private var viewMode: ListType
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
        
        self.viewMode = .scheduled
    }
    
    /// Fetch backlog tasks
    init(hideCompleted: Bool) {
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

        self.viewMode = .backlog
    }
    
    /// Fetch ongoing tasks
    init(timeNow: Date) {
        let predicate = NSPredicate(format: "taskStartTime <= %@ AND taskEndTime > %@", argumentArray: [timeNow, timeNow])
        
        _request = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: false)],
            predicate: predicate
        )
        
        self.viewMode = .ongoing
    }
    
    var body: some View {
        // Fallback screen when no task can be found
        if request.isEmpty {
            switch viewMode {
            case .ongoing:
                OngoingFallback(title: "Uhh, nothing's going on",
                                image: Image("no-ongoing"),
                                caption: "Looks like you are currently free.")
            case .scheduled:
                TasksFallbackView(title: "No scheduled task",
                                  image: Image("no-task"),
                                  caption1: "You don't have any schedule for today.",
                                  caption2: "Tap the plus button to create a new task.")
            case .backlog:
                TasksFallbackView(title: "Your untimed to-do's",
                                  image: Image("backlog"),
                                  caption1: "Task with no specific date goes here.",
                                  caption2: "Schedule them to create timeboxed tasks.")
            }
        }
        
        else {
            switch viewMode {
            case .ongoing:
                OngoingList(data: request)
            case .scheduled:
                // Split fetched tasks into timeboxed and all-day...
                let timeboxed = request.filter { task in
                    taskModel.isTimeboxedTask(task)
                }.sorted {
                    // Sort by task commence time...
                    $0.taskStartTime! < $1.taskEndTime!
                }
                
                let allDay = request.filter { task in
                    taskModel.isAllDayTask(task)
                }
                
                VStack(spacing: 32) {
                    // Show time-constrained task if any...
                    timeboxed.count > 0 ? TimeboxedList(data: timeboxed) : nil
                    
                    // Show all-day task if any...
                    allDay.count > 0 ? AllDayList(data: allDay) : nil
                }
            case .backlog:
                BacklogList(data: request)
            }
        }
    }
    
    private func OngoingList(data: FetchedResults<Task>) -> some View {
        HStack(spacing: 16) {
            ForEach(data, id: \.id) { task in
                OngoingCardView(task: task)
            }
        }
    }
    
    private func TimeboxedList(data: [FetchedResults<Task>.Element]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                // Timeboxed task cards...
                ForEach(data, id: \.id) { task in
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
    
    private func AllDayList(data: [FetchedResults<Task>.Element]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                // All-day task cards...
                ForEach(data, id: \.id) { task in
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
    
    private func BacklogList(data: FetchedResults<Task>) -> some View {
        VStack(spacing: 16) {
            ForEach(data, id: \.id) { task in
                TaskCardView(task: task)
            }
        }
    }
    
    private func TasksFallbackView(title: String, image: Image, caption1: String, caption2: String) -> some View {
        VStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width - 64,
                       maxHeight: isSmallDevice ? 240 : 360)
                // For some reason the illustration for backlog screen lacks of bottom padding
                .padding(.vertical, (viewMode == .scheduled) ? 0 : 16)

            VStack(spacing: 16) {
                Text("\(title)")
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 8) {
                    Text(caption1)
                        .fontWeight(.semibold)
                    Text(caption2)
                        .fontWeight(.semibold)
                }
                .font(.paragraphP1())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            }
        }
    }
    
    private func OngoingFallback(title: String, image: Image, caption: String) -> some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheading1())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                
                Text(caption)
                    .font(.paragraphP1())
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
