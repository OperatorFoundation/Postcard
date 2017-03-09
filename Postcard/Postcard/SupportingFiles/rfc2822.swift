//
//  rfc2822.swift
//  
//
//  Created by Brandon Wiley on 3/9/17.
//
//

import Foundation
import GoogleAPIClientForREST

func payloadToRaw(payload: GTLRGmail_MessagePart) -> String
{
    return partToRFC2822(part: payload)
}

func partToRFC2822(part: GTLRGmail_MessagePart) -> String
{
    var result = ""
    
    if let headers = part.headers
    {
        for header in headers
        {
            result = result + headerToRFC2822(header: header)
        }
    }
    
    if part.body != nil
    {
        result = result + bodyPartHeaders(part: part)
        result = result + "\n"
        result = result + bodyPart(part: part)
    }
    else
    {
        let boundary = makeBoundary()
        result = result + multipartHeaders(part: part, boundary: boundary)
        result = result + "\n"
        result = result + multipart(multi: part, boundary: boundary)
    }
    
    return result
}

func makeBoundary() -> String
{
    return ""
}

func headerToRFC2822(header: GTLRGmail_MessagePartHeader) -> String
{
    return header.name! + ": " + header.value! + "\n"
}

func bodyPartHeaders(part: GTLRGmail_MessagePart) -> String
{
    // Example email body:
    // Content-Type: text/plain
    
    // Example attachment:
    // Content-Type: application/postcard-key; name=Postcard
    // Content-Disposition: attachment; filename=Postcard
    // Content-Transfer-Encoding: base64
    
    var result = ""

    if let filename = part.filename
    {
        if let mimeType = part.mimeType
        {
            result = result + "Content-Type: " + mimeType + "; name=" + filename + "\n"
            result = result + "Content-Disposition: attachment; name=" + filename + "\n"
            result = result + "Content-Transfer-Encoding: base64\n"
        }
    }
    else
    {
        result = result + "Content-Type: text/plain\n"
    }
    
    return result
}

func multipartHeaders(part: GTLRGmail_MessagePart, boundary: String) -> String
{
  // Example: Content-Type: multipart/mixed; boundary=001a1142881cd25a87054971dde2
    
  return "Content-Type: multipart/mixed; boundary=" + boundary + "\n"
}

func bodyPart(part: GTLRGmail_MessagePart) -> String
{
    return GTLREncodeWebSafeBase64(part.body?.data?.data(using: String.Encoding.utf8))!
}

func multipart(multi: GTLRGmail_MessagePart, boundary: String) -> String
{
    var result = ""
    
    result = result + boundary + "\n"
    
    for part in multi.parts!
    {
        result = result + partToRFC2822(part: part)
        
        result = result + "\n"
        
        result = result + boundary + "\n"
    }
    
    return result
}
