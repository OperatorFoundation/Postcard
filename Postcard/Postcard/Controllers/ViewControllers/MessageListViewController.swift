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
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func rowSelected(sender: NSTableView)
    {
        if let selectedPostcard = postcardsArrayController.selectedObjects[0] as? Postcard
        {
            selectedPostcard.decrypted = true
            //Save this Postcard to core data
            do
            {
                try selectedPostcard.managedObjectContext?.save()
            }
            catch
            {
                let saveError = error as NSError
                print("\(saveError)")
            }
            
            let splitVC = parentViewController as! NSSplitViewController
            if let messageVC: MessageViewController = splitVC.childViewControllers[1] as? MessageViewController
            {
                messageVC.postcardObjectController.content = selectedPostcard
            }
        }
    }

}


class MessagesTableCell: NSTableCellView
{
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var subjectLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var snippetLabel: NSTextField!
    @IBOutlet weak var penPalImageView: NSImageView!
    
    override func drawRect(dirtyRect: NSRect)
    {
        super.drawRect(dirtyRect)
        
        //When a cell is selected the system sets background style to dark by default
        //Use this to change the cell color
        if backgroundStyle == NSBackgroundStyle.Dark
        {
            NSColor.whiteColor().setFill()
            NSRectFill(dirtyRect)
        }
    }
    
    
}