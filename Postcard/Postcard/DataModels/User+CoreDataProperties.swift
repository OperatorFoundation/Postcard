//
//  User+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 7/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var emailAddress: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var peopleSyncToken: String?
    @NSManaged var publicKey: NSData?
    @NSManaged var pal: NSSet?
    @NSManaged var postcard: NSSet?

}
