//
//  User+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {

}

extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var uid: UUID?
    @NSManaged public var profilePic: Data?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var points: Int32
    @NSManaged public var task: NSSet?
    @NSManaged public var achievements: NSSet?

}

// MARK: Generated accessors for task
extension User {

    @objc(addTaskObject:)
    @NSManaged public func addToTask(_ value: Task)

    @objc(removeTaskObject:)
    @NSManaged public func removeFromTask(_ value: Task)

    @objc(addTask:)
    @NSManaged public func addToTask(_ values: NSSet)

    @objc(removeTask:)
    @NSManaged public func removeFromTask(_ values: NSSet)

}

// MARK: Generated accessors for achievements
extension User {

    @objc(addAchievementsObject:)
    @NSManaged public func addToAchievements(_ value: Achievement)

    @objc(removeAchievementsObject:)
    @NSManaged public func removeFromAchievements(_ value: Achievement)

    @objc(addAchievements:)
    @NSManaged public func addToAchievements(_ values: NSSet)

    @objc(removeAchievements:)
    @NSManaged public func removeFromAchievements(_ values: NSSet)

}

extension User : Identifiable {

}
