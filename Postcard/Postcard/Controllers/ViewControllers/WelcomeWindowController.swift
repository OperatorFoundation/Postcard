//
//  WelcomeWindowController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/26/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class WelcomeWindowController: NSWindowController
{

    override func windowDidLoad()
    {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        window?.titleVisibility = NSWindowTitleVisibility.hidden        
    }

}
