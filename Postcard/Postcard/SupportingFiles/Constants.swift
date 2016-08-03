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

let bundle = NSBundle.mainBundle()

//PopUpMessages Strings

let localizedOKButtonTitle = NSLocalizedString("OK-Button-Title", tableName: "PopUpMessages", bundle: bundle, value: "OK", comment: "Button to dismiss pop-up windows.")

let localizedUnknownContactError = NSLocalizedString("ERROR-Postcard-Decryption-Unknown-Sender", tableName: "PopUpMessages", bundle: bundle, value: "We did not decrypt a message sent from %d because this person is not one of your PenPals.", comment: "A message could not be decrypted because it is not from a known contact *email*")

let localizedWrongKeyError = NSLocalizedString("ERROR-Decryption-Wrong-Key", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt a message: %d may have a new key.", comment: "A message could not be decrypted, possibly because we have the wrong key for the sender.")

let localizedMissingCipherError = NSLocalizedString("ERROR-Decryption-No-Cipher-Text", tableName: "PopUpMessages", bundle: bundle, value: "We could not decrypt this postcard!! We cannot find the cipher text from %d.", comment: "A message from *email* could not be decrypted because the cipher text was not found.")

let localizedMissingPalKeyError = NSLocalizedString("ERROR-Decryption-No-Key-For-Pal", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt a message: We don't have the sender's key. :(", comment: "A message could not be decrypted because we do not have the sender's key")

let localizedMissingKeyError = NSLocalizedString("ERROR-Decryption-Missing-No-Key-For-User", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt your emails: we don't have your key. :(", comment: "No emails were decrypted because the user's key is missing.")

let localizedDifferentKeyError = NSLocalizedString("ERROR-Different-Key-For-Pal", tableName: "PopUpMessages", bundle: bundle, value: "We received a key from:\n %d\n and it does not match the key we have stored. You may not be able to read new messages from this sender.", comment: "The key we have stored for a contact does not match the key we just received. *sender's email*")

let localizedSavePenPalKeyError = NSLocalizedString("ERROR-Saving-Pal-Key", tableName: "PopUpMessages", bundle: bundle, value: "Warning: We could not save %d's key.", comment: "Unable to save this contact's key. *sender's email*")

let localizedSavePenPalError = NSLocalizedString("ERROR-Saving-PenPal", tableName: "PopUpMessages", bundle: bundle, value: "Warning: We could not save %d as a PenPal.", comment: "Unable to save this contact. *sender's email*")

let localizedSendErrorNoKey = NSLocalizedString("ERROR-Sending-Email-No-Pal-Key", tableName: "PopUpMessages", bundle: bundle, value: "You cannot send a Postcard to %d because you do not have their key! :(", comment: "Unable to send the email because we do not have a key for the recipient. *recipient's email*")

let localizedSendErrorNotAContact = NSLocalizedString("ERROR-Sending-Email-Not-A-Pal", tableName: "PopUpMessages", bundle: bundle, value: "You cannot send a postcard to %d, they are not in your contacts yet.", comment: "Unable to send an email to this address because the person is not a known contact. *recipient's email*")

//MailController Strings
let localizedInviteFiller = NSLocalizedString("Dummy-Postcard-Key-Attachment-Body", tableName: "MailController", bundle: bundle, value: "If you can read this, you have my key.", comment: "We expect this never to be read, but just in case...")

//ComposeView Strings
let localizedAttachmentPrompt = NSLocalizedString("Attachment-Prompt", tableName: "ComposeTable", bundle: bundle, value: "Select the file you would like to attach.", comment: "A prompt for the user to pick a file from a presented list to attach to their email.")

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
    //Menu
    static let inboxButtonTitle = "  Inbox"
    static let localizedInboxButtonTitle = NSLocalizedString(localizationKeys.inboxButtonTitle, comment: "")
    
    static let composeButtonTitle = "COMPOSE"
    static let localizedComposeButtonTitle = NSLocalizedString(localizationKeys.composeButtonTitle, comment: "")
    
    static let penPalsButtonTitle = "  PenPals"
    static let localizedPenPalsButtonTitle = NSLocalizedString(localizationKeys.penPalsButtonTitle, comment: "")
    
    static let lockdownButtonTitle = "  Lockdown"
    static let localizedLockdownButtonTitle = NSLocalizedString(localizationKeys.lockdownButtonTitle, comment: "")
    
    static let logoutButtonTitle = "  Logout"
    static let localizedLogoutButtonTitle = NSLocalizedString(localizationKeys.logoutButtonTitle, comment: "")
    
    //PenPals List
    static let inviteButtonTitle = "INVITE"
    static let localizedInviteButtonTitle = NSLocalizedString(localizationKeys.inviteButtonTitle, comment: "Button for inviting a friend to use the app and be one of your secure contacts.")
    
    static let addButtonTitle = "ADD"
    static let localizedAddButtonTitle = NSLocalizedString(localizationKeys.addButtonTitle, comment: "Accept another user's invitation to be a secure contact.")
    
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
    
    //Login
    static let authenticationErrorAlert = "Authentication Error: "
    static let localizedAuthErrorPrompt = NSLocalizedString(localizationKeys.authenticationErrorAlert, comment: "Authentication Error: ")
    
    //Postcard Wrapper Message
    static let genericSubjectLine = "You've Received a Postcard"
    static let localizedGenericSubject = NSLocalizedString(localizationKeys.genericSubjectLine, comment: "")
    
    static let genericBody = "If you don't know how to read your Postcards yet, you can get more information at http://operatorfoundation.org."
    static let localizedGenericBody = NSLocalizedString(localizationKeys.genericBody, comment: "")
    
    static let savePenPalStatusError = "Warning: We could not save the sent your connection status for %d"
    static let localizedPenPalStatusError = NSLocalizedString(localizationKeys.savePenPalStatusError, comment: "Warning: We could not save the sent your connection status for (penpal email)")
    
}