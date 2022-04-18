//
//  TaskSession.swift
//  Timebox
//
//  Created by Lianghan Siew on 27/03/2022.
//
//

import Foundation
import CoreData

@objc(TaskSession)
public class TaskSession: NSManagedObject {

}

extension TaskSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskSession> {
        return NSFetchRequest<TaskSession>(entityName: "TaskSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var focusedDuration: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var ptsAwarded: Int32
    @NSManaged public var task: Task?

}

extension TaskSession : Identifiable {

}
