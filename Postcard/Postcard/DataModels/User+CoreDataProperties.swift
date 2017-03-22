//
//  User+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 3/20/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var emailAddress: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var peopleSyncToken: String?
    @NSManaged public var pal: NSSet?
    @NSManaged public var postcard: NSSet?

}

// MARK: Generated accessors for pal
extension User {

    @objc(addPalObject:)
    @NSManaged public func addToPal(_ value: PenPal)

    @objc(removePalObject:)
    @NSManaged public func removeFromPal(_ value: PenPal)

    @objc(addPal:)
    @NSManaged public func addToPal(_ values: NSSet)

    @objc(removePal:)
    @NSManaged public func removeFromPal(_ values: NSSet)

}

// MARK: Generated accessors for postcard
extension User {

    @objc(addPostcardObject:)
    @NSManaged public func addToPostcard(_ value: Postcard)

    @objc(removePostcardObject:)
    @NSManaged public func removeFromPostcard(_ value: Postcard)

    @objc(addPostcard:)
    @NSManaged public func addToPostcard(_ values: NSSet)

    @objc(removePostcard:)
    @NSManaged public func removeFromPostcard(_ values: NSSet)

}
