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
    // MARK: Core Data injected environment context
    @Environment(\.managedObjectContext) var context
    // MARK: Core Data fetch request
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    // MARK: ViewModels & global variables
    @ObservedObject var taskModel = TaskViewModel()
    @ObservedObject var eventModel = EventViewModel()
    // Using icon name to identify tab...
    @State var currentTab = "home"
    @AppStorage("syncCalendarsAllowed") var syncCalendarsAllowed = false
    
    // Hiding native one...
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
        
        UITabBar.appearance().isHidden = true
    }
    
    private var allTasks: [Task] {
        get {
            taskModel.getAllTasks(query: self.fetchedTasks)
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
            .onChange(of: self.eventModel.mappedEventStore) { _ in
                withAnimation {
                    eventModel.updateEventStore(context: self.context, persistentTaskStore: self.allTasks)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
                withAnimation {
                    // As per the instruction, so we fetch the EKCalendar again.
                    eventModel.loadCalendars()
                    eventModel.loadEvents()
                    eventModel.updateEventStore(context: self.context, persistentTaskStore: self.allTasks)
                }
            }
            
            // Custom Tab Bar...
            TabBarView()
        }
        .padding(.bottom, GLOBAL.isNotched ? 32 : 8)
        .ignoresSafeArea(edges: .bottom)
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
