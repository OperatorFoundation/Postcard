//
//  rfc2822.swift
//  
//
//  Created by Brandon Wiley on 3/9/17.
//
//

import Foundation
import GoogleAPIClientForREST

let headerNameTo = "To"
let headerNamesubject = "Subject"
let headerNameContentType = "Content-Type"
let headerNameContentDisposition = "Content-Disposition"
let headerNameContentTransferEncoding = "Content-Transfer-Encoding"

let contentTypeMultipartMixed = "multipart/mixed"
let contentTypeTextPlain = "text/plain"

let transferEncodingBase64 = "base64"

struct EmailMessage
{
    var to: String
    var keyData: Data
    var hasPenPalKey: Bool
    var postcardData: Data? //This is the encrypted message, for invitations this will be nil.
    var packageData: Data? //This is the encrypted user attachment
    
    init(to: String, hasPalKey:Bool, keyData: Data, postcardData: Data?, packageData: Data?)
    {
        self.to = to
        self.keyData = keyData
        self.hasPenPalKey = hasPalKey
        
        if postcardData != nil
        {
            self.postcardData = postcardData
        }
        
        if packageData != nil
        {
            self.packageData = packageData
        }
    }
}

func emailToRaw(email: EmailMessage) -> String
{
    let result = multipartToRFC2822(email: email)
    print("Raw message string before encoding: \(result)")
    return GTLREncodeWebSafeBase64(result.data(using: String.Encoding.utf8))!
}

func multipartToRFC2822(email: EmailMessage) -> String
{
    var result = ""
    let boundary = makeBoundary()
    
    //To
    result = result + createRFC2822Header(name: headerNameTo, value: email.to)
    
    //Subject
    if email.postcardData == nil //This is an invite not a message
    {
        result = result + createRFC2822Header(name: headerNamesubject, value: localizedInviteSubject)
    }
    else //This is a message
    {
        result = result + createRFC2822Header(name: headerNamesubject, value: localizedGenericSubject)
    }
    
    //Content Type
    result = result + createRFC2822Header(name: headerNameContentType, value:  "\(contentTypeMultipartMixed); boundary=\(boundary)")
    
    //Blank Line
    result = result + "\r\n"
    
    //Add Boundary
    result = result + "--\(boundary)\r\n"
    
    //Wrapper Body Headers
    result = result + createRFC2822Header(name: headerNameContentType, value: contentTypeTextPlain)
    result = result + createRFC2822Header(name: headerNameContentTransferEncoding, value: transferEncodingBase64)
    result = result + "\r\n"
    
    //Wrapper body content
    if email.postcardData == nil //This is an invite not a message
    {
        if let body = GTLREncodeWebSafeBase64(localizedInviteFiller.data(using: String.Encoding.utf8))
        {
            result = result + body
        }
        else
        {
            print("Unable to encode email body text.")
        }
        
    }
    else //This is a message
    {
        if let body = GTLREncodeWebSafeBase64(localizedGenericBody.data(using: String.Encoding.utf8))
        {
            result = result + body
        }
        else
        {
            print("Unable to encode email body text.")
        }
    }
    
    //Add Another Boundary
    result = result + "\r\n--\(boundary)\r\n"
    
    //Key Attachment
    if email.hasPenPalKey
    {
        //This key attachment has both the user's and the penpal's public keys.
        result = result + createRFC2822Attachment(contentType: PostCardProps.keyMimeType, filename: PostCardProps.keyFilename, content: email.keyData)
    }
    else
    {
        //This attachment only contains the user's public key
        result = result + createRFC2822Attachment(contentType: PostCardProps.senderKeyMimeType, filename: PostCardProps.keyFilename, content: email.keyData)
    }
    
    //Postcard Attachment
    if let postcardData = email.postcardData
    {
        //Add Another Boundary
        result = result + "\r\n--\(boundary)\r\n"
        
        //Postcard Attachment
        result = result + createRFC2822Attachment(contentType: PostCardProps.postcardMimeType, filename: PostCardProps.postcardFilename, content: postcardData)
    }
    
    //Package Attachment
    if let packageData = email.packageData
    {
        //Add Another Boundary
        result = result + "\r\n--\(boundary)\r\n"
        
        //Postcard Attachment
        result = result + createRFC2822Attachment(contentType: PostCardProps.packageMimeType, filename: PostCardProps.packageFilename, content: packageData)
    }
    
    //Add Closing Boundary
    result = result + "\r\n--\(boundary)--"

    return result
}

func createRFC2822Attachment(contentType: String, filename: String, content: Data) -> String
{
    var result = ""
    let contentTypeValue = "\(contentType); name=\(filename)"
    result = result + createRFC2822Header(name: headerNameContentType, value: contentTypeValue)
    result = result + createRFC2822Header(name: headerNameContentTransferEncoding, value: transferEncodingBase64)
    let disposition = "attachment; filename=\(filename)"
    result = result + createRFC2822Header(name: headerNameContentDisposition, value: disposition)
    result = result + "\r\n"
    
    //Attachment content
    if let body = GTLREncodeBase64(content)
    {
        result = result + body
    }
    else
    {
        print("Unable to encode attachment body.")
    }
    
    return result
}

func makeBoundary() -> String
{
    let length = 20
    let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
    let data = Data(bytes: bytes, count: length)
    return GTLREncodeWebSafeBase64(data)!
}

//Create an RFC 2822 Compliant header
func createRFC2822Header(name: String, value: String) -> String
{
    return name + ": " + value + "\r\n"
}
