//
//  ScheduledView.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

struct Scheduled: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: Core Data fetch request
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    @Namespace var animation
    // MARK: ViewModels
    @ObservedObject var eventModel = EventViewModel()
    @ObservedObject var sessionModel = TaskSessionViewModel()
    @StateObject var taskModel = TaskViewModel()
    // MARK: UI States
    @State private var currentWeek = 0
    @State private var hideCompletedTasks = false
    @State var showBacklog = false
    
    // MARK: Tasks prepared from CD fetch
    private var allTasks: [Task] {
        get {
            taskModel.getAllTasks(query: self.fetchedTasks)
        }
    }
    private var timeboxedTasks: [Task] {
        get {
            // Get scheduled task
            let filtered = taskModel.filterScheduledTasks(data: self.allTasks, hideCompleted: self.hideCompletedTasks).map { $0 as Task }
            return filtered.filter { taskModel.isTimeboxedTask($0) }
        }
    }
    private var allDayTasks: [Task] {
        get {
            // Get scheduled task
            let filtered = taskModel.filterScheduledTasks(data: self.allTasks, hideCompleted: self.hideCompletedTasks).map { $0 as Task }
            return filtered.filter { taskModel.isAllDayTask($0) }
                // Sort by name first
                .sorted(by: {$0.taskTitle! < $1.taskTitle! })
                // Then importance
                .sorted(by: {$0.isImportant && !$1.isImportant })
        }
    }
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),                    
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
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
                .padding(.top, GLOBAL.isNotched ? 47: 20)
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
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView() -> some View {
        HStack {
            // Menu button leading to Planned Tasks...
            NavigationLink(isActive: self.$showBacklog) {
                Backlog(isPresent: self.$showBacklog)
            } label: {
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
    
    private func CalendarView() -> some View {
        VStack(spacing: 32) {
            
            // Month selector...
            HStack {
                Button {
                    currentWeek -= 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image("chevron-left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
                Text(taskModel.currentDay.formatDateTime(format: "MMMM y"))
                    .font(.headingH2())
                    .fontWeight(.bold)
                
                Button {
                    currentWeek += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    
                } label: {
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
                        Text(day.formatDateTime(format: "EEEEE"))
                            .font(.paragraphP1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .backgroundSecondary
                                             : Calendar.current.isDateInToday(day) ? .accent
                                             : .textSecondary)
                        
                        // MARK: Date label
                        // dd will return date as 01,02 ...
                        Text(day.formatDateTime(format: "dd"))
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
                    .onTapGesture {
                        taskModel.currentDay = day
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
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
        Scheduled()
    }
}
