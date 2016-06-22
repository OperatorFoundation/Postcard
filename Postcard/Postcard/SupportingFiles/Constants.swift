//
//  Constants.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation
import GoogleAPIClient
import GoogleAPIClientForREST

/*
 Font Names
 ProximaNova-Black
 ProximaNova-Bold
 ProximaNovaA-Black
 ProximaNovaA-Bold
 ProximaNovaA-Extrabld
 ProximaNovaA-Light
 ProximaNovaA-Regular
 ProximaNovaACond-Light
 ProximaNovaACond-Thin
 ProximaNovaAExCn-Bold
 ProximaNovaAExCn-Light
 */

struct GmailProps
{
    static let service = GTLServiceGmail()
    
    /*If modifying these scopes, delete your previously saved credentials by resetting the iOS simulator or uninstalling the app.*/
    static let scopes = [kGTLAuthScopeGmail, kGTLRAuthScopePeopleContacts, kGTLRAuthScopePeopleContactsReadonly]
    static let kKeychainItemName = "Gmail API"
    static let kClientID = "313251347973-cpo986nne3t21bus5499b4kt1kb8thrm.apps.googleusercontent.com"
}

struct PostCardProps
{
    static let subject = "You've Received a Postcard"
    static let body = "If you don't know how to read your Postcards yet, you can get more information at http://operatorfoundation.org."
    
    static let postcardMimeType = "application/postcard-encrypted"
    static let packageMimeType = "application/postcard-package-encrypted"
    static let keyMimeType = "application/postcard-key"
}

struct PostcardUI
{
    static let blue = NSColor(calibratedRed: 0.27, green: 0.65, blue: 0.73, alpha: 1)
    static let red = NSColor(calibratedRed: 0.88, green: 0.34, blue: 0.31, alpha: 1.0)
    static let orange = NSColor(calibratedRed: 0.93, green: 0.49, blue: 0.39, alpha: 1.0)
    static let green = NSColor(calibratedRed: 0.20, green: 0.70, blue: 0.53, alpha: 1.0)
    static let black = NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.23, alpha: 1.0)
    static let gray = NSColor(calibratedRed: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
    
    static let blackFont = "ProximaNova-Black"
    static let boldFont = "ProximaNova-Bold"
    static let blackAFont = "ProximaNovaA-Black"
    static let boldAFont = "ProximaNovaA-Bold"
    static let extraBoldAFont = "ProximaNovaA-Extrabld"
    static let lightAFont = "ProximaNovaA-Light"
    static let regularAFont = "ProximaNovaA-Regular"
    static let lightACondensedFont = "ProximaNovaACond-Light"
    static let thinACondensedFont = "ProximaNovaACond-Thin"
    static let boldAExtraCondensed = "ProximaNovaAExCn-Bold"
    static let lightAExtraCondensed = "ProximaNovaAExCn-Light"
    static let boldFutura = "FuturaT-Bold"
}

struct UDKey
{
    //TODO: We need these to very based on the logged in user (Private key as well)
    static let emailAddressKey = "emailAddress"
    static let publicKeyKey = "publicKey"
}