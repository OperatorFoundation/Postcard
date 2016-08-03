//
//  ComposeViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/20/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class ComposeViewController: NSViewController
{
    @IBOutlet weak var toTextField: NSTextField!
    @IBOutlet var bodyTextView: NSTextView!
    @IBOutlet weak var subjectTextField: NSTextField!
    @IBOutlet weak var attachmentButton: NSButton!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var attachmentsView: NSView!
    
    var sendTo = ""
    var reSubject = ""
    var bodyText = ""
    var attachments = [NSURL]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        styleButtons()
        
        //Set Default Font
        if let font = NSFont(name: PostcardUI.regularAFont, size: 14)
        {
            let attributes = [NSFontAttributeName: font]
            bodyTextView.typingAttributes = attributes
        }
        
        //Check For Prepopulated values
        if !sendTo.isEmpty {toTextField.stringValue = sendTo}
        if !reSubject.isEmpty {subjectTextField.stringValue = reSubject}
        if !bodyText.isEmpty {bodyTextView.string = bodyText}
    }
    
    override func viewDidAppear()
    {
        //This is to make the title bar transparent so that the BG image is uninterrupted
        view.window?.titlebarAppearsTransparent = true
        view.window?.movableByWindowBackground = true
        view.window?.titleVisibility = NSWindowTitleVisibility.Hidden
        self.view.window?.viewsNeedDisplay = true
    }
    
    func styleButtons()
    {
        //Alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        
        //Font
        var buttonFont = NSFont.boldSystemFontOfSize(13)
        if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
        {
            buttonFont = maybeFont
        }
        
        let attributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        
        sendButton.attributedTitle = NSAttributedString(string: localizationKeys.localizedSendTitle, attributes: attributes)
        sendButton.attributedAlternateTitle = NSAttributedString(string: localizationKeys.localizedSendTitle, attributes: altAttributes)
        
        attachmentButton.attributedTitle = NSAttributedString(string: localizationKeys.localizedAttachmentTitle, attributes: attributes)
        attachmentButton.attributedAlternateTitle = NSAttributedString(string: localizationKeys.localizedAttachmentTitle, attributes: altAttributes)
    }
    
    //MARK: Actions
    
    @IBAction func sendClick(sender: NSButton)
    {
        if let recipient:String = toTextField.stringValue where !recipient.isEmpty, let subject:String = subjectTextField.stringValue, let body: String = bodyTextView.string
        {
            MailController.sharedInstance.sendEmail(recipient, subject: subject, body: body, maybeAttachments: attachments, completion:
            { (successful) in
                if successful
                {
                    //Close Window
                    self.view.window?.close()
                }
            })
        }
    }
    
    @IBAction func attachClick(sender: NSButton)
    {
        //Create and configure the choose file panel
        let choosePanel = NSOpenPanel()
        choosePanel.allowsMultipleSelection = true
        choosePanel.message = localizationKeys.localizedAttachmentPrompt
        
        //Display the panel attached to the compose window
        if let composeWindow = self.view.window
        {
            choosePanel.beginSheetModalForWindow(composeWindow, completionHandler:
            { (result) in
                if result == NSFileHandlingPanelOKButton
                {
                    let urls = choosePanel.URLs
                    for thisURL in urls
                    {
                        self.attachments.append(thisURL)
                        
                        if let pathString = thisURL.path
                        {
                            let urlParts = pathString.componentsSeparatedByString(".")
                            let pathParts = urlParts.first?.componentsSeparatedByString("/")
                            let fileName = pathParts?.last ?? ""
                            
                            //Create a button to represent the attachment
                            //TODO: multiple buttons, the ability to remove the attachment, and view the attachment
                            
                            //Button Container View
                            let containerView = NSView(frame: NSRect(x: 0, y: 8, width: 109, height: 21))
                            containerView.wantsLayer = true
                            containerView.layer?.cornerRadius = 5
                            containerView.layer?.backgroundColor = NSColor.whiteColor().CGColor
                            
                            //Attachment Button
                            let attachmentButton = AttachmentButton(frame: NSRect(x: 0, y: 0, width: 79, height: 21), attachmentURL: thisURL)
                            
                            //Alignment
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = .Center
                            
                            //Font
                            var buttonFont = NSFont.systemFontOfSize(13)
                            if let maybeFont = NSFont(name: PostcardUI.regularAFont, size: 13)
                            {
                                buttonFont = maybeFont
                            }
                            
                            let attributes = [NSForegroundColorAttributeName: PostcardUI.black, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
                            attachmentButton.attributedTitle = NSAttributedString(string: fileName, attributes: attributes)
                            attachmentButton.bordered = false
                            
                            //Remove Attachment Button
                            let removeButton = AttachmentButton(frame: NSRect(x: 79, y: 2, width: 30, height: 21), attachmentURL: thisURL)
                            removeButton.bordered = false
                            
                            //Font
                            var removeButtonFont = NSFont.boldSystemFontOfSize(14)
                            if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 14)
                            {
                                removeButtonFont = maybeFont
                            }

                            let removeAttributes = [NSForegroundColorAttributeName: PostcardUI.red, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: removeButtonFont]
                            removeButton.attributedTitle = NSAttributedString(string: "x", attributes: removeAttributes)
                            removeButton.target = self
                            removeButton.action = #selector(ComposeViewController.removeAttachment)
                            
                            containerView.addSubview(attachmentButton)
                            containerView.addSubview(removeButton)
                            self.attachmentsView.addSubview(containerView)
                        }
                    }
                }
            })
        }
    }
    
    //TODO: Open the attachment file when attachment button is clicked
    func attachmentClicked(sender: NSButton, filePath: NSURL)
    {
        
    }
    
    func removeAttachment(sender: AnyObject)
    {
        if let attachmentSender = sender as? AttachmentButton
        {
            //Remove the attachment button from the view
            if let containerView = attachmentSender.superview
            {
                containerView.removeFromSuperview()
            }
            
            //Remove the attachment URL from the list of items to attach to the message
            
            if let index = attachments.indexOf(sender.attachmentURL)
            {
                attachments.removeAtIndex(index)
            }
        }
        else
        {
            //print(sender.description)
        }
    }
 
//
}


class AttachmentButton: NSButton
{
    var attachmentURL: NSURL
    
    init(frame frameRect: NSRect, attachmentURL: NSURL)
    {
        self.attachmentURL = attachmentURL
        
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
//
}
