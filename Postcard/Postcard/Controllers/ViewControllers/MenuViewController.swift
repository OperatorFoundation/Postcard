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
    case Inbox, Penpals
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
        
        selectMode(.Inbox)
    }
    
    //MARK: Actions
    
    @IBAction func composeClick(sender: NSButton) {
    }
    
    @IBAction func inboxClick(sender: NSButton)
    {
        showMessages()
    }
    
    @IBAction func penPalsClick(sender: NSButton)
    {
        showPenPals()
    }
    
    lazy var welcomeWindowController: WelcomeWindowController =
    {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateControllerWithIdentifier("WelcomeWindowController") as! WelcomeWindowController
        return newWindowController
    }()

    
    @IBAction func lockdownClick(sender: NSButton)
    {
        //'Lock' Postcards
        if let currentUser = GlobalVars.currentUser
        {
            MailController.sharedInstance.removeAllDecryptionForUser(currentUser)
        }
        
        //Present Welcome View
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newContentController = storyboard.instantiateControllerWithIdentifier("Locked View") as! LockedViewController
        welcomeWindowController.contentViewController = newContentController
        welcomeWindowController.showWindow(sender)
        
        //And Close Main Postcard Window
        self.view.window?.close()
    }
    
    @IBAction func logoutClick(sender: NSButton)
    {
        //Remove current User from Constants
        GlobalVars.currentUser = nil
        KeyController.sharedInstance.resetKeys()
        
        //Remove google Auth Token
        GTMOAuth2WindowController.removeAuthFromKeychainForName(GmailProps.kKeychainItemName)

        //Present Welcome View
        welcomeWindowController.showWindow(sender)
        
        self.view.window?.close()
    }
    
    //MARK: Content
    
    func selectMode(mode: SelectedMode)
    {
        switch mode
        {
        case .Inbox:
            showMessages()
        case .Penpals:
            showPenPals()
        }
    }
    
    func showPenPals()
    {
        let splitVC = parentViewController as! NSSplitViewController
        let penPalVC = storyboard?.instantiateControllerWithIdentifier("PenPals View") as! PenPalsViewController
        let splitViewItem = NSSplitViewItem(viewController: penPalVC)
        splitVC.removeSplitViewItem(splitVC.splitViewItems[1])
        splitVC.addSplitViewItem(splitViewItem)
        
        //TODO: Show button state
        penPalsButton.state = NSOnState
        inboxButton.state = NSOffState
        
    }
    
    func showMessages()
    {
        let splitVC = parentViewController as! NSSplitViewController
        let contentVC = storyboard?.instantiateControllerWithIdentifier("Messages Split View") as! NSSplitViewController
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
        paragraphStyleCenter.alignment = .Center
        
        let paragraphStyleLeft = NSMutableParagraphStyle()
        paragraphStyleLeft.alignment = .Justified
        
        var buttonFont = NSFont.boldSystemFontOfSize(13)
        if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
        {
            buttonFont = maybeFont
        }
        
        var buttonFont2 = NSFont.boldSystemFontOfSize(13)
        if let maybeFont2 = NSFont(name: PostcardUI.boldAFont, size: 13)
        {
            buttonFont2 = maybeFont2
        }
        
        let composeAttributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyleCenter, NSFontAttributeName: buttonFont]
        let attributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altInboxAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altPenpalAttributes = [NSForegroundColorAttributeName: PostcardUI.green, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.orange, NSParagraphStyleAttributeName: paragraphStyleLeft, NSFontAttributeName: buttonFont2]
        
        inboxButton.attributedTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.inboxButtonTitle, comment: ""), attributes: attributes)
        inboxButton.attributedAlternateTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.inboxButtonTitle, comment: ""), attributes: altInboxAttributes)
        
        composeButton.attributedTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.composeButtonTitle, comment: ""), attributes: composeAttributes)
        
        penPalsButton.attributedTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.penPalsButtonTitle, comment: ""), attributes: attributes)
        penPalsButton.attributedAlternateTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.penPalsButtonTitle, comment: ""), attributes: altPenpalAttributes)
        
        lockdownButton.attributedTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.lockdownButtonTitle, comment: ""), attributes: attributes)
        lockdownButton.attributedAlternateTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.lockdownButtonTitle, comment: ""), attributes: altAttributes)
        
        logoutButton.attributedTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.logoutButtonTitle, comment: ""), attributes: attributes)
        logoutButton.attributedAlternateTitle = NSAttributedString(string: NSLocalizedString(localizationKeys.logoutButtonTitle, comment: ""), attributes: altAttributes)
    }
    
}
