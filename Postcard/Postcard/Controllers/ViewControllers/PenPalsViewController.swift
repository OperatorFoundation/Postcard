//
//  PenPalsViewController.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class PenPalsViewController: NSViewController
{
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
        
//        view.layer?.backgroundColor = PostcardUI.
//        view.superview?.window?.titlebarAppearsTransparent = true
    }
    
}


class PenPalTableCell: NSTableCellView
{
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var penPalImageView: NSImageView!
    @IBOutlet weak var actionButton: NSButton!
    
}
