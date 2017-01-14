//
//  WelcomeViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/20/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GTMOAuth2
//import GoogleAPIClient

class WelcomeViewController: NSViewController
{
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSView!
    @IBOutlet weak var googleLoginButton: NSButton!
    
    var userGoogleName: String?
    var googleAuthWindowController: GTMOAuth2WindowController?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //The description label should be at the same angle as the Big "Postcard"
        descriptionView.rotate(byDegrees: 11.0)
    }
    
    func isAuthorized() -> Bool
    {
        //Initialize GMail API Service
        if let auth = GTMOAuth2WindowController.authForGoogleFromKeychain(forName: GmailProps.kKeychainItemName , clientID: GmailProps.kClientID, clientSecret: nil)
        {
            GmailProps.service.authorizer = auth
            GmailProps.servicePeople.authorizer = auth
        }
        
        //TODO: This goes inside the keychain check
        //Ensure Gmail API service is authorized and perform API calls (fetch postcards)
        if let authorizer = GmailProps.service.authorizer, let canAuth = authorizer.canAuthorize, canAuth
        {
            
            if (GlobalVars.currentUser?.emailAddress) != nil
            {
                fetchGoodies()
            }
            else
            {
                if let currentEmailAddress: String = authorizer.userEmail
                {
                    //Check if a user entity already exists
                    if let existingUser = fetchUserFromCoreData(currentEmailAddress)
                    {
                        GlobalVars.currentUser = existingUser
                        self.fetchGoodies()
                    }
                    else
                    {
                        //Create a new user
                        if let authWindowController = googleAuthWindowController, let name = authWindowController.signIn.userProfile["name"] as? String
                        {
                            if createUser(currentEmailAddress, firstName: name) != nil
                            {
                                self.fetchGoodies()
                            }
                        }
                        else
                        {
                            if createUser(currentEmailAddress) != nil
                            {
                                self.fetchGoodies()
                            }
                        }
                    }
                }
            }
            
            return true
        }
        else
        {
            return false
        }
    }
    
    func fetchUserFromCoreData(_ userEmail: String) -> User?
    {
        //Check if a user entity already exists
        //Get this User Entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext
        fetchRequest.predicate = NSPredicate(format: "emailAddress == %@", userEmail)
        do
        {
            let result = try managedObjectContext.fetch(fetchRequest)
            if result.count > 0, let thisUser = result[0] as? User
            {
                return thisUser
            }
            else
            {
                return nil
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
    
    func createUser(_ userEmail: String) -> User?
    {
        return createUser(userEmail, firstName: nil)
    }
    
    func createUser(_ userEmail: String, firstName: String?) -> User?
    {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext
        
        if let userEntity = NSEntityDescription.entity(forEntityName: "User", in: managedObjectContext)
        {
            let newUser = User(entity: userEntity, insertInto: managedObjectContext)
            newUser.emailAddress = userEmail
            
            //Save this user to core Data
            do
            {
                try newUser.managedObjectContext?.save()
                GlobalVars.currentUser = newUser
                return newUser
            }
            catch
            {
                let saveError = error as NSError
                print("Unable to save new user to core data. \n\(saveError)\n")
                return nil
            }
        }
        else
        {
            return nil
        }
    }
    
    func fetchGoodies()
    {
        MailController.sharedInstance.updateMail()
        PenPalController.sharedInstance.getGoogleContacts()
    }
    
    override func viewDidAppear()
    {
        if isAuthorized()
        {
            //Present Home View
            mainWindowController.showWindow(self)
            
            view.window?.close()
        }
        else
        {
            googleLoginButton.isEnabled = true
        }
    }
    
    lazy var mainWindowController: MainWindowController =
    {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as! MainWindowController
        return newWindowController
    }()
    
    //MARK: Actions
    
    @IBAction func googleSignInTap(_ sender: AnyObject)
    {
        _ = createAuthController()
    }
    
    //MARK: OAuth2 Methods
    
    //Creates the Auth Controller for authorizing access to Gmail
    fileprivate func createAuthController() -> GTMOAuth2WindowController
    {
        let scopeString = GmailProps.scopes.joined(separator: " ")
        let controller = GTMOAuth2WindowController(scope: scopeString, clientID: GmailProps.kClientID, clientSecret: nil, keychainItemName: GmailProps.kKeychainItemName, resourceBundle: nil)
        controller?.signIn.shouldFetchGoogleUserProfile = true
        controller?.signInSheetModal(for: NSApplication.shared().mainWindow, completionHandler:
        {
            (auth: GTMOAuth2Authentication?, error: Error?) -> Void in
            
            if auth != nil
            {
                self.finishedWithAuth(controller!, authResult: auth!, error: error)
            }
        })
        
        return controller!
    }
    
    //Handle completion of authorization process and update the Gmail API with the new credentials
    func finishedWithAuth(_ authWindowController: GTMOAuth2WindowController, authResult: GTMOAuth2Authentication, error: Error?)
    {
        googleAuthWindowController = authWindowController
        
        if let error: Error = error
        {
            GmailProps.service.authorizer = nil
            showAlert(localizedAuthErrorPrompt + error.localizedDescription)
            return
        }
        
        GmailProps.service.authorizer = authResult
        GmailProps.servicePeople.authorizer = authResult
        authWindowController.dismissController(self)
        
        if isAuthorized()
        {
            //Present Home View
            mainWindowController.showWindow(self)
            
            view.window?.close()
        }
    }
    
    //MARK: Helper Methods
    
    //Helper for showing an alert.
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
   
//
}
