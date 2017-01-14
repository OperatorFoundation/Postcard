//
//  MailController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
//import GoogleAPIClient
import GoogleAPIClientForREST
import CoreData
import Sodium
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
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
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MailController: NSObject
{
    static let sharedInstance = MailController()
    
    var allPostcards = [GTLRGmail_Message]()
    //var allPostcards = [GTLGmailMessage]()
    var allPenpals = [PenPal]()
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    let gmailUserId = "me"
    var managedObjectContext: NSManagedObjectContext?
    
    fileprivate override init()
    {
        super.init()
        managedObjectContext = appDelegate.managedObjectContext
    }
    
    //TODO: Make sure that deleting emails via bindings to the array congtroller also removes them from gmail?
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
                    print(error)
                }
                if let _ = maybeResponse, let managedContext = self.managedObjectContext
                {
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
        
        //let trashQuery = GTLQueryGmail.queryForUsersMessagesTrash()
        //trashQuery?.identifier = thisPostcard.identifier
        //trashQuery?.userId = "me"
//
//        GmailProps.service.executeQuery(trashQuery!)
//        { (ticket, maybeResponse, maybeError) in
//            if let error = maybeError
//            {
//                completion(false)
//                print(error)
//            }
//            if let _ = maybeResponse, let managedContext = self.managedObjectContext
//            {
//                managedContext.delete(thisPostcard)
//                do
//                {
//                    try managedContext.save()
//                    completion(true)
//                }
//                catch
//                {
//                     completion(false)
//                }
//            }
//        }
    }
    
    func updateMail()
    {
        fetchGmailMessagesList()
        
        //Refresh every few minutes (counted in seconds)
        _ = Timer.scheduledTimer(timeInterval: 150, target: self, selector: (#selector(fetchGmailMessagesList)), userInfo: nil, repeats: true)
    }
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        let userMessagesListQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: gmailUserId)
        userMessagesListQuery.labelIds = ["INBOX"]
        //query.q = "has:attachment"
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
//        
//        let query = GTLQueryGmail.queryForUsersMessagesList()
//        //query.q = "has:attachment"
//        query?.labelIds = ["INBOX"]
//        
//        GmailProps.service.executeQuery(query!, completionHandler: {(ticket, response, error) in
//            if let listMessagesResponse = response as? GTLGmailListMessagesResponse
//            {
//                //If there are messages that meet the query criteria in the list, get the message payload from Gmail
//                if let metaMessages = listMessagesResponse.messages as? [GTLGmailMessage]
//                {
//                    //Get message payloads
//                    self.fetchAndSaveGmailPayloads(metaMessages)
//                }
//            }
//        })
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
                            //This is a key/penpal invitation
                            for thisPart in parts where thisPart.mimeType == PostCardProps.keyMimeType
                            {
                                //Download the attachment
                                if let messageBody = thisPart.body, let attachmentId = messageBody.attachmentId
                                {
                                    let attachmentQuery = GTLRGmailQuery_UsersMessagesAttachmentsGet.query(withUserId: self.gmailUserId, messageId: messageIdentifier, identifier: attachmentId)
                                    GmailProps.service.executeQuery(attachmentQuery, completionHandler:
                                    {
                                        (ticket, maybeAttachment, maybeError) in
                                        
                                        if let attachment = maybeAttachment as? GTLRGmail_MessagePartBody
                                        {
                                            self.processPenPalKeyAttachment(attachment, forMessage: message)
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
                                                        
                                                        //Decode - GTLBase64
                                                        if let postcardData = self.stringDecodedToData(attachmentString!)
                                                        {
                                                            //CoreData
                                                            if let entity = NSEntityDescription.entity(forEntityName: "Postcard", in: self.managedObjectContext!)
                                                            {
                                                                //Create New Postcard Record
                                                                let newCard = Postcard(entity: entity, insertInto: self.managedObjectContext)
                                                                
                                                                newCard.owner = GlobalVars.currentUser
                                                                newCard.from = thisPenPal
                                                                newCard.cipherText = postcardData
                                                                newCard.identifier = messageMeta.identifier
                                                                
                                                                for dateHeader in headers where dateHeader.name == "Date"
                                                                {
                                                                    let formatter = DateFormatter()
                                                                    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                                                                    if let headerDate = dateHeader.value, let receivedDate = formatter.date(from: headerDate)
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
                if let penPal = postcard.from, let penPalKey = penPal.key, let penPalEMail = penPal.email
                {
                    if let cipherText = postcard.cipherText
                    {
                        if let decryptedPostcard = sodium.box.open(nonceAndAuthenticatedCipherText: cipherText, senderPublicKey: penPalKey, recipientSecretKey: secretKey)
                        {
                            //Parse this message
                            self.parseDecryptedMessageAndSave(decryptedPostcard, saveToPostcard: postcard)
                        }
                        else
                        {
                            showAlert(String(format: localizedWrongKeyError, penPalEMail))
                            print("\nFailed to decrypt message:\n")
                            print("Sender Key: \(penPalKey)\n")
                            print("My public key: \(keyController.mySharedKey)")
                            print("Secret Key: \(secretKey)\n")
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
        let messageParser = MCOMessageParser(data: data)
        
        //Body
        if let mainPart = messageParser?.mainPart() as? MCOAbstractMultipart
        {
            let firstPart = mainPart.parts[0]
            let body = (firstPart as AnyObject).decodedString()
            postcard.body = body
        }
        
        let subject = messageParser?.header.subject
        postcard.subject = subject
        postcard.decrypted = true
        let deliveredTo = messageParser?.header.to
        postcard.to = (deliveredTo?.first as AnyObject).email
        
        //Snippet?
        //Attachment?
        let attachments = messageParser?.attachments()
        
        if (attachments?.isEmpty)!
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
            print("\(saveError)")
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
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PenPal")
            //Check for a penpal with this email address AND this current user as owner
            fetchRequest.predicate = NSPredicate(format: "email == %@ AND owner == %@", emailAddress, currentUser)
            do
            {
                let result = try self.managedObjectContext?.fetch(fetchRequest)
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
    func processPenPalKeyAttachment(_ attachment: GTLRGmail_MessagePartBody, forMessage message: GTLRGmail_Message)
    {
        //Check the headers for the message sender
        if let messagePayload = message.payload, let headers: [GTLRGmail_MessagePartHeader] = messagePayload.headers
        {
            for header in headers
            {
                if header.name == "From"
                {
                    let sender = header.value
                    let attachmentDataString = attachment.data
                    let decodedAttachment = stringDecodedToData(attachmentDataString!)
                    //let decodedAttachment = GTLDecodeBase64(attachmentDataString)
                    
                    //Check if we have this email address saved as a penpal
                    if let thisPenPal = self.fetchPenPalForCurrentUser(sender!)
                    {
                        if let thisPenPalKey = thisPenPal.key
                        {
                            if thisPenPalKey as Data == decodedAttachment!
                            {
                                //print("We have the key for \(sender) and it matches the new one we received. Hooray \n")
                            }
                            else
                            {
                                
                                //TODO: Allow user to reset a contact that is having key issues
                                //showAlert(String(format: localizedDifferentKeyError, sender))
                                
                                print("We received a new key:\n \(decodedAttachment?.description)\n and it does not match the key we have stored:\n \(thisPenPal.key?.description).")
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
                                //self.showAlert(String(format: localizedSavePenPalKeyError, sender))
                            }
                        }
                    }
                    //If not check for a key and create a new PenPal
                    else if sender != ""
                    {
                        //Create New PenPal Record
                        if let entity = NSEntityDescription.entity(forEntityName: "PenPal", in: self.managedObjectContext!)
                        {
                            let newPal = PenPal(entity: entity, insertInto: self.managedObjectContext)
                            newPal.email = sender
                            newPal.key = decodedAttachment
                            newPal.addedDate = Date().timeIntervalSinceReferenceDate
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
                                //self.showAlert(String(format: localizedSavePenPalError, sender))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func messageAlreadySaved(_ identifier: String) -> Bool
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Postcard")
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
            print(fetchError)
        }
        
        return false
    }
    
    func sendEmail(_ to: String, subject: String, body: String, maybeAttachments:[URL]?, completion: @escaping (_ successful: Bool) -> Void)
    {
        if let rawMessage = generateMessage(sendToEmail: to, subject: subject, body: body, maybeAttachments: maybeAttachments)
        {
            let gmailMessage = GTLRGmail_Message()
            gmailMessage.raw = rawMessage
            
            let sendGmailQuery = GTLRGmailQuery_UsersMessagesSend.query(withObject: gmailMessage, userId: gmailUserId, uploadParameters: nil)

            
            GmailProps.service.executeQuery(sendGmailQuery, completionHandler: {(ticket, maybeResponse, maybeError) in
                print("\nSent an email to : \(to)")
                print("send email response: \(maybeResponse)")
                print("send email error: \(maybeError)")
                if let response = maybeResponse as? GTLRGmail_Message, let labelIds = response.labelIds
                {
                    print(labelIds.description)
                }
                if maybeError == nil
                {
                    completion(true)
                    return
                }
            })
        }

        completion(false)
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
    
    func generateMessage(sendToEmail to: String, subject: String, body: String, maybeAttachments: [URL]?) -> String?
    {
        //This is the actual User's Message
        if let messageData = generateMessagePostcard(sendToEmail: to, subject: subject, body: body)
        {
            //TODO: This will call generateMessagePackage for user's attachments
            let packageData:Data? = nil

            //This is the postcard wrapper email
            let mimeMessageString = generateMessageMime(sendToEmail: to, subject: localizedGenericSubject, body: localizedGenericBody, messageData: messageData, maybePackage: packageData)
            
            return mimeMessageString
        }
        else
        {
            return nil
        }
    }
    
    //Main Wrapper Message This is what the user will see in any email client
    func generateMessageMime(sendToEmail to: String, subject: String, body: String, messageData: Data, maybePackage: Data?) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.to = [MCOAddress(mailbox: to)]
        messageBuilder.header.subject = subject
        messageBuilder.textBody = body
        
        //This is the actual user's message as an attachment to the gmail message
        let messageAttachment = MCOAttachment(data: messageData, filename: "Postcard")
        messageAttachment?.mimeType = PostCardProps.postcardMimeType
        messageBuilder.addAttachment(messageAttachment)
        
        //Add a key attachment to this message
        let keyData = generateKeyAttachment()
        
        let keyAttachment = MCOAttachment(data: keyData, filename: "Key")
        keyAttachment?.mimeType = PostCardProps.keyMimeType
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
    
    func generateMessagePostcard(sendToEmail to: String, subject: String, body: String) -> Data?
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
                    
                    let keyAttachment = MCOAttachment(data: KeyController.sharedInstance.mySharedKey as Data!, filename: "postcard.key")
                    messageBuilder.addAttachment(keyAttachment)
                    
                    if let sodium = Sodium(), let secretKey = KeyController.sharedInstance.myPrivateKey
                    {
                        if let encryptedMessageData: Data = sodium.box.seal(message: messageBuilder.data(), recipientPublicKey: penPalKey, senderSecretKey: secretKey)
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
                    showAlert(String(format: localizedSendErrorNoKey, to))
                }
            }
            else
            {
                showAlert(String(format: localizedSendErrorNotAContact, to))
            }
        
        return nil
    }
    
    func generatePostcardAttachment() -> Data
    {
        let textBody = localizedInviteFiller
        return textBody.data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }
    
    func generateKeyMessage(_ emailAddress: String) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.to = [MCOAddress(mailbox: emailAddress)]
        messageBuilder.header.subject = localizedGenericSubject
        messageBuilder.textBody = localizedGenericBody
        
        //Generate the main Postcard Attachment.
        if let postcardWrapperAttachment = MCOAttachment(data: generateKeyAttachment(), filename: "Postcard")
        {
            postcardWrapperAttachment.mimeType = PostCardProps.keyMimeType
            messageBuilder.addAttachment(postcardWrapperAttachment)
        }
        
        return dataEncodedToString(messageBuilder.data())
    }
    
    func generateKeyAttachment() -> Data?
    {
        let keyData = KeyController.sharedInstance.mySharedKey
        return keyData as Data?
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
