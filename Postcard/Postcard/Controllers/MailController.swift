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
    
    //TODO: Make sure that deleting emails via bindings to the array congtroller also removes them from  gmail
    
    func updateMail()
    {
        fetchGmailMessagesList()
        
        //Refresh every few minutes (counted in seconds)
        _ = NSTimer.scheduledTimerWithTimeInterval(150, target: self, selector: (#selector(fetchGmailMessagesList)), userInfo: nil, repeats: true)
    }
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        //TESTING ONLY
        //makeMeSomeFriends()
        //sendKey("looklita@gmail.com")
        
        let query = GTLQueryGmail.queryForUsersMessagesList()
        //query.q = "Subject:Postcard has:attachment"
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
        for messageMeta in messages 
        {
            query.identifier = messageMeta.identifier
            query.fields = "payload"
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, maybeMessage, error) in
                //Save each message
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
                    
                    //Debug: Print info about this message
                    //print("PAYLOAD: " + message.payload.description + "\n")
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
                                //Download the attachment
                                let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                                attachmentQuery.identifier = thisPart.body.attachmentId
                                attachmentQuery.messageId = messageMeta.identifier
                                GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                                    if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                                    {
                                        //We already have this Penpal and their key
                                        if let thisPenPal = self.fetchPenPal(sender), let penPalKey = thisPenPal.key
                                        {
                                            let attachmentString = attachment.data
                                            //Decode - GTLBase64
                                            //if let postcardData = GTLDecodeWebSafeBase64(attachmentString)
                                            if let postcardData = self.stringDecodedToData(attachmentString)
                                            {
                                                //Decrypt - Sodium
                                                if let sodium = Sodium(), let secretKey = KeyController.sharedInstance.myPrivateKey
                                                {
                                                    print("Attempting to decrypt a postcard:\n")
                                                    print("Sender's Public Key: \(self.dataEncodedToString(penPalKey)))\n")
                                                    print("Recipient's Secret Key: \(self.dataEncodedToString(secretKey))\n")
                                                    print("Recipient's Public Key: \(self.dataEncodedToString(KeyController.sharedInstance.mySharedKey!))\n")
                                                    
                                                    print("Postcard Data:\n")
                                                    print("\(self.dataEncodedToString(postcardData))\n")
                                                    
                                                    if let decryptedPostcard = sodium.box.open(postcardData, senderPublicKey: penPalKey, recipientSecretKey: secretKey)
                                                    {
                                                        print("UTF8 Decoded & Decrypted: \n \(String(data: decryptedPostcard, encoding: NSUTF8StringEncoding))")
                                                        //Save to CoreData so it will Display
                                                    }
                                                    else
                                                    {
                                                        print("We could not decrypt this postcard!! We may not have the correct key for \(sender)\n")
                                                    }
                                                }
                                            }
                                        }
                                        else
                                        {
                                            print("We could not convert the raw string to data. Failed to decode the message from \(sender).\n")
                                            print("Attachment String: \(attachment.data)\n")
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
        if let currentUser = Constants.currentUser
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
    
    func fetchPenPal(emailAddress: String) -> PenPal?
    {
        let fetchRequest = NSFetchRequest(entityName: "PenPal")
        //Check for a penpal with this email address AND this current user as owner
        fetchRequest.predicate = NSPredicate(format: "email == %@", emailAddress)
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
                                print("We have the key for \(sender) and it matches the new one we received. Hooray \n")
                            }
                            else
                            {
                                //TODO: Saving the new Key instead....?
                                thisPenPal.key = decodedAttachment
                                //Save this PenPal to core data
                                do
                                {
                                    try thisPenPal.managedObjectContext?.save()
                                    print("New PenPal Key Saved.\n")
                                }
                                catch
                                {
                                    let saveError = error as NSError
                                    print("\(saveError), \(saveError.userInfo)")
                                    self.showAlert("Warning: We could not save this contacts key.\n")
                                }
                                showAlert("We received a new key from \(sender) and it does not match the key we have stored. This is a problem. For now we have decided to save the new key.\n")
                                
                            }
                        }
                        else
                        {
                            //This Penpal didn't have a key stored, save the receved key
                            thisPenPal.key = decodedAttachment
                            
                            //Save this PenPal to core data
                            do
                            {
                                try thisPenPal.managedObjectContext?.save()
                                print("New PenPal Key Saved.\n")
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print("\(saveError), \(saveError.userInfo)")
                                self.showAlert("Warning: We could not save this contacts key.\n")
                            }
                        }
                        
//                        if thisPenPal.key != nil
//                        {
//                            //We have a key for this PenPal
//                            return
//                        }
//                        else
//                        {
//                            //We have this pal but not a key
//                            //Update the record
//                            thisPenPal.key = decodedAttachment
//                            //Save this PenPal to core data
//                            do
//                            {
//                                try thisPenPal.managedObjectContext?.save()
//                                print("NewPal Saved.\n")
//                            }
//                            catch
//                            {
//                                let saveError = error as NSError
//                                print("\(saveError), \(saveError.userInfo)")
//                                self.showAlert("Warning: We could not save this contact.")
//                            }
//                        }
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
                            newPal.owner = Constants.currentUser
                            
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

    //DEV ONLY: create contacts
    func makeMeSomeFriends()
    {
        //Create New PenPal record
        
        if let managedObjectContext = self.managedObjectContext, let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: managedObjectContext)
        {
//            let newPal = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
//            newPal.email = "brandon@operatorFoundation.org"
//            newPal.name = "Brandon Wiley"
//            newPal.owner = Constants.currentUser
//            
//            //Save this PenPal to core data
//            do
//            {
//                try newPal.managedObjectContext?.save()
//            }
//            catch
//            {
//                let saveError = error as NSError
//                print("\(saveError)")
//            }
//            
//            let newPal2 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
//            newPal2.email = "corie@operatorFoundation.org"
//            newPal2.name = "Corie Johnson"
//            newPal2.owner = Constants.currentUser
//            
//            //Save this PenPal to core data
//            do
//            {
//                try newPal2.managedObjectContext?.save()
//            }
//            catch
//            {
//                let saveError = error as NSError
//                print("\(saveError)")
//            }
//            
//            let newPal3 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
//            newPal3.email = "litaDev@gmail.com"
//            newPal3.name = "Lita Schule"
//            newPal3.owner = Constants.currentUser
//            
//            //Save this PenPal to core data
//            do
//            {
//                try newPal3.managedObjectContext?.save()
//            }
//            catch
//            {
//                let saveError = error as NSError
//                print("\(saveError)")
//            }
            
//            let newPal4 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
//            newPal4.email = "looklita@gmail.com"
//            newPal4.name = "Lita Consuelo"
//            newPal4.owner = Constants.currentUser
//            
//            //Save this PenPal to core data
//            do
//            {
//                try newPal4.managedObjectContext?.save()
//                //print("NewCard From:" + (newCard.from?.email)! + "\n")
//            }
//            catch
//            {
//                let saveError = error as NSError
//                print("\(saveError)")
//            }
            
            let newPal4 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal4.email = "adelita.schule@gmail.com"
            newPal4.name = "Adelita Schule"
            newPal4.owner = Constants.currentUser
            
            //Save this PenPal to core data
            do
            {
                try newPal4.managedObjectContext?.save()
            }
            catch
            {
                let saveError = error as NSError
                print("\(saveError)")
            }
            
        }
    }
    
    //TODO: This message is exactly the same as above
    func processPostcard(message: GTLGmailMessage)
    {
        //Check the headers for the message sender
        if let headers = message.payload.headers as? [GTLGmailMessagePartHeader]
        {
            //Get the Penpal record to create the sender relationship for this Postcard
            if let entity = NSEntityDescription.entityForName("Postcard", inManagedObjectContext: self.managedObjectContext!)
            {
                //Create New Postcard Record
                let newCard = Postcard(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
                
                //Postcard Sender/Penpal
                var sender = ""
                for header in headers where header.name == "From"
                {
                    sender = header.value
                }
                
                let fetchRequest = NSFetchRequest(entityName: "PenPal")
                fetchRequest.predicate = NSPredicate(format: "email == %@", sender)
                do
                {
                    let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
                    if result?.count > 0, let thisPenpal = result?[0] as? PenPal
                    {
                        newCard.from = thisPenpal
                    }
                }
                catch
                {
                    //Could not fetch this Penpal from core data
                    let fetchError = error as NSError
                    print(fetchError)
                }
                
                //Message Body
                for thisPart in message.payload.parts
                {
                    if let thisPart = thisPart as? GTLGmailMessagePart
                    {
                        if thisPart.mimeType == "text/plain"
                        {
                            //if let bodyData = GTLDecodeBase64(thisPart.body.data), let bodyText = String(data: bodyData, encoding: NSUTF8StringEncoding)
                            if let bodyData = stringDecodedToData(thisPart.body.data), let bodyText = String(data: bodyData, encoding: NSUTF8StringEncoding)
                            {
                                newCard.body = bodyText
                            }
                        }
                    }
                }
                
                //Message Snippet
                newCard.snippet = message.snippet
                
                //Date
                for dateHeader in headers where dateHeader.name == "Date"
                {
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                    if let receivedDate = formatter.dateFromString(dateHeader.value)
                    {
                        newCard.receivedDate = receivedDate.timeIntervalSinceReferenceDate
                    }
                }
                
                //Subject
                for subjectHeader in headers where subjectHeader.name == "Subject"
                {
                    newCard.subject = subjectHeader.value
                }
                
                //Unique Identifier
                for idHeader in headers where (idHeader.name == "Message-ID" || idHeader.name == "Message-Id")
                {
                    newCard.identifier = idHeader.value
                }
                
                //Delivered To
                for toHeader in headers where toHeader.name == "Delivered-To"
                {
                    newCard.to = toHeader.value
                }
                
                //Decrypted
                newCard.decrypted = false
                
                //Attachment?
                for contentHeader in headers where contentHeader.name == "Content-Type"
                {
                    if contentHeader.value.containsString("multipart/mixed")
                    {
                        for maybeAttachmentPart in message.payload.parts
                        {
                            if let attachmentPart = maybeAttachmentPart as? GTLGmailMessagePart
                            {
                                if !attachmentPart.filename.isEmpty
                                {
                                    //print("This attachment has a filename: \(attachmentPart.filename)\n")
                                }
                                //There's an attachment
                                newCard.hasPackage = true
                            }
                        }
                    }
                        
                    else
                    {
                        newCard.hasPackage = false
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
    }
    
    //MARK: DEV ONLY (move this to a window controller)
    func sendEmail(to: String, subject: String, body: String, maybeAttachments:[NSURL]?)
    {
        if let rawMessage = generateMessage(sendToEmail: to, subject: subject, body: body, maybeAttachments: maybeAttachments)
        {
            let gmailMessage = GTLGmailMessage()
            gmailMessage.raw = rawMessage
            
            let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
            query.message = gmailMessage
            
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
                print("send email ticket: \(ticket)\n")
                print("send email response: \(response)\n")
                print("send email error: \(error)\n")
            })
        }
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
        let fetchRequest = NSFetchRequest(entityName: "PenPal")
        fetchRequest.predicate = NSPredicate(format: "email == %@", to)
        do
        {
            let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
            if result?.count > 0, let thisPenpal = result?[0] as? PenPal
            {
                if let penPalKey = thisPenpal.key
                {
                    let messageBuilder = MCOMessageBuilder()
                    messageBuilder.header.to = [MCOAddress(mailbox: to)]
                    messageBuilder.header.subject = subject
                    messageBuilder.textBody = body
                    
                    let keyAttachment = MCOAttachment(data: KeyController.sharedInstance.mySharedKey, filename: "postcard.key")
                    messageBuilder.addAttachment(keyAttachment)
                    
                    if let sodium = Sodium(), let secretKey = KeyController.sharedInstance.myPrivateKey
                    {
                        print("Encrypting a message to send.\n")
                        print("Private Key: \(self.dataEncodedToString(secretKey)) \n")
                        print("Public Key: \(self.dataEncodedToString(KeyController.sharedInstance.mySharedKey!))\n")
                        print("This Pal's Key: \(self.dataEncodedToString(penPalKey))")
                        print("This message data:\n")
                        print("\(self.dataEncodedToString(messageBuilder.data()))\n")
                        
                        if let encryptedMessageData: NSData = sodium.box.seal(messageBuilder.data(), recipientPublicKey:penPalKey, senderSecretKey: secretKey)
                        {
                            print("This encrypted message data:\n")
                            print("\(self.dataEncodedToString(encryptedMessageData))")
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
                    showAlert("You cannot send a Postcard to \(to) becuase you do not have their key! :(")
                    print("You cannot send a message to \(to) becuase you do not have their key! :(\n")
                }
            }
            else
            {
                showAlert("You cannot send a postcard to this person, they are not in your contacts yet.")
                print("This email is not in the PenPals group, could not generate a message to: \(to)")
            }
        }
        catch
        {
            //Could not fetch this Penpal from core data
            let fetchError = error as NSError
            showAlert("Sorry we could not send your Postcard, something blew up!")
            print(fetchError)
        }
        
        return nil
    }
    
    func generatePostcardAttachment() -> NSData
    {
        let textBody = "If you can read this, you have my key."
        
        //TO DO: encrypt encoded data with sodium
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
//        return GTLEncodeWebSafeBase64(messageBuilder.data())
    }
    
    func generateKeyAttachment() -> NSData?
    {
        let keyData = KeyController.sharedInstance.mySharedKey
        print("Attaching my shared key to a message: \(keyData)\n")
        
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
