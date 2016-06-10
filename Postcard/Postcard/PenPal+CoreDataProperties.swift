//
//  PenPal+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 6/3/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PenPal {

    @NSManaged var addedDate: NSDate?
    @NSManaged var email: String?
    @NSManaged var key: NSData?
    @NSManaged var name: String?
    @NSManaged var photo: NSObject?
    @NSManaged var sentKey: NSNumber?
    @NSManaged var messages: NSSet?

}
