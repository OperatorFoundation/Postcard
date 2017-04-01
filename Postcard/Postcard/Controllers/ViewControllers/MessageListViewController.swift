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
    @IBOutlet weak var postcardsTableView: NSTableView!
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        //Make sure that the array controller for bindings is only looking at messages for the correct user
        //TODO: This is not available quickly enough, should we store it in UD?
        if let currentUser = GlobalVars.currentUser
        {
            if let userPublicKey = KeyController.sharedInstance.mySharedKey as NSData?
            {
                //let predicate = NSPredicate(format: "(owner == %@) AND (receiverKey == %@)", currentUser, userPublicKey)
                let predicate = NSPredicate(format: "owner == %@", currentUser)
                postcardsArrayController.fetchPredicate = predicate
                print("******My Public Key: 🗝\(userPublicKey)🗝")
            }
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
                if GlobalVars.messageCache == nil
                {
                    GlobalVars.messageCache = Dictionary <String, PostcardMessage>()
                }
                
                guard let messageID = selectedPostcard.identifier
                else
                {
                    return
                }
                
                if GlobalVars.messageCache![messageID] != nil
                {
                    print("Found a message in the cache: \(GlobalVars.messageCache![messageID])")
                    return
                }

                if let decryptedMessage = MailController.sharedInstance.decryptPostcard(selectedPostcard)
                {
                    selectedPostcard.decrypted = true
                    selectedPostcard.to = decryptedMessage.to
                    GlobalVars.messageCache![messageID] = decryptedMessage
                    
                    //Attachment?
                    //            let attachments = messageParser?.attachments()
                    //
                    //            if (attachments?.isEmpty)!
                    //            {
                    //                postcard.hasPackage = false
                    //            }
                    //            else
                    //            {
                    //                //TODO: ignore key attachments
                    //                postcard.hasPackage = true
                    //            }
                    
                    //Save these changes to core data
                    do
                    {
                        try selectedPostcard.managedObjectContext?.save()
                    }
                    catch
                    {
                        let saveError = error as NSError
                        print("\(saveError.localizedDescription)")
                    }
                    
                    postcardsTableView.reloadData()
                }
            }
            
            //Tell the message VC what message to display
            let splitVC = parent as! NSSplitViewController
            if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController
            {
                messageVC.postcardObjectController.content = selectedPostcard
                
                //Show Message Header
                messageVC.headerView.isHidden = false
            }
        }
        else
        {
            let splitVC = parent as! NSSplitViewController
            if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController
            {
                messageVC.postcardObjectController.content = nil
                
                //Hide Message Header
                messageVC.headerView.isHidden = true
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
