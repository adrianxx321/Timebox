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
    @State var currentWeek = 0
    
    var body: some View {
        VStack {
            HeaderView()
            
            // MARK: Calendar view
            CalendarView()
        }
    }
    
    func HeaderView() -> some View {
        HStack() {
            
            Button {
                
            } label: {
                Image("menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
            }
            
            Spacer()
            
            Text("Scheduled")
                .font(.headingH2())
                .fontWeight(.heavy)
            
            Spacer()
            
            Button {
                
            } label: {
                Image("more-horizontal-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
            }
        }
        .padding()
    }
    
    func CalendarView() -> some View {
        VStack(spacing: 32) {
            
            // MARK: Month selector
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        currentWeek -= 1
                    }
                } label: {
                    Image("chevron-left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
                
                Text("\(taskModel.formatDate(date: taskModel.currentDay, format: "MMMM y"))")
                    .font(.headingH2())
                    .fontWeight(.bold)
                
                Button {
                    withAnimation {
                        currentWeek += 1
                    }
                } label: {
                    Image("chevron-right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // MARK: Calendar cells
            HStack(spacing: 2) {
                ForEach(taskModel.currentWeek, id: \.self) { day in
                    VStack(spacing: 8) {
                        // EEEEE returns day as M,T,W ...
                        Text(taskModel.formatDate(date: day, format: "EEEEE"))
                            .font(.paragraphP1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            // Text color
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .backgroundSecondary : .textSecondary)
                        
                        // dd will return date as 01,02 ...
                        Text(taskModel.formatDate(date: day, format: "dd"))
                            .font(.subheading1())
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            // Text color
                            .foregroundColor(taskModel.isCurrentDay(date: day) ? .uiWhite : .textPrimary)
                    }
                    // MARK: Capsule shape for day picker
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if taskModel.isCurrentDay(date: day) {
                            Capsule()
                                .fill(Color.accent)
                                .matchedGeometryEffect(id: "CURRENTDAY", in: animation)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation {
                            taskModel.currentDay = day
                        }
                    }
                }
            }
        }
        .onChange(of: currentWeek) { newVal in
            taskModel.updateWeek(offset: newVal)
        }
    }
}

struct ScheduledTasks_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledTasks()
    }
}
