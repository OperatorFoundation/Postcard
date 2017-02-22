//
//  MessageListViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class MessageListViewController: NSViewController, NSTableViewDelegate
{
    @IBOutlet var postcardsArrayController: NSArrayController!
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
        let splitVC = parent as! NSSplitViewController
        if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController, let messageView = messageVC.messageContentView
        {
            messageView.isHidden = true
        }
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()

        //Make sure that the array controller for bindings is only looking at messages for the correct user
        //TODO: This is not available quickly enough, should we store it in UD?
        if let currentUser = GlobalVars.currentUser
        {
            let predicate = NSPredicate(format: "owner == %@", currentUser)
            postcardsArrayController.fetchPredicate = predicate
        }
    }
    
    @IBAction func rowSelected(_ sender: NSTableView)
    {
        if !postcardsArrayController.selectedObjects.isEmpty, let selectedPostcard = postcardsArrayController.selectedObjects[0] as? Postcard
        {
            //Decrypt the postcard on selection
            //TODO: Should this be a callback function?
            if selectedPostcard.decrypted == false
            {
                MailController.sharedInstance.decryptPostcard(selectedPostcard)
            }
            
            //Tell the message VC what message to display
            let splitVC = parent as! NSSplitViewController
            if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController
            {
                messageVC.postcardObjectController.content = selectedPostcard
                messageVC.headerView.isHidden = false
//                let newConstraint = NSLayoutConstraint(item: messageVC.contentView, attribute: .top, relatedBy: .equal, toItem: messageVC.headerView, attribute: .bottom, multiplier: 1, constant: 0)
//                newConstraint.isActive = true
            }
        }
        else
        {
            let splitVC = parent as! NSSplitViewController
            if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController
            {
                messageVC.postcardObjectController.content = nil
                messageVC.headerView.isHidden = true
//                let newConstraint = NSLayoutConstraint(item: messageVC.contentView, attribute: .top, relatedBy: .equal, toItem: messageVC.headerView, attribute: .top, multiplier: 1, constant: 0)
//                newConstraint.isActive = true
            }
        }
    }
    
//
}


//MARK: Custom Table Cell Class
class MessagesTableCell: NSTableCellView
{
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var subjectLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var snippetLabel: NSTextField!
    @IBOutlet weak var penPalImageView: NSImageView!
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        //When a cell is selected the system sets background style to dark by default
        //Use this to change the cell color
        if backgroundStyle == NSBackgroundStyle.dark
        {
            NSColor.white.setFill()
            NSRectFill(dirtyRect)
        }
    }
    
//
}
