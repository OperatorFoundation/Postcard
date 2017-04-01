//
//  Postcard+CoreDataProperties.swift
//  Postcard
//
//  Created by Adelita Schule on 3/29/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import CoreData


extension Postcard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Postcard>
    {
        return NSFetchRequest<Postcard>(entityName: "Postcard");
    }

    @NSManaged public var cipherText: NSData?
    @NSManaged public var decrypted: Bool
    @NSManaged public var hasPackage: Bool
    @NSManaged public var identifier: String?
    @NSManaged public var receivedDate: NSDate?
    @NSManaged public var senderKey: NSData?
    @NSManaged public var snippet: String?
    @NSManaged public var to: String?
    @NSManaged public var receiverKey: NSData?
    @NSManaged public var from: PenPal?
    @NSManaged public var owner: User?
    
    //These are properties thatwe never want saved in core data, but that are part of the Postcard object
    public var subject: String?
        {
        get
        {
            if self.decrypted
            {
                if let messageID = self.identifier
                {
                    if GlobalVars.messageCache == nil
                    {
                        GlobalVars.messageCache = Dictionary <String, PostcardMessage>()
                    }
                    
                    if let thisPostcard = GlobalVars.messageCache![messageID]
                    {
                        return thisPostcard.subject
                    }
                    else
                    {
                        //Initialize the message
                        if let thisPostcard = MailController.sharedInstance.decryptPostcard(self)
                        {
                            GlobalVars.messageCache![messageID] = thisPostcard
                            return thisPostcard.subject
                        }
                    }
                }
            }
            
            return nil
        }
    }
    
    public var body: String?
        {
        get
        {
            if self.decrypted
            {
                if let messageID = self.identifier
                {
                    if GlobalVars.messageCache == nil
                    {
                        GlobalVars.messageCache = Dictionary <String, PostcardMessage>()
                    }
                    
                    if let thisPostcard = GlobalVars.messageCache![messageID]
                    {
                        return thisPostcard.body
                    }
                    else
                    {
                        //Initialize the message
                        if let thisPostcard = MailController.sharedInstance.decryptPostcard(self)
                        {
                            GlobalVars.messageCache![messageID] = thisPostcard
                            return thisPostcard.body
                        }
                    }
                }
            }
            
            return nil
        }
    }
    
    //This is required for Cocoa bindings to respond to changes in body and subject properties
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String>
    {
        if key == "subject" || key == "body"
        {
            return Set(["decrypted"])
        }
        else
        {
            return super.keyPathsForValuesAffectingValue(forKey: key)
        }
    }

}
