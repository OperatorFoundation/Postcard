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
            //Check the keychain for the private key
            if let privateKey = SAMKeychain.passwordData(forService: service, account: emailAddress)
            {
                myPrivateKey = privateKey
            }
            else
            {
                missingKey = true
                print("Couldn't find user's Private Key. A new key pair will be generated.")
            }
            
            //Check the user for a public key
            if let sharedKey = GlobalVars.currentUser?.publicKey
            {
                mySharedKey = sharedKey as Data
            }
            else
            {
                missingKey = true
                print("Couldn't find user's Public Key. A new key pair will be generated.")
            }
            
            //Check the user for a key timestamp
            if let keyTimestamp = GlobalVars.currentUser?.keyTimestamp
            {
                myKeyTimestamp = keyTimestamp
            }
            else
            {
                missingKey = true
                print("Couldn't find user's key timestamp. A new key pair will be generated.")
            }
            
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
        //Save it to the Keychain
        SAMKeychain.setPasswordData(privateKey, forService: service, account: email)
        
        //Save it to the class var as well
        myPrivateKey = privateKey
        
        //Save Public Key to Core Data
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate
        {
            //Fetch the correct user
            let managedObjectContext = appDelegate.managedObjectContext
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "emailAddress == %@", email)
            do
            {
                let result = try managedObjectContext.fetch(fetchRequest)
                
                if result.count > 0
                {
                    let thisUser = result[0]
                    thisUser.publicKey = publicKey as NSData?
                    
                    //Set key timestamp to now
                    thisUser.keyTimestamp = NSDate()
                    
                    //Save this user
                    do
                    {
                        try thisUser.managedObjectContext?.save()
                        
                        //Update the class variable as well
                        mySharedKey = publicKey
                        myKeyTimestamp = thisUser.keyTimestamp
                    }
                    catch
                    {
                        let saveError = error as NSError
                        print("Error Saving public key: \(saveError)")
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
            
            let gmailMessage = GTLRGmail_Message()
            gmailMessage.raw = MailController.sharedInstance.generateKeyMessage(forPenPal: penPal)
            
            let sendMessageQuery = GTLRGmailQuery_UsersMessagesSend.query(withObject: gmailMessage, userId: "me", uploadParameters: nil)
            GmailProps.service.executeQuery(sendMessageQuery, completionHandler:
            {
                (ticket, maybeResponse, maybeError) in
                
                print("\nsend key email ticket: \(ticket)")
                print("send key email response: \(maybeResponse)")
                print("send key email error: \(maybeError)\n")
                
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
