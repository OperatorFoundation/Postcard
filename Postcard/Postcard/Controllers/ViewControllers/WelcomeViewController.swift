//
//  WelcomeViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/20/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GTMOAuth2
import GoogleAPIClient

class WelcomeViewController: NSViewController
{
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //The description label should be at the same angle as the Big "Postcard"
        descriptionView.rotateByAngle(11.0)
        //let rotation: CGAffineTransform = CGAffineTransformMakeRotation(M_PI/4)
    }
    
    func isAuthorized() -> Bool
    {
        //Initialize GMail API Service
        if let auth = GTMOAuth2WindowController.authForGoogleFromKeychainForName(GmailProps.kKeychainItemName , clientID: GmailProps.kClientID, clientSecret: nil)
        {
            GmailProps.service.authorizer = auth
        }
        
        //Ensure Gmail API service is authorized and perform API calls (fetch postcards)
        if let authorizer = GmailProps.service.authorizer, canAuth = authorizer.canAuthorize where canAuth
        {
            //If we do not already have the user's email saved fetch it
            let userDefaults = NSUserDefaults.standardUserDefaults()
            if let _ = userDefaults.objectForKey(UDKey.emailAddressKey) as? String
            {
                fetchGoodies()
            }
            else
            {
                //Get user profile
                let query = GTLQueryGmail.queryForUsersGetProfile()
                GmailProps.service.executeQuery(query, completionHandler: { (ticket, maybeProfile, error) in
                    if let profile = maybeProfile as? GTLGmailProfile
                    {
                        print("\(profile)\n")
                        //save email to user defaults
                        userDefaults.setValue(profile.emailAddress, forKey: UDKey.emailAddressKey)
                        self.fetchGoodies()
                    }
                })
            }
            
            return true
        }
        else
        {
            
            return false
        }
    }
    
    func fetchGoodies()
    {
        //DEV ONLY
        //MailController().sendEmail()
        //MailController().sendKey()
        let mailController = MailController()
        mailController.fetchGmailMessagesList()
        //mailController.sendKey()
        PenPalController().getGoogleContacts()
    }
    
    override func viewWillAppear()
    {
        //Windows?
        
        let windows = NSApplication.sharedApplication().windows
        
        print(windows)
        
    }
    
    lazy var mainWindowController: MainWindowController = {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateControllerWithIdentifier("MainWindowController") as! MainWindowController
        return newWindowController
    }()
    
    //MARK: Actions
    
    @IBAction func googleSignInTap(sender: AnyObject)
    {
        _ = createAuthController()
    }
    
    //MARK: OAuth2 Methods
    
    //Creates the Auth Controller for authorizing access to Gmail
    private func createAuthController() -> GTMOAuth2WindowController
    {
        let scopeString = GmailProps.scopes.joinWithSeparator(" ")
        let controller = GTMOAuth2WindowController(scope: scopeString, clientID: GmailProps.kClientID, clientSecret: nil, keychainItemName: GmailProps.kKeychainItemName, resourceBundle: nil)
        controller.signInSheetModalForWindow(NSApplication.sharedApplication().mainWindow, completionHandler: {(auth, error) in
            //Handle response
            self.finishedWithAuth(controller, authResult: auth, error: error)
        })
        return controller
    }
    
    //Handle completion of authorization process and update the Gmail API with the new credentials
    func finishedWithAuth(authWindowController: GTMOAuth2WindowController, authResult: GTMOAuth2Authentication, error: NSError?)
    {
        if let error: NSError = error
        {
            GmailProps.service.authorizer = nil
            showAlert("Authentication Error: \(error.localizedDescription)")
            return
        }
        
        GmailProps.service.authorizer = authResult
        //
        print("Authorization result from app delegate: \(authResult)\n")
        //
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
    func showAlert(message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
}
