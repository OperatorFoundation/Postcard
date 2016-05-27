//
//  Postcard+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 5/25/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Postcard {

    @NSManaged var body: String?
    @NSManaged var decrypted: NSNumber?
    @NSManaged var hasPackage: NSNumber?
    @NSManaged var receivedDate: NSDate?
    @NSManaged var subject: String?
    @NSManaged var identifier: String?
    @NSManaged var snippet: String?
    @NSManaged var from: PenPal?

}
