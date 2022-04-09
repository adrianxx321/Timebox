//
//  Timer.swift
//  Timebox
//
//  Created by Lianghan Siew on 08/04/2022.
//

import SwiftUI

private enum TimerMode: String, CaseIterable {
    case normal = "clock-f"
    case pomodoro = "tomato-f"
}

struct Timer: View {
    // MARK: Core Data stuff
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    // MARK: Core Data request
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: ViewModels
    @ObservedObject private var taskModel = TaskViewModel()
    @StateObject private var sessionModel = TaskSessionViewModel()
    // MARK: UI States
    @State private var start = false // Timer start toggle
    @State private var percent : CGFloat = 0.67 // Percentage that fills the inner stroke
    @State private var currentCounter: Int64 = 0 // Timer counter (in seconds, to match with data model's)
    @State private var isMuted = false
    @State private var selectedMode: TimerMode = .normal
    @State private var time = SwiftUI.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    // MARk: Current task
    var currentTask: Task? {
        get {
            let allTasks = self.taskModel.getAllTasks(query: self.fetchedTasks)
            
            return allTasks.filter{self.taskModel.isTimeboxedTask($0)}.filter{self.taskModel.isOngoing($0)}.first
        }
    }
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: false)])
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                if let currentTask = self.currentTask {
                    VStack(spacing: 48) {
                        // Task information...
                        VStack(spacing: 20) {
                            VStack(spacing: 10) {
                                Text(currentTask.taskTitle!)
                                    .font(.headingH2())
                                    .fontWeight(.heavy)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                Label(title: {
                                    Text("\(self.taskModel.formatDate(date: currentTask.taskStartTime!, format: "hh:mm a")) - \(self.taskModel.formatDate(date: currentTask.taskEndTime!, format: "hh:mm a"))")
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                    
                                }, icon: {
                                    Image("clock")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24)
                                })
                                .foregroundColor(.textSecondary)
                            }
                            
                            // Show timer mode selection if haven't started
                            // Otherwise show caption of the day
                            VStack(spacing: 24) {
                                if self.start {
                                    Text("Get your toughest work done now!")
                                        .font(.paragraphP1())
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                } else {
                                    self.TimerModeSelector()
                                }
                                
                                // TODO: For task with subtasks...
                                if currentTask.subtasks.count > 0 {
                                    Group {
                                        // Horizontal progress bar... (with subtasks)
                                        
                                        // Subtasks checklist...
                                        SubtasksChecklist(selectedTask: currentTask)
                                    }
                                } else {
                                    // TODO: For singleton task
                                }
                            }
                        }
                        
                        // Timer clock view
                        self.TimerClock(currentTask)
                        
                        // Timer controller buttons
                        self.TimerControls()
                        
                        self.start ? nil : UserGuideCaptions()
                    }
                    .padding(.horizontal, GLOBAL.isSmallDevice ? 16 : 32)
                    .padding(.vertical, 24)
                } else {
                    ScreenFallbackView(title: "No task for now", image: Image("no-timebox"), caption1: "You don’t have any timeboxed task right now.", caption2: "Tap the plus button to create a new one.")
                        .padding(.top, 48)
                        
                }
            }
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundPrimary)
        }.navigationBarHidden(true)
    }
    
    private func TimerModeSelector() -> some View {
        HStack {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation {
                        self.selectedMode = mode
                    }
                } label: {
                    Image(mode.rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(self.selectedMode == mode ? Color.uiWhite : Color.clear)
                        .clipShape(Capsule())
                }.foregroundColor(self.selectedMode == mode ? .accent : .textSecondary)
            }
        }
        .padding(8)
        .background(Color.backgroundTertiary)
        .clipShape(Capsule())
    }
    
    private func TimerClock(_ task: Task) -> some View {
        VStack{
            // Timer circle
            ZStack{
                // Outer stroke
                Circle()
                .trim(from: 0, to: 1)
                    .stroke(Color.backgroundTertiary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 224, height: 224)
                
                // Inner stroke
                Circle()
                .trim(from: 0, to: self.percent)
                // TODO: Use task's color
                .stroke(Color(task.color!), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 224, height: 224)
                .rotationEffect(.init(degrees: -90))
                
                // Timing information
                VStack(spacing: 8) {
                    // TODO: Time remaining...
                    Text("6:15")
                        .font(.headingH0())
                        .fontWeight(.heavy)
                    
                    // TODO: Number of sessions, if using pomodoro mode...
                    Text("1 of 3 sessions")
                        .font(.paragraphP1())
                        .fontWeight(.bold)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func TimerControls() -> some View {
        HStack(spacing: 32) {
            // TODO: Mute/unmute button...
            Button {
                
            } label: {
                ControllerButtonLabel(icon: Image(self.isMuted ? "volume-up-f" : "volume-mute-f"),
                                      padding: 16, cornerRadius: 24, customColor: nil)
            }
            
            // TODO: Play button...
            Button {
                
            } label: {
                ControllerButtonLabel(icon: Image("play-f"), padding: 24,
                                      cornerRadius: 32, customColor: .accent)
            }
            
            // TODO: Stop button...
            Button {
                
            } label: {
                ControllerButtonLabel(icon: Image("stop-f"), padding: 16,
                                      cornerRadius: 24, customColor: nil)
            }
        }
    }
    
    private func ControllerButtonLabel(icon: Image, padding: CGFloat, cornerRadius: CGFloat, customColor: Color?) -> some View {
        icon
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28)
            .foregroundColor(customColor != nil ? .uiWhite : .accent)
            .padding(padding)
            .background(customColor ?? Color.backgroundSecondary)
            .cornerRadius(cornerRadius)
            .shadow(color: customColor ?? .textTertiary, radius: 8, x: 0, y: 3)
    }
    
    private func UserGuideCaptions() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select the timer mode to begin timeboxing")
                .font(.headingH2())
                .fontWeight(.heavy)
                .foregroundColor(.textPrimary)
            
            Text("Tap on the play button to start timer.")
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(.textSecondary)
        }
    }
}
