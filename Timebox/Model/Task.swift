//
//  Task.swift
//  Timebox
//
//  Created by Lianghan Siew on 01/03/2022.
//

import SwiftUI

struct Subtask {
    var subtaskTitle: String
    var isSubtaskComplete: Bool
}

struct Task: Identifiable {
    let id = UUID().uuidString
    let isImported: Bool
    var taskTitle: String
    var isImportant: Bool
    var taskDate: Date?
    var taskStartTime: Date?
    var taskEndTime: Date?
    var isCompleted: Bool = false
    var color: Color
    var subtasks: [Subtask] = []
}
