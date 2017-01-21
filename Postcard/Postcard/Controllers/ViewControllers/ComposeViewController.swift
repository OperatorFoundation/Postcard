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
    @IBOutlet weak var toTextField: NSTokenField!
    @IBOutlet var bodyTextView: NSTextView!
    @IBOutlet weak var subjectTextField: NSTextField!
    @IBOutlet weak var attachmentButton: NSButton!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var attachmentsView: NSView!
    
    var sendTo = ""
    var reSubject = ""
    var bodyText = ""
    var attachments = [URL]()
    
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
        
        //Setup "to" tokenField
        toTextField.delegate = self
        //Should attempt to tokenize when user types a comma, a space, or a carriage return (default setting does not include a space)
        let characterSet = CharacterSet(charactersIn: " \n,")
        toTextField.tokenizingCharacterSet = characterSet
    }
    
    override func viewDidAppear()
    {
        //This is to make the title bar transparent so that the BG image is uninterrupted
        view.window?.titlebarAppearsTransparent = true
        view.window?.isMovableByWindowBackground = true
        view.window?.titleVisibility = NSWindowTitleVisibility.hidden
        self.view.window?.viewsNeedDisplay = true
    }
    
    func styleButtons()
    {
        //Alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        //Font
        var buttonFont = NSFont.boldSystemFont(ofSize: 13)
        if let maybeFont = NSFont(name: PostcardUI.boldFutura, size: 13)
        {
            buttonFont = maybeFont
        }
        
        let attributes = [NSForegroundColorAttributeName: NSColor.white,NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        let altAttributes = [NSForegroundColorAttributeName: PostcardUI.blue, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
        
        sendButton.attributedTitle = NSAttributedString(string: localizedSendTitle, attributes: attributes)
        sendButton.attributedAlternateTitle = NSAttributedString(string: localizedSendTitle, attributes: altAttributes)
        
        attachmentButton.attributedTitle = NSAttributedString(string: localizedAttachmentTitle, attributes: attributes)
        attachmentButton.attributedAlternateTitle = NSAttributedString(string: localizedAttachmentTitle, attributes: altAttributes)
    }
    
    //MARK: Actions
    
    @IBAction func sendClick(_ sender: NSButton)
    {
        if let allRecipients = toTextField.objectValue as? [String]
        {
            let subject:String = subjectTextField.stringValue
            if allRecipients.isEmpty
            {
                print("There is no recipient for this message.")
            }
            else if subject.isEmpty
            {
                print("There is no subject for this message.")
            }
            else
            {
                if let body: String = bodyTextView.string
                {
                    if body.isEmpty
                    {
                        print("This message has no body.")
                    }
                    else
                    {
                        MailController.sharedInstance.sendEmail(allRecipients, subject: subject, body: body, maybeAttachments: attachments, completion:
                        {
                            (successful) in
                            
                            if successful
                            {
                                //Close Window
                                self.view.window?.close()
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func attachClick(_ sender: NSButton)
    {
        //Create and configure the choose file panel
        let choosePanel = NSOpenPanel()
        choosePanel.allowsMultipleSelection = true
        choosePanel.message = localizedAttachmentPrompt
        
        //Display the panel attached to the compose window
        if let composeWindow = self.view.window
        {
            choosePanel.beginSheetModal(for: composeWindow, completionHandler:
            { (result) in
                if result == NSFileHandlingPanelOKButton
                {
                    let urls = choosePanel.urls
                    for thisURL in urls
                    {
                        self.attachments.append(thisURL)
                        
                        let pathString: String = thisURL.path
                        if pathString == ""
                        {
                            print("Empty attachment path.")
                        }
                        else
                        {
                            let urlParts = pathString.components(separatedBy: ".")
                            let pathParts = urlParts.first?.components(separatedBy: "/")
                            let fileName = pathParts?.last ?? ""
                            
                            //Create a button to represent the attachment
                            //TODO: multiple buttons, the ability to remove the attachment, and view the attachment
                            
                            //Button Container View
                            let containerView = NSView(frame: NSRect(x: 0, y: 8, width: 109, height: 21))
                            containerView.wantsLayer = true
                            containerView.layer?.cornerRadius = 5
                            containerView.layer?.backgroundColor = NSColor.white.cgColor
                            
                            //Attachment Button
                            let attachmentButton = AttachmentButton(frame: NSRect(x: 0, y: 0, width: 79, height: 21), attachmentURL: thisURL)
                            
                            //Alignment
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = .center
                            
                            //Font
                            var buttonFont = NSFont.systemFont(ofSize: 13)
                            if let maybeFont = NSFont(name: PostcardUI.regularAFont, size: 13)
                            {
                                buttonFont = maybeFont
                            }
                            
                            let attributes = [NSForegroundColorAttributeName: PostcardUI.black, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: buttonFont]
                            attachmentButton.attributedTitle = NSAttributedString(string: fileName, attributes: attributes)
                            attachmentButton.isBordered = false
                            
                            //Remove Attachment Button
                            let removeButton = AttachmentButton(frame: NSRect(x: 79, y: 2, width: 30, height: 21), attachmentURL: thisURL)
                            removeButton.isBordered = false
                            
                            //Font
                            var removeButtonFont = NSFont.boldSystemFont(ofSize: 14)
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
    func attachmentClicked(_ sender: NSButton, filePath: URL)
    {
        
    }
    
    func removeAttachment(_ sender: AnyObject)
    {
        if let attachmentSender = sender as? AttachmentButton
        {
            //Remove the attachment button from the view
            if let containerView = attachmentSender.superview
            {
                containerView.removeFromSuperview()
            }
            
            //Remove the attachment URL from the list of items to attach to the message
            
            if let index = attachments.index(of: attachmentSender.attachmentURL)
            {
                attachments.remove(at: index)
            }
        }
        else
        {
            //print(sender.description)
        }
    }
 
//✏️//
}

extension ComposeViewController: NSTokenFieldDelegate
{
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenStyle
    {
        //Visually Token-ize valid emails
        if let maybeEmail = representedObject as? String
        {
            if isValidEmailAddress(emailAddressString: maybeEmail)
            {
                return NSRoundedTokenStyle
            }
        }
        
        //Leave everything else in NSPlainTextTokenStyle
        return NSPlainTextTokenStyle
    }
    
/*
     From https://www.cocoanetics.com/2013/05/tokenize-this/
     If you use represented objects instead of the default strings, then you have to implement several delegate methods because the token field needs to convert between the object and what it should write on the token and what the editing value should be. From the NSTokenField.h header:
     
    // If you return nil or don't implement these delegate methods, we will assume
    // editing string = display string = represented object
    - (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject;
    - (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject;
    - (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString: (NSString *)editingString;
     
     You provide backing object for a given editing string. Conversely if the user double-clicks on a token this turns into editable text. Finally the display string is the inscription on the blue pills.
     
     For example if you have the token represent an email address, then the editing string could be “Oliver Drobnik <oliver@cocoanetics.com>” and the display string be just “Oliver Drobnik”. In that case you could have a token object class with a displayName and an email string.
*/
    
//    //Set Autocompletion Values for "To:" Token Field
//    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]?
//    {
//        return (names as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "SELF beginswith[cd] %@", substring))
//    }
    
    
    func isValidEmailAddress(emailAddressString: String) -> Bool
    {
        //Thanks to: http://swiftdeveloperblog.com/email-address-validation-in-swift/
        var returnValue = true
        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        
        do
        {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = emailAddressString as NSString
            let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0
            {
                returnValue = false
            }
            
        }
        catch let error as NSError
        {
            print("invalid regex for To field email address: \(error.localizedDescription)")
            returnValue = false
        }
        
        return  returnValue
    }
    
}


class AttachmentButton: NSButton
{
    var attachmentURL: URL
    
    init(frame frameRect: NSRect, attachmentURL: URL)
    {
        self.attachmentURL = attachmentURL
        
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    

}
