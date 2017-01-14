//
//  Constants.swift
//  Postcard
//
//  Created by Adelita Schule on 4/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation
//import GoogleAPIClient
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

let bundle = Bundle.main

//PopUpMessages Strings

let localizedOKButtonTitle = NSLocalizedString("OK-Button-Title", tableName: "PopUpMessages", bundle: bundle, value: "OK", comment: "Button to dismiss pop-up windows.")

//let localizedUnknownContactError = NSLocalizedString("ERROR-Postcard-Decryption-Unknown-Sender", tableName: "PopUpMessages", bundle: bundle, value: "We did not decrypt a message sent from %@ because this person is not one of your PenPals.", comment: "A message could not be decrypted because it is not from a known contact *email*")

//BRANDON START HERE

let localizedWrongKeyError = NSLocalizedString("ERROR-Decryption-Wrong-Key", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt a message: %@ may have a new key.", comment: "A message could not be decrypted, possibly because we have the wrong key for the sender.")

let localizedMissingCipherError = NSLocalizedString("ERROR-Decryption-No-Cipher-Text", tableName: "PopUpMessages", bundle: bundle, value: "We could not decrypt this postcard!! We cannot find the cipher text from %@.", comment: "A message from *email* could not be decrypted because the cipher text was not found.")

let localizedMissingPalKeyError = NSLocalizedString("ERROR-Decryption-No-Key-For-Pal", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt a message: We don't have the sender's key. :(", comment: "A message could not be decrypted because we do not have the sender's key")

let localizedMissingKeyError = NSLocalizedString("ERROR-Decryption-Missing-No-Key-For-User", tableName: "PopUpMessages", bundle: bundle, value: "We were unable to decrypt your emails: we don't have your key. :(", comment: "No emails were decrypted because the user's key is missing.")

let localizedDifferentKeyError = NSLocalizedString("ERROR-Different-Key-For-Pal", tableName: "PopUpMessages", bundle: bundle, value: "We received a key from:\n %@\n and it does not match the key we have stored. You may not be able to read new messages from this sender.", comment: "The key we have stored for a contact does not match the key we just received. *sender's email*")

//let localizedSavePenPalKeyError = NSLocalizedString("ERROR-Saving-Pal-Key", tableName: "PopUpMessages", bundle: bundle, value: "Warning: We could not save %@'s key.", comment: "Unable to save this contact's key. *sender's email*")

//let localizedSavePenPalError = NSLocalizedString("ERROR-Saving-PenPal", tableName: "PopUpMessages", bundle: bundle, value: "Warning: We could not save %@ as a PenPal.", comment: "Unable to save this contact. *sender's email*")

let localizedSendErrorNoKey = NSLocalizedString("ERROR-Sending-Email-No-Pal-Key", tableName: "PopUpMessages", bundle: bundle, value: "You cannot send a Postcard to %@ because you do not have their key! :(", comment: "Unable to send the email because we do not have a key for the recipient. *recipient's email*")

let localizedSendErrorNotAContact = NSLocalizedString("ERROR-Sending-Email-Not-A-Pal", tableName: "PopUpMessages", bundle: bundle, value: "You cannot send a postcard to %@, they are not in your contacts yet.", comment: "Unable to send an email to this address because the person is not a known contact. *recipient's email*")

let localizedPenPalStatusError = NSLocalizedString("ERROR-Saving-PenPal-Status", tableName: "PopUpMessages", bundle: bundle, value: "Warning: We could not save the sent your connection status for %@", comment: "Unable to save the new status of a connection (e.g. added or invited)")

let localizedDeleteGmailError = NSLocalizedString("ERROR-Deleting-Message-From-Gmail", tableName: "PopUpMessages", bundle: bundle, value: "We couldn't delete this message from Gmail. Try again later or try deleting this email from Gmail directly.", comment: "Unable to delete the selected email from the user's gmail account.")

let localizedAuthErrorPrompt = NSLocalizedString("ERROR-Authenticating-User", tableName: "PopUpMessages", bundle: bundle, value: "Authentication Error: ", comment: "This is the title for a pop-up. the error itself will be provided by Google.")


//MailController Strings
let localizedInviteFiller = NSLocalizedString("Dummy-Postcard-Key-Attachment-Body", tableName: "MailController", bundle: bundle, value: "If you can read this, you have my key.", comment: "We expect this never to be read, but just in case...")

let localizedGenericSubject = NSLocalizedString("Wrapper-Subject-Line", tableName: "MailController", bundle: bundle, value: "You've Received a Postcard", comment: "This is the subject line for the 'wrapper' email. The email that the user will see in their Gmail account that does not have to be decrypted. The postcard/encrypted message itself will be an attachment to this wrapper message.")

let localizedGenericBody = NSLocalizedString("Wrapper-Body-Text", tableName: "MailController", bundle: bundle, value: "If you don't know how to read your Postcards yet, you can get more information at http://operatorfoundation.org.", comment: "This is the body of the 'wrapper' email.")


//ComposeView Strings
let localizedAttachmentPrompt = NSLocalizedString("Attachment-Prompt", tableName: "ComposeView", bundle: bundle, value: "Select the file you would like to attach.", comment: "A prompt for the user to pick a file from a presented list to attach to their email.")

//BRANDON STOP HERE

let localizedReplyStarter = NSLocalizedString("Reply-Subject-Line-Prefix", tableName: "ComposeView", bundle: bundle, value: "re: ", comment: "The re: that is added to the subject line when replying to someone's email.")

let localizedSendTitle = NSLocalizedString("BUTTON-TITLE-Send", tableName: "ComposeView", bundle: bundle, value: "SEND", comment: "For sending an email.")

let localizedAttachmentTitle = NSLocalizedString("BUTTON-TITLE-Attachment", tableName: "ComposeView", bundle: bundle, value: "ATTACHMENT", comment: "For attaching a file to an email you are writing.")


//MessageView
let localizedReplyTitle = NSLocalizedString("BUTTON-TITLE-Reply", tableName: "MessageView", bundle: bundle, value: "REPLY", comment: "For replying to the email you are reading.")

let localizedDeleteTitle = NSLocalizedString("BUTTON-TITLE-Delete", tableName: "MessageView", bundle: bundle, value: "DELETE", comment: "For deleting the email you are reading")


//PenPalsView
let localizedInviteButtonTitle = NSLocalizedString("BUTTON-TITLE-Invite", tableName: "PenPalsView", bundle: bundle, value: "INVITE", comment: "For sending your key to a contact who has not already sent you theirs, inviting them to be your penpal. (they may or may not already be using this software)")

let localizedAddButtonTitle = NSLocalizedString("BUTTON-TITLE-Add", tableName: "PenPalsView", bundle: bundle, value: "ADD", comment: "For accepting an invite from another user and sending them your key. This will add the sender as a secure contact with whom you can exchange encrypted 'Postcards'.")


//MenuView
let localizedInboxButtonTitle = NSLocalizedString("BUTTON-TITLE-Inbox", tableName: "MenuView", bundle: bundle, value: "  Inbox", comment: "For viewing the emails in your inbox. *The two spaces before the word are necessary for formatting.")

let localizedComposeButtonTitle = NSLocalizedString("BUTTON-TITLE-Compose", tableName: "MenuView", bundle: bundle, value: "COMPOSE", comment: "For opening the compose view and starting a new email.")

let localizedPenPalsButtonTitle = NSLocalizedString("BUTTON-TITLE-PenPals", tableName: "MenuView", bundle: bundle, value: "  PenPals", comment: "For viewing your list of contacts. *The two spaces before the word are necessary for formatting.")

let localizedLockdownButtonTitle = NSLocalizedString("BUTTON-TITLE-Lockdowm", tableName: "MenuView", bundle: bundle, value: "  Lockdown", comment: "For re-encrypting your inbox messages. *The two spaces before the word are necessary for formatting.")

let localizedLogoutButtonTitle = NSLocalizedString("BUTTON-TITLE", tableName: "MenuView", bundle: bundle, value: "  Logout", comment: "For logging out of the program/gmail. *The two spaces before the word are necessary for formatting.")

struct GmailProps
{
    static let service = GTLRGmailService()
    static let servicePeople = GTLRPeopleService()
    
    /*If modifying these scopes, delete your previously saved credentials by resetting the iOS simulator or uninstalling the app.*/
    static let scopes = [kGTLRAuthScopeGmailCompose, kGTLRAuthScopeGmailMailGoogleCom, kGTLRAuthScopePeopleContactsReadonly, kGTLRAuthScopePeoplePlusLogin]
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
