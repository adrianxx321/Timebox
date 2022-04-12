//
//  TimeInterval+extension.swift
//  Timebox
//
//  Created by Lianghan Siew on 12/04/2022.
//

import Foundation

extension TimeInterval {
    static func formatTimeInterval(_ interval: TimeInterval, units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .positional
        
        return formatter.string(from: interval) ?? "00:00"
    }
}
