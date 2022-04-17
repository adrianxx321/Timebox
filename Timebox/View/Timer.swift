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

private enum TimerPopOver: String, Identifiable, CaseIterable {
    case completed, timesUp, pointsCollected
    var id: Self { self }
    
    var lottieFile: String {
        switch self {
            case .timesUp: return "alarm-ringing"
            case .completed: return "timeboxing-done"
            case .pointsCollected: return "points-collected"
        }
    }
    
    var caption: String {
        switch self {
            case.timesUp: return "Time's Up! It's time to let go your task now."
            case .completed: return "Yay! You've completed your task with Timeboxing."
            case .pointsCollected: return "You've been rewarded"
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
    // For pomodoro timer
    @State private var isTakingBreak = false
    
    // MARK: Task-related states
    @State private var selectedMode: TimerMode = .normal
    @State private var timerCountdown: String = "00:00"
    // MARK: Task session metrics
    @State private var completedTasksCount: Int = 0
    @State private var currentPomoSession: Int = 1
    @State private var countedFocusedTime: Double = 0
    @State private var totalPoints: Int32 = 0
    
    // MARK: Modal states
    @State private var popover: TimerPopOver?
    
    // MARK: Publish something every 1 second
    @State private var time = SwiftUI.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: true)])
    }
    
    /// Function dedicated to reset all view states to default value
    private func reInit() {
        DispatchQueue.main.async {
            self.start = false
            self.mute = false
            self.pause = true
            self.timerProgress = 0
            self.isPulsing = false
            self.selectedMode = .normal
            self.timerCountdown = "00:00"
            self.completedTasksCount = 0
            self.currentPomoSession = 1
            self.countedFocusedTime = 0
        }
    }
    
    // MARK: Convenient derived properties
    private var currentTask: Task? {
        get {
            self.taskModel.getAllTasks(query: self.fetchedTasks)
                .filter({self.taskModel.isTimeboxedTask($0)})
                // Get those tasks which has not been "timeboxed" yet
                .filter({self.taskModel.isOngoing($0) && $0.session == nil})
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
                    VStack(spacing: 38) {
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
        // Show the points collected modal
        // After the dismissing the first (times up/completion) modal...
        .fullScreenCover(item: self.$popover, onDismiss: {
            self.popover = self.start ? .pointsCollected : nil
            
            // Resetting ALL states
            self.reInit()
        }, content: { modal in
            TimerPopOverView()
        })
    }
    
    private func TimerPopOverView() -> some View {
        ZStack {
            if let popover = self.popover {
                VStack(spacing: 16) {
                    LottieAnimationView(animation: popover.lottieFile, loop: true, playbackSpeed: 0.75)
                        .frame(width: 224, height: 224)
                    
                    // Display the points earned accordingly
                    Text(self.popover == .pointsCollected ? "\(popover.caption) \(self.totalPoints) points." : popover.caption)
                        .font(.paragraphP1())
                        .fontWeight(.heavy)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    CTAButton(btnLabel: "Dismiss", btnFullSize: false, action: {
                        withAnimation {
                            // Dismiss this popover
                            self.popover = nil
                        }
                    })
                }
                .padding(24)
                .background(Color.backgroundTertiary)
                .cornerRadius(32)
            }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .background(BackgroundBlurView())
    }
    
    private func TaskHeader(_ task: Task) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                // Task Title...
                Text(task.taskTitle!)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Task duration information...
                Label(title: {
                    let startTime = task.taskStartTime!.formatDateTime(format: "hh:mm a")
                    let endTime = task.taskEndTime!.formatDateTime(format: "hh:mm a")
                    
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
                    Text(self.timerCountdown)
                        .font(self.timerCountdown.count > 5 ? .headingH1() : .headingH0())
                        .fontWeight(.heavy)
                        .foregroundColor(self.pause ? .textSecondary : .textPrimary)
                    
                    // Number of sessions, if using pomodoro mode...
                    self.selectedMode == .pomodoro ?
                    Text(self.isTakingBreak ? "Taks a break." : "\(self.currentPomoSession) of \(self.totalPomoSessions) sessions)")
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
                if self.start { withAnimation { self.completionHandler(task) } }
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
                
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
    
    private func TaskOngoingProgress(_ task: Task) -> some View {
        VStack(spacing: 24) {
            Text("Get your toughest work done now!")
                .font(.paragraphP1())
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
            
            // Subtasks/Complete Task button
            Group {
                // Subtasks breakdown if any...
                if task.subtasks.count > 0 {
                    VStack(alignment: .leading, spacing: 24) {
                        // Horizontal progress bar... (with subtasks)
                        HorizontalProgressBar(task)
                        
                        // Subtasks checklist...
                        SubtasksChecklist(parentTask: task)
                            // Loading & Updating the number of tasks done
                            // During the course of timeboxing...
                            .onAppear {
                                self.completedTasksCount = task.subtasks.filter{$0.isCompleted}.count
                            }
                            .onChange(of: task.subtasks.filter{$0.isCompleted}.count) { completed in
                                self.completedTasksCount = completed
                            }
                            // Disable checklist when timer is paused...
                            .disabled(self.pause)
                            .opacity(self.pause ? 0.5 : 1)
                    }.frame(maxWidth: .infinity)
                }
                
                // For singleton task
                else {
                    CTAButton(btnLabel: "Complete Task", btnFullSize: true) {
                        self.taskModel.completeTask(task)
                    }
                    // Disable the button when timer is paused...
                    .disabled(self.pause)
                    .opacity(self.pause ? 0.4 : 1)
                }
            }
        }
        // What happens when user completed all tasks in the middle...
        .onChange(of: task.isCompleted) { completed in
            if completed { withAnimation { self.completionHandler(task) } }
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
        self.timerCountdown = Date.formatTimeDuration(grandRemaining, unitStyle: .positional,
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
            let hasPartiality = !self.totalDuration.truncatingRemainder(dividingBy: 30).isZero
            // The end time & duration for last cycle
            cycleDuration = hasPartiality ? self.totalDuration.truncatingRemainder(dividingBy: 30) : (30 * 60)
            cycleEnd = task.taskEndTime!
        } else {
            // The end time & duration for first and subsequent cycles
            cycleDuration = (30 * 60)
            cycleEnd = task.taskStartTime! + (Double(self.currentPomoSession) * cycleDuration)
        }
        
        let cycleRemaining: TimeInterval = cycleEnd - Date()
        
        withAnimation {
            self.isTakingBreak = cycleRemaining <= 5 * 60
            // Shouldn't pulse when taking break
            self.isPulsing = !self.isTakingBreak
        }
        
        self.currentPomoSession = cycleRemaining <= 0 ? self.currentPomoSession + 1 : self.currentPomoSession
        self.timerCountdown = Date.formatTimeDuration(cycleRemaining, unitStyle: .positional, units: [.minute, .second], padding: .pad)
        
        withAnimation {
            self.timerProgress = (cycleDuration - cycleRemaining) / cycleDuration
        }
    }
    
    // MARK: UI Logic for Timer completion (task done/time's up)
    private func completionHandler(_ task: Task) {
        withAnimation {
            // Show animated modal accordingly
            self.popover = self.timeRemaining <= 0 ? .timesUp : task.isCompleted ? .completed : nil
            
            // Calculating points earned...
            self.totalPoints = self.sessionModel.computeScore(self.countedFocusedTime, self.completedTasksCount, self.selectedMode == .pomodoro)
            
            // Saving session...
            self.sessionModel.saveSession(task: task, focusedDuration: self.countedFocusedTime,
                                          completedTasks: self.completedTasksCount,
                                          usedPomodoro: self.selectedMode == .pomodoro,
                                          scoreObtained: self.totalPoints)
        }
    }
}

// Helper
private struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .uiBlack.withAlphaComponent(0.6)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

