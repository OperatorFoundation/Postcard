//
//  PenPal+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 3/20/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import CoreData


extension PenPal
{

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PenPal>
    {
        return NSFetchRequest<PenPal>(entityName: "PenPal");
    }

    @NSManaged public var addedDate: NSDate?
    @NSManaged public var email: String
    @NSManaged public var key: NSData?
    @NSManaged public var keyTimestamp: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var photo: NSObject?
    @NSManaged public var sentKey: Bool
    @NSManaged public var messages: NSSet?
    @NSManaged public var owner: User?

}

// MARK: Generated accessors for messages
extension PenPal {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Postcard)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Postcard)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}
