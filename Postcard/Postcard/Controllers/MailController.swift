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

class MailController: NSObject
{
    var allPostcards = [GTLGmailMessage]()
    var allPenpals = [PenPal]()
    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext?
    
    override init()
    {
        super.init()
        managedObjectContext = appDelegate.managedObjectContext
    }
    
    //TODO: Make sure that deleting emails via bindings to the array congtroller also removes them from  gmail
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        //TESTING ONLY
        //makeMeSomeFriends()
        
        
        //First get all penpal emails from core data so that we can compare them to new invites
        PenPalController().getPenPalEmails
        {
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
                    for thisPart in parts where thisPart.mimeType == "application/postcard-key"
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
                        
                        //Check to see if we have this sender as a Penpal
                        //TODO: This needs to be checking against penpal keys in coredata!
                        if !sender.isEmpty && PostCardProps.penPalEmailSet.contains(sender)
                        {
                            print("We are already friends with \(sender) we can decrypt this postcard!")
                            self.processPostcard(message)
                            
                            //Looking for Postcard Specific Attachments
                            for thisPart in parts where thisPart.mimeType == "application/postcard-encrypted"
                            {
                                //This is a postcard attachment
                                
                                //TODO: Right now we will process the main message
                                //The message SHOULD actually be in the encrypted attachment
                                
                                //Download the attachment
                                let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                                attachmentQuery.identifier = thisPart.body.attachmentId
                                attachmentQuery.messageId = messageMeta.identifier
                                GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                                    if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                                    {
                                        //self.processPostcard(attachment, forMessage: message)
                                        //self.processPostcard(message)
                                    }
                                })
                            }
                        }
                    }
                }
            })
        }
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
                    
                    //Check if we have this email address saved as a penpal
                    //Ignore message andprint error, we already have this key
                    if PostCardProps.penPalEmailSet.contains(sender)
                    {
                        print("We are already friends with \(sender)!")
                        return
                    }
                    
                    //If not check for a key and create a new PenPal
                    if let data = NSData(base64EncodedString: attachment.data, options: []) where sender != ""
                    {
                        //Create New PenPal Record
                        
                        if let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: self.managedObjectContext!)
                        {
                            let newPal = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
                            newPal.email = sender
                            newPal.key = data
                            newPal.addedDate = NSDate().timeIntervalSinceReferenceDate
                            
                            //Save this PenPal to core data
                            do {
                                try newPal.managedObjectContext?.save()
                                print("NewPal Saved.\n")
                            }
                            catch {
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
    
//    //Check if the downloaded attachment is valid and save the information as a new postcard to core data
//    func processPostcard(attachment: GTLGmailMessagePartBody, forMessage message: GTLGmailMessage)
//    {
//        //Check the headers for the message sender
//        if let headers = message.payload.headers as? [GTLGmailMessagePartHeader]
//        {
//            for header in headers where header.name == "From"
//            {
//                let sender = header.value
//                
//                if PostCardProps.penPalEmailSet.contains(sender)
//                {
//                    print("We are already friends with \(sender) we can decrypt this postcard!")
//                    
//                    //TODO: Check if we have this email saved as a postcard
//                    //Ignore message, we already have this postcard
//                    
//                    //If not create a new Postcard
//                    //TODO: Postcard will actually be an attachment to this message that will need to be downloaded
//                    
//                    //Get the Penpal record to create the sender relationship for this Postcard
//                    if let entity = NSEntityDescription.entityForName("Postcard", inManagedObjectContext: self.managedObjectContext!)
//                    {
//                        //Create New Postcard Record
//                        let newCard = Postcard(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
//                        
//                        let fetchRequest = NSFetchRequest(entityName: "PenPal")
//                        fetchRequest.predicate = NSPredicate(format: "email == %@", sender)
//                        do
//                        {
//                            let result = try self.managedObjectContext?.executeFetchRequest(fetchRequest)
//                            if result?.count > 0, let thisPenpal = result?[0] as? PenPal
//                            {
//                                newCard.from = thisPenpal
//                            }
//                        }
//                        catch
//                        {
//                            //Could not fetch this Penpal from core data
//                            let fetchError = error as NSError
//                            print(fetchError)
//                        }
//                        newCard.body = message.payload.body.data
//                        newCard.snippet = message.snippet
//                        
//                        //Date
//                        //newCard.receivedDate = NSDate(timeIntervalSince1970: (message.internalDate).doubleValue/1000.0)
//                        for dateHeader in headers where dateHeader.name == "Date"
//                        {
//                            let formatter = NSDateFormatter()
//                            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
//                            newCard.receivedDate = formatter.dateFromString(dateHeader.value)
//                        }
//                        
//                        //Subject
//                        for subjectHeader in headers where subjectHeader.name == "Subject"
//                        {
//                            newCard.subject = subjectHeader.value
//                        }
//                        
//                        //Unique Identifier
//                        for idHeader in headers where idHeader.name == "Message-Id"
//                        {
//                            newCard.identifier = idHeader.value
//                        }
//
//                        //Save this Postcard to core data
//                        do {
//                            try newCard.managedObjectContext?.save()
//                            //print("NewCard From:" + (newCard.from?.email)! + "\n")
//                        }
//                        catch {
//                            let saveError = error as NSError
//                            print("\(saveError), \(saveError.userInfo)")
//                            self.showAlert("Warning: We could not save this contact.")
//                        }
//                    }
//                    
//                }
//            }
//        }
//    }
    func makeMeSomeFriends()
    {
        //Create New PenPal record
        
        if let managedObjectContext = self.managedObjectContext, let entity = NSEntityDescription.entityForName("PenPal", inManagedObjectContext: managedObjectContext)
        {
            let newPal = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal.email = "brandon@operatorFoundation.org"
            newPal.name = "Brandon Wiley"
            
            if !PostCardProps.penPalEmailSet.contains(newPal.email!)
            {
                //Save this PenPal to core data
                do {
                    try newPal.managedObjectContext?.save()
                    //print("NewCard From:" + (newCard.from?.email)! + "\n")
                    PostCardProps.penPalEmailSet.insert(newPal.email!)
                }
                catch {
                    let saveError = error as NSError
                    print("\(saveError)")
                }
            }

            
            
            let newPal2 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal2.email = "corie@operatorFoundation.org"
            newPal2.name = "Corie Johnson"
            newPal2.sentKey = true
            
            if !PostCardProps.penPalEmailSet.contains(newPal2.email!)
            {
                //Save this PenPal to core data
                do {
                    try newPal2.managedObjectContext?.save()
                    //print("NewCard From:" + (newCard.from?.email)! + "\n")
                    PostCardProps.penPalEmailSet.insert(newPal2.email!)
                }
                catch {
                    let saveError = error as NSError
                    print("\(saveError)")
                }
            }
            
            let newPal3 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal3.email = "jess@gmail.com"
            newPal3.name = "Jess Hill"
            
            
            if !PostCardProps.penPalEmailSet.contains(newPal3.email!)
            {
                //Save this PenPal to core data
                do {
                    try newPal3.managedObjectContext?.save()
                    //print("NewCard From:" + (newCard.from?.email)! + "\n")
                    PostCardProps.penPalEmailSet.insert(newPal3.email!)
                }
                catch {
                    let saveError = error as NSError
                    print("\(saveError)")
                }
            }
            
            let newPal4 = PenPal(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
            newPal4.email = "SarahJane@bluebox.com"
            newPal4.name = "Sarah Jane"
            
            if !PostCardProps.penPalEmailSet.contains(newPal4.email!)
            {
                //Save this PenPal to core data
                do {
                    try newPal4.managedObjectContext?.save()
                    //print("NewCard From:" + (newCard.from?.email)! + "\n")
                    PostCardProps.penPalEmailSet.insert(newPal4.email!)
                }
                catch
                {
                    let saveError = error as NSError
                    print("\(saveError)")
                }
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
                            if let bodyData = GTLDecodeBase64(thisPart.body.data), let bodyText = String(data: bodyData, encoding: NSUTF8StringEncoding)
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
                print("NewCard Subject: \(newCard.subject)\nHasAttachment:\(newCard.hasPackage.boolValue)\n")
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
        let gmailMessage = GTLGmailMessage()
        gmailMessage.raw = generateMessage(sendToEmail: to, subject: subject, body: body, maybeAttachments: maybeAttachments)
        
        let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
        query.message = gmailMessage
        
        GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
            print("send email ticket: \(ticket)\n")
            print("send email response: \(response)\n")
            print("send email error: \(error)\n")
        })
    }
    
    func sendKey()
    {
        let gmailMessage = GTLGmailMessage()
        gmailMessage.raw = generateKeyMessage()
        
        let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
        query.message = gmailMessage
        
        GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
            print("send email ticket: \(ticket)\n")
            print("send email response: \(response)\n")
            print("send email error: \(error)\n")
        })
    }
    
    //MARK: Create the message
    
    //Main Wrapper Message This is what the user will see in any email client
    func generateMessage(sendToEmail to: String, subject: String, body: String, maybeAttachments: [NSURL]?) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.to = [MCOAddress(mailbox: to)]
        messageBuilder.header.subject = subject
        messageBuilder.textBody = body
        
        if let attachmentURLs = maybeAttachments where !attachmentURLs.isEmpty
        {
            for attachmentURL in attachmentURLs
            {
                if let fileData = NSData(contentsOfURL: attachmentURL)
                {
                    if let urlString: String = attachmentURL.path
                    {
                        let urlParts = urlString.componentsSeparatedByString(".")
                        let pathParts = urlParts.first?.componentsSeparatedByString("/")
                        let fileName = pathParts?.last ?? ""
                        let fileExtension = attachmentURL.pathExtension
                        
                        var mimeType = ""
                        if fileExtension == "jpg"
                        {
                            mimeType = "image/jpeg"
                        }
                        else if fileExtension == "png"
                        {
                            mimeType = "image/png"
                        }
                        else if fileExtension == "doc"
                        {
                            mimeType = "application/msword"
                        }
                        else if fileExtension == "ppt"
                        {
                            mimeType = "application/vnd.ms-powerpoint"
                        }
                        else if fileExtension == "html"
                        {
                            mimeType = "text/html"
                        }
                        else if fileExtension == "pdf"
                        {
                            mimeType = "application/pdf"
                        }
                        
                        if !mimeType.isEmpty
                        {
                            if let attachment = MCOAttachment(data: fileData, filename: fileName)
                            {
                                attachment.mimeType = mimeType
                                messageBuilder.addAttachment(attachment)
                            }
                        }
                    }
                    
                    //self.attachments.append(fileData)
                }
            }
        }
        
//        //Generate the main Postcard Attachment.
//        if let postcardWrapperAttachment = MCOAttachment(data: generatePostcardAttachment(), filename: "Postcard")
//        {
//            postcardWrapperAttachment.mimeType = "application/postcard-encrypted"
//            messageBuilder.addAttachment(postcardWrapperAttachment)
//        }
        
        return GTLEncodeWebSafeBase64(messageBuilder.data())
    }
    
    //This is the actual Postcard Message.
    func generatePostcardAttachment() -> NSData
    {
        let textBody = "If you can read this, you have my key."
        
        //TO DO: encrypt encoded data with sodium
        return textBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    func generateKeyMessage() -> String
    {
        let messageBuilder = MCOMessageBuilder()
        //messageBuilder.header.to = [MCOAddress(mailbox: "brandon.wiley@gmail.com")]
        messageBuilder.header.to = [MCOAddress(mailbox: "looklita@gmail.com")]
        //messageBuilder.header.to = [MCOAddress(mailbox: "adelita.schule@gmail.com")]
        messageBuilder.header.subject = PostCardProps.subject
        messageBuilder.textBody = PostCardProps.body
        
        //Generate the main Postcard Attachment.
        if let postcardWrapperAttachment = MCOAttachment(data: generateKeyAttachment(), filename: "Postcard")
        {
            postcardWrapperAttachment.mimeType = "application/postcard-key"
            messageBuilder.addAttachment(postcardWrapperAttachment)
        }
        
        return GTLEncodeWebSafeBase64(messageBuilder.data())
    }
    
    func generateKeyAttachment() -> NSData
    {
        //Get Public Key from User Defaults
        
        //TO DO: encrypt encoded data with sodium
        return "My Key".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
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
