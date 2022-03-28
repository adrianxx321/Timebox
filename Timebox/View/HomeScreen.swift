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

struct HomeScreen: View {
    @StateObject var achievementModel = AchievementViewModel()
    @State var selectedRange: GraphRange = .week
    @State private var showMedalInfo = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @FetchRequest var request: FetchedResults<TaskSession>
    
    init() {
        _request = FetchRequest(
            entity: TaskSession.entity(),
            sortDescriptors: [.init(keyPath: \TaskSession.timestamp, ascending: true)])
    }
    
    var body: some View {
        NavigationView {
            // Total points obtained by user...
            let totalPts = request.reduce(0) { $0 + $1.ptsAwarded }
            
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(points: totalPts)
                    .padding(.top, isNotched ? 47: 20)
                    .background(Color.uiWhite)
                
                // MARK: Contents
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 40) {
                        // Ongoing Tasks...
                        SectionView(title: "Ongoing Tasks") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                DynamicTaskList(timeNow: Date())
                                    .frame(maxHeight: 128)
                            }
                        }
                        
                        // Analytics...
                        SectionView(title: "Statistics") {
                            switch selectedRange {
                            case .week:
                                DynamicAnalyticsView(data: request, forWeek: Date(), selectedRange: $selectedRange)
                            case .month:
                                DynamicAnalyticsView(data: request, forMonth: Date(), selectedRange: $selectedRange)
                            }
                        }
                        
                        // Achievements...
                        SectionView(title: "Achievements") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 24) {
                                    ForEach(achievementModel.achievements, id: \.id) { medal in
                                        AchievementCardView(medal: medal, userPts: totalPts)
                                            .onTapGesture {
                                                showMedalInfo.toggle()
                                                alertTitle = medal.title
                                                alertMessage = medal.description
                                            }
                                    }
                                }
                                .alert(alertTitle,
                                       isPresented: $showMedalInfo,
                                       actions: {}, message: {
                                    Text(alertMessage)
                                })
                            }
                        }
                    }
                    .padding(.horizontal, isSmallDevice ? 16 : 24)
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
            // Make progress bar show at least 1%
            let percent = max(0.01, CGFloat(points / achievementModel.getPtsToNextRank(userPoints: points)))
            
            // TODO: Profile picture
            ZStack {
                Image("144083514_3832508416843992_8153494803557931190_n")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 78)
                    .clipShape(Circle())
                    .padding(6)
                    .overlay(Circle()
                        .trim(from: 0.0, to: CGFloat(min(percent, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.uiPurple)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: percent))
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
            // TODO: Medal icon
            Image("144083514_3832508416843992_8153494803557931190_n")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72)
                .cornerRadius(16)
                .grayscale(achievementModel.isUnlocked(medal, userPoints: userPts) ? 0 : 1.0)
            
            Text(medal.title)
                .font(.caption())
                .fontWeight(.semibold)
                .foregroundColor(achievementModel.isUnlocked(medal, userPoints: userPts) ? .textPrimary : .textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
