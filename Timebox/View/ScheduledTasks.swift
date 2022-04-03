//
//  ScheduledView.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

struct ScheduledTasks: View {
    // MARK: Core Data stuff
    @Environment(\.managedObjectContext) var context
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    @Namespace var animation
    @ObservedObject var taskModel = TaskViewModel()
    @State private var currentWeek = 0
    @State private var hideCompletedTasks = false
    
    // MARK: Tasks prepared from CD fetch
    var allTasks: [Task] {
        get {
            fetchedTasks.map { $0 as Task }
        }
    }
    var timeboxedTasks: [Task] {
        get {
            // Get scheduled task
            let filtered = taskModel.getScheduledTasks(data: self.allTasks, hideCompleted: self.hideCompletedTasks).map { $0 as Task }
            return filtered.filter { taskModel.isTimeboxedTask($0) }
        }
    }
    var allDayTasks: [Task] {
        get {
            // Get scheduled task
            let filtered = taskModel.getScheduledTasks(data: self.allTasks, hideCompleted: self.hideCompletedTasks).map { $0 as Task }
            return filtered.filter { taskModel.isAllDayTask($0) }
        }
    }
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),                    
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: false)])
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack {
                    HeaderView()
                        .padding()
                    
                    // Calendar view...
                    CalendarView()
                        .padding(.vertical)
                }
                .padding(.top, isNotched ? 47: 20)
                .background(Color.uiWhite)
                .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
                .shadow(radius: 12, x: 0, y: 3)
                // Cover up the unwanted top shadow
                .mask(Rectangle().padding(.bottom, -24))
                
                // A scrollview showing a list of tasks...
                ScrollView(.vertical, showsIndicators: false) {
                    if timeboxedTasks.isEmpty && allDayTasks.isEmpty {
                        ScreenFallbackView(title: "No scheduled task",
                                          image: Image("no-task"),
                                          caption1: "You don't have any schedule for today.",
                                          caption2: "Tap the plus button to create a new task.")
                    } else {
                        TaskListView().padding(.bottom, 32)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .onReceive(taskModel.$eventStore) { _ in
                if let removedEvents = taskModel.shouldRemoveEvents(taskStore: self.allTasks) {
                    taskModel.removeEventsFromPersistent(context: self.context, events: removedEvents)
                }
                
                if let newEvents = taskModel.shouldAddNewEvents(taskStore: self.allTasks) {
                    taskModel.addNewEventsToPersistent(context: self.context, events: newEvents)
                }
                
                if let updatedEvents = taskModel.shouldUpdateEvents(taskStore: self.allTasks) {
                    taskModel.updateEvents(context: self.context, events: updatedEvents)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack {
            // Menu button leading to Planned Tasks...
            NavigationLink(destination: BacklogTasks()) {
                Image("menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // Screen title...
            Text("Scheduled")
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
    
    private func CalendarView() -> some View {
        VStack(spacing: 32) {
            
            // Month selector...
            HStack {
                Button { currentWeek -= 1 } label: {
                    Image("chevron-left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
                
                Text("\(taskModel.formatDate(date: taskModel.currentDay, format: "MMMM y"))")
                    .font(.headingH2())
                    .fontWeight(.bold)
                
                Button { currentWeek += 1 } label: {
                    Image("chevron-right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .foregroundColor(.textPrimary)
            // Update the view when selecting another week...
            .onChange(of: currentWeek) { [currentWeek] newVal in
                let offset = newVal - currentWeek
                taskModel.updateWeek(offset: offset)

                // Update the selected day also upon updating week
                taskModel.currentDay = Calendar.current.date(byAdding: .weekOfMonth,
                                                             value: offset,
                                                             to: taskModel.currentDay)!
            }
            
            // Calendar cells...
            HStack(spacing: 4) {
                ForEach(taskModel.currentWeek, id: \.self) { day in
                    VStack(spacing: 8) {
                        // MARK: Day label
                        // EEEEE returns day as M,T,W ...
                        Text(taskModel.formatDate(date: day,
                                                  format: "EEEEE"))
                            .font(.paragraphP1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .backgroundSecondary
                                             : Calendar.current.isDateInToday(day) ? .accent
                                             : .textSecondary)
                        
                        // MARK: Date label
                        // dd will return date as 01,02 ...
                        Text(taskModel.formatDate(date: day, format: "dd"))
                            .font(.subheading1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .uiWhite
                                             : Calendar.current.isDateInToday(day) ? .accent
                                             : .textPrimary)
                    }
                    // Capsule shape for cell...
                    .frame(maxWidth: 56)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if taskModel.isCurrentDay(date: day) {
                            Capsule()
                                .fill(Color.accent)
                                .matchedGeometryEffect(id: "currentDay", in: animation)
                            }
                        }
                    )
                    .animation(.easeInOut, value: taskModel.currentDay)
                    // Update the view when select another day...
                    .onTapGesture { taskModel.currentDay = day }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func TaskListView() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            // Show time-constrained task if any...
            self.timeboxedTasks.count > 0 ? TaskSectionView(data: self.timeboxedTasks, header: "Timeboxed", icon: Image("clock")) : nil
            
            // Show all-day task if any...
            self.allDayTasks.count > 0 ? TaskSectionView(data: self.allDayTasks, header: "To-do Anytime", icon: Image("checkmark")) : nil
        }
    }
    
    private func TaskSectionView(data: [Task], header: String, icon: Image) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                // Timeboxed task cards...
                ForEach(data, id: \.id) { task in
                    TaskCardView(task: task)
                }
            } header: {
                // Heading for time-constrained tasks...
                HStack(spacing: 12) {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.textPrimary)
                        .frame(width: 28)

                    Text(header)
                        .font(.subheading1())
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

struct ScheduledTasks_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledTasks()
    }
}
