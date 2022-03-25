//
//  Task+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//
//

import Foundation
import CoreData
import UIKit

@objc(Task)
public class Task: NSManagedObject {

}

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var color:  UIColor?
    @NSManaged public var completedTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isImportant: Bool
    @NSManaged public var isImported: Bool
    @NSManaged public var taskEndTime: Date?
    @NSManaged public var taskLabel: String?
    @NSManaged public var taskStartTime: Date?
    @NSManaged public var taskTitle: String?
    @NSManaged public var focusedDuration: Int64
    @NSManaged public var subtask: NSSet?
    @NSManaged public var user: User?
    
    public var subtasks: [Subtask] {
        let set = subtask as? Set<Subtask> ?? []
        
        return set.sorted {
            $0.order < $1.order
        }
    }
    
}

// MARK: Generated accessors for subtask
extension Task {

    @objc(addSubtaskObject:)
    @NSManaged public func addToSubtask(_ value: Subtask)

    @objc(removeSubtaskObject:)
    @NSManaged public func removeFromSubtask(_ value: Subtask)

    @objc(addSubtask:)
    @NSManaged public func addToSubtask(_ values: NSSet)

    @objc(removeSubtask:)
    @NSManaged public func removeFromSubtask(_ values: NSSet)

}

extension Task : Identifiable {

}
