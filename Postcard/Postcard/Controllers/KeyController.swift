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
    let service = "org.operatorfoundation.Postcard"
    
    var mySharedKey: NSData
    {
        get{
            if let sharedKey = NSUserDefaults.standardUserDefaults().objectForKey(UDKey.publicKeyKey) as? NSData
            {
                return sharedKey
            }
            else
            {
                return createNewKeyPair().publicKey
            }
        }
    }
    
    var myPrivateKey:NSData?
    {
        get
        {
            if let userID = NSUserDefaults.standardUserDefaults().stringForKey(UDKey.emailAddressKey)
            {
                if let secretKey = SSKeychain.passwordDataForService(service, account: userID)
                {
                    return secretKey
                }
                else
                {
                    return createNewKeyPair().secretKey
                }
            }
            else
            {
                print("Couldn't find my user id so I don't know what my secret key is!!!!")
            }
            return nil
        }
    }
    
    override init()
    {
        super.init()
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
        defaults.setValue(publicKey, forKey: UDKey.publicKeyKey)
    }
    
    private func createNewKeyPair() -> Box.KeyPair
    {
        //Generate a key pair for the user.
        let mySodium = Sodium()!
        let myKeyPair = mySodium.box.keyPair()!
        
        //Save it to the keychain.
        if let userID = NSUserDefaults.standardUserDefaults().stringForKey(UDKey.emailAddressKey)
        {
            self.saveUserKeys(myKeyPair.secretKey, publicKey: myKeyPair.publicKey, userID: userID)
        }
        else
        {
            print("Couldn't find my user id so I don't know what my secret key is!!!!")
        }
        
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
