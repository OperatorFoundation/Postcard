//
//  MainWindowController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/20/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController
{
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.window?.setContentSize(NSSize(width: 1070, height: 640))
        self.window?.titlebarAppearsTransparent = true
        
        window?.isMovableByWindowBackground = true
        window?.titleVisibility = NSWindow.TitleVisibility.hidden
        window?.backgroundColor = PostcardUI.blue
        
    }

}
