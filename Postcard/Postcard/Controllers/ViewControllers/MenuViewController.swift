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

class MenuViewController: NSViewController
{
    @IBOutlet weak var composeButton: NSButton!
    @IBOutlet weak var inboxButton: NSButton!
    @IBOutlet weak var penPalsButton: NSButton!
    @IBOutlet weak var lockdownButton: NSButton!
    @IBOutlet weak var logoutButton: NSButton!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //selectMode(.Inbox)
        styleButtons()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        selectMode(.inbox)
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
    }
    
    @IBAction func logoutClick(_ sender: NSButton)
    {
        //Remove current User from Constants
        GlobalVars.currentUser = nil
        KeyController.sharedInstance.resetKeys()
        
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
