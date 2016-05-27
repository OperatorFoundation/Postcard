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
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
        self.view.window?.titlebarAppearsTransparent = true
        //self.view.window?.styleMask |= NSFullSizeContentViewWindowMask
        self.view.window?.movableByWindowBackground  = true
    }
    
    //MARK: Actions
    
    @IBAction func sendClick(sender: NSButton)
    {
        if let recipient:String = toTextField.stringValue where !recipient.isEmpty, let subject:String = subjectTextField.stringValue, let body: String = bodyTextView.string
        {
            MailController().sendEmail(recipient, subject: subject, body: body)
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
                    
                    //Attach these files to the outgoing message
                }
            })
        }
    }

    
}
