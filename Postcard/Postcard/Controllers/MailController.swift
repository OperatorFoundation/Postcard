//
//  MailController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GoogleAPIClientForREST
import CoreData
import Sodium
import MessagePack

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
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    let gmailUserId = "me"
    
    var managedObjectContext: NSManagedObjectContext?
    var allPostcards = [GTLRGmail_Message]()
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
        
        //Refresh every few minutes (counted in seconds)
        _ = Timer.scheduledTimer(timeInterval: 150, target: self, selector: (#selector(fetchGmailMessagesList)), userInfo: nil, repeats: true)
    }
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        //First get messages from the inbox
        //let userMessagesListQuery = GTLRGmailQuery_UsersHistoryList.query(withUserId: gmailUserId)
        let userMessagesListQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: gmailUserId)
        userMessagesListQuery.maxResults = 800
        //Search for messages thathave an attachment and the Inbox or Postcard labels
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
    
    func fetchAndSaveGmailPayloads(_ messages: [GTLRGmail_Message])
    {
        for messageMeta in messages
        {
            if let messageIdentifier = messageMeta.identifier
            {
                if messageAlreadySaved(messageIdentifier) == false
                {
                    let userMessagesQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: gmailUserId, identifier: messageIdentifier)
                    userMessagesQuery.fields = "payload"
                    
                    //Get full messages
                    GmailProps.service.executeQuery(userMessagesQuery, completionHandler:
                    {
                        (ticket, maybeMessage, maybeError) in
                        
                        if let message = maybeMessage as? GTLRGmail_Message, let payload = message.payload, let parts: [GTLRGmail_MessagePart] = payload.parts
                        {
                            //This is a key/penpal invitation with receiver key info
                            for thisPart in parts where thisPart.mimeType == PostCardProps.keyMimeType || thisPart.mimeType == PostCardProps.senderKeyMimeType
                            {
                                //Label it with our Gmail Label
                                self.updateLabels(forMessage: message, withId: messageIdentifier)
                                
                                //Download the attachment
                                if let messageBody = thisPart.body, let attachmentId = messageBody.attachmentId
                                {
                                    let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
                                    GmailProps.service.executeQuery(attachmentQuery, completionHandler:
                                    {
                                        (ticket, maybeAttachment, maybeError) in
                                        
                                        //Process the attachments
                                        if let attachment = maybeAttachment as? GTLRGmail_MessagePartBody
                                        {
                                            var keyCompareSucceeded = false
                                            
                                            if thisPart.mimeType == PostCardProps.keyMimeType
                                            {
                                                keyCompareSucceeded = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageIdentifier, hasReceiverKey: true)
                                            }
                                            else if thisPart.mimeType == PostCardProps.senderKeyMimeType
                                            {
                                                keyCompareSucceeded = self.processPenPalKeyAttachment(attachment, forMessage: message, withID: messageIdentifier, hasReceiverKey: false)
                                            }
                                            
                                            if !keyCompareSucceeded
                                            {
                                                print("\nKeycompare failed for Message ID \(messageIdentifier): \n" + payload.description + "\nPayload had \(payload.parts!.count) parts:\n \(payload.parts?.description).\n")
                                            }
                                        }
                                    })
                                }
                            }
                            
                            if let headers: [GTLRGmail_MessagePartHeader] = payload.headers
                            {
                                var sender = ""
                                for header in headers where header.name == "From"
                                {
                                    if let headerValue = header.value
                                    {
                                        sender = headerValue
                                    }
                                }
                                
                                if !sender.isEmpty
                                {
                                    //This is a postcard message/attachment
                                    for thisPart in parts where thisPart.mimeType == PostCardProps.postcardMimeType
                                    {
                                        //Download the attachment that is a Postcard
                                        if let messageBody = thisPart.body, let attachmentId = messageBody.attachmentId
                                        {
                                            let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
                                            GmailProps.service.executeQuery(attachmentQuery, completionHandler:
                                            {
                                                (ticket, maybeAttachment, maybeError) in
                                                
                                                if let attachment = maybeAttachment as? GTLRGmail_MessagePartBody
                                                {
                                                    //Do we have this person saved as a PenPal?
                                                    if let thisPenPal = PenPalController.sharedInstance.fetchPenPal(sender)
                                                    {
                                                        let attachmentString = attachment.data
                                                        
                                                        //Decode - GTLWebSafeBase64
                                                        if let postcardData = self.stringDecodedToData(attachmentString!)
                                                        {
                                                            //CoreData
                                                            if let entity = NSEntityDescription.entity(forEntityName: "Postcard", in: self.managedObjectContext!)
                                                            {
                                                                //Create New Postcard Record
                                                                let newCard = Postcard(entity: entity, insertInto: self.managedObjectContext)
                                                                
                                                                newCard.owner = GlobalVars.currentUser
                                                                newCard.from = thisPenPal
                                                                newCard.cipherText = postcardData as NSData?
                                                                newCard.identifier = messageMeta.identifier
                                                                
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
                                                                    print("\(saveError.localizedDescription)")
                                                                }
                                                            }
                                                        }
                                                        else
                                                        {
                                                            print("Failed to decode the message from \(sender).\n")
                                                        }
                                                    }
                                                    else
                                                    {
                                                        print("A message could not be decrypted because it is not from a known contact \(sender)")
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func decryptPostcard(_ postcard: Postcard)
    {
        //Decrypt - Sodium
        let keyController = KeyController.sharedInstance
        if let sodium = Sodium()
        {
            if let secretKey = keyController.myPrivateKey
            {
                if let penPal = postcard.from, let penPalKey = penPal.key
                {
                    let penPalEMail = penPal.email
                    if let cipherText = postcard.cipherText
                    {
                        if let decryptedPostcard = sodium.box.open(nonceAndAuthenticatedCipherText: cipherText as Data, senderPublicKey: penPalKey as Box.PublicKey, recipientSecretKey: secretKey)
                        {
                            //Parse this message
                            self.parseDecryptedMessageAndSave(decryptedPostcard, saveToPostcard: postcard)
                        }
                        else
                        {
                            showAlert(String(format: localizedWrongKeyError, penPalEMail))
                            print("\nFailed to decrypt message:\n")
                            print("Sender's Public Key: \(penPalKey)\n")
                            print("My public key: \(keyController.mySharedKey?.description)")
                            print("My Secret Key: \(secretKey.description)\n")
                        }
                    }
                    else
                    {
                        showAlert(String(format: localizedMissingCipherError, penPalEMail))
                    }
                }
                else
                {
                    showAlert(localizedMissingPalKeyError)
                }
            }
            else
            {
                showAlert(localizedMissingKeyError)
            }
        }
        else
        {
            print("\nUnable to decrypt message: could not initialize Sodium. That's weird.\n")
        }
    }
    
    fileprivate func parseDecryptedMessageAndSave(_ data: Data, saveToPostcard postcard: Postcard)
    {
        //Parse this message into usable parts
        if let postcardMessage = PostcardMessage.init(postcardData: data)
        {
            postcard.body = postcardMessage.body
            postcard.subject = postcardMessage.subject
            postcard.decrypted = true
            postcard.to = postcardMessage.to
            
            //Snippet?
            //Attachment?
//            let attachments = messageParser?.attachments()
//            
//            if (attachments?.isEmpty)!
//            {
//                postcard.hasPackage = false
//            }
//            else
//            {
//                //TODO: ignore key attachments
//                postcard.hasPackage = true
//            }
            
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
    }
    
    func removeDecryptedPostcardData(_ postcard: Postcard)
    {
        //Remove all sensitive data
        postcard.body = nil
        postcard.subject = nil
        postcard.snippet = nil
        postcard.to = nil
        postcard.hasPackage = false
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
    
    func removeAllDecryptionForUser(_ lockdownUser: User)
    {
        if let postcards = lockdownUser.postcard
        {
            for maybeCard in postcards
            {
                if let card = maybeCard as? Postcard
                {
                    removeDecryptedPostcardData(card)
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
    
    func dataEncodedToString(_ data: Data) -> String
    {
        let newString = GTLREncodeWebSafeBase64(data)
        
        return newString!
    }
    
    func stringDecodedToData(_ string: String) -> Data?
    {
        if let newData = GTLRDecodeWebSafeBase64(string)
        {
            return newData
        }
        else {return nil}
    }
    
    func fetchPenPalForCurrentUser(_ emailAddress: String) -> PenPal?
    {
        //Make sure we have a current user
        if let currentUser = GlobalVars.currentUser
        {
            let fetchRequest: NSFetchRequest<PenPal> = PenPal.fetchRequest()
            //Check for a penpal with this email address AND this current user as owner
            fetchRequest.predicate = NSPredicate(format: "email == %@ AND owner == %@", emailAddress, currentUser)
            do
            {
                let result = try self.managedObjectContext?.fetch(fetchRequest)
                if result?.count > 0
                {
                    let thisPenpal = result?[0]
                    return thisPenpal
                }
            }
            catch
            {
                //Could not fetch this Penpal from core data
                let fetchError = error as NSError
                print(fetchError.localizedDescription)
                
                return nil
            }
        }
        
        return nil
    }
    
    //MARK: Process Different Message Types
    
    //Check if the downloaded attachment is valid and save the information as a new penpal to core data
    func processPenPalKeyAttachment(_ attachment: GTLRGmail_MessagePartBody, forMessage message: GTLRGmail_Message, withID messageId: String, hasReceiverKey: Bool) -> Bool
    {
        var keyCompareSucceeded = true
        
        //Check the headers for the message sender
        if let messagePayload = message.payload, let headers: [GTLRGmail_MessagePartHeader] = messagePayload.headers
        {
            for header in headers
            {
                if header.name == "From"
                {
                    let sender = header.value
                    let attachmentDataString = attachment.data
                    
                    guard let decodedAttachment = stringDecodedToData(attachmentDataString!) else { return false }
                    
                    //Check if we have this email address saved as a penpal
                    if let thisPenPal = self.fetchPenPalForCurrentUser(sender!)
                    {
                        //Check to see if the copy of our key we received matches what we have stored
                        let keyController = KeyController.sharedInstance
                        
                        guard let recipientStoredKey = keyController.mySharedKey
                            else
                        {
                            print("Could not find recipient's stored key")
                            return false
                        }
                        
                        guard let recipientStoredDate = keyController.myKeyTimestamp
                            else
                        {
                            //This should never happen as KeyController checks for this on init
                            print("Unable to process key attachment as user key has no timestamp")
                            return false
                        }
                        
                        if hasReceiverKey
                        {
                            //Get the public keys from this attachment
                            guard let timestampedKeys = dataToPublicKeys(keyData: decodedAttachment)
                                else
                            {
                                print("Unable to get public keys from key attachment")
                                return false
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
                                
                                return false
                            }
                            
                            guard let timestamp = thisPenPal.keyTimestamp
                                else
                            {
                                print("Unable to find penpal key timestamp.")
                                
                                return false
                            }
                            keyCompareSucceeded = compare(recipientKey: timestampedKeys.recipientPublicKey, andTimestamp: timestampedKeys.recipientKeyTimestamp, withStoredKey: recipientStoredKey, andTimestamp: recipientStoredDate, forPenPal: thisPenPal, andMessageId: messageId)
                            
                            keyCompareSucceeded = keyCompareSucceeded && compare(senderKey: timestampedKeys.senderPublicKey, andTimestamp: timestampedKeys.senderKeyTimestamp, withStoredKey: thisPenPalKey, andTimestamp: timestamp, forPenPal: thisPenPal, andMessageId: messageId)
                        }
                        else
                        {
                            //Get the public keys from this attachment
                            guard let timestampedKey = dataToSenderPublicKeys(keyData: decodedAttachment) else {
                                print("Unable to get public key from key attachment")
                                return false }
                            
                            guard let thisPenPalKey = thisPenPal.key else {
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
                                
                                return keyCompareSucceeded }
                            
                            guard let timestamp = thisPenPal.keyTimestamp else {
                                print("Unable to find penpal key timestamp.")
                                return keyCompareSucceeded }
                            
                            keyCompareSucceeded = compare(senderKey: timestampedKey.senderPublicKey, andTimestamp: timestampedKey.senderKeyTimestamp, withStoredKey: thisPenPalKey, andTimestamp: timestamp, forPenPal: thisPenPal, andMessageId: messageId)
                        }
                    }
                        //If not check for a key and create a new PenPal
                    else if sender != ""
                    {
                        //Create New PenPal Record
                        if let entity = NSEntityDescription.entity(forEntityName: "PenPal", in: self.managedObjectContext!)
                        {
                            let newPal = PenPal(entity: entity, insertInto: self.managedObjectContext)
                            newPal.email = sender!
                            //                            newPal.key = timestampedKeys.senderPublicKey as NSData?
                            //                            newPal.keyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(timestampedKeys.senderKeyTimestamp))
                            newPal.addedDate = NSDate()
                            newPal.owner = GlobalVars.currentUser
                            
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
                        }
                    }
                }
            }
        }
        
        return keyCompareSucceeded
    }
    
    func compare(recipientKey: Data, andTimestamp timestamp: Int64, withStoredKey recipientStoredKey: Data, andTimestamp storedTimestamp: NSDate, forPenPal thisPenPal: PenPal, andMessageId messageId: String) -> Bool
    {
        guard recipientKey == recipientStoredKey
            else
        {
            let recipientStoredTimestamp = Int64(storedTimestamp.timeIntervalSince1970)
            
            if recipientStoredTimestamp > timestamp
            {
                //Key in the message is older than what the user is currently using
                alertReceivedOutdatedRecipientKey(from: thisPenPal, withMessageId: messageId)
            }
            else if recipientStoredTimestamp < timestamp
            {
                //Key in the message is newer than what we are currently using
                alertReceivedNewerRecipientKey(from: thisPenPal, withMessageId: messageId)
                print("recipientKey: \(recipientKey), andTimestamp \(timestamp), recipientStoredKey: \(recipientStoredKey), storedTimestamp: \(storedTimestamp), forPenPal \(thisPenPal), andMessageId \(messageId)")
            }
            
            return false
        }
        
        return true
    }
    
    func compare(senderKey: Data, andTimestamp timestamp: Int64, withStoredKey senderStoredKey: NSData, andTimestamp storedTimestamp: NSDate, forPenPal thisPenPal: PenPal, andMessageId messageId: String) -> Bool
    {
        //Check to see if the sender's key we received matches what we have stored
        if senderKey == senderStoredKey as Data
        {
            //print("We have the key for \(sender) and it matches the new one we received. Hooray \n")
            return true
        }
        else
        {
            let currentSenderKeyTimestamp = Int64(storedTimestamp.timeIntervalSince1970)
            
            if currentSenderKeyTimestamp > timestamp
            {
                //received key is older
                alertReceivedOutdatedSenderKey(from: thisPenPal, withMessageId: messageId)
            }
            else if currentSenderKeyTimestamp < timestamp
            {
                //received key is newer
                alertReceivedNewerSenderKey(senderPublicKey: senderKey, senderKeyTimestamp: timestamp, from: thisPenPal, withMessageId: messageId)
            }
            
            return false
        }
    }
    
    ///TODO: Approve and localize strings for translation
    func alertReceivedOutdatedSenderKey(from penPal: PenPal, withMessageId messageId: String)
    {
        let oldKeyAlert = NSAlert()
        oldKeyAlert.messageText = "This email cannot be read and will be deleted. It was encrypted using older settings for: \(penPal.email)"
        oldKeyAlert.informativeText = "You should let this contact know that they sent you a message using a previous version of their encryption settings."
        oldKeyAlert.runModal()
        
        trashGmailMessage(withId: messageId)
    }
    
    func alertReceivedNewerSenderKey(senderPublicKey: Data, senderKeyTimestamp: Int64, from penPal: PenPal, withMessageId messageId: String)
    {
        let newKeyAlert = NSAlert()
        newKeyAlert.messageText = "Accept PenPal's new encryption settings?"
        newKeyAlert.informativeText = "It looks like \(penPal.email) reset their encryption. Do you want to accept their new settings? You will no longer be able to read their old messages once you do, but you will be able to read the new ones. If you do not, this message or invite will be deleted."
        newKeyAlert.addButton(withTitle: "No")
        newKeyAlert.addButton(withTitle: "Yes")
        let response = newKeyAlert.runModal()
        
        if response == NSAlertSecondButtonReturn
        {
            //User wants to update penpal key
            penPal.key = senderPublicKey as NSData?
            penPal.keyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(senderKeyTimestamp))
            
            //Save this PenPal to core data
            do
            {
                try penPal.managedObjectContext?.save()
            }
            catch
            {
                let saveError = error as NSError
                print("\(saveError.localizedDescription)")
                showAlert("Warning: We could not save this contact's new encryption settings.\n")
            }
        }
        else if response == NSAlertFirstButtonReturn
        {
            //User has chosen to ignore contact's new key, let's delete it so the user does not keep getting these alerts
            trashGmailMessage(withId: messageId)
        }
    }
    
    func alertReceivedOutdatedRecipientKey(from penPal: PenPal, withMessageId messageId: String)
    {
        let oldKeyAlert = NSAlert()
        oldKeyAlert.messageText = "\(penPal.email) used an older version of your security settings. Send new settings to this contact?"
        oldKeyAlert.informativeText = "A message or invitation was received that uses your old settings. You will not be able to read any new messages they send until they have your current settings, however this message or invitation will be deleted as it cannot be read. Choose 'No' if you have a previous installation of Postcard and you are going to import those settings."
        oldKeyAlert.addButton(withTitle: "No")
        oldKeyAlert.addButton(withTitle: "Yes")
        let response = oldKeyAlert.runModal()
        
        if response == NSAlertSecondButtonReturn
        {
            //User wants to send new key to contact
            KeyController.sharedInstance.sendKey(toPenPal: penPal)
            
            //Delete the message as we will be unable to read it
            trashGmailMessage(withId: messageId)
        }
        else
        {
            //Do not send newer key
            ///Show instructions for importing settings here?
        }
    }
    
    func alertReceivedNewerRecipientKey(from penPal: PenPal, withMessageId messageId: String)
    {
        let newKeyAlert = NSAlert()
        newKeyAlert.messageText = "\(penPal.email) used a newer version of your security settings. Do you want to import these settings to this device?"
        newKeyAlert.informativeText = "You received a message with newer encryption settings than what this installation of Postcard is using. This may be because you installed postcard on a different device. Do you want to import the newer settings from the other installation? Choose 'No' if you want to keep these settings (This message or invitation will be deleted as it cannot be read)."
        newKeyAlert.addButton(withTitle: "No")
        newKeyAlert.addButton(withTitle: "Yes")
        let response = newKeyAlert.runModal()
        
        if response == NSAlertSecondButtonReturn
        {
            //User wants to import settings from other machine
            ///Show instructions for importing settings here?
        }
        else if response == NSAlertFirstButtonReturn
        {
            //User selected No
            //Delete this message as we will be unable to read it
            trashGmailMessage(withId: messageId)
        }
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
                if let thisPenpal = fetchPenPalForCurrentUser(thisRecipient)
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
                                        print("PenPal Key: \(thisPenpal.key)")
                                        
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
            if let thisPenpal = fetchPenPalForCurrentUser(thisRecipient)
            {
                //Make sure we have a key for each recipient
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
    
    //MARK: Create the message
    
    struct PostcardMessage: Packable
    {
        var to: String
        var subject: String
        var body: String
        
        init(to: String, subject: String, body: String)
        {
            self.to = to
            self.subject = subject
            self.body = body
        }
        
        init?(postcardData: Data)
        {
            do
            {
                let unpackResult = try unpack(postcardData)
                let unpackValue: MessagePackValue = unpackResult.value
                self.init(value: unpackValue)
            }
            catch let unpackError as NSError
            {
                print("Unpack postcard data error: \(unpackError.localizedDescription)")
                return nil
            }
        }
        
        func dataValue() -> Data?
        {
            let keyMessagePack = self.messagePackValue()
            return pack(keyMessagePack)
        }
        
        internal init?(value: MessagePackValue)
        {
            guard let keyDictionary = value.dictionaryValue
                else
            {
                print("Postcard Message deserialization error.")
                return nil
            }
            
            //To
            guard let toMessagePack = keyDictionary[.string(messageToKey)]
                else
            {
                print("Postcard message deserialization error: unable to unpack 'to' property.")
                return nil
            }
            
            guard let toString = toMessagePack.stringValue
                else
            {
                print("Postcard message deserialization error: unable to get string value for 'to' property.")
                return nil
            }
            
            //Subject
            guard let subjectMessagePack = keyDictionary[.string(messageSubjectKey)]
                else
            {
                print("Postcard message deserialization error: unable to unpack subject property.")
                return nil
            }
            
            guard let subjectString = subjectMessagePack.stringValue
                else
            {
                print("Postcard message deserialization error: unable to get string value for subject property.")
                return nil
            }
            
            //Message Body
            guard let bodyMessagePack = keyDictionary[.string(messageBodyKey)]
                else
            {
                print("Postcard message deserialization error: unable to unpack body property.")
                return nil
            }
            
            guard let bodyString = bodyMessagePack.stringValue
                else
            {
                print("Postcard message deserialization error: unable to get string value for body property.")
                return nil
            }
            
            self.to = toString
            self.subject = subjectString
            self.body = bodyString
        }
        
        internal func messagePackValue() -> MessagePackValue
        {
            let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
                MessagePackValue(messageToKey): MessagePackValue(self.to),
                MessagePackValue(messageSubjectKey): MessagePackValue(self.subject),
                MessagePackValue(messageBodyKey): MessagePackValue(self.body)
            ]
            
            return MessagePackValue(keyDictionary)
        }
    }
    
    //    func generateMessagePackage(maybeAttachments: [NSURL]?) -> NSData
    //    {
    //        if let attachmentURLs = maybeAttachments where !attachmentURLs.isEmpty
    //        {
    //            for attachmentURL in attachmentURLs
    //            {
    //                if let fileData = NSData(contentsOfURL: attachmentURL)
    //                {
    //                    if let urlString: String = attachmentURL.path
    //                    {
    //                        let urlParts = urlString.componentsSeparatedByString(".")
    //                        let pathParts = urlParts.first?.componentsSeparatedByString("/")
    //                        let fileName = pathParts?.last ?? ""
    //                        let fileExtension = attachmentURL.pathExtension
    //
    //                        var mimeType = ""
    //                        if fileExtension == "jpg"
    //                        {
    //                            mimeType = "image/jpeg"
    //                        }
    //                        else if fileExtension == "png"
    //                        {
    //                            mimeType = "image/png"
    //                        }
    //                        else if fileExtension == "doc"
    //                        {
    //                            mimeType = "application/msword"
    //                        }
    //                        else if fileExtension == "ppt"
    //                        {
    //                            mimeType = "application/vnd.ms-powerpoint"
    //                        }
    //                        else if fileExtension == "html"
    //                        {
    //                            mimeType = "text/html"
    //                        }
    //                        else if fileExtension == "pdf"
    //                        {
    //                            mimeType = "application/pdf"
    //                        }
    //
    //                        if !mimeType.isEmpty
    //                        {
    //                            if let attachment = MCOAttachment(data: fileData, filename: fileName)
    //                            {
    //                                attachment.mimeType = mimeType
    //                            }
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    
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
    
//    //Main Wrapper Message This is what the user will see in any email client
//    func generateMessageMime(forPenPal penPal: PenPal, subject: String, body: String, messageData: Data, maybePackage: Data?) -> String
//    {
//        let messageBuilder = MCOMessageBuilder()
//        messageBuilder.header.to = [MCOAddress(mailbox: penPal.email)]
//        messageBuilder.header.subject = subject
//        messageBuilder.textBody = body
//        
//        //This is the actual user's message as an attachment to the gmail message
//        let messageAttachment = MCOAttachment(data: messageData, filename: "Postcard")
//        messageAttachment?.mimeType = PostCardProps.postcardMimeType
//        messageBuilder.addAttachment(messageAttachment)
//        
//        //Add a key attachment to this message
//        let keyData = generateKeyAttachment(forPenPal: penPal)
//        
//        let keyAttachment = MCOAttachment(data: keyData, filename: "Key")
//        keyAttachment?.mimeType = PostCardProps.keyMimeType
//        messageBuilder.addAttachment(keyAttachment)
//        
//        
//        //        if let packageData = maybePackage
//        //        {
//        //            if let packageAttachment = MCOAttachment(data: packageData, filename: "Postcard")
//        //            {
//        //                packageAttachment.mimeType = PostCardProps.packageMimeType
//        //                messageBuilder.addAttachment(packageAttachment)
//        //            }
//        //        }
//        
//        return dataEncodedToString(messageBuilder.data())
//    }
    
    //Main Wrapper Message This is what the user will see in any email client
    
    func generateMessagePostcard(sendToEmail to: String, subject: String, body: String, withKey key: Data) -> Data?
    {
        print("\nSending an email to: \(to)\nRecipient's Public Key: \(key)")
        
        let postcardMessage = PostcardMessage.init(to: to, subject: subject, body: body)
        if let postcardMessageData = postcardMessage.dataValue()
        {
            if let sodium = Sodium(), let secretKey = KeyController.sharedInstance.myPrivateKey
            {
                if let encryptedMessageData: Data = sodium.box.seal(message: postcardMessageData, recipientPublicKey: key, senderSecretKey: secretKey)
                {
                    return encryptedMessageData
                }
                else
                {
                    //We are not showing alerts for these because there is nothing the user can do about this
                    print("We could not encrypt this message.")
                }
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
            guard let keyAttachmentData = generateSenderPublicKeyAttachment(forPenPal: penPal) else { return nil }
            let emailMessage = EmailMessage.init(to: emailAddress, hasPalKey: false, keyData: keyAttachmentData, postcardData: nil, packageData: nil)
            return emailMessage
        }
        else
        {
            guard let keyAttachmentData = generateKeyAttachment(forPenPal: penPal) else { return nil }
            let emailMessage = EmailMessage.init(to: emailAddress, hasPalKey: true, keyData: keyAttachmentData, postcardData: nil, packageData: nil)
            return emailMessage
        }
    }
    
    //MARK: Key Attachments
    struct VersionedData: Packable
    {
        var version: String
        var serializedData: Data
        
        init(version: String, serializedData: Data)
        {
            self.version = version
            self.serializedData = serializedData
        }
        
        init?(value: MessagePackValue)
        {
            guard let versionDictionary = value.dictionaryValue
                else
            {
                print("Version deserialization error.")
                return nil
            }
            
            //Version
            guard let versionMessagePack = versionDictionary[.string(versionKey)]
                else
            {
                print("Version deserialization error.")
                return nil
            }
            
            guard let versionValue = versionMessagePack.stringValue
                else
            {
                print("Version deserialization error.")
                return nil
            }
            
            //Serialized Data
            guard let dataMessagePack = versionDictionary[.string(serializedDataKey)]
                else
            {
                print("Version deserialization error.")
                return nil
            }
            
            guard let sData = dataMessagePack.dataValue
                else
            {
                print("Version deserialization error.")
                return nil
            }
            
            self.version = versionValue
            self.serializedData = sData
        }
        
        func messagePackValue() -> MessagePackValue
        {
            let versionDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
                MessagePackValue(versionKey): MessagePackValue(version),
                MessagePackValue(serializedDataKey): MessagePackValue(serializedData)
            ]
            
            return MessagePackValue(versionDictionary)
        }
    }
    
    struct TimestampedPublicKeys: Packable
    {
        var senderPublicKey: Data
        var senderKeyTimestamp: Int64
        var recipientPublicKey: Data
        var recipientKeyTimestamp: Int64
        
        init(senderKey: Data, senderKeyTimestamp: Int64, recipientKey: Data, recipientKeyTimestamp: Int64)
        {
            self.senderPublicKey = senderKey
            self.senderKeyTimestamp = senderKeyTimestamp
            self.recipientPublicKey = recipientKey
            self.recipientKeyTimestamp = recipientKeyTimestamp
        }
        
        init?(value: MessagePackValue)
        {
            guard let keyDictionary = value.dictionaryValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Sender Public Key
            guard let senderKeyMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyKey)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let senderPKeyData = senderKeyMessagePack.dataValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Sender Key Timestamp
            guard let senderTimestampMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyTimestampKey)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let senderPKeyTimestamp = senderTimestampMessagePack.integerValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Recipient Public Key
            guard let recipientKeyMessagePack = keyDictionary[.string(keyAttachmentRecipientPublicKeyKey)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let recipientPKeyData = recipientKeyMessagePack.dataValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Recipient Key Timestamp
            guard let recipientTimestampMessagePack = keyDictionary[.string(keyAttachmentRecipientPublicKeyTimestamp)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let recipientPKeyTimestamp = recipientTimestampMessagePack.integerValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            self.senderPublicKey = senderPKeyData
            self.senderKeyTimestamp = senderPKeyTimestamp
            self.recipientPublicKey = recipientPKeyData
            self.recipientKeyTimestamp = recipientPKeyTimestamp
        }
        
        func messagePackValue() -> MessagePackValue
        {
            let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
                MessagePackValue(keyAttachmentSenderPublicKeyKey): MessagePackValue(self.senderPublicKey),
                MessagePackValue(keyAttachmentSenderPublicKeyTimestampKey): MessagePackValue(self.senderKeyTimestamp),
                MessagePackValue(keyAttachmentRecipientPublicKeyKey): MessagePackValue(self.recipientPublicKey),
                MessagePackValue(keyAttachmentRecipientPublicKeyTimestamp): MessagePackValue(self.recipientKeyTimestamp)
            ]
            
            return MessagePackValue(keyDictionary)
        }
    }
    
    struct TimestampedSenderPublicKey: Packable
    {
        var senderPublicKey: Data
        var senderKeyTimestamp: Int64
        
        init(senderKey: Data, senderKeyTimestamp: Int64)
        {
            self.senderPublicKey = senderKey
            self.senderKeyTimestamp = senderKeyTimestamp
        }
        
        init?(value: MessagePackValue)
        {
            guard let keyDictionary = value.dictionaryValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Sender Public Key
            guard let senderKeyMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyKey)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let senderPKeyData = senderKeyMessagePack.dataValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            //Sender Key Timestamp
            guard let senderTimestampMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyTimestampKey)]
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            guard let senderPKeyTimestamp = senderTimestampMessagePack.integerValue
                else
            {
                print("TimestampedPublicKeys deserialization error.")
                return nil
            }
            
            self.senderPublicKey = senderPKeyData
            self.senderKeyTimestamp = senderPKeyTimestamp
        }
        
        func messagePackValue() -> MessagePackValue
        {
            let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
                MessagePackValue(keyAttachmentSenderPublicKeyKey): MessagePackValue(self.senderPublicKey),
                MessagePackValue(keyAttachmentSenderPublicKeyTimestampKey): MessagePackValue(self.senderKeyTimestamp)
            ]
            
            return MessagePackValue(keyDictionary)
        }
    }
    
    func generateKeyAttachment(forPenPal penPal: PenPal) -> Data?
    {
        guard let recipientKey = penPal.key else {
            return nil
        }
        
        guard let senderKey = KeyController.sharedInstance.mySharedKey else {
            return nil
        }
        
        guard let userKeyTimestamp = KeyController.sharedInstance.myKeyTimestamp else {
            return nil
        }
        
        guard let penPalKeyTimestamp = penPal.keyTimestamp else {
            return nil
        }
        
        let senderKeyTimestamp = Int64(userKeyTimestamp.timeIntervalSince1970)
        let recipientKeyTimestamp = Int64(penPalKeyTimestamp.timeIntervalSince1970)
        
        let timestampedKeys = TimestampedPublicKeys.init(senderKey: senderKey,
                                                         senderKeyTimestamp: senderKeyTimestamp,
                                                         recipientKey: recipientKey as Data,
                                                         recipientKeyTimestamp: recipientKeyTimestamp)
        ///TODO: Include Versioned Data
        let keyMessagePack = timestampedKeys.messagePackValue()
        return pack(keyMessagePack)
    }
    
    func generateSenderPublicKeyAttachment(forPenPal penPal: PenPal) -> Data?
    {
        guard let senderKey = KeyController.sharedInstance.mySharedKey else {
            return nil
        }
        
        guard let userKeyTimestamp = KeyController.sharedInstance.myKeyTimestamp else {
            return nil
        }
        
        let senderKeyTimestamp = Int64(userKeyTimestamp.timeIntervalSince1970)
        
        let timestampedKeys = TimestampedSenderPublicKey.init(senderKey: senderKey, senderKeyTimestamp: senderKeyTimestamp)
        
        ///TODO: Include Versioned Data
        let keyMessagePack = timestampedKeys.messagePackValue()
        return pack(keyMessagePack)
    }
    
    func dataToPublicKeys(keyData: Data) -> TimestampedPublicKeys?
    {
        do
        {
            let unpackResult = try unpack(keyData)
            let unpackValue: MessagePackValue = unpackResult.value
            return TimestampedPublicKeys.init(value: unpackValue)
        }
        catch let unpackError as NSError
        {
            print("Unpack error: \(unpackError.localizedDescription)")
            return nil
        }
        
//        let messagePack = MessagePackValue(keyData)
//        guard let versionedData = VersionedData.init(value: messagePack)
//            else
//        {
//            print("could not get versioned data")
//            return nil
//        }
//        
//        guard versionedData.version == keyFormatVersion
//            else
//        {
//            print("Key format versions do not match.")
//            return nil
//        }
//        
//        return TimestampedPublicKeys.init(value: MessagePackValue(versionedData.serializedData))
    }
    
    func dataToSenderPublicKeys(keyData: Data) -> TimestampedSenderPublicKey?
    {
        do
        {
            let unpackResult = try unpack(keyData)
            let unpackValue: MessagePackValue = unpackResult.value
            return TimestampedSenderPublicKey.init(value: unpackValue)
        }
        catch let unpackError as NSError
        {
            print("Unpack error: \(unpackError.localizedDescription)")
            return nil
        }
//        let messagePack = MessagePackValue(keyData)
//        guard let versionedData = VersionedData.init(value: messagePack)
//            else
//        {
//            print("could not get versioned data")
//            return nil
//        }
//        
//        guard versionedData.version == keyFormatVersion
//            else
//        {
//            print("Key format versions do not match.")
//            return nil
//        }
//        
//        return TimestampedSenderPublicKey.init(value: MessagePackValue(versionedData.serializedData))
        
    }
    
    //MARK: Helper Methods
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
    
    //💌//
}

protocol Packable
{
    init?(value: MessagePackValue)
    func messagePackValue() -> MessagePackValue
}
