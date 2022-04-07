//
//  Achievement.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//

import SwiftUI

struct Achievement: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case iconName
        case title
        case description
        case unlockedAt
        case unlockedDescription
    }
    
    var id = UUID().uuidString
    var iconName: String
    var title: String
    var description: String
    var unlockedAt: Int32
    var unlockedDescription: String
}
