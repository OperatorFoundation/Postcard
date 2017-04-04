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
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
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
                performSegue(withIdentifier: "Email PenPal", sender: self)
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "Email PenPal"
        {
            if let composeVC = segue.destinationController as? ComposeViewController
            {
                if let thisPenPal = penPalsArrayController.selectedObjects[0] as? PenPal
                {
                    let email = thisPenPal.email
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
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    override var objectValue: Any?
    {
        didSet
        {
            //Set up the action button based on penpal status
            if let penPal = objectValue as? PenPal
            {
                //Button Appearance
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                var buttonFont = NSFont.boldSystemFont(ofSize: 13)
                if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
                {
                    buttonFont = maybeFont
                }
                
                let attributes = [NSForegroundColorAttributeName: NSColor.white,NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
                let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]

                if penPal.key != nil && penPal.sentKey == false
                {
                    //They sent a key, but we have not
                    actionTitle = localizedAddButtonTitle
                    actionButton.image = NSImage(named: "greenButton")
                    actionButton.target = self
                    actionButton.action = #selector(addAction)
                    backgroundView.viewColor = NSColor.white
                    actionButton.isHidden = false
                }
                else if penPal.key != nil && penPal.sentKey == true
                {
                    //They have sent a key and so have we, these are Postcard Contacts
                    actionButton.isHidden = true
                    backgroundView.viewColor = PostcardUI.gray
                }
                else //penPal.key == nil && penPal.sentKey == false
                {
                    //We have not sent an invite, and neither have they
                    actionTitle = localizedInviteButtonTitle
                    actionButton.image = NSImage(named: "redButton")
                    actionButton.target = self
                    actionButton.action = #selector(inviteAction)
                    backgroundView.viewColor = PostcardUI.gray
                    actionButton.isHidden = false
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
        
        actionButton.isHidden = true
    }
    
    //We don't have their key, and they don't have ours
    func inviteAction()
    {
        //Send key email to this user
        if let penPal = objectValue as? PenPal
        {
            KeyController.sharedInstance.sendKey(toPenPal: penPal)
        }
        
        actionButton.isHidden = true
    }
    
    
}
