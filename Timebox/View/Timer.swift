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
    
    var description : String {
        switch self {
            case .normal: return "Regular Timer"
            case .pomodoro: return "Pomodoro"
        }
    }
}

struct Timer: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: Core Data fetch request & result
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    // MARK: ViewModels
    @ObservedObject private var taskModel = TaskViewModel()
    @ObservedObject private var notificationModel = NotificationViewModel()
    @StateObject private var sessionModel = TaskSessionViewModel()
    // MARK: Timer States
    @State private var start = false
    @State private var mute = false
    @State private var pause = true
    @State private var timerProgress : CGFloat = 0
    @State private var isPulsing = false
    
    // MARK: Task-related states
    @State private var selectedMode: TimerMode = .normal
    @State private var timeRemainingText: String = "00:00"
    // MARK: Task session metrics
    @State private var completedTasksCount: Int = 0
    @State private var currentPomoSession: Int = 1
    @State private var countedFocusedTime: Double = 0
    
    // MARK: Modal states
    @State private var completedTimebox = false
    @State private var collectedPoints = false
    @State private var timesUp = false
    
    // MARK: Publish something every 1 second
    @State private var time = SwiftUI.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
    }
    
    // MARK: Convenient derived properties
    private var currentTask: Task? {
        get {
            withAnimation {
                return self.taskModel.getAllTasks(query: self.fetchedTasks)
                    .filter({self.taskModel.isTimeboxedTask($0)})
                    // Get those tasks which has not been "timeboxed" yet
                    .filter({self.taskModel.isOngoing($0) && $0.session == nil})
                    .first
            }
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
    private var timeRemaining: Double {
        get {
            (self.currentTask?.taskEndTime! ?? Date()) - Date()
        }
    }
    private var totalPomoSessions: Int {
        get {
            guard self.currentTask != nil else {
                return 0
            }
            
            return Int(ceil(self.totalDuration/(25 * 60)))
        }
    }
    private var pulseAnimation: Animation {
        (!self.pause && self.start) ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default
    }

    var body: some View {
        NavigationView {
            if let currentTask = self.currentTask {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: self.pause ? 36 : 38) {
                        // Task information...
                        self.TaskHeader(currentTask)
                        
                        // Timer clock view
                        self.TimerClock(currentTask)
                        
                        // Timer controller buttons
                        self.TimerButtons()
                        
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
                // What happens when user completed all tasks in the middle...
                .onChange(of: currentTask.isCompleted) { completed in
                    if completed { self.taskCompletedHandler(currentTask) }
                }
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
        .overlay(content: {
            // Messages showing completed timebox session & points awarded
            if self.completedTimebox {
                LottieModalView(isPresent: self.$completedTimebox, lottieFile: "timeboxing-done",
                                loop: true, playbackSpeed: 0.75,
                                caption: "Yay! You've completed your task with Timeboxing.")
            } else if self.timesUp {
                LottieModalView(isPresent: self.$timesUp, lottieFile: "alarm-ringing",
                                loop: true, playbackSpeed: 1.0,
                                caption: "Time's Up! It's time to let go your task now.")
            } else if self.collectedPoints {
                LottieModalView(isPresent: self.$collectedPoints, lottieFile: "points-collected",
                                loop: true, playbackSpeed: 0.75,
                                caption: "You've been rewarded XXX points.")
            }
        })
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
            if !self.start { self.TimerModeSelector() }
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
    
    private func TimerClock(_ task: Task) -> some View {
        ZStack {
            // Circular Progress Bar...
            Group {
                // Outer stroke
                Circle()
                .trim(from: 0, to: 1)
                    .stroke(Color.backgroundTertiary, style: StrokeStyle(lineWidth: 32, lineCap: .round))
                .frame(width: 224, height: 224)
                
                // Inner stroke
                Circle()
                .trim(from: 0, to: self.timerProgress)
                .stroke(Color(task.color!), style: StrokeStyle(lineWidth: 32, lineCap: .round))
                .frame(width: 224, height: 224)
                .rotationEffect(.init(degrees: -90))
                .opacity(!self.pause && self.start ? 1 : 0.2)
            }
            .scaleEffect(self.isPulsing ? 1.0625 : 1)
            
            // Timing information
            // Presents only when timer started...
            // Otherwise presents a indicator showing timer mode selected
            if self.start {
                VStack(spacing: 8) {
                    // Time remaining...
                    Text(self.timeRemainingText)
                        .font(self.timeRemainingText.count > 5 ? .headingH1() : .headingH0())
                        .fontWeight(.heavy)
                        .foregroundColor(self.pause ? .textSecondary : .textPrimary)
                    
                    // Number of sessions, if using pomodoro mode...
                    self.selectedMode == .pomodoro ?
                    Text("\(self.currentPomoSession) of \(self.totalPomoSessions) sessions")
                        .font(.paragraphP1())
                        .fontWeight(.bold)
                        .foregroundColor(self.pause ? .textTertiary : .textSecondary) : nil
                }
            } else {
                VStack(spacing: 16) {
                    // Logo for the timer mode selected...
                    Image("\(self.selectedMode.rawValue)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(self.selectedMode.description)")
                        .font(.paragraphP1())
                        .fontWeight(.heavy)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        // MARK: This is the functional part of the timer
        .onReceive(self.time) { _ in
            if self.timeRemaining < 0 {
                // We don't need it when we start off
                self.time.upstream.connect().cancel()
                return
            } else if self.timeRemaining > 0 {
                // Use either normal or pomodoro timer
                // The timer always runs in background
                // And is independent of timeboxing calculation
                switch selectedMode {
                    case .normal:
                        self.regularTimerFunction(task)
                    case .pomodoro:
                        self.pomodoroTimerFunction(task)
                }
                
                // Count the focused duration...
                // Will only count after start && is not paused
                self.countedFocusedTime += (self.start && !self.pause) ? 1 : 0
            } else {
                // Save it at very last second
                self.time.upstream.connect().cancel()
                
                // Save the task if and only if timer is running...
                if self.start { self.timesUpHandler(task) }
            }
        }
    }
    
    private func TimerButtons() -> some View {
        HStack(spacing: 32) {
            // MARK: Mute button
            Button {
                self.mute.toggle()
                self.sessionModel.playWhiteNoise(!self.mute)
            } label: {
                ControllerButtonLabel(icon: Image(self.mute ? "volume-mute-f" : "volume-up-f"),
                                      padding: 16, cornerRadius: 24, customColor: nil)
            }
            .disabled(!self.start || self.pause)
            .opacity(!self.pause ? 1 : 0.5)
            
            // MARK: Play button
            Button {
                withAnimation {
                    if !self.start {
                        start = true
                        pause = false
                        // Play the white noise after begin timeboxing
                        self.sessionModel.playWhiteNoise(true)
                    } else {
                        self.pause.toggle()
                        self.mute.toggle()
                        self.sessionModel.playWhiteNoise(!self.pause)
                    }
                }
                
                // MARK: Specially controls the pulse animation
                withAnimation(self.pulseAnimation) {
                    self.isPulsing.toggle()
                }
            } label: {
                ControllerButtonLabel(icon: self.pause ? Image("play-f") : Image("pause-f"),
                                      padding: 24, cornerRadius: 32, customColor: .accent)
            }
            
            // MARK: Stop button
            Button {
                withAnimation {
                    // Reset (almost) everything...
                    self.start = false
                    self.pause = true
                    self.mute = false
                    self.sessionModel.playWhiteNoise(false)
                    self.countedFocusedTime = 0
                }
                
                // MARK: Specially controls the pulse animation
                withAnimation(self.pulseAnimation) {
                    // Stops the animation
                    self.isPulsing = false
                }
            } label: {
                ControllerButtonLabel(icon: Image("stop-f"), padding: 16,
                                      cornerRadius: 24, customColor: nil)
            }
            .disabled(!self.start)
            .opacity(self.start ? 1 : 0.5)
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
            .background(customColor ?? Color.backgroundTertiary)
            .cornerRadius(cornerRadius)
            .shadow(color: customColor ?? .textTertiary, radius: 8, x: 0, y: 3)
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
            
            // Subtasks/Complete Task button
            Group {
                // Subtasks breakdown if any...
                if currentTask.subtasks.count > 0 {
                    VStack(alignment: .leading, spacing: 24) {
                        // Horizontal progress bar... (with subtasks)
                        HorizontalProgressBar(currentTask)
                        
                        // Subtasks checklist...
                        SubtasksChecklist(parentTask: currentTask)
                            // Updating the number of tasks done
                            // In the course of timeboxing...
                            .onAppear {
                                self.completedTasksCount = currentTask.subtasks.filter{$0.isCompleted}.count
                            }
                            .onChange(of: currentTask.subtasks.filter{$0.isCompleted}.count) { completed in
                                self.completedTasksCount = completed
                                print(self.completedTasksCount)
                            }
                            // Disable checklist when timer is paused...
                            .disabled(self.pause)
                            .opacity(self.pause ? 0.5 : 1)
                    }.frame(maxWidth: .infinity)
                } else {
                    // For singleton task
                    CTAButton(btnLabel: "Complete Task", btnFullSize: true) {
                        self.taskModel.completeTask(currentTask)
                    }
                    // Disable the button when timer is paused...
                    .disabled(self.pause)
                    .opacity(self.pause ? 0.4 : 1)
                }
            }
        }
    }
    
    private func UserGuideCaptions() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select the timer mode for Timeboxing")
                .font(.headingH2())
                .fontWeight(.heavy)
                .foregroundColor(.textPrimary)
            
            Text("Tap on the play button to begin.")
                .font(.paragraphP1())
                .fontWeight(.bold)
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: UI Logic for normal timer
    private func regularTimerFunction(_ task: Task) {
        let grandRemaining = self.timeRemaining
        self.timeRemainingText = Date.formatTimeDuration(grandRemaining, unitStyle: .positional,
                                                     units: [.hour, .minute, .second],
                                                     padding: .pad)
        
        withAnimation {
            self.timerProgress = (self.totalDuration - grandRemaining) / self.totalDuration
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
            cycleDuration = hasPartiality ? self.totalDuration.truncatingRemainder(dividingBy: 25) : (25 * 60)
            cycleEnd = task.taskEndTime!
        } else {
            // The end time & duration for first and subsequent cycles
            cycleDuration = (25 * 60)
            cycleEnd = task.taskStartTime! + (Double(self.currentPomoSession) * cycleDuration)
        }
        
        let cycleRemaining: TimeInterval = cycleEnd - Date()
        self.currentPomoSession = cycleRemaining <= 0 ? self.currentPomoSession + 1 : self.currentPomoSession
        self.timeRemainingText = Date.formatTimeDuration(cycleRemaining, unitStyle: .positional, units: [.minute, .second], padding: .pad)
        
        withAnimation {
            self.timerProgress = (cycleDuration - cycleRemaining) / cycleDuration
        }
    }
    
    private func taskCompletedHandler(_ task: Task) {
        withAnimation {
            // Play animations accordingly...
            self.completedTimebox = !self.collectedPoints
            self.collectedPoints = self.completedTimebox
            
            // Saving session...
            self.sessionModel.saveSession(task: task, focusedDuration: self.countedFocusedTime,
                                          completedTasks: self.completedTasksCount,
                                          usedPomodoro: self.selectedMode == .pomodoro)
        }
    }
    
    private func timesUpHandler(_ task: Task) {
        withAnimation {
            // Play animations accordingly...
            self.timesUp = !self.collectedPoints
            self.collectedPoints = self.timesUp
            
            // Saving session...
            self.sessionModel.saveSession(task: task, focusedDuration: self.countedFocusedTime,
                                          completedTasks: self.completedTasksCount,
                                          usedPomodoro: self.selectedMode == .pomodoro)
        }
    }
}
