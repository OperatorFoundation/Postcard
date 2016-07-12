//
//  Postcard+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 7/8/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Postcard {

    @NSManaged var body: String?
    @NSManaged var decrypted: Bool
    @NSManaged var hasPackage: Bool
    @NSManaged var identifier: String?
    @NSManaged var receivedDate: NSTimeInterval
    @NSManaged var snippet: String?
    @NSManaged var subject: String?
    @NSManaged var to: String?
    @NSManaged var cipherText: NSData?
    @NSManaged var from: PenPal?
    @NSManaged var owner: User?

}
