//
//  KeyController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import SAMKeychain
import GoogleAPIClientForREST
import Sodium
import MessagePack

//Key Attachment Keys
let userPublicKeyKey = "userPublicKey"
let userPrivateKeyKey = "userPrivateKey"
let userKeyTimestampKey = "userPublicKeyTimestamp"

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
    
    let keyService = "org.operatorfoundation.Postcard"
    
    var mySharedKey: Data?
    var myPrivateKey: Data?
    var myKeyTimestamp: NSDate?
    
    fileprivate override init()
    {
        super.init()
        
        var missingKey = false
        
        //If there is a userID available (i.e. email address)
        if let emailAddress: String = GlobalVars.currentUser?.emailAddress, !emailAddress.isEmpty
        {
            //Check the keychain for the user's keys
            if let keyData = SAMKeychain.passwordData(forService: keyService, account: emailAddress)
            {
                if let userKeyPack = TimestampedUserKeys.init(keyData: keyData)
                {
                    myPrivateKey = userKeyPack.userPrivateKey
                    mySharedKey = userKeyPack.userPublicKey
                    myKeyTimestamp = NSDate(timeIntervalSince1970: TimeInterval(userKeyPack.userKeyTimestamp))
                }
            }
            else
            {
                missingKey = true
                print("Couldn't find user's Private Key. A new key pair will be generated.")
            }
            
//            //Check the user for a public key
//            if let sharedKey = GlobalVars.currentUser?.publicKey
//            {
//                mySharedKey = sharedKey as Data
//            }
//            else
//            {
//                missingKey = true
//                print("Couldn't find user's Public Key. A new key pair will be generated.")
//            }
//            
//            //Check the user for a key timestamp
//            if let keyTimestamp = GlobalVars.currentUser?.keyTimestamp
//            {
//                myKeyTimestamp = keyTimestamp
//            }
//            else
//            {
//                missingKey = true
//                print("Couldn't find user's key timestamp. A new key pair will be generated.")
//            }
            
            //If we do not already have a key pair make one.
            if missingKey
            {
                createAndSaveUserKeys(forUserWithEmail: emailAddress)
            }
        }
        else
        {
            print("REALLY TERRIBLE ERROR: Couldn't find my user id so I don't know what my secret key is!!!!")
        }
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
            SAMKeychain.setPasswordData(userKeyData, forService: keyService, account: email)
        }
        
        //Save it to the class vars as well
        myPrivateKey = privateKey
        mySharedKey = publicKey
        myKeyTimestamp = keyTimestamp
    }
    
    func resetKeys()
    {
        _singletonSharedInstance = nil
        mySharedKey = nil
        myPrivateKey = nil
    }
    
    func sendKey(toPenPal penPal: PenPal)
    {
        //Send key email to this user
        let emailAddress = penPal.email
        let gmailMessage = GTLRGmail_Message()
        gmailMessage.raw = MailController.sharedInstance.generateKeyMessage(forPenPal: penPal)
        
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
    
    fileprivate func createNewKeyPair() -> Box.KeyPair
    {
        //Generate a key pair for the user.
        let mySodium = Sodium()!
        let myKeyPair = mySodium.box.keyPair()!

        return myKeyPair
    }
    
    struct TimestampedUserKeys: Packable
    {
        var userPublicKey: Data
        var userPrivateKey: Data
        var userKeyTimestamp: Int64
        
        init(userPublicKey: Data, userPrivateKey: Data, userKeyTimestamp: Int64)
        {
            self.userPublicKey = userPublicKey
            self.userPrivateKey = userPrivateKey
            self.userKeyTimestamp = userKeyTimestamp
        }
        
        init?(keyData: Data)
        {
            do
            {
                let unpackResult = try unpack(keyData)
                let unpackValue: MessagePackValue = unpackResult.value
                self.init(value: unpackValue)
            }
            catch let unpackError as NSError
            {
                print("Unpack user keys error: \(unpackError.localizedDescription)")
                return nil
            }
        }
        
        init?(value: MessagePackValue)
        {
            guard let keyDictionary = value.dictionaryValue
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            //User Public Key
            guard let userPublicKeyMessagePack = keyDictionary[.string(userPublicKeyKey)]
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            guard let userPublicKeyData = userPublicKeyMessagePack.dataValue
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            //User Private Key
            guard let userPrivateKeyMessagePack = keyDictionary[.string(userPrivateKeyKey)]
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            guard let userPrivateKeyData = userPrivateKeyMessagePack.dataValue
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            //Sender Key Timestamp
            guard let userTimestampMessagePack = keyDictionary[.string(userKeyTimestampKey)]
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            guard let userKeyTimestamp = userTimestampMessagePack.integerValue
                else
            {
                print("TimestampedUserKeys deserialization error.")
                return nil
            }
            
            self.userPublicKey = userPublicKeyData
            self.userPrivateKey = userPrivateKeyData
            self.userKeyTimestamp = userKeyTimestamp
        }
        
        func messagePackValue() -> MessagePackValue
        {
            let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
                MessagePackValue(userPublicKeyKey): MessagePackValue(self.userPublicKey),
                MessagePackValue(userPrivateKeyKey): MessagePackValue(self.userPrivateKey),
                MessagePackValue(userKeyTimestampKey): MessagePackValue(self.userKeyTimestamp)
            ]
            
            return MessagePackValue(keyDictionary)
        }
        
        func dataValue() -> Data?
        {
            let keyMessagePack = self.messagePackValue()
            return pack(keyMessagePack)
        }
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
