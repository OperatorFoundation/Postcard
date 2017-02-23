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
    @IBOutlet weak var headerView: DesignableView!
    @IBOutlet weak var contentView: DesignableView!
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        styleButtons()
        
        //Do we have an attachment?
        if let thisPostcard = postcardObjectController.content as? Postcard
        {
            attachmentButton.isHidden = !(thisPostcard.hasPackage)
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
            bodyTextView.font = font
            if let textStorage = bodyTextView.textStorage
            {
                textStorage.font = font
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?)
    {
        //Populate compose view with this message information.
        
        if segue.identifier == "Reply To Message"
        {
            if let rePostcard = postcardObjectController.content as? Postcard
            {
                if let composeVC = segue.destinationController as? ComposeViewController
                {
                    if let from = rePostcard.from, let subject = rePostcard.subject
                    {
                        let sendTo = from.email
                        
                        composeVC.sendTo = sendTo
                        composeVC.reSubject = localizedReplyStarter + subject
                    }
                }
            }
        }
    }
    
    @IBAction func deleteClick(_ sender: NSButton)
    {
        if let thisPostcard = postcardObjectController.content as? Postcard
        {
            MailController.sharedInstance.trashGmailMessage(thisPostcard, completion:
            { (successful) in
                if successful
                {
                    //self.postcardObjectController.removeObject(thisPostcard)
                }
                else
                {
                    self.showAlert(localizedDeleteGmailError)
                }
            })
        }
    }
    
    func styleButtons()
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        var buttonFont = NSFont.boldSystemFont(ofSize: 13)
        if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
        {
            buttonFont = maybeFont
        }
        
        let attributes = [NSForegroundColorAttributeName: NSColor.white,NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        
        replyButton.attributedTitle = NSAttributedString(string: localizedReplyTitle, attributes: attributes)
        replyButton.attributedAlternateTitle = NSAttributedString(string: localizedReplyTitle, attributes: altAttributes)
        
        deleteButton.attributedTitle = NSAttributedString(string: localizedDeleteTitle, attributes: attributes)
        deleteButton.attributedAlternateTitle = NSAttributedString(string: localizedDeleteTitle, attributes: altAttributes)
    }
    
    //MARK: Helper Methods
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: localizedOKButtonTitle)
        alert.runModal()
    }
    
}
