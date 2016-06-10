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
    var attachments = [NSURL]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
        styleButtons()
        
        self.view.window?.titlebarAppearsTransparent = true
        //self.view.window?.styleMask |= NSFullSizeContentViewWindowMask
        self.view.window?.movableByWindowBackground  = true
        
        //Check For Prepopulated values
        if !sendTo.isEmpty
        {
            toTextField.stringValue = sendTo
        }
        
        if !reSubject.isEmpty
        {
            subjectTextField.stringValue = reSubject
        }
    }
    
    func styleButtons()
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        let attributes = [NSForegroundColorAttributeName: NSColor.whiteColor(),NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: NSFont.boldSystemFontOfSize(13)]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: NSFont.boldSystemFontOfSize(13)]
        
        sendButton.attributedTitle = NSAttributedString(string: "Send", attributes: attributes)
        sendButton.attributedAlternateTitle = NSAttributedString(string: "Send", attributes: altAttributes)
        
        attachmentButton.attributedTitle = NSAttributedString(string: "Attachment", attributes: attributes)
        attachmentButton.attributedAlternateTitle = NSAttributedString(string: "Attachment", attributes: altAttributes)
    }
    
    //MARK: Actions
    
    @IBAction func sendClick(sender: NSButton)
    {
        if let recipient:String = toTextField.stringValue where !recipient.isEmpty, let subject:String = subjectTextField.stringValue, let body: String = bodyTextView.string
        {
            MailController().sendEmail(recipient, subject: subject, body: body, maybeAttachments: attachments)
        }
        
        //Close Window
        self.view.window?.close()
    }
    
    @IBAction func attachClick(sender: NSButton)
    {
        
        //Create and configure the choose file panel
        let choosePanel = NSOpenPanel()
        choosePanel.allowsMultipleSelection = true
        choosePanel.message = "Select the file(s) you would like to attach."
        
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
                            let attachmentButton = NSButton(frame: NSRect(x: 0, y: 0, width: 79, height: 21))
                            attachmentButton.title = fileName
                            attachmentButton.bordered = false
                            
                            //Remove Attachment Button
                            let removeButton = NSButton(frame: NSRect(x: 79, y: 2, width: 30, height: 21))
                            removeButton.bordered = false
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = .Center
                            let attributes = [NSForegroundColorAttributeName: PostcardUI.red, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: NSFont.boldSystemFontOfSize(14)]
                            removeButton.attributedTitle = NSAttributedString(string: "x", attributes: attributes)
                            
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

    
}
