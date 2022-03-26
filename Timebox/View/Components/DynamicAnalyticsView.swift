//
//  GraphView.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//

import SwiftUI

private enum GraphRange {
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

struct DynamicAnalyticsView: View {
    @State private var selectedRange: GraphRange = .week
    @State private var showProductivityAlert: Bool = false
    @StateObject var taskModel = TaskViewModel()
    
    // MARK: Core Data Request for fetching tasks
    @FetchRequest var currentDoneTasks: FetchedResults<Task>
    @FetchRequest var previousDoneTasks: FetchedResults<Task>
    
    /// Compare timeboxed hours of this week to last week
    init(forWeek: Date) {
        let calendar = Calendar.current
        
        var thisWeek: [Date] = []
        let thisWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: forWeek)!
        let thisFirstWeekday = thisWeekInterval.start
        
        var lastWeek: [Date] = []
        let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth,
                                                     for: calendar.date(byAdding: .day, value: -7, to: forWeek)!)!
        let lastFirstWeekday = lastWeekInterval.start
        
        // 8 days because we need to include the next week's first day
        // for easier calculation
        (1...8).forEach { day in
            if let weekday = calendar.date(byAdding: .day, value: day, to: thisFirstWeekday) {
                thisWeek.append(weekday)
            }
        }
        
        (1...8).forEach { day in
            if let weekday = calendar.date(byAdding: .day, value: day, to: lastFirstWeekday) {
                lastWeek.append(weekday)
            }
        }
        
        let query1 = NSPredicate(format: "completedTime >= %@ AND completedTime < %@ AND isCompleted == true",
                                argumentArray: [thisWeek.first!, thisWeek.last!])
        let query2 = NSPredicate(format: "completedTime >= %@ AND completedTime < %@ AND isCompleted == true",
                                 argumentArray: [lastWeek.first!, lastWeek.last!])
        
        _currentDoneTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.completedTime, ascending: true)],
            predicate: query1)
        
        _previousDoneTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.completedTime, ascending: true)],
            predicate: query2)
    }
    
    /// Compare timeboxed hours of this month to last month
    init(forMonth: Date) {
        let calendar = Calendar.current
        
        var thisMonth: [Date] = []
        let thisMonthRange = Calendar.current.range(of: .day, in: .month, for: forMonth)!
        let thisMonthInterval = Calendar.current.dateInterval(of: .month, for: forMonth)!
        let thisMonthFirstday = thisMonthInterval.start
        thisMonthRange.forEach { day in
            if let monthDay = calendar.date(byAdding: .day, value: day, to: thisMonthFirstday) {
                thisMonth.append(monthDay)
            }
        }
        
        var lastMonth: [Date] = []
        let lastMonthRange = Calendar.current.range(of: .day, in: .month, for: calendar.date(byAdding: .month, value: -1, to: forMonth)!)!
        let lastMonthInterval = Calendar.current.dateInterval(of: .month,
                                                              for: forMonth)!
        let lastMonthFirstday = lastMonthInterval.start
        lastMonthRange.forEach { day in
            if let monthDay = calendar.date(byAdding: .day, value: day, to: lastMonthFirstday) {
                lastMonth.append(monthDay)
            }
        }
        
        let query1 = NSPredicate(format: "completedTime >= %@ AND completedTime < %@ AND isCompleted == true",
                                argumentArray: [thisMonth.first!, thisMonth.last!])
        let query2 = NSPredicate(format: "completedTime >= %@ AND completedTime < %@ AND isCompleted == true",
                                argumentArray: [lastMonth.first!, lastMonth.last!])
        
        _currentDoneTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.completedTime, ascending: true)],
            predicate: query1)
        
        _previousDoneTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [.init(keyPath: \Task.completedTime, ascending: true)],
            predicate: query2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary card view...
            let percentage = taskModel.compareProductivity(current: currentDoneTasks, previous: previousDoneTasks)
            SummaryCardView(percentage: percentage)
                .onTapGesture {
                    if percentage != 0 {
                        showProductivityAlert.toggle()
                    }
                }
                .alert("Productivity \(percentage > 0 ? "increased" : "decreased")",
                       isPresented: $showProductivityAlert,
                       actions: {}, message: {
                    percentage > 0 ?
                    Text("You have been able to focus for \(percentage)% longer than last \(selectedRange.rawValue).")
                    : Text("Your ability to focus have dropped \(-percentage)% compared to last \(selectedRange.rawValue).")
                })
            
            // Bar graph view...
            GraphView()
        }
    }
    
    private func SummaryCardView(percentage: Int) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Productivity")
                    .font(.subheading1())
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Label {
                    percentage != 0 ? Text("\(percentage)%") : Text("- %")
                } icon: {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10)
                        .rotationEffect(percentage < 0 ? Angle(degrees: 180) : Angle(degrees: 0))
                }
                .font(.paragraphP1().weight(.bold))
                .foregroundColor(percentage >= 0 ? .uiGreen : .uiRed)
            }
            
            Image("line-graph")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 80)
                .offset(y: 5)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(Color.uiWhite)
        .cornerRadius(16)
    }
    
    private func GraphView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: Data needed for drawing graph
            let data = selectedRange == .week ? taskModel.analyseTaskDoneByWeek(data: currentDoneTasks) : taskModel.analyseTaskDoneByMonth(data: currentDoneTasks)
            let maxBarHeight = data.max { first, second in
                return second.1 > first.1
            }?.1 ?? 0
            let totalSeconds = data.reduce(0) { $0 + $1.1 }
            
            Text("Timeboxed Duration")
                .font(.subheading1())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            HStack {
                // Summary...
                Label {
                    let formattedDuration = taskModel.formatTimeInterval(interval: TimeInterval(totalSeconds),
                                                                         unitsStyle: .full,
                                                                         units: [.hour, .minute])
                    let durationComponents = formattedDuration.components(separatedBy: " ")
                    
                    // Stylish total focus duration text
                    // Numeric part is big, non-numeric part is small
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        ForEach(durationComponents, id: \.self) { component in
                            // Numeric part
                            Text(component.isNumber ? component : "")
                                .font(.subheading1())
                                .fontWeight(.bold) +
                            // Text part
                            Text(component.isNumber ? "" : component)
                                .font(.caption())
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.textPrimary)
                } icon: {
                    Image("clock-f")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                        .foregroundColor(.accent)
                }
                
                Spacer()
                
                // Interval selection...
                Menu {
                    Button("This week") { selectedRange = .week }
                    Button("This month") { selectedRange = .month }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedRange.description)
                            .font(.caption())
                            .fontWeight(.semibold)
                        
                        Image(systemName: "chevron.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 8)
                    }
                    .padding(8)
                    .foregroundColor(.textSecondary)
                    .background(Color.backgroundTertiary)
                    .cornerRadius(10)
                }
            }
            
            // Presentation of graph...
            // Show fallback instead if graph is empty
            Group {
                totalSeconds > 0 ? GraphRenderer(data: data, max: Int(maxBarHeight)) : nil
                totalSeconds == 0 ? GraphFallback() : nil
            }
            .frame(height: 128, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(Color.uiWhite)
        .cornerRadius(24)
    }
    
    private func GraphRenderer(data: [(String, Int64)], max: Int) -> some View {
        GeometryReader { proxy in
            HStack {
                ForEach(data, id: \.0) { item in
                    VStack {
                        Capsule()
                            .fill(item.1 > 0 ? Color.uiLavender : Color.backgroundQuarternary)
                            .frame(width: 16)
                            .frame(height: max > 0 ? getBarHeight(point: Int(item.1), max: max, size: proxy.size) : 0)
                        
                        // Abbreviate day labels (e.g. Mon -> M)
                        Text(selectedRange == .week ? String(item.0.first!) : item.0)
                            .font(.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func GraphFallback() -> some View {
        Text("No data available")
            .font(.subheading1())
            .fontWeight(.semibold)
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity)
    }
    
    private func getBarHeight(point: Int, max: Int, size: CGSize) -> CGFloat {
        // 12 Text Height
        // 5 Spacing..
        let height = (CGFloat(point) / CGFloat(max)) * (size.height - 24)
        
        return height
    }
}
