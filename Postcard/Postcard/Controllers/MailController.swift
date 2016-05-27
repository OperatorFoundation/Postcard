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
    
    //This gets a bare list of messages that meet our criteria and then calls a func to retrieve the payload for each one
    func fetchGmailMessagesList()
    {
        let query = GTLQueryGmail.queryForUsersMessagesList()
        query.q = "Subject:Postcard has:attachment"
        
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
                    //Debug: Print info about this message
//                                                        print("PAYLOAD: " + message.payload.description + "\n")
//                                                        if let headers = message.payload.headers
//                                                        {
//                                                            for thisHeader in headers
//                                                            {
//                                                                print("HEADER: " + thisHeader.description + "\n")
//                                                            }
//                                                        }
//                    
//                                                        print("PARTS: " + message.payload.parts.description + "\n")

                    for thisPart in parts
                    {
                        //This is a postcard
                        if thisPart.mimeType == "application/postcard-encrypted"
                        {
                            //Message has an attachment of the correct mime type, save it
                            //This is a Postcard
                            self.allPostcards.append(message)
                            //TODO CoreData
                            
                            //Download the attachment
                            let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                            attachmentQuery.identifier = thisPart.body.attachmentId
                            attachmentQuery.messageId = messageMeta.identifier
                            GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                                if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                                {
                                    self.processPostcard(attachment, forMessage: message)
                                }
                            })
                            
                            
                        }
                            
                        //This is a key/penpal invitation
                        else if thisPart.mimeType == "application/postcard-key"
                        {
                            //Download the attachment
                            let attachmentQuery = GTLQueryGmail.queryForUsersMessagesAttachmentsGet()
                            attachmentQuery.identifier = thisPart.body.attachmentId
                            attachmentQuery.messageId = messageMeta.identifier
                            
//                            print("Attachment ID: \(thisPart.body.attachmentId) \n")
//                            print("Message ID: \(messageMeta.identifier) \n")
                            
                            GmailProps.service.executeQuery(attachmentQuery, completionHandler: {(ticket, maybeAttachment, error) in
                                if let attachment = maybeAttachment as? GTLGmailMessagePartBody
                                {
                                    self.processPenPalKeyAttachment(attachment, forMessage: message)
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    //Process Different Message Types
    
    //Check if the downloaded attachment is valid and save the information as a new penpal to core data
    func processPenPalKeyAttachment(attachment: GTLGmailMessagePartBody, forMessage message: GTLGmailMessage)
    {
        //First get all penpal emails from core data so that we can compare them to new invites
        PenPalController().getPenPalEmails
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
                                newPal.addedDate = NSDate()//.timeIntervalSinceReferenceDate
                                
                                //Save this PenPal to core data
                                do {
                                    try newPal.managedObjectContext?.save()
                                    print("NewPal Saved:" + newPal.email! + "\n")
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
    }
    
    //Check if the downloaded attachment is valid and save the information as a new postcard to core data
    func processPostcard(attachment: GTLGmailMessagePartBody, forMessage message: GTLGmailMessage)
    {
        //Check the headers for the message sender
        if let headers = message.payload.headers as? [GTLGmailMessagePartHeader]
        {
            for header in headers where header.name == "From"
            {
                let sender = header.value
                
                if PostCardProps.penPalEmailSet.contains(sender)
                {
                    print("We are already friends with \(sender) we can decrypt this postcard!")
                    
                    //TODO: Check if we have this email saved as a postcard
                    //Ignore message, we already have this postcard
                    
                    //If not create a new Postcard
                    //TODO: Postcard will actually be an attachment to this message that will need to be downloaded
                    
                    //Get the Penpal record to create the sender relationship for this Postcard
                    if let entity = NSEntityDescription.entityForName("Postcard", inManagedObjectContext: self.managedObjectContext!)
                    {
                        //Create New Postcard Record
                        let newCard = Postcard(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
                        
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
                        newCard.body = message.payload.body.data
                        newCard.snippet = message.snippet
                        
                        //Date
                        //newCard.receivedDate = NSDate(timeIntervalSince1970: (message.internalDate).doubleValue/1000.0)
                        for dateHeader in headers where dateHeader.name == "Date"
                        {
                            let formatter = NSDateFormatter()
                            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                            newCard.receivedDate = formatter.dateFromString(dateHeader.value)
                        }
                        
                        //Subject
                        for subjectHeader in headers where subjectHeader.name == "Subject"
                        {
                            newCard.subject = subjectHeader.value
                        }
                        
                        //Unique Identifier
                        for idHeader in headers where idHeader.name == "Message-Id"
                        {
                            newCard.identifier = idHeader.value
                        }

                        //Save this Postcard to core data
                        do {
                            try newCard.managedObjectContext?.save()
                            print("NewCard From:" + (newCard.from?.email)! + "\n")
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
    
    //MARK: DEV ONLY (move this to a window controller)
    func sendEmail(to: String, subject: String, body: String)
    {
        let gmailMessage = GTLGmailMessage()
        gmailMessage.raw = generateMessage(sendToEmail: to, subject: subject, body: body)
        
        
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
    func generateMessage(sendToEmail to: String, subject: String, body: String) -> String
    {
        let messageBuilder = MCOMessageBuilder()
        //messageBuilder.header.to = [MCOAddress(mailbox: "brandon.wiley@gmail.com")]
        messageBuilder.header.to = [MCOAddress(mailbox: to)]
        messageBuilder.header.subject = subject
        messageBuilder.textBody = body
        
        //Generate the main Postcard Attachment.
        if let postcardWrapperAttachment = MCOAttachment(data: generatePostcardAttachment(), filename: "Postcard")
        {
            postcardWrapperAttachment.mimeType = "application/postcard-encrypted"
            messageBuilder.addAttachment(postcardWrapperAttachment)
        }
        
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
        //messageBuilder.header.to = [MCOAddress(mailbox: "looklita@gmail.com")]
        messageBuilder.header.to = [MCOAddress(mailbox: "adelitaDev@gmail.com")]
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
