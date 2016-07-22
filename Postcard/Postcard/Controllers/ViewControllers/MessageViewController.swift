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
    @IBOutlet var bodyTextView: NSTextView!
    @IBOutlet weak var attachmentView: DesignableView!
    @IBOutlet weak var attachmentButton: NSButton!
    @IBOutlet weak var messageContentView: NSView!
    
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        styleButtons()
        
        //Do we have an attachment?
        if let thisPostcard = postcardObjectController.content as? Postcard
        {
            attachmentButton.hidden = !(thisPostcard.hasPackage)
        }
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        if let currentUser = GlobalVars.currentUser
        {
            let predicate = NSPredicate(format: "owner == %@", currentUser)
            postcardObjectController.fetchPredicate = predicate
        }
        
        //TODO: Font setting doesn't work currently
        //Set Default Font
        if let font = NSFont(name: PostcardUI.regularAFont, size: 14)
        {
//            let attributes = [NSFontAttributeName: font]
//            bodyTextView.typingAttributes = attributes
            bodyTextView.font = font
            if let textStorage = bodyTextView.textStorage
            {
                textStorage.font = font
            }
        }
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
    
    @IBAction func deleteClick(sender: NSButton)
    {
        if let thisPostcard = postcardObjectController.content as? Postcard, let messageID = thisPostcard.identifier
        {
            MailController.sharedInstance.trashGmailMessage(thisPostcard, completion:
            { (successful) in
                if successful
                {
                    //self.postcardObjectController.removeObject(thisPostcard)
                }
                else
                {
                    self.showAlert("We couldn't delete this message from Gmail. Try again later or try deleting this email from Gmail directly.")
                }
            })
        }
    }
    
    func styleButtons()
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
        
        replyButton.attributedTitle = NSAttributedString(string: "REPLY", attributes: attributes)
        replyButton.attributedAlternateTitle = NSAttributedString(string: "REPLY", attributes: altAttributes)
        
        deleteButton.attributedTitle = NSAttributedString(string: "DELETE", attributes: attributes)
        deleteButton.attributedAlternateTitle = NSAttributedString(string: "DELETE", attributes: altAttributes)
    }
    
    //MARK: Helper Methods
    func showAlert(message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
}
