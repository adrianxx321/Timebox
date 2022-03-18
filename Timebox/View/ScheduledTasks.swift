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
    
    
    // MARK: Core Data environment
    @Environment(\.managedObjectContext) var context
    
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
                .mask(Rectangle().padding(.bottom, -24))
                
                // A scrollview showing a list of tasks...
                ScrollView(.vertical, showsIndicators: false) {
                    DynamicTaskList(taskDate: taskModel.currentDay,
                                    hideCompleted: hideCompletedTasks)
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
                Image(hideCompletedTasks ? "eye" : "eye-close")
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
        // Update the view when selecting another week...
        .onChange(of: currentWeek) { [currentWeek] newVal in
            let offset = newVal - currentWeek
            taskModel.updateWeek(offset: offset)

            // Update the selected day also upon updating week
            taskModel.currentDay = Calendar.current.date(byAdding: .weekOfMonth,
                                                         value: offset,
                                                         to: taskModel.currentDay)!
        }
    }
}

struct ScheduledTasks_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledTasks()
    }
}
