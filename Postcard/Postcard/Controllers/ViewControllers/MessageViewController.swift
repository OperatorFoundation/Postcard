//
//  MessageViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class MessageViewController: NSViewController
{
    @IBOutlet weak var replyButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet var postcardObjectController: NSObjectController!
    
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do view setup here.
        styleButtons()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?)
    {
        //Populate compose view with this message information.
        
        if segue.identifier == "Reply To Message"
        {
            if let rePostcard = postcardObjectController.content as? Postcard
            {
                if let composeVC = segue.destinationController as? ComposeViewController
                {
                    if let from = rePostcard.from, let sendTo = from.email, let subject = rePostcard.subject
                    {
                        composeVC.sendTo = sendTo
                        composeVC.reSubject = "re: \(subject)"
                    }
                }
            }
        }
    }
    
    func styleButtons()
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        let attributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: NSFont.boldSystemFontOfSize(13)]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: NSFont.boldSystemFontOfSize(13)]
        
        replyButton.attributedTitle = NSAttributedString(string: "Reply", attributes: attributes)
        replyButton.attributedAlternateTitle = NSAttributedString(string: "Reply", attributes: altAttributes)
        
        deleteButton.attributedTitle = NSAttributedString(string: "Delete", attributes: attributes)
        deleteButton.attributedAlternateTitle = NSAttributedString(string: "Delete", attributes: altAttributes)
    }
}
