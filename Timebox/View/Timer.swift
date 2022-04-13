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
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    // MARK: Core Data fetch request & result
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    // MARK: ViewModels
    @ObservedObject private var taskModel = TaskViewModel()
    @StateObject private var sessionModel = TaskSessionViewModel()
    // MARK: UI States
    @State private var selectedMode: TimerMode = .normal
    @State private var start = false
    @State private var pause = false
    @State private var abort = false
    @State private var isMuted = false
    // MARK: Task-related states
    // Circular progress bar percentage
    @State private var timerProgress : CGFloat = 0
    @State private var subtaskProgress: CGFloat = 0
    @State private var timeRemaining: String = "00:00"
    @State private var currentPomoSession: Int = 1
    // Timer counter (in seconds, to match with data model's)
    @State private var countedSeconds: Double = 0
    // Publish something every 1 second
    @State private var time = SwiftUI.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
    }
    
    // MARK: Convenient derived properties
    private var currentTask: Task? {
        get {
            self.taskModel.getAllTasks(query: self.fetchedTasks)
                .filter({self.taskModel.isTimeboxedTask($0)})
                .filter({self.taskModel.isOngoing($0)})
                .first
        }
    }
    private var totalDuration: Double {
        get {
            guard let currentTask = self.currentTask else {
                return 0
            }
            
            return (currentTask.taskEndTime ?? Date()) - (currentTask.taskStartTime ?? Date())
        }
    }
    private var totalPomoSessions: Int {
        get {
            guard self.currentTask != nil else {
                return 0
            }
            
            return Int(ceil(self.totalDuration/(2 * 60)))
        }
    }

    var body: some View {
        NavigationView {
            if let currentTask = self.currentTask {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Task information...
                        self.TaskHeader(currentTask)
                        
                        // Timer clock view
                        self.TimerClock(currentTask)
                            .onReceive(self.time) { _ in
                                // Use either normal or pomodoro timer
                                // The timer always runs in background
                                // And is independent of timeboxing calculation
                                switch selectedMode {
                                    case .normal:
                                        self.regularTimerFunction(currentTask)
                                    case .pomodoro:
                                        self.pomodoroTimerFunction(currentTask)
                                }
                            }
                        
                        // Timer controller buttons
                        self.TimerControls()
                        
                        // User guide captions if not already started
                        // Show task ongoing info (subtasks & some captions etc.) if started
                        if self.start {
                            TaskOngoingProgress(currentTask)
                        }  else {
                            UserGuideCaptions()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.backgroundPrimary)
            }
            else {
                VStack(spacing: 24) {
                    UniversalCustomNavigationBar(screenTitle: "Timer", hasBackButton: false)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        ScreenFallbackView(title: "No task for now", image: Image("no-timebox"),
                                           caption1: "You don’t have any ongoing task.",
                                           caption2: "Tap the plus button to create one.")
                    }
                }
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.backgroundPrimary)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func TaskHeader(_ currentTask: Task) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                // Task Title...
                Text(currentTask.taskTitle!)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Task duration information...
                Label(title: {
                    let startTime = currentTask.taskStartTime!.formatDateTime(format: "hh:mm a")
                    let endTime = currentTask.taskEndTime!.formatDateTime(format: "hh:mm a")
                    
                    Text("\(startTime) - \(endTime)")
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
            if !self.start {
                self.TimerModeSelector()
            }
        }
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
    
    private func HorizontalProgressBar(_ task: Task) -> some View {
        HStack(spacing: 8) {
            let totalSubtasksCount: CGFloat = CGFloat(task.subtasks.count)
            let completedSubtasksCount: CGFloat = CGFloat(self.taskModel.countCompletedSubtask(task.subtasks))
            let percentage: CGFloat = totalSubtasksCount != 0 ? (completedSubtasksCount / totalSubtasksCount) : 0
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 8)
                    .frame(maxWidth: 256)
                    .foregroundColor(.backgroundQuarternary)
                    .cornerRadius(8)
                
                Rectangle()
                    .frame(width: 256 * CGFloat(percentage), height: 8)
                    .foregroundColor(Color(task.color!))
                    .cornerRadius(8)
            }
            
            Text("\(Int(percentage * 100))%")
                .font(.caption())
                .fontWeight(.heavy)
                .foregroundColor(.textSecondary)
        }
    }
    
    private func TaskOngoingProgress(_ currentTask: Task) -> some View {
        VStack(spacing: 24) {
            Text("Get your toughest work done now!")
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
            
            // Subtasks breakdown if any...
            if currentTask.subtasks.count > 0 {
                VStack(alignment: .leading, spacing: 24) {
                    // Horizontal progress bar... (with subtasks)
                    HorizontalProgressBar(currentTask)
                    
                    // Subtasks checklist...
                    SubtasksChecklist(parentTask: currentTask)
                }.frame(maxWidth: .infinity)
            } else {
                // For singleton task
                CTAButton(btnLabel: "Complete Task", btnFullSize: true) {
                    self.taskModel.completeTask(currentTask)
                }
            }
        }
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

    private func TimerClock(_ task: Task) -> some View {
        ZStack {
            // Outer stroke
            Circle()
            .trim(from: 0, to: 1)
                .stroke(Color.backgroundTertiary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
            .frame(width: 224, height: 224)
            
            // Inner stroke
            Circle()
            .trim(from: 0, to: self.timerProgress)
            // TODO: Use task's color
            .stroke(Color(task.color!), style: StrokeStyle(lineWidth: 20, lineCap: .round))
            .frame(width: 224, height: 224)
            .rotationEffect(.init(degrees: -90))
            
            // Timing information
            VStack(spacing: 8) {
                // TODO: Time remaining...
                Text(self.timeRemaining)
                    .font(self.timeRemaining.count > 5 ? .headingH1() : .headingH0())
                    .fontWeight(.heavy)
                
                // Number of sessions, if using pomodoro mode...
                self.selectedMode == .pomodoro ?
                Text("\(self.currentPomoSession) of \(self.totalPomoSessions) sessions")
                    .font(.paragraphP1())
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary) : nil
            }
        }
    }
    
    private func TimerControls() -> some View {
        HStack(spacing: 32) {
            // TODO: Mute/unmute button...
            Button {
                self.isMuted.toggle()
            } label: {
                ControllerButtonLabel(icon: Image(self.isMuted ? "volume-up-f" : "volume-mute-f"),
                                      padding: 16, cornerRadius: 24, customColor: nil)
            }
            
            // TODO: Play button...
            Button {
                withAnimation {
                    if !self.start {
                        self.start.toggle()
                        self.pause.toggle()
                    } else {
                        self.pause.toggle()
                    }
                }
            } label: {
                ControllerButtonLabel(icon: self.pause ? Image("pause-f") : Image("play-f"),
                                      padding: 24, cornerRadius: 32, customColor: .accent)
            }
            
            // TODO: Stop button...
            Button {
                withAnimation {
                    self.abort.toggle()
                }
            } label: {
                ControllerButtonLabel(icon: Image("stop-f"), padding: 16,
                                      cornerRadius: 24, customColor: nil)
            }
        }
    }
    
    private func ControllerButtonLabel(icon: Image, padding: CGFloat,
                                       cornerRadius: CGFloat, customColor: Color?) -> some View {
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
    
    // MARK: UI Logic for normal timer
    private func regularTimerFunction(_ task: Task) {
        let remaining = task.taskEndTime! - Date()
        self.timeRemaining = Date.formatTimeDuration(remaining, unitStyle: .positional, units: [.hour, .minute, .second])
        
        withAnimation {
            self.timerProgress = (self.totalDuration - remaining) / self.totalDuration
        }
    }
    
    // MARK: UI Logic for pomodoro timer
    private func pomodoroTimerFunction(_ task: Task) {
        let isLastCycle = self.currentPomoSession >= self.totalPomoSessions
        let cycleDuration: TimeInterval
        let cycleEnd: Date
        
        if isLastCycle {
            // Partiality means the last cycle is less than the standard 25 minutes.
            let hasPartiality = !self.totalDuration.truncatingRemainder(dividingBy: 2).isZero
            // The end time & duration for last cycle
            cycleDuration = hasPartiality ? self.totalDuration.truncatingRemainder(dividingBy: 2) : (2 * 60)
            cycleEnd = task.taskEndTime!
        } else {
            // The end time & duration for first and subsequent cycles
            cycleDuration = (2 * 60)
            cycleEnd = task.taskStartTime! + (Double(self.currentPomoSession) * cycleDuration)
        }
        
        let cycleRemaining: TimeInterval = cycleEnd - Date()
        self.currentPomoSession = cycleRemaining <= 0 ? self.currentPomoSession + 1 : self.currentPomoSession
        self.timeRemaining = Date.formatTimeDuration(cycleRemaining, unitStyle: .positional, units: [.minute, .second])
        
        withAnimation {
            self.timerProgress = (cycleDuration - cycleRemaining) / cycleDuration
        }
    }
}
