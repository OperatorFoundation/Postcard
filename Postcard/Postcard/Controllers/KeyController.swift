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
    
    let service = "org.operatorfoundation.Postcard"
    
    var mySharedKey: NSData?
    var myPrivateKey: NSData?
    
    private override init()
    {
        super.init()
        
        var missingKey = false
        
        //If there is a userID available (i.e. email address)
        if let emailAddress: String = GlobalVars.currentUser?.emailAddress where !emailAddress.isEmpty
        {
            //Check the keychain for the private key
            if let privateKey = SSKeychain.passwordDataForService(service, account: emailAddress)
            {
                myPrivateKey = privateKey
            }
            else
            {
                missingKey = true
            }
            
            //Check the user for a public key
            if let sharedKey = GlobalVars.currentUser?.publicKey
            {
                mySharedKey = sharedKey
            }
            else
            {
                missingKey = true
            }
            
            //If we do not already have a key pair make one.
            if missingKey
            {
                let newKeyPair = createNewKeyPair()
                mySharedKey = newKeyPair.publicKey
                myPrivateKey = newKeyPair.secretKey
                
                //Save it to the Keychain
                SSKeychain.setPasswordData(myPrivateKey, forService: service, account: emailAddress)
                
                //Save Public Key to Core Data
                if let appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate
                {
                    //Fetch the correct user
                    let managedObjectContext = appDelegate.managedObjectContext
                    let fetchRequest = NSFetchRequest(entityName: "User")
                    fetchRequest.predicate = NSPredicate(format: "emailAddress == %@", emailAddress)
                    do
                    {
                        let result = try managedObjectContext.executeFetchRequest(fetchRequest)
                        
                        if result.count > 0, let thisUser = result[0] as? User
                        {
                            thisUser.publicKey = mySharedKey
                            
                            //Save this user
                            do
                            {
                                try thisUser.managedObjectContext?.save()
                            }
                            catch
                            {
                                let saveError = error as NSError
                                print(saveError)
                            }
                        }
                    }
                    catch
                    {
                        let fetchError = error as NSError
                        print(fetchError)
                    }
                }
            }
        }
        else
        {
            print("REALLY TERRIBLE ERROR: Couldn't find my user id so I don't know what my secret key is!!!!")
        }
    }
    
    func resetKeys()
    {
        _singletonSharedInstance = nil
        mySharedKey = nil
        myPrivateKey = nil
    }
    
    func sendKey(toPenPal penPal: PenPal)
    {
        if let emailAddress = penPal.email
        {
            //Send key email to this user
            
            let gmailMessage = GTLGmailMessage()
            gmailMessage.raw = MailController.sharedInstance.generateKeyMessage(emailAddress)
            
            let query = GTLQueryGmail.queryForUsersMessagesSendWithUploadParameters(nil)
            query.message = gmailMessage
            
            GmailProps.service.executeQuery(query, completionHandler: {(ticket, response, error) in
                print("\nsend key email ticket: \(ticket)")
                print("send key email response: \(response)")
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
        alert.addButtonWithTitle(localizationKeys.localizedOKButtonTitle)
        alert.runModal()
    }
    
    
}
