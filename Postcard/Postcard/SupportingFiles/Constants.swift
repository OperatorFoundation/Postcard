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
    static let servicePeople = GTLRPeopleService()
    
    /*If modifying these scopes, delete your previously saved credentials by resetting the iOS simulator or uninstalling the app.*/
    static let scopes = [kGTLAuthScopeGmail, kGTLRAuthScopePeopleContactsReadonly, kGTLRAuthScopePeoplePlusLogin]
    static let kKeychainItemName = "Gmail API"
    static let kClientID = "313251347973-cpo986nne3t21bus5499b4kt1kb8thrm.apps.googleusercontent.com"
}

struct PostCardProps
{
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

struct localizationKeys
{
    //Generic
    static let okButtonTitle = "OK"
    static let localizedOKButtonTitle = NSLocalizedString(localizationKeys.okButtonTitle, comment: "OK - Button to dismiss pop-up windows.")
    
    //Menu
    static let inboxButtonTitle = "  Inbox"
    static let composeButtonTitle = "COMPOSE"
    static let penPalsButtonTitle = "  PenPals"
    static let lockdownButtonTitle = "  Lockdown"
    static let logoutButtonTitle = "  Logout"
    
    //PenPals List
    static let inviteButtonTitle = "INVITE"
    static let addButtonTitle = "ADD"
    
    //Message Detail
    static let replyButtonTitle = "REPLY"
    static let localizedReplyTitle = NSLocalizedString(localizationKeys.replyButtonTitle, comment: "REPLY")
    
    static let deleteButtonTitle = "DELETE"
    static let localizedDeleteTitle = NSLocalizedString(localizationKeys.deleteButtonTitle, comment: "DELETE")
    
    static let deleteGmailMessageError = "We couldn't delete this message from Gmail. Try again later or try deleting this email from Gmail directly."
    static let localizedDeleteGmailError = NSLocalizedString(localizationKeys.deleteGmailMessageError, comment: "We couldn't delete this message from Gmail. Try again later or try deleting this email from Gmail directly.")
    
    //Compose
    static let replySubjectLineStarter = "re: "
    static let localizedReplyStarter = NSLocalizedString(localizationKeys.replySubjectLineStarter, comment: "re: ")
    
    static let sendEmailButtonTitle = "SEND"
    static let localizedSendTitle = NSLocalizedString(localizationKeys.sendEmailButtonTitle, comment: "SEND")
    
    static let addAttachmentButtonTitle = "ATTACHMENT"
    static let localizedAttachmentTitle = NSLocalizedString(localizationKeys.addAttachmentButtonTitle, comment: "ATTACHMENT")
    
    static let selectAttachmentPrompt = "Select the file you would like to attach."
    static let localizedAttachmentPrompt = NSLocalizedString(localizationKeys.selectAttachmentPrompt, comment: "Select the file you would like to attach.")
    
    //Login
    static let authenticationErrorAlert = "Authentication Error: "
    static let localizedAuthErrorPrompt = NSLocalizedString(localizationKeys.authenticationErrorAlert, comment: "Authentication Error: ")
    
    //Mail Controller
    static let unknownContactError = "We did not decrypt a message sent from %d because this person is not one of your PenPals."
    static let localizedUnknownContactError = NSLocalizedString(localizationKeys.unknownContactError, comment: "We did not decrypt a message sent from (email address) because this person is not one of your PenPals.")
    
    static let wrongKeyError = "We were unable to decrypt a message: %d may have a new key."
    static let localizedWrongKeyError = NSLocalizedString(localizationKeys.wrongKeyError, comment: "We were unable to decrypt a message: %d may have a new key.")
    
    static let missingCipherError = "We could not decrypt this postcard!! We cannot find the cipher text from (penPal email)."
    static let localizedMissingCipherError = NSLocalizedString(localizationKeys.missingCipherError, comment: "We could not decrypt this postcard!! We cannot find the cipher text from (penPal email).")
    
    static let missingPenPalKeyError = "We were unable to decrypt a message: We don't have their key. :("
    static let localizedMissingPalKeyError = NSLocalizedString(localizationKeys.missingPenPalKeyError, comment: "We were unable to decrypt a message: We don't have their key. :(")
    
    static let missingKeyError = "We were unable to decrypt your emails: we don't have your key. :("
    static let localizedMissingKeyError = NSLocalizedString(localizationKeys.missingKeyError, comment: "We were unable to decrypt your emails: we don't have your key. :(")
    
    static let penPalSentDifferentKeyError = "We received a key from:\n %d\n and it does not match the key we have stored. You may not be able to read new messages from this sender."
    static let localizedDifferentKeyError = NSLocalizedString(localizationKeys.penPalSentDifferentKeyError, comment: "We received a key from:\n (sender's email)\n and it does not match the key we have stored. You may not be able to read new messages from this sender.")
    
    static let savePenPalKeyError = "Warning: We could not save %d's key."
    static let localizedSavePenPalKeyError = NSLocalizedString(localizationKeys.savePenPalKeyError, comment: "Warning: We could not save (sender email)'s key.")
    
    static let savePenPalError = "Warning: We could not save %d as a PenPal."
    static let localizedSavePenPalError = NSLocalizedString(localizationKeys.savePenPalError, comment: "Warning: We could not save (sender email) as a PenPal.")
    
    static let sendPostcardErrorNoKey = "You cannot send a Postcard to %d because you do not have their key! :("
    static let localizedSendErrorNoKey = NSLocalizedString(localizationKeys.sendPostcardErrorNoKey, comment: "You cannot send a Postcard to (email address) because you do not have their key! :(")
    
    static let sendPostcardErrorContactDoesNotExist = "You cannot send a postcard to %d, they are not in your contacts yet."
    static let localizedSendErrorNotAContact = NSLocalizedString(localizationKeys.sendPostcardErrorContactDoesNotExist, comment: "You cannot send a postcard to (email), they are not in your contacts yet.")
    
    static let postcardInviteBodyGeneric = "If you can read this, you have my key."
    static let localizedInviteFiller = NSLocalizedString(localizationKeys.postcardInviteBodyGeneric, comment: "(We expect this never to be read, but just in case...)")
    
    //Postcard Wrapper Message
    static let genericSubjectLine = "You've Received a Postcard"
    static let localizedGenericSubject = NSLocalizedString(localizationKeys.genericSubjectLine, comment: "")
    
    static let genericBody = "If you don't know how to read your Postcards yet, you can get more information at http://operatorfoundation.org."
    static let localizedGenericBody = NSLocalizedString(localizationKeys.genericBody, comment: "")
    
}

struct UDKey
{
    //TODO: We need these to very based on the logged in user (Private key as well)
    static let emailAddressKey = "emailAddress"
    static let publicKeyKey = "publicKey"
}