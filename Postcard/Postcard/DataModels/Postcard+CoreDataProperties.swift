//
//  Postcard+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 2/7/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Postcard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Postcard> {
        return NSFetchRequest<Postcard>(entityName: "Postcard");
    }

    @NSManaged public var body: String?
    @NSManaged public var cipherText: NSData?
    @NSManaged public var decrypted: Bool
    @NSManaged public var hasPackage: Bool
    @NSManaged public var identifier: String?
    @NSManaged public var receivedDate: NSDate?
    @NSManaged public var snippet: String?
    @NSManaged public var subject: String?
    @NSManaged public var to: String?
    @NSManaged public var from: PenPal?
    @NSManaged public var owner: User?

}
