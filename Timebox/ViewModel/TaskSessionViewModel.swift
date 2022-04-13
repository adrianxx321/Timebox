//
//  TaskSessionViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI
import CoreData
import AVFoundation

class TaskSessionViewModel: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    // MARK: Core Data shared context
    private var context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    func getAllTaskSessions(query: FetchedResults<TaskSession>) -> [TaskSession] {
        return query.map{$0 as TaskSession}
    }
    
    func saveSession(task: Task, focusedDuration: Double, completedProgress: CGFloat, usedPomodoro: Bool) {
        
        let newSession = TaskSession(context: self.context)
        newSession.id = UUID()
        newSession.task = task
        newSession.timestamp = Date()
        newSession.focusedDuration = focusedDuration
        newSession.ptsAwarded = self.computeScore(focusedDuration, completedProgress, usedPomodoro)
            
        // Save to Core Data
        do {
            try self.context.save()
        } catch let error {
            print(error)
        }
    }
    
    func playWhiteNoise(_ play: Bool) {
        let sound = UserDefaults.standard.string(forKey: "whiteNoise") ?? "Ticking"
        guard let data = NSDataAsset(name: sound)?.data else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            self.audioPlayer = try AVAudioPlayer(data: data)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = self.audioPlayer else { return }
            // Plays the white noise in loop
            player.numberOfLoops =  -1
            
            if play {
                player.play()
            } else {
                player.pause()
            }

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    /// System for calculating points awarded from timeboxing
    private func computeScore(_ focusedDuration: Double, _ completedProgress: CGFloat
                              , _ usedPomodoro: Bool) -> Int32 {
        return 0
    }
    
    func getTotalTimeboxedHours(data: [TaskSession]) -> String {
        let total = data.reduce(0) { $0 + $1.focusedDuration }
        
        return Date.formatTimeDuration(TimeInterval(total), unitStyle: .abbreviated,
                                       units: [.hour, .minute], padding: nil)
    }
    
    func presentGraphByWeek(data: [TaskSession]) -> [(String, Double)] {
        let defaultData: [(String, Double)] = [("Mon", 0), ("Tue", 0), ("Wed", 0),
                                              ("Thu", 0), ("Fri", 0), ("Sat", 0),
                                              ("Sun", 0)]
        
        if data.isEmpty {
            return defaultData
        } else {
            // Aggregate by the day (Mon/Tue etc.) of completion
            let subset = Dictionary(grouping: data, by: {
                $0.timestamp!.formatDateTime(format: "EEE")
            }).map { key, value in
                (key, value.reduce(0) {
                    $0 + $1.focusedDuration
                })
            }
            
            return defaultData.map { (key, value) -> (String, Double) in
                var temp = (key, value)
                subset.forEach { k, v in
                    temp = (key == k) ? (k, v) : temp
                }
                
                return temp
            }
        }
    }
    
    func presentGraphByMonth(data: [TaskSession]) -> [(String, Double)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentYear = components.year!
        let currentMonth = components.month!
        let defaultData: [(Int, Double)] = [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
        
        // Aggregate by the week number of current month
        // given the completion date
        let subset = Dictionary(grouping: data, by: {
            calendar.component(.weekOfMonth, from: $0.timestamp!)
        }).map { key, value in
            (key, value.reduce(0) {
                $0 + $1.focusedDuration
            })
        }
        
        let secondPass = defaultData.map { (key, value) -> (Int, Double)  in
            var temp = (key, value)
            subset.forEach { k, v in
                temp = (key == k) ? (k, v) : temp
            }
            
            return temp
        }
        
        return secondPass.map { (key, value) -> (String, Double) in
            // Use weekday = 2 to tell use Monday as first weekday
            let newComponents = DateComponents(year: currentYear, month: currentMonth, weekday: 2, weekOfMonth: key) // nth week of March
            // Getting first & last day given weekOfMonth
            let firstWeekday = calendar.date(from: newComponents)!
            let startDate = firstWeekday.formatDateTime(format: "d/M")
            
            return ("\(startDate) -", value)
        }
    }
    
    func compareProductivity(current: [TaskSession], previous: [TaskSession]) -> Int {
        let currentTotal = current.reduce(0) { $0 + $1.focusedDuration }
        let previousTotal = previous.reduce(0) { $0 + $1.focusedDuration }
        
        let delta = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 0
        
        return Int(delta)
    }
}
