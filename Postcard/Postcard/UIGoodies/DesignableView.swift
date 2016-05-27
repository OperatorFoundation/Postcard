//
//  DesignableView.swift
//  Postcard
//
//  Created by Adelita Schule on 5/13/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

//Allows us to change some things about this view in interface builder
//To see these properties in IB don't forget to set that view's class to DesignableView
@IBDesignable class DesignableView: NSView
{
    @IBInspectable var cornerRounding: CGFloat = 10
    {
        didSet
        {
            layer?.cornerRadius = cornerRounding
        }
    }
    
    @IBInspectable var viewColor: NSColor = NSColor.grayColor()
    {
        didSet
        {
            layer?.backgroundColor = viewColor.CGColor
        }
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    override func prepareForInterfaceBuilder()
    {
        layer?.cornerRadius = cornerRounding
        layer?.backgroundColor = viewColor.CGColor
    }
    
}
