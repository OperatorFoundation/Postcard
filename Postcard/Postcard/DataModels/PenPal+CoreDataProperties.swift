//
//  PenPal+CoreDataProperties.swift
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

extension PenPal {

    @NSManaged var addedDate: TimeInterval
    @NSManaged var email: String?
    @NSManaged var key: Data?
    @NSManaged var name: String?
    @NSManaged var photo: NSObject?
    @NSManaged var sentKey: Bool
    @NSManaged var messages: NSSet?
    @NSManaged var owner: User?

}
