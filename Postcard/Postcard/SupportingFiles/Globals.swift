//
//  Globals.swift
//  Postcard
//
//  Created by Adelita Schule on 7/21/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation
import AppAuth

struct GlobalVars
{
    static var currentUser: User?
    static var userActivity: NSUserActivity?
    
    static var messageCache: Dictionary <String, PostcardMessage>?
}
