//
//  Badge+CoreDataClass.swift
//  Timebox
//
//  Created by Lianghan Siew on 25/03/2022.
//
//

import Foundation
import CoreData

@objc(Badge)
public class Badge: Achievement {

}

extension Badge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Badge> {
        return NSFetchRequest<Badge>(entityName: "Badge")
    }


}
