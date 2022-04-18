//
//  AchievementsViewModel.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//

import SwiftUI
import Foundation

class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    
    init() {
        loadData()
    }
    
    private func loadData()  {
        guard let path = Bundle.main.url(forResource: "Achievements", withExtension: "json")
            else {
                print("Error loading assets: Achievement.json not found")
                return
            }
        
        let data = try? Data(contentsOf: path)
        let decodedData = try? JSONDecoder().decode([Achievement].self, from: data!)
        self.achievements = decodedData!
    }
    
    func isUnlocked(_ achievement: Achievement, userPoints: Int32) -> Bool {
        return userPoints >= achievement.unlockedAt
    }
    
    func getCurrentRank(userPoints: Int32) -> String {
        let currentRank = achievements.reversed().first(where: {
            userPoints >= $0.unlockedAt
        })?.title.components(separatedBy: " ").first ?? "No ranking"

        return currentRank
    }
    
    func getNextRank(userPoints: Int32) -> String {
        if userPoints > achievements.last!.unlockedAt {
            return "None"
        } else {
            let nextRank = achievements.max { this, next in
                return this.unlockedAt...next.unlockedAt ~= userPoints
            }?.title.components(separatedBy: " ").first ?? "None"
            
            return nextRank
        }
    }
    
    func getPtsToNextRank(userPoints: Int32) -> Int32 {
        let nextRank = achievements.max { this, next in
            return this.unlockedAt...next.unlockedAt ~= userPoints
        }?.unlockedAt
        
        return nextRank!
    }
}
