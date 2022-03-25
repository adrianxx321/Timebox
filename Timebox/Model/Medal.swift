//
//  Medal+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//
//

import Foundation
import CoreData

@objc(Medal)
public class Medal: Achievement {

}

extension Medal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Medal> {
        return NSFetchRequest<Medal>(entityName: "Medal")
    }

    @NSManaged public var rank: Int16

}
