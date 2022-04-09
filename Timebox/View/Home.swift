//
//  HomeScreen.swift
//  Timebox
//
//  Created by Lianghan Siew on 24/03/2022.
//

import SwiftUI
import AuthenticationServices

enum GraphRange {
    case week, month
    var description : String {
        switch self {
            case .week: return "This week"
            case .month: return "This month"
        }
    }
    var rawValue: String {
        switch self {
            case .week: return "week"
            case .month: return "month"
        }
    }
}

struct Home: View {
    // MARK: GLOBAL VARIABLES
    @EnvironmentObject var GLOBAL: GlobalVariables
    // MARK: Core Data injected environment context
    @Environment(\.managedObjectContext) var context
    // MARK: ViewModels
    @StateObject var achievementModel = AchievementsViewModel()
    @ObservedObject var taskModel = TaskViewModel()
    @ObservedObject var eventModel = EventViewModel()
    // MARK: Core Data fetch requests
    @FetchRequest var fetchedTasks: FetchedResults<Task>
    @FetchRequest var timeboxSessions: FetchedResults<TaskSession>
    // MARK: UI States
    @State var selectedRange: GraphRange = .week
    @State private var showMedalUnlockTips = false
    @State private var showUnlockedMedal = false
    @State private var selectedMedal: Achievement?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @AppStorage("avatar") private var avatar = "Avatar-1"
    // MARK: Data prepared from CD fetch
    var allTasks: [Task] {
        get {
            self.fetchedTasks.map { $0 as Task }
        }
    }
    var ongoingTasks: [Task] {
        get {
            return taskModel.filterOngoingTasks(data: self.allTasks)
        }
    }
    var totalPts: Int32 {
        get {
            timeboxSessions.reduce(0) { $0 + $1.ptsAwarded }
        }
    }
    var percent: CGFloat {
        get {
            // Make progress bar show at least 1%
            max(0.01, CGFloat(self.totalPts / achievementModel.getPtsToNextRank(userPoints: self.totalPts)))
        }
    }
    
    init() {
        _fetchedTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.taskStartTime, ascending: false)])
        
        _timeboxSessions = FetchRequest(
            entity: TaskSession.entity(),
            sortDescriptors: [.init(keyPath: \TaskSession.timestamp, ascending: true)])
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(points: self.totalPts)
                    
                    VStack(spacing: 40) {
                        // Ongoing Tasks...
                        SectionView(title: "Ongoing Tasks") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                if ongoingTasks.isEmpty {
                                    OngoingFallback()
                                } else {
                                    HStack(spacing: 16) {
                                        ForEach(ongoingTasks, id: \.id) { task in
                                            OngoingCardView(task: task)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 128)
//                        .onAppear {
//                            withAnimation {
//                                eventModel.updateEventStore(context: self.context, persistentTaskStore: self.allTasks)
//                            }
//                        }
                        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
                            withAnimation {
                                // As per the instruction, so we fetch the EKCalendar again.
                                eventModel.loadCalendars()
                                eventModel.loadEvents()
                                eventModel.updateEventStore(context: self.context, persistentTaskStore: self.allTasks)
                            }
                        }
                        
                        // Analytics...
                        SectionView(title: "Statistics") {
                            switch selectedRange {
                            case .week:
                                DynamicAnalyticsView(data: timeboxSessions, forWeek: Date(), selectedRange: $selectedRange)
                            case .month:
                                DynamicAnalyticsView(data: timeboxSessions, forMonth: Date(), selectedRange: $selectedRange)
                            }
                        }
                        
                        // Achievements...
                        SectionView(title: "Achievements") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 24) {
                                    ForEach(achievementModel.achievements, id: \.id) { medal in
                                        AchievementCardView(medal: medal, userPts: self.totalPts)
                                            .onTapGesture {
                                                if achievementModel.isUnlocked(medal, userPoints: self.totalPts) {
                                                    self.selectedMedal = medal
                                                    self.showUnlockedMedal.toggle()
                                                } else {
                                                    self.alertTitle = medal.title
                                                    self.alertMessage = medal.description
                                                    self.showMedalUnlockTips.toggle()
                                                }
                                            }
                                    }
                                }
                                .alert(alertTitle,
                                       isPresented: $showMedalUnlockTips,
                                       actions: {}, message: {
                                    Text(alertMessage)
                                })
                                .sheet(item: self.$selectedMedal) { medal in
                                    UnlockedMedalModal(medal: medal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, GLOBAL.isSmallDevice ? 16 : 24)
                    .padding(.bottom, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }
    
    private func HeaderView(points: Int32) -> some View {
        VStack(spacing: 12) {
            // Profile picture
            ZStack {
                AvatarView(size: 78, avatar: Image(self.avatar))
                    .padding(6)
                
                // Will show at least 1%
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.percent, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.uiPurple)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: self.percent)
            }
            
            VStack(spacing: 4) {
                // Greetings message
                Group {
                    Text("Howdy! You have ")
                        .foregroundColor(.textPrimary) +
                    // User's points
                    Text("\(points) pts")
                        .foregroundColor(.accent)
                }.font(.subheading1().weight(.heavy))
                
                // User's current rank (medal) & next rank
                Text("\(achievementModel.getCurrentRank(userPoints: points)) | Next rank: \(achievementModel.getNextRank(userPoints: points))")
                    .font(.paragraphP1())
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        // Double padding
        // Latter one is to offset the ignore top safe area
        .padding(.top, GLOBAL.isNotched ? 47: 20)
        .background(Color.uiWhite)
        .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
        .shadow(radius: 12, x: 0, y: 3)
        // Cover up the unwanted top shadow
        .mask(Rectangle().padding(.bottom, -24))
    }
    
    private func SectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                content()
            } header: {
                Text(title)
                    .font(.headingH2())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private func AchievementCardView(medal: Achievement, userPts: Int32) -> some View {
        VStack(alignment: .center) {
            // Medal icon
            Image(medal.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72)
                .cornerRadius(16)
                .grayscale(achievementModel.isUnlocked(medal, userPoints: userPts) ? 0 : 0.9)
                .overlay(
                    achievementModel.isUnlocked(medal, userPoints: userPts) ? nil :
                    Image("padlock-f")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32)
                    .foregroundColor(.textSecondary)
                )
            
            Text(medal.title)
                .font(.caption())
                .fontWeight(.semibold)
                .foregroundColor(achievementModel.isUnlocked(medal, userPoints: userPts) ? .textPrimary : .textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func UnlockedMedalModal(medal: Achievement) -> some View {
        VStack(spacing: 32) {
            VStack {
                Image(medal.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 384)
                
                VStack(spacing: 16) {
                    Text(medal.title)
                        .font(.headingH2())
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(medal.unlockedDescription)
                        .font(.paragraphP1())
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }.padding(.horizontal)
            }
            
            CTAButton(btnLabel: "Dismiss", btnFullSize: true, action: {
                self.selectedMedal = nil
            })
        }
    }
    
    private func OngoingFallback() -> some View {
        HStack(spacing: 16) {
            Image("no-ongoing")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Uhh, nothing's going on")
                    .font(.subheading1())
                    .fontWeight(.heavy)
                    .foregroundColor(.textPrimary)
                
                Text("Looks like you are currently free.")
                    .font(.paragraphP1())
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
