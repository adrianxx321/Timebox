//
//  Subtask+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 06/03/2022.
//
//

import Foundation
import CoreData

@objc(Subtask)
public class Subtask: NSManagedObject {

}

import Foundation
import CoreData


extension Subtask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subtask> {
        return NSFetchRequest<Subtask>(entityName: "Subtask")
    }

    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int32
    @NSManaged public var subtaskTitle: String
    @NSManaged public var parentTask: Task?

}

extension Subtask : Identifiable {

}
