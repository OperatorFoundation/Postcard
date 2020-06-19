//
//  MenuViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import AppAuth

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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        styleButtons()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        selectMode(.inbox)
    }
    
    //MARK: Actions
    
    @IBAction func composeClick(_ sender: NSButton)
    {
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
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: GmailProps.kKeychainItemName)

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
        penPalsButton.state = .on
        inboxButton.state = .off
    }
    
    func showMessages()
    {
        let splitVC = parent as! NSSplitViewController
        let contentVC = storyboard?.instantiateController(withIdentifier: "Messages Split View") as! NSSplitViewController
        let splitViewItem = NSSplitViewItem(viewController: contentVC)
        splitVC.removeSplitViewItem(splitVC.splitViewItems[1] )
        splitVC.addSplitViewItem(splitViewItem)
        
        //TODO: Show button state
        inboxButton.state = .on
        penPalsButton.state = .off
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
        
        let composeAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.white,convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyleCenter, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont]
        let attributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.white,convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyleLeft, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont2]
        let altInboxAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): PostcardUI.blue, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyleLeft, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont2]
        let altPenpalAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): PostcardUI.green, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyleLeft, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont2]
        let altAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): PostcardUI.orange, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyleLeft, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont2]
        
        inboxButton.attributedTitle = NSAttributedString(string: localizedInboxButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        inboxButton.attributedAlternateTitle = NSAttributedString(string: localizedInboxButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altInboxAttributes))
        
        composeButton.attributedTitle = NSAttributedString(string: localizedComposeButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(composeAttributes))
        
        penPalsButton.attributedTitle = NSAttributedString(string: localizedPenPalsButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        penPalsButton.attributedAlternateTitle = NSAttributedString(string: localizedPenPalsButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altPenpalAttributes))
        
        lockdownButton.attributedTitle = NSAttributedString(string: localizedLockdownButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        lockdownButton.attributedAlternateTitle = NSAttributedString(string: localizedLockdownButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altAttributes))
        
        logoutButton.attributedTitle = NSAttributedString(string: localizedLogoutButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        logoutButton.attributedAlternateTitle = NSAttributedString(string: localizedLogoutButtonTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altAttributes))
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
