//
//  Encoding.swift
//  Postcard
//
//  Created by Brandon Wiley on 4/9/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import GoogleAPIClientForRESTCore


func dataEncodedToString(_ data: Data) -> String
{
    let newString = GTLREncodeWebSafeBase64(data)
    
    return newString!
}

func stringDecodedToData(_ string: String) -> Data?
{
    if let newData = GTLRDecodeWebSafeBase64(string)
    {
        return newData
    }
    else {return nil}
}
    
