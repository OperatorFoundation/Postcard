//
//  LockedViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 6/8/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class LockedViewController: NSViewController
{
    
    lazy var mainWindowController: MainWindowController =
    {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let newWindowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as! MainWindowController
        return newWindowController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func unlockTap(_ sender: NSButton)
    {
        //Present Home View
        mainWindowController.showWindow(self)
        
        view.window?.close()
    }
    
}
