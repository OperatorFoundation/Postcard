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

private let _singletonInstance = KeyController()

class KeyController: NSObject
{
    //static let sharedInstance = KeyController()
    
    class var sharedInstance: KeyController
    {
        return _singletonInstance
    }
    
    let service = "org.operatorfoundation.Postcard"
    
    var mySharedKey: NSData?
    var myPrivateKey:NSData?
    
    
    override init()
    {
        super.init()
        
        var missingKey = false
        
        //If there is a userID available (i.e. email address)
        if let emailAddress: String = Constants.currentUser?.emailAddress where !emailAddress.isEmpty
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
            if let sharedKey = Constants.currentUser?.publicKey
            {
                mySharedKey = sharedKey
            }
            else
            {
                missingKey = true
            }
            
//            //Check the keychain for the serialized KeyPair
//            if let keyPairData = SSKeychain.passwordDataForService(service, account: emailAddress)
//            {
//                //Deserialize the KeyPair
//                if let keyPair = NSKeyedUnarchiver.unarchiveObjectWithData(keyPairData) as? Box.KeyPair
//                {
//                    myPrivateKey = keyPair.secretKey
//                    mySharedKey = keyPair.publicKey
//                }
//                else
//                {
//                    missingKey = true
//                }
//            }
//            else
//            {
//                missingKey = true
//            }
            
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
                    fetchRequest.predicate = NSPredicate(format: "email == %@", emailAddress)
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
                
                
//                //Serialize the keypair so that they can be stored together in the keychain
//                if let keyPairData: NSData = NSKeyedArchiver.archivedDataWithRootObject(newKeyPair as! AnyObject)
//                {
//                    //Save it to the Keychain
//                }
            }
        }
        else
        {
            print("REALLY TERRIBLE ERROR: Couldn't find my user id so I don't know what my secret key is!!!!")
        }
    }
    
//    func makeLookupKey(userID: String) -> String
//    {
//        return userID + UDKey.publicKeyKey
//    }
    
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
    
//    private func saveUserKeys(privateKey: NSData, publicKey: NSData, userID: String)
//    {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        
//        //Save secret key in the keychain with the user's email address
//        SSKeychain.setPasswordData(privateKey, forService: service, account: userID)
//        
//        //Save public key to NSUser Defaults
//        defaults.setValue(publicKey, forKey: makeLookupKey(userID))
//    }
    
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
