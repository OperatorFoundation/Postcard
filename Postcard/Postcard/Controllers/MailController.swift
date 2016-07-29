//
//  MailController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GoogleAPIClient
import CoreData
import Sodium

class MailController: NSObject
{
    static let sharedInstance = MailController()
    
    var allPostcards = [GTLGmailMessage]()
    var allPenpals = [PenPal]()
    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext?
    
    private override init()
    {
        super.init()
        managedObjectContext = appDelegate.managedObjectContext
    }
    
    //TODO: Make sure that deleting emails via bindings to the array congtroller also removes them from gmail?
    func trashGmailMessage(thisPostcard: Postcard, completion: (successful: Bool) -> Void)
    {
        let trashQuery = GTLQueryGmail.queryForUsersMessagesTrash()
        trashQuery.identifier = thisPostcard.identifier
        trashQuery.userId = "me"
        
        GmailProps.service.executeQuery(trashQuery)
        { (ticket, maybeResponse, maybeError) in
            if let error = maybeError
            {
                completion(successful: false)
            }
            if let _ = maybeResponse, let managedContext = self.managedObjectContext
            {
                managedContext.deleteObject(thisPostcard)
                do
                {
                    try managedContext.save()
                    completion(successful: true)
                }
                catch
                {
                     completion(successful: false)
                }
            }
        }
    }
    
    func updateMail()
    {
        fetchGmailMessagesList()
        
        //Refresh every few minutes (counted in seconds)
        _ = NSTimer.scheduledTimerWithTimeInterval(150, target: self, selector: (#selector(fetchGmailMessagesList)), userInfo: nil, repeats: true)
    }
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        let query = GTLQueryGmail.queryForUsersMessagesList()
        //query.q = "has:attachment"
        query.labelIds = ["INBOX"]
        
        GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
            if let listMessagesResponse = response as? GTLGmailListMessagesResponse
            {
                //If there are messages that meet the query criteria in the list, get the message payload from Gmail
                if let metaMessages = listMessagesResponse.messages as? [GTLGmailMessage]
                {
                    //Get message payloads
                    self.fetchAndSaveGmailPayloads(metaMessages)
                }
            }
        })
    }
    
    func fetchAndSaveGmailPayloads(messages: [GTLGmailMessage])
    {
        let query = GTLQueryGmail.queryForUsersMessagesGet()
        
        //Get the payload for each metaMessage returned from the list request
        //Only Download messages that have new ids
        for messageMeta in messages where messageAlreadySaved(messageMeta.identifier) == false
        {
            query.identifier = messageMeta.identifier
            query.fields = "payload"
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, maybeMessage, error) in
                if let message = maybeMessage as? GTLGmailMessage, parts = message.payload.parts as? [GTLGmailMessagePart]
                {
                    //This is a key/penpal invitation
                    for thisPart in parts where thisPart.mimeType == PostCardProps.keyMimeType
                    {
                        //Download the attachment
                        let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                        attachmentQuery.identifier = thisPart.body.attachmentId
                        attachmentQuery.messageId = messageMeta.identifier
                        
                        GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                            if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                            {
                                self.processPenPalKeyAttachment(attachment, forMessage: message)
                            }
                        })
                    }

                    if let headers = message.payload.headers as? [GTLGmailMessagePartHeader]
                    {
                        var sender = ""
                        for header in headers where header.name == "From"
                        {
                            sender = header.value
                        }
                        
                        if !sender.isEmpty
                        {
                            //This is a postcard message/attachment
                            for thisPart in parts where thisPart.mimeType == PostCardProps.postcardMimeType
                            {
                                //Download the attachment that is a Postcard
                                let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                                attachmentQuery.identifier = thisPart.body.attachmentId
                                attachmentQuery.messageId = messageMeta.identifier
                                GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                                    if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                                    {
                                        //Do we have this person saved as a PenPal?
                                        if let thisPenPal = PenPalController.sharedInstance.fetchPenPal(sender)
                                        {
                                            let attachmentString = attachment.data
                                            
                                            //Decode - GTLBase64
                                            if let postcardData = self.stringDecodedToData(attachmentString)
                                            {
                                                //CoreData
                                                if let entity = NSEntityDescription.entityForName("Postcard", inManagedObjectContext: self.managedObjectContext!)
                                                {
                                                    //Create New Postcard Record
                                                    let newCard = Postcard(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
                                                    
                                                    newCard.owner = GlobalVars.currentUser
                                                    newCard.from = thisPenPal
                                                    newCard.cipherText = postcardData
                                                    newCard.identifier = messageMeta.identifier
                                                    
                                                    for dateHeader in headers where dateHeader.name == "Date"
                                                    {
                                                        let formatter = NSDateFormatter()
                                                        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                                                        if let receivedDate = formatter.dateFromString(dateHeader.value)
                                                        {
                                                            newCard.receivedDate = receivedDate.timeIntervalSinceReferenceDate
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
                                                        print("\(saveError)")
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
                                            self.showAlert("We did not decrypt a message sent from \(sender) because this person is not saved as a contact.")
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            })
        }
    }
    
    func decryptPostcard(postcard: Postcard)
    {
        //Decrypt - Sodium
        let keyController = KeyController.sharedInstance
        if let sodium = Sodium()
        {
            if let secretKey = keyController.myPrivateKey
            {
                if let penPal = postcard.from, let penPalKey = penPal.key
                {
                    if let cipherText = postcard.cipherText
                    {
                        if let decryptedPostcard = sodium.box.open(cipherText, senderPublicKey: penPalKey, recipientSecretKey: secretKey)
                        {
                            //Parse this message
                            self.parseDecryptedMessageAndSave(decryptedPostcard, saveToPostcard: postcard)
                        }
                        else
                        {
                            showAlert("Final step for decryption failed for message from \(penPal.email).")
                            print("\nFailed to decrypt message:\n")
                            print("Sender Key: \(penPalKey)\n")
                            print("My public key: \(keyController.mySharedKey)")
                            print("Secret Key: \(secretKey)\n")
                        }
                    }
                    else
                    {
                        showAlert("We could not decrypt this postcard!! We cannot find the cipher text from \(penPal.email).\n")
                    }
                }
                else
                {
                    showAlert("We were unable to decrypt a message: We don't have the key. :(")
                }
            }
            else
            {
                showAlert("We were unable to decrypt your emails: we don't have your key. :(")
            }
        }
        else
        {
            print("\nUnable to decrypt message: could not initialize Sodium. That's weird.\n")
        }
    }
    
    private func parseDecryptedMessageAndSave(data: NSData, saveToPostcard postcard: Postcard)
    {
        //Parse this message into usable parts
        let messageParser = MCOMessageParser(data: data)
        
        //Body
        if let mainPart = messageParser.mainPart() as? MCOAbstractMultipart
        {
            let firstPart = mainPart.parts[0]
            let body = firstPart.decodedString()
            postcard.body = body
        }
        
        let subject = messageParser.header.subject
        postcard.subject = subject
        postcard.decrypted = true
        let deliveredTo = messageParser.header.to
        postcard.to = deliveredTo.first?.email
        
        //Snippet?
        //Attachment?
        let attachments = messageParser.attachments()
        
        if attachments.isEmpty
        {
            postcard.hasPackage = false
        }
        else
        {
            //TODO: ignore key attachments
            postcard.hasPackage = true
        }
        
        //Save these changes to core data
        do
        {
            try postcard.managedObjectContext?.save()
        }
        catch
        {
            let saveError = error as NSError
            print("\(saveError)")
        }
    }
    
    func removeDecryptedPostcardData(postcard: Postcard)
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
            print("\(saveError)")
        }
    }
    
    func removeAllDecryptionForUser(lockdownUser: User)
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
    
    func dataEncodedToString(data: NSData) -> String
    {
        let newString = GTLEncodeWebSafeBase64(data)
        
        return newString
    }
    
    func stringDecodedToData(string: String) -> NSData?
    {
        if let newData = GTLDecodeWebSafeBase64(string)
        {
            return newData
        }
        else {return nil}
    }
    
    func fetchPenPalForCurrentUser(emailAddress: String) -> PenPal?
    {
        //Make sure we have a current user
        if let currentUser = GlobalVars.currentUser
        {
            let fetchRequest = NSFetchRequest(entityName: "PenPal")
            //Check for a penpal with this email address AND this current user as owner
            fetchRequest.predicate = NSPredicate(format: "email == %@ AND owner == %@", emailAddress, currentUser)
            do
            {
                let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
                if result?.count > 0, let thisPenpal = result?[0] as? PenPal
                {
                    return thisPenpal
                }
            }
            catch
            {
                //Could not fetch this Penpal from core data
                let fetchError = error as NSError
                print(fetchError)
                
                return nil
            }
        }
        
        return nil
    }
    
    //MARK: Process Different Message Types
    
    //Check if the downloaded attachment is valid and save the information as a new penpal to core data
    func processPenPalKeyAttachment(attachment: GTLGmailMessagePartBody, forMessage message: GTLGmailMessage)
    {
        //Check the headers for the message sender
        if let headers = message.payload.headers as? [GTLGmailMessagePartHeader]
        {
            for header in headers
            {
                if header.name == "From"
                {
                    let sender = header.value
                    let attachmentDataString = attachment.data
                    let decodedAttachment = stringDecodedToData(attachmentDataString)
                    //let decodedAttachment = GTLDecodeBase64(attachmentDataString)
                    
                    //Check if we have this email address saved as a penpal
                    if let thisPenPal = self.fetchPenPalForCurrentUser(sender)
                    {
                        if let thisPenPalKey = thisPenPal.key
                        {
                            if thisPenPalKey == decodedAttachment
                            {
                                //print("We have the key for \(sender) and it matches the new one we received. Hooray \n")
                            }
                            else
                            {
                                showAlert("We received a new key:\n \(decodedAttachment?.description)\n and it does not match the key we have stored:\n \(thisPenPal.key?.description).")
//                                
//                                //TODO: Saving the new Key instead....?
//                                thisPenPal.key = decodedAttachment
//                                //Save this PenPal to core data
//                                do
//                                {
//                                    try thisPenPal.managedObjectContext?.save()
//                                }
//                                catch
//                                {
//                                    let saveError = error as NSError
//                                    print("\(saveError), \(saveError.userInfo)")
//                                    self.showAlert("Warning: We could not save this contacts key.\n")
//                                }
                            }
                        }
                        else
                        {
                            //This Penpal didn't have a key stored, save the received key
                            thisPenPal.key = decodedAttachment
                            
                            //Save this PenPal to core data
                            do
                            {
                                try thisPenPal.managedObjectContext?.save()
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print("\(saveError), \(saveError.userInfo)")
                                self.showAlert("Warning: We could not save this contacts key.\n")
                            }
                        }
                    }
                    //If not check for a key and create a new PenPal
                    else if sender != ""
                    {
                        //Create New PenPal Record
                        if let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: self.managedObjectContext!)
                        {
                            let newPal = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
                            newPal.email = sender
                            newPal.key = decodedAttachment
                            newPal.addedDate = NSDate().timeIntervalSinceReferenceDate
                            newPal.owner = GlobalVars.currentUser
                            
                            //Save this PenPal to core data
                            do
                            {
                                try newPal.managedObjectContext?.save()
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print("\(saveError), \(saveError.userInfo)")
                                self.showAlert("Warning: We could not save this contact.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func messageAlreadySaved(identifier: String) -> Bool
    {
        let fetchRequest = NSFetchRequest(entityName: "Postcard")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        do
        {
            let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
            if result?.count > 0
            {
                return true
            }
        }
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        return false
    }
    
    func sendEmail(to: String, subject: String, body: String, maybeAttachments:[NSURL]?, completion: (successful: Bool) -> Void)
    {
        if let rawMessage = generateMessage(sendToEmail: to, subject: subject, body: body, maybeAttachments: maybeAttachments)
        {
            let gmailMessage = GTLGmailMessage()
            gmailMessage.raw = rawMessage
            
            let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
            query.message = gmailMessage
            
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
                print("\nSent an email to : \(to)")
                print("send email response: \(response)")
                print("send email error: \(error)")
                if let response = response as? GTLGmailMessage
                {
                    print(response.labelIds.description)
                }
                if error == nil
                {
                    completion(successful: true)
                    return
                }
            })
        }

        completion(successful: false)
    }
    
    //MARK: Create the message
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
    
    func generateMessage(sendToEmail to: String, subject: String, body: String, maybeAttachments: [NSURL]?) -> String?
    {
        //This is the actual User's Message
        if let messageData = generateMessagePostcard(sendToEmail: to, subject: subject, body: body)
        {
            //TODO: This will call generateMessagePackage for user's attachments
            let packageData:NSData? = nil

            //This is the postcard wrapper email
            let mimeMessageString = generateMessageMime(sendToEmail: to, subject: PostCardProps.subject, body: PostCardProps.body, messageData: messageData, maybePackage: packageData)
            
            return mimeMessageString
        }
        else
        {
            return nil
        }
    }
    
    //Main Wrapper Message This is what the user will see in any email client
    func generateMessageMime(sendToEmail to: String, subject: String, body: String, messageData: NSData, maybePackage: NSData?) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.to = [MCOAddress(mailbox: to)]
        messageBuilder.header.subject = subject
        messageBuilder.textBody = body
        
        //This is the actual user's message as an attachment to the gmail message
        let messageAttachment = MCOAttachment(data: messageData, filename: "Postcard")
        messageAttachment.mimeType = PostCardProps.postcardMimeType
        messageBuilder.addAttachment(messageAttachment)
        
        //Add a key attachment to this message
        let keyData = generateKeyAttachment()
        
        let keyAttachment = MCOAttachment(data: keyData, filename: "Key")
        keyAttachment.mimeType = PostCardProps.keyMimeType
        messageBuilder.addAttachment(keyAttachment)
        
        
//        if let packageData = maybePackage
//        {
//            if let packageAttachment = MCOAttachment(data: packageData, filename: "Postcard")
//            {
//                packageAttachment.mimeType = PostCardProps.packageMimeType
//                messageBuilder.addAttachment(packageAttachment)
//            }
//        }
        
        return dataEncodedToString(messageBuilder.data())
//        return GTLEncodeWebSafeBase64(messageBuilder.data())
    }
    
    func generateMessagePostcard(sendToEmail to: String, subject: String, body: String) -> NSData?
    {
            if let thisPenpal = fetchPenPalForCurrentUser(to)
            {
                if let penPalKey = thisPenpal.key
                {
                    print("\nSending an email to: \(to)\nRecipient's Public Key: \(penPalKey)")
                    
                    let messageBuilder = MCOMessageBuilder()
                    messageBuilder.header.to = [MCOAddress(mailbox: to)]
                    messageBuilder.header.subject = subject
                    messageBuilder.textBody = body
                    
                    let keyAttachment = MCOAttachment(data: KeyController.sharedInstance.mySharedKey, filename: "postcard.key")
                    messageBuilder.addAttachment(keyAttachment)
                    
                    if let sodium = Sodium(), let secretKey = KeyController.sharedInstance.myPrivateKey
                    {
                        if let encryptedMessageData: NSData = sodium.box.seal(messageBuilder.data(), recipientPublicKey:penPalKey, senderSecretKey: secretKey)
                        {
                            return encryptedMessageData
                        }
                        else
                        {
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
                    showAlert("You cannot send a Postcard to \(to) because you do not have their key! :(")
                }
            }
            else
            {
                showAlert("You cannot send a postcard to this person, they are not in your contacts yet.")
            }
        
        return nil
    }
    
    func generatePostcardAttachment() -> NSData
    {
        let textBody = "If you can read this, you have my key."
        return textBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    func generateKeyMessage(emailAddress: String) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.to = [MCOAddress(mailbox: emailAddress)]
        messageBuilder.header.subject = PostCardProps.subject
        messageBuilder.textBody = PostCardProps.body
        
        //Generate the main Postcard Attachment.
        if let postcardWrapperAttachment = MCOAttachment(data: generateKeyAttachment(), filename: "Postcard")
        {
            postcardWrapperAttachment.mimeType = PostCardProps.keyMimeType
            messageBuilder.addAttachment(postcardWrapperAttachment)
        }
        
        return dataEncodedToString(messageBuilder.data())
    }
    
    func generateKeyAttachment() -> NSData?
    {
        let keyData = KeyController.sharedInstance.mySharedKey
        return keyData
    }
    
    //MARK: Helper Methods
    func showAlert(message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
}
