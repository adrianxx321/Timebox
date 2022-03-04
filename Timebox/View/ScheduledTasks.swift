//
//  ScheduledView.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

struct ScheduledTasks: View {
    @Namespace var animation
    @StateObject var taskModel = TaskViewModel()
    @State private var currentWeek = 0
    @State private var hideCompletedTasks = false
    @State private var showBacklog = false
    
    var body: some View {
        if showBacklog {
            
            // MARK: Go to backlog tasks
            BacklogTasks(showBacklog: $showBacklog)
                .transition(.move(edge: .trailing))
        } else {
            
            VStack(spacing: 24) {
                VStack {
                    HeaderView()
                        .padding()
                    
                    // MARK: Calendar view
                    CalendarView()
                        .padding(.vertical)
                }
                .padding(.top, 48)
                .background(Color.uiWhite)
                .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
                .shadow(radius: 12, x: 0, y: 3)
                .mask(Rectangle().padding(.bottom, -24))
                
                // MARK: A scrollview showing a list of tasks
                TasksView()
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.backgroundPrimary)
        }
    }
    
    private func HeaderView() -> some View {
        HStack {
            
            // MARK: Menu button leading to Planned Tasks
            Button {
                withAnimation {
                    showBacklog.toggle()
                }
            } label: {
                Image("menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            // MARK: Header title
            Text("Scheduled")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            // MARK: Hide/Show completed tasks
            Button {
                
            } label: {
                Image("more-horizontal-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
        }
        .foregroundColor(.textPrimary)
    }
    
    private func CalendarView() -> some View {
        VStack(spacing: 32) {
            
            // MARK: Month selector
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
            
            // MARK: Calendar cells
            HStack(spacing: 4) {
                
                ForEach(taskModel.currentWeek, id: \.self) { day in
                    VStack(spacing: 8) {
                        
                        // MARK: Day label
                        // EEEEE returns day as M,T,W ...
                        Text(taskModel.formatDate(date: day, format: "EEEEE"))
                            .font(.paragraphP1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .backgroundSecondary : Calendar.current.isDateInToday(day) ? .accent : .textSecondary)
                        
                        // MARK: Date label
                        // dd will return date as 01,02 ...
                        Text(taskModel.formatDate(date: day, format: "dd"))
                            .font(.subheading1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .uiWhite : Calendar.current.isDateInToday(day) ? .accent : .textPrimary)
                    }
                    // MARK: Capsule shape for cell
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
                    // MARK: Update the view when select another day
                    .onTapGesture { taskModel.currentDay = day }
                }
            }
            .padding(.horizontal)
        }
        // MARK: Update the view when selecting another week
        .onChange(of: currentWeek) { [currentWeek] newVal in
            let offset = newVal - currentWeek
            taskModel.updateWeek(offset: offset)

            // Update the selected day also upon updating week
            taskModel.currentDay = Calendar.current.date(byAdding: .weekOfMonth, value: offset, to: taskModel.currentDay)!
        }
    }
    
    private func TasksView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {

            // MARK: Show if there's any task for given date
            if taskModel.hasTask(taskModel.storedTasks, date: taskModel.currentDay) {

                VStack(spacing: 32) {

                    // MARK: Show time-constrained task if any
                    if taskModel.filterTasks(taskModel.storedTasks, date: taskModel.currentDay, isAllDay: false, hideCompleted: hideCompletedTasks).count > 0 {
                        VStack(alignment: .leading, spacing: 16) {

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

                            // MARK: Timeboxed task cards
                            ForEach(taskModel.filterTasks(taskModel.storedTasks, date: taskModel.currentDay, isAllDay: false, hideCompleted: hideCompletedTasks), id: \.self.id) { task in
                                TaskCardView(task: task)
                            }
                        }
                    }

                    // MARK: Show all-day task if any
                    if taskModel.filterTasks(taskModel.storedTasks, date: taskModel.currentDay, isAllDay: true, hideCompleted: hideCompletedTasks).count > 0 {
                        VStack(alignment: .leading, spacing: 16) {

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
                            
                            // MARK: All-day task cards
                            ForEach(taskModel.filterTasks(taskModel.storedTasks, date: taskModel.currentDay, isAllDay: true, hideCompleted: hideCompletedTasks), id: \.self.id) { task in
                                TaskCardView(task: task)
                            }
                        }
                    }
                }
            }
            
            // MARK: Fall back screen showing no task
            else {
                VStack {
                   Image("no-task")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                    
                    Text("No scheduled task")
                        .font(.headingH2())
                        .fontWeight(.heavy)
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 16)
                    
                    VStack(spacing: 8) {
                        Text("You don't have any schedule for today.")
                            .fontWeight(.semibold)
                        Text("Tap the plus button to create one.")
                            .fontWeight(.semibold)
                    }
                    .font(.paragraphP1())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
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
