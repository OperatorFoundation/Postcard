//
//  KeyController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import KeychainAccess
import GoogleAPIClientForREST
import Sodium
import MessagePack

//Key Attachment Keys
let userPublicKeyKey = "userPublicKey"
let userPrivateKeyKey = "userPrivateKey"
let userKeyTimestampKey = "userPublicKeyTimestamp"
let keyService = "org.operatorfoundation.Postcard"

private var _singletonSharedInstance: KeyController! = KeyController()

class KeyController: NSObject
{
    class var sharedInstance: KeyController
    {
        if _singletonSharedInstance == nil
        {
            _singletonSharedInstance = KeyController()
        }
        
        return _singletonSharedInstance
    }
    
    let keychain = Keychain(service: keyService).synchronizable(true)
    
    var mySharedKey: Data?
    var myPrivateKey: Data?
    var myKeyTimestamp: NSDate?
    
    fileprivate override init()
    {
        super.init()

        //If there is a userID available (i.e. email address)
        if let emailAddress: String = GlobalVars.currentUser?.emailAddress, !emailAddress.isEmpty
        {
            //Check the keychain for the user's keys
            do
            {
                guard let keyData = try keychain.getData(emailAddress)
                else
                {
                    //If we do not already have a key pair make one.
                    createAndSaveUserKeys(forUserWithEmail: emailAddress)
                    print("Couldn't find user's Key data. A new key pair will be generated.")
                    print("GET DATA FROM KEYCHAIN ERROR")
                    return
                }
                
                if let userKeyPack = TimestampedUserKeys.init(keyData: keyData)
                {
                    myPrivateKey = userKeyPack.userPrivateKey
                    mySharedKey = userKeyPack.userPublicKey
                    myKeyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(userKeyPack.userKeyTimestamp))
                }
                else
                {
                    //If we do not already have a key pair make one.
                    createAndSaveUserKeys(forUserWithEmail: emailAddress)
                    print("Could not unpack user's Key data. A new key pair will be generated.")
                    return
                }
            }
            catch let error
            {
                print("Error retreiving data from keychain: \(error.localizedDescription)")
            }
        }
        else
        {
            print("REALLY TERRIBLE ERROR: Couldn't find my user id so I don't know what my secret key is!!!!")
        }
    }
    
    func checkMessagesForCurrentKey()
    {
        
    }
    
    func createAndSaveUserKeys(forUserWithEmail email: String)
    {
        let newKeyPair = createNewKeyPair()
        save(privateKey: newKeyPair.secretKey, publicKey: newKeyPair.publicKey, forUserWithEmail: email)
    }
    
    func save(privateKey: Data, publicKey: Data, forUserWithEmail email: String)
    {
        //Set the timestamp to now
        let keyTimestamp = NSDate()
        let keyTimestampAsInt = Int64(keyTimestamp.timeIntervalSince1970)
        
        //Serialize the key information
        let userKeyPack = TimestampedUserKeys.init(userPublicKey: publicKey, userPrivateKey: privateKey, userKeyTimestamp: keyTimestampAsInt)
        if let userKeyData: Data = userKeyPack.dataValue()
        {
            //Save it to the Keychain
            
            do
            {
                try keychain
                    .set(userKeyData, key: email)
            }
            catch let error
            {
                print("Error saving key data to keychain: \(error.localizedDescription)")
            }
        }
        
        //Save it to the class vars as well
        myPrivateKey = privateKey
        mySharedKey = publicKey
        myKeyTimestamp = keyTimestamp
    }
    
    func deleteInstance()
    {
        _singletonSharedInstance = nil
    }
    
    func sendKey(toPenPal penPal: PenPal)
    {
        //Send key email to this user
        let emailAddress = penPal.email
        let gmailMessage = GTLRGmail_Message()
        
        if let keyInvitationEmail = MailController.sharedInstance.generateKeyMessage(forPenPal: penPal)
        {
            let rawInvite = emailToRaw(email: keyInvitationEmail)
            gmailMessage.raw = rawInvite
            let sendMessageQuery = GTLRGmailQuery_UsersMessagesSend.query(withObject: gmailMessage, userId: "me", uploadParameters: nil)
            GmailProps.service.executeQuery(sendMessageQuery, completionHandler:
            {
                (ticket, maybeResponse, maybeError) in
                
                //Update sentKey to "true"
                penPal.sentKey = true
                
                //Save this PenPal to core data
                do
                {
                    try penPal.managedObjectContext?.save()
                    print("Sent a key to \(penPal.email).\n")
                }
                catch
                {
                    let saveError = error as NSError
                    print("\(saveError), \(saveError.userInfo)")
                    
                    self.showAlert(String(format: localizedPenPalStatusError, emailAddress))
                }
            })
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
            MailController.sharedInstance.trashGmailMessage(withId: messageId)
        }
    }    
    
    func alertReceivedOutdatedRecipientKey(from penPal: PenPal, withMessageId messageId: String)
    {
        let oldKeyAlert = NSAlert()
        oldKeyAlert.messageText = "\(penPal.email) used an older version of your security settings. Send new settings to this contact?"
        oldKeyAlert.informativeText = "A message or invitation was received that uses your old settings. You will not be able to read any new messages they send until they have your current settings, however this message or invitation will be deleted as it cannot be read."
        oldKeyAlert.addButton(withTitle: "No")
        oldKeyAlert.addButton(withTitle: "Yes")
        let response = oldKeyAlert.runModal()
        
        if response == NSAlertSecondButtonReturn
        {
            //User wants to send new key to contact
            KeyController.sharedInstance.sendKey(toPenPal: penPal)
            
            //Delete the message as we will be unable to read it
            MailController.sharedInstance.trashGmailMessage(withId: messageId)
        }
        else
        {
            //Do not send newer key
            ///Show instructions for importing settings here?
            MailController.sharedInstance.trashGmailMessage(withId: messageId)
        }
    }    
    
    func alertReceivedNewerSenderKey(senderPublicKey: Data, senderKeyTimestamp: Int64, from penPal: PenPal, withMessageId messageId: String)
    {
        let newKeyAlert = NSAlert()
        newKeyAlert.messageText = "Accept PenPal's new encryption settings?"
        newKeyAlert.informativeText = "It looks like \(penPal.email) reset their encryption. Do you want to accept their new settings? If you do not, this message or invite will be deleted."
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
            //trashGmailMessage(withId: messageId)
        }
    }    
    
    ///TODO: Approve and localize strings for translation
    func alertReceivedOutdatedSenderKey(from penPal: PenPal, withMessageId messageId: String)
    {
        let oldKeyAlert = NSAlert()
        oldKeyAlert.messageText = "This email cannot be read. It was encrypted using older settings for: \(penPal.email)"
        oldKeyAlert.informativeText = "You should let this contact know that they sent you a message using a previous version of their encryption settings."
        oldKeyAlert.runModal()
        
        //trashGmailMessage(withId: messageId)
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
    
    fileprivate func createNewKeyPair() -> Box.KeyPair
    {
        //Generate a key pair for the user.
        let mySodium = Sodium()!
        let myKeyPair = mySodium.box.keyPair()!

        return myKeyPair
    }
        
    //MARK: Helper Methods
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
    
    
}
