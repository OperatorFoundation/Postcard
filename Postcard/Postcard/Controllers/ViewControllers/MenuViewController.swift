//
//  MenuViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import GTMOAuth2

enum SelectedMode
{
    case inbox, penpals
}

class MenuViewController: NSViewController, NSUserActivityDelegate
{
    @IBOutlet weak var composeButton: NSButton!
    @IBOutlet weak var inboxButton: NSButton!
    @IBOutlet weak var penPalsButton: NSButton!
    @IBOutlet weak var lockdownButton: NSButton!
    @IBOutlet weak var logoutButton: NSButton!

    let syncActivity = NSUserActivity(activityType: activityTypePrivateKeySync)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        styleButtons()

        //This listens for a handoff activity from another device
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: keyHandoffNotificationName), object: nil, queue: nil)
        {
            (keyHandoffNotification) in
            
            //Get user object here and send to handler function
            if let notificationObject = keyHandoffNotification.object
            {
                print("Key handoff notification object received: \(notificationObject)")
                //self.receivedKeyHandoff(userDictionary: <#T##Dictionary<AnyHashable, Any>#>)
            }
        }
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        selectMode(.inbox)
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        
        //This creates a handoff activity that allows the user to sync their key to another device
        createKeySyncUserActivity()
    }
    
    func createKeySyncUserActivity()
    {
        
        syncActivity.title = "Import Encryption Settings"
        syncActivity.isEligibleForSearch = false
        syncActivity.isEligibleForPublicIndexing = false
        syncActivity.isEligibleForHandoff = true
        //userActivity?.delegate = self
        
        //Get the needed user info values
        if KeyController.sharedInstance.mySharedKey != nil, KeyController.sharedInstance.myPrivateKey != nil
        {
            //Create the user info dictionary
            syncActivity.userInfo = [activityItemKeyPrivateKey:KeyController.sharedInstance.myPrivateKey!,
                                     activityItemKeyPublicKey:KeyController.sharedInstance.mySharedKey!,
                                     activityItemKeyVersion: activityKeySyncVersion]
            //userActivity = syncActivity
            syncActivity.becomeCurrent()
            print("User activity with title: \(syncActivity.title) called becomeCurrent.")
        }
    }
    
    func receivedKeyHandoff(userDictionary: Dictionary<String, Any>)
    {
        var updatedKey = false
        
        ///TODO: NEW USER VISIBLE TEXT NEEDS APPROVAL FOR TRANSLATION
        
        if let thisSyncVersion = userDictionary[activityItemKeyVersion] as? String
        {
            //Make sure these sync objects are compatible
            if thisSyncVersion == activityKeySyncVersion
            {
                //Get the new private key from the object
                if let newPrivateKey = userDictionary[activityItemKeyPrivateKey] as? Data
                {
                    //Get the new public key from the object
                    if let newPublicKey = userDictionary[activityItemKeyPublicKey] as? Data
                    {
                        //Check to see if the new keys are different from the old ones
                        if KeyController.sharedInstance.myPrivateKey == newPrivateKey && KeyController.sharedInstance.mySharedKey == newPublicKey
                        {
                            showAlert("Your security settings have already been synced.")
                        }
                        else
                        {
                            //New keys are different, ask user for confirmation
                            let confirmKeySyncAlert = NSAlert()
                            confirmKeySyncAlert.alertStyle = NSAlertStyle.warning
                            confirmKeySyncAlert.messageText = "Do you want to overwrite your current encryption settings?"
                            confirmKeySyncAlert.informativeText = "If you continue any messages you are currently able to decrypt on this machine will be lost."
                            confirmKeySyncAlert.addButton(withTitle: localizedCancelButtonTitle)
                            confirmKeySyncAlert.addButton(withTitle: localizedOKButtonTitle)
                            let response = confirmKeySyncAlert.runModal()
                            if response == NSAlertFirstButtonReturn
                            {
                                //User cancelled sync.
                                showAlert("You cannot have multiple encryption settings for the same email account. Please update your settings on your other device with the ones that you have here.")
                            }
                            else
                            {
                                //User wishes to proceed.
                                //Get the current user's email Address so we can save the new keys
                                if let emailAddress: String = GlobalVars.currentUser?.emailAddress, !emailAddress.isEmpty
                                {
                                    //Save the new keys
                                    KeyController.sharedInstance.save(privateKey: newPrivateKey, publicKey: newPublicKey, forUserWithEmail: emailAddress)
                                    updatedKey = true
                                    
                                    //Ask user if they want to send their new keys to their PenPals
                                    let notifyPenPalsAlert = NSAlert()
                                    notifyPenPalsAlert.messageText = "Send new settings to current PanPals?"
                                    notifyPenPalsAlert.informativeText = "Your encryption settings have been synced with your other device. Do you want to send your new settings to all of your existing PenPals?"
                                    notifyPenPalsAlert.addButton(withTitle: localizedCancelButtonTitle)
                                    notifyPenPalsAlert.addButton(withTitle: localizedOKButtonTitle)
                                    let response = notifyPenPalsAlert.runModal()
                                    
                                    if response == NSAlertFirstButtonReturn
                                    {
                                        //Do not send new key to current PenPals
                                        showAlert("Your new key has not been sent to any of your current PenPals. You can still choose to send a key to PenPals manually whenever you are ready.")
                                        
                                        //Reset sentKey property for all contacts
                                        PenPalController.sharedInstance.updateAllPenPalsKeyNotSent()
                                        
                                    }
                                    else
                                    {
                                        //Send new key to all existing penpals
                                        PenPalController.sharedInstance.sendKeyToAllExistingPenPals()
                                    }
                                    
                                }
                                else
                                {
                                    //Unable To Find User's Email Failure
                                    updatedKey = false
                                }
                            }
                        }
                    }
                    else
                    {
                        //New Public Key Not Available Failure
                        updatedKey = false
                    }
                }
                else
                {
                    //New Private Key Not Available Failure
                    updatedKey = false
                }
            }
            else
            {
                //Sync versions do not match failure
                updatedKey = false
            }
        }
        else
        {
            //Sync version wasn't provided failure
            updatedKey = false
        }
        
        if updatedKey == false
        {
            ///TODO: NEW USER VISIBLE TEXT NEEDS APPROVAL FOR TRANSLATION
            showAlert("We were unable to import your new encryption settings")
        }
    }
    
    //MARK: Actions
    
    @IBAction func composeClick(_ sender: NSButton) {
    }
    
    @IBAction func inboxClick(_ sender: NSButton)
    {
        showMessages()
    }
    
    @IBAction func penPalsClick(_ sender: NSButton)
    {
        showPenPals()
    }
    
    lazy var welcomeWindowController: WelcomeWindowController =
    {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateController(withIdentifier: "WelcomeWindowController") as! WelcomeWindowController
        return newWindowController
    }()

    
    @IBAction func lockdownClick(_ sender: NSButton)
    {
        //'Lock' Postcards
        if let currentUser = GlobalVars.currentUser
        {
            MailController.sharedInstance.removeAllDecryptionForUser(currentUser)
        }
        
        //Present Welcome View
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newContentController = storyboard.instantiateController(withIdentifier: "Locked View") as! LockedViewController
        welcomeWindowController.contentViewController = newContentController
        welcomeWindowController.showWindow(sender)
        
        //And Close Main Postcard Window
        self.view.window?.close()
        
        KeyController.sharedInstance.deleteInstance()
    }
    
    @IBAction func logoutClick(_ sender: NSButton)
    {
        //Remove current User from Constants
        GlobalVars.currentUser = nil
        KeyController.sharedInstance.deleteInstance()
        
        //Remove google Auth Token
        GTMOAuth2WindowController.removeAuthFromKeychain(forName: GmailProps.kKeychainItemName)

        //Present Welcome View
        welcomeWindowController.showWindow(sender)
        
        self.view.window?.close()
    }
    
    //MARK: Content
    
    func selectMode(_ mode: SelectedMode)
    {
        switch mode
        {
        case .inbox:
            showMessages()
        case .penpals:
            showPenPals()
        }
    }
    
    func showPenPals()
    {
        let splitVC = parent as! NSSplitViewController
        let penPalVC = storyboard?.instantiateController(withIdentifier: "PenPals View") as! PenPalsViewController
        let splitViewItem = NSSplitViewItem(viewController: penPalVC)
        splitVC.removeSplitViewItem(splitVC.splitViewItems[1])
        splitVC.addSplitViewItem(splitViewItem)
        
        //TODO: Show button state
        penPalsButton.state = NSOnState
        inboxButton.state = NSOffState
    }
    
    func showMessages()
    {
        let splitVC = parent as! NSSplitViewController
        let contentVC = storyboard?.instantiateController(withIdentifier: "Messages Split View") as! NSSplitViewController
        let splitViewItem = NSSplitViewItem(viewController: contentVC)
        splitVC.removeSplitViewItem(splitVC.splitViewItems[1] )
        splitVC.addSplitViewItem(splitViewItem)
        
        //TODO: Show button state
        inboxButton.state = NSOnState
        penPalsButton.state = NSOffState
    }
    
    //MARK: Helper Methods
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
    
    //MARK: Style
    
    func styleButtons()
    {
        let paragraphStyleCenter = NSMutableParagraphStyle()
        paragraphStyleCenter.alignment = .center
        
        let paragraphStyleLeft = NSMutableParagraphStyle()
        paragraphStyleLeft.alignment = .justified
        
        var buttonFont = NSFont.boldSystemFont(ofSize: 13)
        if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
        {
            buttonFont = maybeFont
        }
        
        var buttonFont2 = NSFont.boldSystemFont(ofSize: 13)
        if let maybeFont2 = NSFont(name: PostcardUI.boldAFont, size: 13)
        {
            buttonFont2 = maybeFont2
        }
        
        let composeAttributes = [NSForegroundColorAttributeName: NSColor.white,NSParagraphStyleAttributeName: paragraphStyleCenter, NSFontAttributeName: buttonFont]
        let attributes = [NSForegroundColorAttributeName: NSColor.white,NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altInboxAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altPenpalAttributes = [NSForegroundColorAttributeName: PostcardUI.green, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.orange, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        
        inboxButton.attributedTitle = NSAttributedString(string: localizedInboxButtonTitle, attributes: attributes)
        inboxButton.attributedAlternateTitle = NSAttributedString(string: localizedInboxButtonTitle, attributes: altInboxAttributes)
        
        composeButton.attributedTitle = NSAttributedString(string: localizedComposeButtonTitle, attributes: composeAttributes)
        
        penPalsButton.attributedTitle = NSAttributedString(string: localizedPenPalsButtonTitle, attributes: attributes)
        penPalsButton.attributedAlternateTitle = NSAttributedString(string: localizedPenPalsButtonTitle, attributes: altPenpalAttributes)
        
        lockdownButton.attributedTitle = NSAttributedString(string: localizedLockdownButtonTitle, attributes: attributes)
        lockdownButton.attributedAlternateTitle = NSAttributedString(string: localizedLockdownButtonTitle, attributes: altAttributes)
        
        logoutButton.attributedTitle = NSAttributedString(string: localizedLogoutButtonTitle, attributes: attributes)
        logoutButton.attributedAlternateTitle = NSAttributedString(string: localizedLogoutButtonTitle, attributes: altAttributes)
    }
    
}
