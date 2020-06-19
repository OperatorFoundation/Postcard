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
    
    var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext

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
        
        postcardObjectController.content = nil
        //Hide Message Header
        headerView.isHidden = true

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
        
        let attributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.white,convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont]
        let altAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): PostcardUI.blue, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle, convertFromNSAttributedStringKey(NSAttributedString.Key.font): buttonFont]
        
        replyButton.attributedTitle = NSAttributedString(string: localizedReplyTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        replyButton.attributedAlternateTitle = NSAttributedString(string: localizedReplyTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altAttributes))
        
        deleteButton.attributedTitle = NSAttributedString(string: localizedDeleteTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        deleteButton.attributedAlternateTitle = NSAttributedString(string: localizedDeleteTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary(altAttributes))
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
