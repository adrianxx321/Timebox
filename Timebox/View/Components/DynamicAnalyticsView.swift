//
//  GraphView.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//

import SwiftUI

struct DynamicAnalyticsView: View {
    // MARK: ViewModels
    @ObservedObject var sessionModel = TaskSessionViewModel()
    // MARK: UI States
    @Binding private var selectedRange: GraphRange
    @State private var currentDoneTasks: [TaskSession]
    @State private var previousDoneTasks: [TaskSession]
    @State private var showProductivityAlert: Bool = false
    @State private var selectedBar: String?

    // MARK: Data needed for analytics presentation
    var percentageImprove: Int {
        get {
            self.sessionModel.compareProductivity(current: currentDoneTasks, previous: previousDoneTasks)
        }
    }
    // Graph columns and values presented in array of tuples
    var data: [(String, Double)] {
        get {
            self.selectedRange == .week ? sessionModel.presentGraphByWeek(data: currentDoneTasks)
            : self.sessionModel.presentGraphByMonth(data: currentDoneTasks)
        }
    }
    var maxBarHeight: Double {
        get {
            self.data.max { first, second in
                return second.1 > first.1
            }?.1 ?? 0
        }
    }
    // String formatted in "1h 2m" etc.
    var totalDuration: [String] {
        get {
            let totalSeconds = TimeInterval(self.data.reduce(0) { $0 + $1.1 })
            let formattedDuration = Date.formatTimeDuration(totalSeconds, unitStyle: .full,
                                                            units: [.hour, .minute], padding: nil)
            
            return formattedDuration.components(separatedBy: " ")
        }
    }
    
    /// Prepare graph for weekly view
    init(data: FetchedResults<TaskSession>, forWeek: Date, selectedRange: Binding<GraphRange>) {
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
        
        self.currentDoneTasks = data.filter {
            $0.timestamp! >= thisWeek.first! && $0.timestamp! < thisWeek.last!
        }
        
        self.previousDoneTasks = data.filter {
            $0.timestamp! >= lastWeek.first! && $0.timestamp! < lastWeek.last!
        }
        
        self._selectedRange = selectedRange
    }
    
    /// Prepare graph for monthly view
    init(data: FetchedResults<TaskSession>, forMonth: Date, selectedRange: Binding<GraphRange>) {
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
        
        self.currentDoneTasks = data.filter {
            $0.timestamp! >= thisMonth.first! && $0.timestamp! < thisMonth.last!
        }
        
        self.previousDoneTasks = data.filter {
            $0.timestamp! >= lastMonth.first! && $0.timestamp! < lastMonth.last!
        }
        
        self._selectedRange = selectedRange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary card view...
            SummaryCardView(percentage: self.percentageImprove)
                .onTapGesture {
                    if self.percentageImprove != 0 {
                        showProductivityAlert.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                .alert("Productivity \(self.percentageImprove > 0 ? "increased" : "decreased")",
                       isPresented: $showProductivityAlert,
                       actions: {}, message: {
                    self.percentageImprove > 0 ?
                    Text("You have been able to focus for \(self.percentageImprove)% longer than last \(selectedRange.rawValue).")
                    : Text("Your ability to focus have dropped \(-self.percentageImprove)% compared to last \(selectedRange.rawValue).")
                })
            
            // Bar graph view...
            GraphView(data: self.data)
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
            
            Image("lineGraph")
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
    
    private func GraphView(data: [(String, Double)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeboxed Duration")
                .font(.subheading1())
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            HStack {
                // Summary...
                Label {
                    // Stylish total focus duration text
                    // Numeric part is big, non-numeric part is small
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        ForEach(self.totalDuration, id: \.self) { component in
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
                    Button("This week") {
                        self.selectedRange = .week
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    Button("This month") {
                        self.selectedRange = .month
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(self.selectedRange.description)
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
                self.maxBarHeight > 0 ? GraphRenderer(data: data, max: Int(maxBarHeight)) : nil
                self.maxBarHeight == 0 ? GraphFallback() : nil
            }
            .frame(height: 128, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(Color.uiWhite)
        .cornerRadius(24)
    }
    
    private func GraphRenderer(data: [(String, Double)], max: Int) -> some View {
        GeometryReader { proxy in
            HStack {
                ForEach(data, id: \.0) { item in
                    VStack {
                        Button {
                            withAnimation {
                                self.selectedBar = item.0
                            }
                            
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            VStack {
                                self.selectedBar == item.0 ?
                                Text(Date.formatTimeDuration(item.1, unitStyle: .abbreviated,
                                                             units: [.hour, .minute], padding: nil))
                                .font(.caption())
                                .fontWeight(.heavy)
                                .foregroundColor(.accent) : nil
                                
                                Capsule()
                                    .fill(self.selectedBar == item.0 ? Color.accent : Color.uiLavender)
                                    .frame(width: 16)
                                    .frame(height: max > 0 ? self.getBarHeight(point: Int(item.1), max: max, size: proxy.size) : 0)
                            }
                        }
                        
                        // Abbreviate day labels (e.g. Mon -> M)
                        Text(self.selectedRange == .week ? String(item.0.first!) : item.0)
                            .font(.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(self.selectedBar == item.0 ? .accent : .textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.bottom, self.selectedBar != nil ? 20 : 0)
    }
    
    private func GraphFallback() -> some View {
        Text("No data to display")
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
