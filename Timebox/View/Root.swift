//
//  BaseView.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI

struct Root: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: Core Data fetch request
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    // MARK: ViewModels
    @ObservedObject var taskModel = TaskViewModel()
    @ObservedObject var eventModel = EventViewModel()
    @ObservedObject var sessionModel = TaskSessionViewModel()
    // Using icon name to identify tab...
    @State var currentTab = "home"
    
    // Hiding native one...
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
        
        UITabBar.appearance().isHidden = true
    }
    
    private var allTasks: [Task] {
        get {
            self.taskModel.getAllTasks(query: self.fetchedTasks)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab View...
            TabView(selection: $currentTab) {
                Home()
                    .tag("home")
                    .environmentObject(self.GLOBAL)
                
                Scheduled()
                    .tag("tasks")
                    .environmentObject(self.GLOBAL)
                
                Timer()
                    .tag("timer")
                    .environmentObject(self.GLOBAL)
                
                Settings()
                    .tag("more")
                    .environmentObject(self.GLOBAL)
            }

            // Custom Tab Bar...
            TabBarView()
        }
        .padding(.bottom, GLOBAL.isNotched ? 32 : 8)
        .ignoresSafeArea(edges: .bottom)
        // Load the events added when app was closed upon launching the app...
        .onAppear {
            self.eventModel.updatePersistedEventStore(persistentTaskStore: self.allTasks)
        }
        // Detect any changes made to the default Calendar app (in background)
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            withAnimation {
                print("Calendar changed")
                print("Current calendar permission: \(self.eventModel.syncCalendarsAllowed)")
                // As per the instruction, so we fetch the EKCalendar again.
                self.eventModel.loadCalendars()
                self.eventModel.loadEvents()
                self.eventModel.updatePersistedEventStore(persistentTaskStore: self.allTasks)
            }
        }
    }
    
    private func TabBarView() -> some View {
        HStack {
            Spacer()
            Group {
                TabButton(icon: "home")
                Spacer()
                TabButton(icon: "tasks")
            }
            
            Spacer()
            
            // Center Add Button...
            ZStack {
                Hexagon(radius: 8)
                    .aspectRatio((7/8), contentMode: .fit)
                    .frame(maxHeight: 64)
                    .foregroundColor(.accent)
                
                Button {
                    taskModel.addNewTask.toggle()
                } label: {
                    Image("add")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36)
                        .foregroundColor(.uiWhite)
                }
            }
            Spacer()
            
            Group {
                TabButton(icon: "timer")
                Spacer()
                TabButton(icon: "more")
            }
            Spacer()
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .background(Color.uiWhite
            .shadow(color: .backgroundQuarternary, radius: 4, x: 0, y: 0)
            // Cover up the unwanted top shadow
            .mask(Rectangle().padding(.top, -8)))
        // Brings up the add task modal
        .sheet(isPresented: $taskModel.addNewTask) {
            // Clearing Edit Data
            taskModel.editTask = nil
        } content: {
            TaskModal()
                .environmentObject(taskModel)
        }
    }
    
    private func TabButton(icon: String) -> some View {
        Button {
            withAnimation {
                currentTab = icon
            }
        } label: {
            VStack(spacing: 4) {
                Image(currentTab == icon ? "\(icon)-f" : icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
                
                Text(icon.capitalized)
                    .font(.caption())
                    .fontWeight(.semibold)
            }.foregroundColor(currentTab == icon ? .accent : .textSecondary)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        Root()
    }
}
