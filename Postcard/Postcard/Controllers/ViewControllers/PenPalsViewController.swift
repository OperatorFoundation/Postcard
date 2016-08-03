//
//  PenPalsViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class PenPalsViewController: NSViewController, NSTableViewDelegate
{
    @IBOutlet weak var penPalsTableView: NSTableView!
    @IBOutlet var penPalsArrayController: NSArrayController!
    
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
        //Setup Array Controller Contents
        if let currentUser = GlobalVars.currentUser
        {
            let predicate = NSPredicate(format: "owner == %@", currentUser)
            penPalsArrayController.fetchPredicate = predicate
            
            let hasKeySortDescriptor = NSSortDescriptor(key: "key", ascending: false)
            let invitedSortDescriptor = NSSortDescriptor(key: "sentKey", ascending: false)
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
            let emailSortDescriptor = NSSortDescriptor(key: "email", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
            penPalsArrayController.sortDescriptors = [hasKeySortDescriptor, invitedSortDescriptor, nameSortDescriptor, emailSortDescriptor]
        }
        
        penPalsTableView.target = self
        penPalsTableView.doubleAction = #selector(doubleClickComposeEmail)
    }
    
    func doubleClickComposeEmail()
    {
        if let thisPenPal = penPalsArrayController.selectedObjects[0] as? PenPal
        {
            if thisPenPal.sentKey == true
            {
                performSegueWithIdentifier("Email PenPal", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "Email PenPal"
        {
            if let composeVC = segue.destinationController as? ComposeViewController
            {
                if let thisPenPal = penPalsArrayController.selectedObjects[0] as? PenPal, let email = thisPenPal.email
                {
                    composeVC.sendTo = email
                }
            }
        }
    }
    
    
}


//MARK: TableCellView
class PenPalTableCell: NSTableCellView
{
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var penPalImageView: NSImageView!
    @IBOutlet weak var actionButton: NSButton!
    @IBOutlet weak var backgroundView: DesignableView!
    
    var actionTitle = ""
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override var objectValue: AnyObject?
    {
        didSet
        {
            //Set up the action button based on penpal status
            if let penPal = objectValue as? PenPal
            {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .Center
                var buttonFont = NSFont.boldSystemFontOfSize(13)
                if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
                {
                    buttonFont = maybeFont
                }
                let attributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
                let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
                
                if penPal.key == nil && penPal.sentKey == false
                {
                    actionTitle = NSLocalizedString(localizationKeys.inviteButtonTitle, comment: "Button for inviting a friend to use the app and be one of your secure contacts.")
                    actionButton.image = NSImage(named: "redButton")
                    actionButton.target = self
                    actionButton.action = #selector(inviteAction)
                    backgroundView.viewColor = PostcardUI.gray
                    actionButton.hidden = false
                }
                else if penPal.key != nil && penPal.sentKey == false
                {
                    actionTitle = NSLocalizedString(localizationKeys.addButtonTitle, comment: "Accept another user's invitation to be a secure contact.")
                    actionButton.image = NSImage(named: "greenButton")
                    actionButton.target = self
                    actionButton.action = #selector(addAction)
                    backgroundView.viewColor = NSColor.whiteColor()
                    actionButton.hidden = false
                }
                else //if penPal.key != nil && penPal.sentKey == true
                {
                    actionButton.hidden = true
                    backgroundView.viewColor = PostcardUI.gray
                }
                
                actionButton.attributedTitle = NSAttributedString(string: actionTitle, attributes: attributes)
                actionButton.attributedAlternateTitle = NSAttributedString(string: actionTitle, attributes: altAttributes)
            }
        }
    }
    
    //We already have their key, but they don't have ours
    func addAction()
    {
        //Send key email to this user
        if let penPal = objectValue as? PenPal
        {
            KeyController.sharedInstance.sendKey(toPenPal: penPal)
        }
        
        actionButton.hidden = true
    }
    
    //We don't have their key, and they don't have ours
    func inviteAction()
    {
        //Send key email to this user
        if let penPal = objectValue as? PenPal
        {
            KeyController.sharedInstance.sendKey(toPenPal: penPal)
        }
        
        actionButton.hidden = true
    }
    
    
}
