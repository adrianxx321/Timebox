//
//  Achievement+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//
//

import Foundation
import CoreData

@objc(Achievement)
public class Achievement: NSManagedObject {

}

extension Achievement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Achievement> {
        return NSFetchRequest<Achievement>(entityName: "Achievement")
    }

    @NSManaged public var icon: Data?
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var users: NSSet?

}

// MARK: Generated accessors for users
extension Achievement {

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: User)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: User)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: NSSet)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: NSSet)

}

extension Achievement : Identifiable {

}
