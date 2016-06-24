//
//  KeyController.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import SSKeychain
import Sodium
import GoogleAPIClient

class KeyController: NSObject
{
    static let sharedInstance = KeyController()
    
    let service = "org.operatorfoundation.Postcard"
    
    var mySharedKey: NSData?
    var myPrivateKey:NSData?
    
    override init()
    {
        super.init()
        
        var missingKey = false
        
        if let userID = NSUserDefaults.standardUserDefaults().stringForKey(UDKey.emailAddressKey)
        {
            if let secretKey = SSKeychain.passwordDataForService(service, account: userID)
            {
                myPrivateKey = secretKey
            }
            else
            {
                missingKey = true
            }
            
            if let sharedKeyKey: String = makeLookupKey(userID)
            {
                if let sharedKey = NSUserDefaults.standardUserDefaults().objectForKey(sharedKeyKey) as? NSData
                {
                    print("My shared key is: \(sharedKey)\n")
                    mySharedKey = sharedKey
                }
                else
                {
                    missingKey = true
                    print("Could not find our shared key in the user defaults using defaults key: \(sharedKeyKey)\n")
                }
            }
                
            else
            {
                missingKey = true
                print("Couldn't find my user id so I don't know what my secret key is!!!!")
            }
            
            if missingKey
            {
                let newKeyPair = createNewKeyPair()
                mySharedKey = newKeyPair.publicKey
                myPrivateKey = newKeyPair.secretKey
                
                //Save it to the keychain.
                saveUserKeys(newKeyPair.secretKey, publicKey: newKeyPair.publicKey, userID: userID)
            }
        }
        else
        {
            print("REALLY TERRIBLE ERROR: Couldn't find my user id so I don't know what my secret key is!!!!")
        }
    }
    
    func makeLookupKey(userID: String) -> String
    {
        return userID + UDKey.publicKeyKey
    }
    
    func sendKey(toPenPal penPal: PenPal)
    {
        if let emailAddress = penPal.email
        {
            //Send key email to this user
            
            let gmailMessage = GTLGmailMessage()
            gmailMessage.raw = MailController().generateKeyMessage(emailAddress)
            
            let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
            query.message = gmailMessage
            
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
                print("send key email ticket: \(ticket)\n")
                print("send key email response: \(response)\n")
                print("send key email error: \(error)\n")
                
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
                    self.showAlert("Warning: We could not save the sent key status of \(penPal.email).")
                }
            })
        }
    }
    
    private func saveUserKeys(privateKey: NSData, publicKey: NSData, userID: String)
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        //Save secret key in the keychain with the user's email address
        SSKeychain.setPasswordData(privateKey, forService: service, account: userID)
        
        //Save public key to NSUser Defaults
        defaults.setValue(publicKey, forKey: makeLookupKey(userID))
    }
    
    private func createNewKeyPair() -> Box.KeyPair
    {
        //Generate a key pair for the user.
        let mySodium = Sodium()!
        let myKeyPair = mySodium.box.keyPair()!

        return myKeyPair
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
