//
//  MailController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GoogleAPIClientForRESTCore
import CoreData
import Sodium
import GoogleAPIClientForREST_Gmail
import Datable

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

//Key Attachment Keys
let keyAttachmentSenderPublicKeyKey = "senderPublicKey"
let keyAttachmentSenderPublicKeyTimestampKey = "senderPublicKeyTimestamp"
let keyAttachmentRecipientPublicKeyKey = "recipientPublicKey"
let keyAttachmentRecipientPublicKeyTimestamp = "recipientPublicKeyTimestamp"

//Message Keys
let messageToKey = "to"
let messageSubjectKey = "subject"
let messageBodyKey = "body"

//Version Keys
let versionKey = "version"
let serializedDataKey = "serializedData"
let keyFormatVersion = "0.0.1"
let ourLabel = "Postcard"
var ourLabelId: String?
var inboxLabelId: String?

class MailController: NSObject
{
    static let sharedInstance = MailController()
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let gmailUserId = "me"
    
    var managedObjectContext: NSManagedObjectContext?
//    var allPostcards = [GTLRGmail_Message]()
    var allPenpals = [PenPal]()
    
    fileprivate override init()
    {
        super.init()
        
        managedObjectContext = appDelegate.managedObjectContext
        
        //Make sure we are fetching any additional pages for Google requests
        GmailProps.service.shouldFetchNextPages = true
        
        //Get our Gmail label ID
        getGmailLabelId()
        
    }
    
    //MARK: Create Gmail Label
    
    func createGmailLabel()
    {
        let labelDict = [
            "name": ourLabel, //The display name of the label.
            "messageListVisibility": "hide", //Do not show the label in the message list.
            "labelListVisibility": "labelHide" //Do not show the label in the label list.
        ]
        let userLabelObject = GTLRGmail_Label(json: labelDict)
        let createLabelQuery = GTLRGmailQuery_UsersLabelsCreate.query(withObject: userLabelObject, userId: gmailUserId)
        GmailProps.service.executeQuery(createLabelQuery)
        {
            (ticket, maybeResponse, maybeError) in
            
            if let error = maybeError
            {
                //Likely this label already exists
                print("ERROR creating a new user label:\(error.localizedDescription)")
            }
            else if let response = maybeResponse as? GTLRGmail_Label
            {
                ourLabelId = response.identifier
            }
        }
    }
    
    func getGmailLabelId()
    {
        //Get a list of the user's labels from Gmail
        let listLabelsQuery = GTLRGmailQuery_UsersLabelsList.query(withUserId: gmailUserId)
        GmailProps.service.executeQuery(listLabelsQuery)
        {
            (ticket, maybeResponse, maybeError) in
            
            if let error = maybeError
            {
                print("ERROR getting user's label:\(error.localizedDescription)")
            }
            else if let response = maybeResponse as? GTLRGmail_ListLabelsResponse
            {
                let labels = response.labels
                if let postcardLabel = labels?.first(where: { $0.name == ourLabel})
                {
                    ourLabelId = postcardLabel.identifier
                    return
                }
            }
            
            //That didn't work, let's try making one.
            self.createGmailLabel()
        }
    }
    
    func updateLabels(forMessage message: GTLRGmail_Message, withId messageId: String)
    {
        if ourLabelId != nil
        {
            //Make sure this message doesn't already have our label
            if message.labelIds != nil
            {
                if (message.labelIds!.contains(ourLabelId!))
                {
                    return
                }
            }
            
            //Update the message so that it has a Postcard label
            let modifyRequestObject = GTLRGmail_ModifyMessageRequest(json: ["addLabelIds": [ourLabelId],
                                                                            "removeLabelIds": ["INBOX", "UNREAD"]])
            let updateLabelQuery = GTLRGmailQuery_UsersMessagesModify.query(withObject: modifyRequestObject, userId: self.gmailUserId, identifier: messageId)
            GmailProps.service.executeQuery(updateLabelQuery, completionHandler:
            {
                (ticket, maybeResponse, maybeError) in
                
                if let error = maybeError
                {
                    print("ERROR adding a label to gmail message:\(error.localizedDescription)")
                }
                else if let _ = maybeResponse
                {
                    print("ADDED POSTCARD LABEL TO GMAIL MESSAGE")
                }
            })
            
        }
    }
    
    //MARK: Delete Messages
    
    //Delete Gmail Message as well as Postcard
    func trashGmailMessage(_ thisPostcard: Postcard, completion: @escaping (_ successful: Bool) -> Void)
    {
        if let postcardIdentifier = thisPostcard.identifier
        {
            let trashQuery = GTLRGmailQuery_UsersMessagesTrash.query(withUserId: gmailUserId, identifier: postcardIdentifier)
            GmailProps.service.executeQuery(trashQuery, completionHandler:
                {
                    (ticket, maybeResponse, maybeError) in
                    
                    if let error = maybeError
                    {
                        completion(false)
                        print("ERROR deleting email:\(error.localizedDescription)")
                    }
                    if let _ = maybeResponse, let managedContext = self.managedObjectContext
                    {
                        print("DELETED EMAIL")
                        
                        managedContext.delete(thisPostcard)
                        do
                        {
                            try managedContext.save()
                            completion(true)
                        }
                        catch
                        {
                            completion(false)
                        }
                    }
            })
        }
    }
    
    //Deletes Gmail Messages only
    func trashGmailMessage(withId messageId: String)
    {
        if messageId != ""
        {
            let trashQuery = GTLRGmailQuery_UsersMessagesTrash.query(withUserId: gmailUserId, identifier: messageId)
            GmailProps.service.executeQuery(trashQuery, completionHandler:
            {
                (ticket, maybeResponse, maybeError) in
                
                if let error = maybeError
                {
                    print("ERROR deleting email:\(error.localizedDescription)")
                }
                if let _ = maybeResponse
                {
                    print("DELETED EMAIL")
                }
            })
        }
    }
    
    //MARK: Get Messages
    
    func updateMail()
    {
        fetchGmailMessagesList()
        fetchSentMessages()
        
        //Refresh every few minutes (counted in seconds)
        _ = Timer.scheduledTimer(timeInterval: 150, target: self, selector: (#selector(fetchGmailMessagesList)), userInfo: nil, repeats: true)
    }
    
    func fetchSentMessages()
    {
        //First get messages from the sent folder
        let listSentMessagesQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: gmailUserId)
        listSentMessagesQuery.maxResults = 800
        //Search for messages that have an attachment and the Inbox or Postcard labels
        listSentMessagesQuery.q = "has:attachment {label:SENT label:\(ourLabel)}"
        
        GmailProps.service.executeQuery(listSentMessagesQuery)
        {
            (ticket, maybeResponse, maybeError) in
            
            if let listMessagesResponse = maybeResponse as? GTLRGmail_ListMessagesResponse
            {
                //If there are messages that meet the query criteria in the list, get the message payload from Gmail
                if let metaMessages: [GTLRGmail_Message]  = listMessagesResponse.messages
                {
                    //Get message payloads
                    self.fetchAndSaveSentMailPayloads(metaMessages)
                }
            }
        }
    }
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    @objc func fetchGmailMessagesList()
    {
        //First get messages from the inbox
        let userMessagesListQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: gmailUserId)
        userMessagesListQuery.maxResults = 800
        //Search for messages that have an attachment and the Inbox or Postcard labels
        userMessagesListQuery.q = "has:attachment {label:INBOX label:\(ourLabel)}"
        
        GmailProps.service.executeQuery(userMessagesListQuery)
        {
            (ticket, maybeResponse, maybeError) in
            
            if let listMessagesResponse = maybeResponse as? GTLRGmail_ListMessagesResponse
            {
                //If there are messages that meet the query criteria in the list, get the message payload from Gmail
                if let metaMessages: [GTLRGmail_Message]  = listMessagesResponse.messages
                {
                    //Get message payloads
                    self.fetchAndSaveGmailPayloads(metaMessages)
                }
            }
        }
    }
    
    func fetchAndSaveSentMailPayloads(_ messages: [GTLRGmail_Message])
    {
        for messageMeta in messages
        {
            guard let messageIdentifier = messageMeta.identifier else
            {
                return
            }
            
            let userMessagesQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: gmailUserId, identifier: messageIdentifier)
            userMessagesQuery.fields = "payload"
            
            //Get full messages
            GmailProps.service.executeQuery(userMessagesQuery, completionHandler:
            {
                (ticket, maybeMessage, maybeError) in
                
                
                guard let message = maybeMessage as? GTLRGmail_Message else
                {
                    if let error = maybeError
                    {
                        print("Attempted to download a sent message payload, received an error: \(error.localizedDescription).")
                    }
                    else
                    {
                        print("Attempted to download a sent message payload, received no response.")
                    }
                    
                    return
                }
                
                guard let payload = message.payload, let parts: [GTLRGmail_MessagePart] = payload.parts else
                {
                    return
                }
                
                //This is a key/penpal invitation with receiver key info
                for thisPart in parts where thisPart.mimeType == PostCardProps.keyMimeType || thisPart.mimeType == PostCardProps.senderKeyMimeType || thisPart.mimeType == PostCardProps.postcardMimeType
                {
                    //Label it with our Gmail Label
                    self.updateLabels(forMessage: message, withId: messageIdentifier)
                    
                    guard let messageBody = thisPart.body, let attachmentId = messageBody.attachmentId else
                    {
                        print("Invalid message part")
                        return
                    }
                    
                    let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
                    
                    //Download the attachment
                    GmailProps.service.executeQuery(attachmentQuery, completionHandler:
                    {
                        (ticket, maybeAttachment, maybeError) in
                        
                        //Process the attachments
                        guard let attachment = maybeAttachment as? GTLRGmail_MessagePartBody else
                        {
                            print("Unable to process message attachment, attachment was an invalid type")
                            return
                        }
                        
                        print("^^^^^^Downloaded attachment from a sent message: ", attachment)
                        //                                        var senderKey: NSData?
                        //
                        ///ToDo: This key compare will not work as it assigns receiver sender based on the "From" field
                        //                                        if messagePart.mimeType == PostCardProps.keyMimeType
                        //                                        {
                        //                                            let parsedKey = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageID, hasReceiverKey: true)
                        //                                            keyCompareSucceeded = parsedKey.keysMatch
                        //
                        //                                            if keyCompareSucceeded
                        //                                            {
                        //                                                senderKey = parsedKey.senderKey
                        //                                            }
                        //                                            else
                        //                                            {
                        //                                                print("\nKeycompare failed for Message ID \(messageID): \n")
                        //                                            }
                        //                                        }
                        //                                        else if messagePart.mimeType == PostCardProps.senderKeyMimeType
                        //                                        {
                        //                                            let parsedKey = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageID, hasReceiverKey: false)
                        //                                            keyCompareSucceeded = parsedKey.keysMatch
                        //
                        //                                            if keyCompareSucceeded
                        //                                            {
                        //                                                senderKey = parsedKey.senderKey
                        //                                            }
                        //                                            else
                        //                                            {
                        //                                                print("\nKeycompare failed for Message ID \(messageID): \n")
                        //                                            }
                        //                                        }
                    })
                }
            })
        }
    }
    
    func fetchAndSaveGmailPayloads(_ messages: [GTLRGmail_Message])
    {
        for messageMeta in messages
        {
            guard let messageIdentifier = messageMeta.identifier else
            {
                return
            }
            
            guard messageAlreadySaved(messageIdentifier) == false else
            {
                print("Will not save message, it has already been saved.")
                return
            }
            
            let userMessagesQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: gmailUserId, identifier: messageIdentifier)
            userMessagesQuery.fields = "payload"
            
            //Get full messages
            GmailProps.service.executeQuery(userMessagesQuery, completionHandler:
            {
                (ticket, maybeMessage, maybeError) in
                
                guard let message = maybeMessage as? GTLRGmail_Message, let payload = message.payload, let parts: [GTLRGmail_MessagePart] = payload.parts else
                {
                    return
                }

                var senderKeyPart: GTLRGmail_MessagePart?
                var keyPart: GTLRGmail_MessagePart?
                var postcardPart: GTLRGmail_MessagePart?
                
                //This is a key/penpal invitation with receiver key info
                for thisPart in parts
                {
                    guard let mime=thisPart.mimeType else
                    {
                        continue
                    }
                    
                    switch mime
                    {
                        case PostCardProps.senderKeyMimeType:
                            senderKeyPart = thisPart
                        case PostCardProps.keyMimeType:
                            keyPart = thisPart
                        case PostCardProps.postcardMimeType:
                            postcardPart = thisPart
                        default:
                            print("Bad Postcard mimetype: \(thisPart.mimeType!)")
                            return
                    }
                }
                
                if senderKeyPart != nil
                {
                    self.processSenderKeyMessage(message, part: senderKeyPart!)
                }
                else if keyPart != nil, postcardPart != nil
                {
                    self.processKeyAndPostcardMessage(message, key: keyPart!, postcard: postcardPart!)
                }
            })
        }
    }
    
    func processSenderKeyMessage(_ message: GTLRGmail_Message, part thisPart: GTLRGmail_MessagePart)
    {
        //Label it with our Gmail Label
        self.updateLabels(forMessage: message, withId: message.identifier!)
        
        guard let messageBody = thisPart.body, let attachmentId = messageBody.attachmentId else
        {
            print("Invalid message part")
            return
        }
        
        let messageIdentifier = message.identifier!
        let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
        
        //Download the attachment
        GmailProps.service.executeQuery(attachmentQuery, completionHandler: {
            (ticket: GTLRServiceTicket, maybeAttachment: Any?, maybeError: Error?) in
            
            //Process the attachments
            guard let attachment = maybeAttachment as? GTLRGmail_MessagePartBody else
            {
                print("Unable to process message attachment, attachment was an invalid type")
                return
            }
            
            // This parses the keys and also saves them to Core Data.
            let parsedKey = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageIdentifier, hasReceiverKey: false)
            let keyCompareSucceeded = parsedKey.keysMatch
            
            if keyCompareSucceeded
            {
                print("\nKeycompare succeeded for Message ID \(messageIdentifier): \(parsedKey.senderKey!)\n")
            }
            else
            {
                print("\nKeycompare failed for Message ID \(messageIdentifier): \n")
            }
        })
    }
    
    func processKeyAndPostcardMessage(_ message: GTLRGmail_Message, key keyPart: GTLRGmail_MessagePart, postcard postcardPart: GTLRGmail_MessagePart)
    {
        //Label it with our Gmail Label
        self.updateLabels(forMessage: message, withId: message.identifier!)
        
        guard let keyBody = keyPart.body, let keyAttachmentId = keyBody.attachmentId else
        {
            print("Invalid message part")
            return
        }

        let messageIdentifier = message.identifier!
        let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: message.identifier!, identifier: keyAttachmentId)
    
        //This is a postcard message/attachment
        GmailProps.service.executeQuery(attachmentQuery, completionHandler:
        {
            (ticket: GTLRServiceTicket, maybeAttachment: Any?, maybeError: Error?) in
            
            //Process the attachments
            guard let attachment = maybeAttachment as? GTLRGmail_MessagePartBody else
            {
                print("Unable to process message attachment, attachment was an invalid type")
                return
            }
            
            var senderKey: NSData?
            var receiverKey: NSData?

            // This parses the keys and also saves them to Core Data.
            let attachmentKeys = self.processGmailAttachment(attachment: attachment, message: message, messageID: messageIdentifier, messagePart: keyPart)
            senderKey = attachmentKeys.senderKey
            receiverKey = attachmentKeys.receiverKey

            guard let payload = message.payload else
            {
                return
            }
            
            guard let headers: [GTLRGmail_MessagePartHeader] = payload.headers else
            {
                return
            }
            
            var sender = ""
            for header in headers where header.name == "From"
            {
                if let headerValue = header.value
                {
                    sender = headerValue
                }
            }
            
            guard !sender.isEmpty else
            {
                return
            }
            
            print("Processing a postcard Attachment")
            guard let messageBody = postcardPart.body, let attachmentId = messageBody.attachmentId else
            {
                return
            }
            
            let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
            
            //Download the attachment that is a Postcard
            GmailProps.service.executeQuery(attachmentQuery, completionHandler:
                {
                    (ticket, maybeAttachment, maybeError) in
                    
                    guard let attachment = maybeAttachment as? GTLRGmail_MessagePartBody else
                    {
                        print("Unable to decode postcard data")
                        return
                    }
                    
                    //Do we have this person saved as a PenPal?
                    guard let thisPenPal = PenPalController.sharedInstance.fetchPenPal(sender) else
                    {
                        print("A message was not saved because it is not from a known contact \(sender)")
                        return
                    }
                    
                    let attachmentString = attachment.data
                    
                    //Decode - GTLWebSafeBase64
                    guard let postcardData = stringDecodedToData(attachmentString!) else
                    {
                        return
                    }
                    
                    guard senderKey != nil, receiverKey != nil else
                    {
                        return
                    }
                    
                    //Create New Postcard Record
                    guard let entity = NSEntityDescription.entity(forEntityName: "Postcard", in: self.managedObjectContext!) else
                    {
                        return
                    }
                    
                    let newCard = Postcard(entity: entity, insertInto: self.managedObjectContext)
                    newCard.owner = GlobalVars.currentUser
                    newCard.from = thisPenPal
                    newCard.cipherText = postcardData as NSData?
                    newCard.identifier = message.identifier
                    newCard.senderKey = senderKey
                    newCard.receiverKey = receiverKey
                    
                    if let thisKey = receiverKey
                    {
                        print("🔑Postcard says my key is:\(thisKey)🔑")
                    }
                    else
                    {
                        print("🔑Postcard says my key is nil🔑")
                    }
                    
                    //                                                print("New Card Owner: \(newCard.owner)")
                    
                    for dateHeader in headers where dateHeader.name == "Date"
                    {
                        let formatter = DateFormatter()
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                        //Wed, 15 Feb 2017 20:48:50 -0500
                        if let headerDate = dateHeader.value
                        {
                            if let receivedDate = formatter.date(from: headerDate)
                            {
                                newCard.receivedDate = receivedDate as NSDate?
                            }
                        }
                    }
                    
                    //Save this Postcard to core data
                    do
                    {
                        try newCard.managedObjectContext?.save()
                    }
                    catch
                    {
                        let saveError = error as NSError
                        print("Unable to save a new postcard: \(saveError.localizedDescription)")
                    }
            })
        })
    }

    func processGmailAttachment(attachment: GTLRGmail_MessagePartBody, message: GTLRGmail_Message, messageID: String, messagePart: GTLRGmail_MessagePart) -> (senderKey: NSData?, receiverKey: NSData?)
    {
        var keyCompareSucceeded = false
        var senderKey: NSData?
        var receiverKey: NSData?
        
        if messagePart.mimeType == PostCardProps.keyMimeType
        {
            let parsedKey = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageID, hasReceiverKey: true)
            keyCompareSucceeded = parsedKey.keysMatch
            
            if keyCompareSucceeded
            {
                senderKey = parsedKey.senderKey
                receiverKey = parsedKey.receiverKey
            }
            else
            {
                print("\nKeycompare failed for Message ID \(messageID): \n")
            }
        }
        else if messagePart.mimeType == PostCardProps.senderKeyMimeType
        {
            let parsedKey = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageID, hasReceiverKey: false)
            keyCompareSucceeded = parsedKey.keysMatch
            
            if keyCompareSucceeded
            {
                senderKey = parsedKey.senderKey
            }
            else
            {
                print("\nKeycompare failed for Message ID \(messageID): \n")
            }
        }
        
        return(senderKey, receiverKey)
    }

    func decryptPostcard(_ postcard: Postcard) -> PostcardMessage?
    {
        //Decrypt - Sodium
        let keyController = KeyController.sharedInstance
        let sodium = Sodium()
        
        guard let secretKey = keyController.myPrivateKey
            else
        {
            showAlert(localizedMissingKeyError)
            return nil
        }
        
        guard let penPal = postcard.from
            else
        {
            showAlert(localizedMissingPalKeyError)
            return nil
        }
        
        guard let penPalKey = postcard.senderKey
            else
        {
            return nil
        }
        
        let penPalEMail = penPal.email
        
        guard let cipherText = postcard.cipherText
            else
        {
            showAlert(String(format: localizedMissingCipherError, penPalEMail))
            return nil
        }
    
        // FIXME: Encryption
        
//        guard let decryptedPostcard = sodium.box.open(nonceAndAuthenticatedCipherText: cipherText as Data, senderPublicKey: penPalKey as Box.PublicKey, recipientSecretKey: secretKey)
//            else
//        {
//            showAlert(String(format: localizedWrongKeyError, penPalEMail))
//
//            //If this postcard is already flagged as decrypted, set flag to false as it can no longer be decrypted
//            if postcard.decrypted
//            {
//                postcard.decrypted = false
//
//                //Save these changes to core data
//                do
//                {
//                    try postcard.managedObjectContext?.save()
//                }
//                catch
//                {
//                    let saveError = error as NSError
//                    print("\(saveError.localizedDescription)")
//                }
//            }
//            print("\nFailed to decrypt message from \(penPalEMail)\n")
//            return nil
//        }
//
//        //Parse this message into usable parts
//        guard let postcardMessage = PostcardMessage.init(postcardData: decryptedPostcard)
//            else
//        {
//            return nil
//        }
//
//        return postcardMessage
        
        /***/
        print("Decryption is currently disabled.")
        showAlert(String(format: localizedWrongKeyError, penPalEMail))
        
        //If this postcard is already flagged as decrypted, set flag to false as it can no longer be decrypted
        if postcard.decrypted
        {
            postcard.decrypted = false
            
            //Save these changes to core data
            do
            {
                try postcard.managedObjectContext?.save()
            }
            catch
            {
                let saveError = error as NSError
                print("\(saveError.localizedDescription)")
            }
        }
        print("\nFailed to decrypt message from \(penPalEMail)\n")
        return nil
        /***/
    }
    
    func removeAllDecryptionForUser(_ lockdownUser: User)
    {
        //Empty the message cache
        GlobalVars.messageCache = nil
        
        if let postcards = lockdownUser.postcard
        {
            for maybeCard in postcards
            {
                if let card = maybeCard as? Postcard
                {
                    //Remove all sensitive data
                    card.to = nil
                    card.hasPackage = false
                    card.decrypted = false
                    
                    //Save these changes to core data
                    do
                    {
                        try card.managedObjectContext?.save()
                    }
                    catch
                    {
                        let saveError = error as NSError
                        print("\(saveError.localizedDescription)")
                    }
                }
                else
                {
                    print("User's postcard set does not contain Postcards. We cannot re-encrypt these objects.")
                }
            }
        }
        else
        {
            print("Could not find postcards to re-encrypt for this user.")
        }
    }
        
    //MARK: Process Different Message Types
    
    //Check if the downloaded attachment is valid and save the information as a new penpal to core data
    func processPenPalKeyAttachment(_ attachment: GTLRGmail_MessagePartBody, forMessage message: GTLRGmail_Message, withID messageId: String, hasReceiverKey: Bool) -> (keysMatch: Bool, senderKey: NSData?, receiverKey: NSData?)
    {
        var keyCompareSucceeded = true
        
        //Check the headers for the message sender
        guard let messagePayload = message.payload, let headers: [GTLRGmail_MessagePartHeader] = messagePayload.headers
            else {return (false, nil, nil)}

        for header in headers
        {
            if header.name == "From"
            {
                let sender = header.value
                let attachmentDataString = attachment.data
                
                guard let decodedAttachment = stringDecodedToData(attachmentDataString!)
                    else { return (false, nil, nil) }
                
                //Check if we have this email address saved as a penpal
                if let thisPenPal = PenPalController.sharedInstance.fetchPenPalForCurrentUser(sender!)
                {
                    //Check to see if the copy of our key we received matches what we have stored
                    let keyController = KeyController.sharedInstance
                    
                    guard let recipientStoredKey = keyController.mySharedKey
                        else
                    {
                        print("Could not find recipient's stored key")
                        return (false, nil, nil)
                    }
                    
                    guard let recipientStoredDate = keyController.myKeyTimestamp
                        else
                    {
                        //This should never happen as KeyController checks for this on init
                        print("Unable to process key attachment as user key has no timestamp")
                        return (false, nil, nil)
                    }
                    
                    if hasReceiverKey
                    {
                        //Get the public keys from this attachment
                        guard let timestampedKeys = dataToPublicKeys(keyData: decodedAttachment)
                            else
                        {
                            print("Unable to get public keys from key attachment")
                            return (false, nil, nil)
                        }
                        
                        guard let thisPenPalKey = thisPenPal.key
                            else
                        {
                            print("Unable to find penpal key when procesing key attachment.")
                            
                            //This Penpal didn't have a key stored, save the received key
                            thisPenPal.key = timestampedKeys.senderPublicKey as NSData?
                            thisPenPal.keyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(timestampedKeys.senderKeyTimestamp))
                            
                            //Save this PenPal to core data
                            do
                            {
                                try thisPenPal.managedObjectContext?.save()
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print("\(saveError.localizedDescription), \(saveError.userInfo)")
                            }
                            
                            return (true, timestampedKeys.senderPublicKey as NSData?, timestampedKeys.recipientPublicKey as NSData?)
                        }
                        
                        guard let timestamp = thisPenPal.keyTimestamp
                            else
                        {
                            print("Unable to find penpal key timestamp.")
                            
                            return (false, nil, nil)
                        }
                        keyCompareSucceeded = KeyController.sharedInstance.compare(recipientKey: timestampedKeys.recipientPublicKey, andTimestamp: timestampedKeys.recipientKeyTimestamp, withStoredKey: recipientStoredKey, andTimestamp: recipientStoredDate, forPenPal: thisPenPal, andMessageId: messageId)
                        
                        keyCompareSucceeded = keyCompareSucceeded && KeyController.sharedInstance.compare(senderKey: timestampedKeys.senderPublicKey, andTimestamp: timestampedKeys.senderKeyTimestamp, withStoredKey: thisPenPalKey, andTimestamp: timestamp, forPenPal: thisPenPal, andMessageId: messageId)
                        
                        return (keyCompareSucceeded, timestampedKeys.senderPublicKey as NSData?, timestampedKeys.recipientPublicKey as NSData?)
                    }
                    else
                    {
                        //Get the public keys from this attachment
                        guard let timestampedKey = dataToSenderPublicKeys(keyData: decodedAttachment)
                            else
                        {
                            print("Unable to get public key from key attachment")
                            return (false, nil, nil)
                        }
                        
                        guard let thisPenPalKey = thisPenPal.key
                            else
                        {
                            print("Unable to find penpal key when procesing key attachment.")
                            //This Penpal didn't have a key stored, save the received key
                            thisPenPal.key = timestampedKey.senderPublicKey as NSData?
                            thisPenPal.keyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(timestampedKey.senderKeyTimestamp))
                            
                            //Save this PenPal to core data
                            do
                            {
                                try thisPenPal.managedObjectContext?.save()
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print("\(saveError.localizedDescription)")
                            }
                            
                            return (keyCompareSucceeded, timestampedKey.senderPublicKey as NSData?, nil)
                        }
                        
                        guard let timestamp = thisPenPal.keyTimestamp
                            else
                        {
                            print("Unable to find penpal key timestamp.")
                            return (keyCompareSucceeded, timestampedKey.senderPublicKey as NSData?, nil)
                        }
                        
                        keyCompareSucceeded = KeyController.sharedInstance.compare(senderKey: timestampedKey.senderPublicKey, andTimestamp: timestampedKey.senderKeyTimestamp, withStoredKey: thisPenPalKey, andTimestamp: timestamp, forPenPal: thisPenPal, andMessageId: messageId)
                        
                        return (keyCompareSucceeded, timestampedKey.senderPublicKey as NSData?, nil)
                    }
                }
                    //If not check for a key and create a new PenPal
                else if sender != ""
                {
                    //Create New PenPal Record
                    guard let entity = NSEntityDescription.entity(forEntityName: "PenPal", in: self.managedObjectContext!)
                        else {return (false, nil, nil)}
                    
                    let newPal = PenPal(entity: entity, insertInto: self.managedObjectContext)
                    newPal.email = sender!
                    newPal.addedDate = NSDate()
                    newPal.owner = GlobalVars.currentUser
                    
                    if hasReceiverKey
                    {
                        //Get the public keys from this attachment
                        guard let timestampedKeys = dataToPublicKeys(keyData: decodedAttachment)
                            else
                        {
                            print("Unable to get public keys from key attachment")
                            return (false, nil, nil)
                        }
                        
                        let palKey = timestampedKeys.senderPublicKey as NSData
                        newPal.key = palKey
                        
                        let palKeyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(timestampedKeys.senderKeyTimestamp))
                        newPal.keyTimestamp = palKeyTimestamp
                        
                        return (true, palKey, nil)
                    }
                    else
                    {
                        //Get the public keys from this attachment
                        guard let timestampedKey = dataToSenderPublicKeys(keyData: decodedAttachment)
                            else
                        {
                            print("Unable to get public key from key attachment")
                            return (false, nil, nil)
                        }
                        
                        let palKey = timestampedKey.senderPublicKey as NSData
                        
                        newPal.key = palKey
                        
                        let palKeyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(timestampedKey.senderKeyTimestamp))
                        newPal.keyTimestamp = palKeyTimestamp
                        
                        //Save this PenPal to core data
                        do
                        {
                            try newPal.managedObjectContext?.save()
                        }
                        catch
                        {
                            let saveError = error as NSError
                            print("\(saveError.localizedDescription)")
                        }
                        
                        return (true, palKey, nil)
                    }
                }
            }
        }
        
        return (false, nil, nil)
    }
                        
    func messageAlreadySaved(_ identifier: String) -> Bool
    {
        let fetchRequest: NSFetchRequest<Postcard> = Postcard.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        do
        {
            let result = try self.managedObjectContext?.fetch(fetchRequest)
            if result?.count > 0
            {
                return true
            }
        }
        catch
        {
            let fetchError = error as NSError
            print(fetchError.localizedDescription)
        }
        
        return false
    }
    
    func sendEmail(_ to: [String], subject: String, body: String, maybeAttachments:[URL]?, completion: @escaping (_ successful: Bool) -> Void)
    {
        //This method handles any error alerts if there are invalid emails
        if allEmailsAreValid(forRecipients: to)
        {
            for thisRecipient in to
            {
                //Make sure each recipient is a Gmail Contact (this is already checked in allEmailsAreValid:forRecipients so no error handling here)
                if let thisPenpal = PenPalController.sharedInstance.fetchPenPalForCurrentUser(thisRecipient)
                {
                    //Make sure we have a key for each recipient (this is already checked in allEmailsAreValid:forRecipients so no error handling here)
                    if let penPalKey = thisPenpal.key
                    {
                        //Send a seperate email to each valid recipient in the list
                        if let emailMessage = generateMessage(forPenPal: thisPenpal, subject: subject, body: body, maybeAttachments: maybeAttachments, withKey: penPalKey as Data)
                        {
                            let gmailMessage = GTLRGmail_Message()
                            let rawMessage = emailToRaw(email: emailMessage)
                            gmailMessage.raw = rawMessage
                            
                            let sendGmailQuery = GTLRGmailQuery_UsersMessagesSend.query(withObject: gmailMessage, userId: gmailUserId, uploadParameters: nil)
                            
                            GmailProps.service.executeQuery(sendGmailQuery, completionHandler:
                            {
                                (ticket, maybeResponse, maybeError) in

                                print("Attempting to send email to: \(thisPenpal.email)")
                                
                                if let response = maybeResponse as? GTLRGmail_Message
                                {
                                    print("Send email response: \(response)")
                                    
                                    if let labelIds = response.labelIds
                                    {
                                        print("Label ids:\(labelIds.description)")
                                    }
                                    if maybeError == nil
                                    {
                                        print("Sent Key: \(thisPenpal.sentKey)")
                                        if let thisKey = thisPenpal.key
                                        {
                                            print("PenPal Key: \(thisKey)")
                                        }
                                        else
                                        {
                                            print("PenPal Key is nil")
                                        }
                                        
                                        completion(true)
                                        return
                                    }
                                    else if let error = maybeError
                                    {
                                        print("Error sending email: \(error.localizedDescription)")
                                    }
                                }
                                else
                                {
                                    print("We did not receive a valid response when attempting to send a message.")
                                    if let error = maybeError
                                    {
                                        print("Send email error: \(error.localizedDescription)")
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    func allEmailsAreValid(forRecipients recipients: [String]) -> Bool
    {
        var recipientEmails = [String]()
        var notaContact = [String]()
        var notaPalEmails = [String]()
        var errorMessage = ""
        
        for thisRecipient in recipients
        {
            //Make sure each recipient is a Gmail Contact
            if let thisPenpal = PenPalController.sharedInstance.fetchPenPalForCurrentUser(thisRecipient)
            {
                //Make sure we have a key for each recipient
                print("Trying to send an email to:")
                print(thisPenpal.email)
                print(thisPenpal.key ?? "No Key Stored")
                print("Current user")
                print(thisPenpal.owner?.emailAddress ?? "No Owner Stored")
                if thisPenpal.key == nil
                {
                    notaPalEmails.append(thisRecipient)
                }
                else
                {
                    recipientEmails.append(thisRecipient)
                }
            }
            else
            {
                notaContact.append(thisRecipient)
            }
        }
        
        //Show user what went wrong
        if !notaPalEmails.isEmpty
        {
            errorMessage = String(format: localizedSendErrorNoKey, notaPalEmails.joined(separator: ","))
        }
        if !notaContact.isEmpty
        {
            errorMessage = errorMessage + "\n" + String(format: localizedSendErrorNoKey, notaContact.joined(separator: ","))
        }
        
        if recipientEmails.isEmpty && notaContact.isEmpty && notaPalEmails.isEmpty
        {
            errorMessage = localizedSendErrorNoValidEmails
        }
        
        if errorMessage.isEmpty
        {
            return true
        }
        else
        {
            showAlert(errorMessage)
            return false
        }
    }

    func generateMessage(forPenPal penPal: PenPal, subject: String, body: String, maybeAttachments: [URL]?, withKey key: Data) -> EmailMessage?
    {
        let emailAddress = penPal.email
        guard let key = penPal.key else { return nil }
        
        //This is the actual User's Message
        if let messageData = generateMessagePostcard(sendToEmail: emailAddress, subject: subject, body: body, withKey: key as Data)
            
        {
            //TODO: This will call generateMessagePackage for user's attachments
            let packageData:Data? = nil
            
            //Key Attachment Data
            guard let keyAttachmentData = generateKeyAttachment(forPenPal: penPal) else { return nil }
            
            //This is the actual complete email
            let emailMessage = EmailMessage.init(to: emailAddress, hasPalKey: true, keyData: keyAttachmentData, postcardData: messageData, packageData: packageData)
            
            return emailMessage
        }
        else
        {
            return nil
        }
    }
    
    //Main Wrapper Message This is what the user will see in any email client
    
    func generateMessagePostcard(sendToEmail to: String, subject: String, body: String, withKey key: Data) -> Data?
    {
        print("\nSending an email to: \(to)\nRecipient's Public Key: \(key)")
        
        let postcardMessage = PostcardMessage.init(to: to, subject: subject, body: body)
        if let postcardMessageData = postcardMessage.dataValue()
        {
            let sodium = Sodium()
            if let secretKey = KeyController.sharedInstance.myPrivateKey
            {
                //FIXME: Encryption Overhaul
                print("Encryption has been disabled.")
                
//                if let encryptedMessageBytes: Bytes = sodium.box.seal(message: postcardMessageData, recipientPublicKey: key, senderSecretKey: secretKey)
//                {
//                    return Data(bytes: encryptedMessageBytes)
//                }
//                else
//                {
//                    //We are not showing alerts for these because there is nothing the user can do about this
//                    print("We could not encrypt this message.")
//                }
            }
            else
            {
                print("Couldn't send a Postcard because either sodium blew up, or we couldn't find your secret key DX")
            }
        }
        else
        {
            print("***Unable to create postcard message data.***")
        }
        
        return nil
    }
    
    func generateKeyMessage(forPenPal penPal: PenPal) -> EmailMessage?
    {
        //This is the invitation message
        let emailAddress = penPal.email
        
        if penPal.key == nil || penPal.keyTimestamp == nil
        {
            guard let keyAttachmentData = generateSenderPublicKeyAttachment(forPenPal: penPal) else
            {
                return nil
            }
            
            let emailMessage = EmailMessage.init(to: emailAddress, hasPalKey: false, keyData: keyAttachmentData, postcardData: nil, packageData: nil)
            return emailMessage
        }
        else
        {
            guard let keyAttachmentData = generateKeyAttachment(forPenPal: penPal) else
            {
                return nil
            }
            
            let emailMessage = EmailMessage.init(to: emailAddress, hasPalKey: true, keyData: keyAttachmentData, postcardData: nil, packageData: nil)
            return emailMessage
        }
    }
                        
    //MARK: Helper Methods
    func showAlert(_ message: String)
    {
        DispatchQueue.main.async
        {
            let alert = NSAlert()
            alert.messageText = message
            alert.addButton(withTitle: localizedOKButtonTitle)
            alert.runModal()
        }
    }
    
    //💌//
}
