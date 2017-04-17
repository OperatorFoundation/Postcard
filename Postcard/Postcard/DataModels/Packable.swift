//
//  Packable.swift
//  Postcard
//
//  Created by Brandon Wiley on 4/9/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import MessagePack

protocol Packable
{
    init?(value: MessagePackValue)
    func messagePackValue() -> MessagePackValue
}

struct PostcardMessage: Packable
{
    var to: String
    var subject: String
    var body: String
    
    init(to: String, subject: String, body: String)
    {
        self.to = to
        self.subject = subject
        self.body = body
    }
    
    init?(postcardData: Data)
    {
        do
        {
            let unpackResult = try unpack(postcardData)
            let unpackValue: MessagePackValue = unpackResult.value
            self.init(value: unpackValue)
        }
        catch let unpackError as NSError
        {
            print("Unpack postcard data error: \(unpackError.localizedDescription)")
            return nil
        }
    }
    
    func dataValue() -> Data?
    {
        let keyMessagePack = self.messagePackValue()
        return pack(keyMessagePack)
    }
    
    internal init?(value: MessagePackValue)
    {
        guard let keyDictionary = value.dictionaryValue
            else
        {
            print("Postcard Message deserialization error.")
            return nil
        }
        
        //To
        guard let toMessagePack = keyDictionary[.string(messageToKey)]
            else
        {
            print("Postcard message deserialization error: unable to unpack 'to' property.")
            return nil
        }
        
        guard let toString = toMessagePack.stringValue
            else
        {
            print("Postcard message deserialization error: unable to get string value for 'to' property.")
            return nil
        }
        
        //Subject
        guard let subjectMessagePack = keyDictionary[.string(messageSubjectKey)]
            else
        {
            print("Postcard message deserialization error: unable to unpack subject property.")
            return nil
        }
        
        guard let subjectString = subjectMessagePack.stringValue
            else
        {
            print("Postcard message deserialization error: unable to get string value for subject property.")
            return nil
        }
        
        //Message Body
        guard let bodyMessagePack = keyDictionary[.string(messageBodyKey)]
            else
        {
            print("Postcard message deserialization error: unable to unpack body property.")
            return nil
        }
        
        guard let bodyString = bodyMessagePack.stringValue
            else
        {
            print("Postcard message deserialization error: unable to get string value for body property.")
            return nil
        }
        
        self.to = toString
        self.subject = subjectString
        self.body = bodyString
    }
    
    internal func messagePackValue() -> MessagePackValue
    {
        let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
            MessagePackValue(messageToKey): MessagePackValue(self.to),
            MessagePackValue(messageSubjectKey): MessagePackValue(self.subject),
            MessagePackValue(messageBodyKey): MessagePackValue(self.body)
        ]
        
        return MessagePackValue(keyDictionary)
    }
}

struct TimestampedSenderPublicKey: Packable
{
    var senderPublicKey: Data
    var senderKeyTimestamp: Int64
    
    init(senderKey: Data, senderKeyTimestamp: Int64)
    {
        self.senderPublicKey = senderKey
        self.senderKeyTimestamp = senderKeyTimestamp
    }
    
    init?(value: MessagePackValue)
    {
        guard let keyDictionary = value.dictionaryValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Sender Public Key
        guard let senderKeyMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyKey)]
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        guard let senderPKeyData = senderKeyMessagePack.dataValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Sender Key Timestamp
        guard let senderTimestampMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyTimestampKey)]
            else
        {
            print("TimestampedPublicKeys deserialization error: Unable to deserialize the Timestamp MessagePack.")
            return nil
        }
        
        guard let senderPKeyTimestamp = senderTimestampMessagePack.integerValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        self.senderPublicKey = senderPKeyData
        self.senderKeyTimestamp = senderPKeyTimestamp
    }
    
    func messagePackValue() -> MessagePackValue
    {
        let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
            MessagePackValue(keyAttachmentSenderPublicKeyKey): MessagePackValue(self.senderPublicKey),
            MessagePackValue(keyAttachmentSenderPublicKeyTimestampKey): MessagePackValue(self.senderKeyTimestamp)
        ]
        
        return MessagePackValue(keyDictionary)
    }
}

struct TimestampedPublicKeys: Packable
{
    var senderPublicKey: Data
    var senderKeyTimestamp: Int64
    var recipientPublicKey: Data
    var recipientKeyTimestamp: Int64
    
    init(senderKey: Data, senderKeyTimestamp: Int64, recipientKey: Data, recipientKeyTimestamp: Int64)
    {
        self.senderPublicKey = senderKey
        self.senderKeyTimestamp = senderKeyTimestamp
        self.recipientPublicKey = recipientKey
        self.recipientKeyTimestamp = recipientKeyTimestamp
    }
    
    init?(value: MessagePackValue)
    {
        guard let keyDictionary = value.dictionaryValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Sender Public Key
        guard let senderKeyMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyKey)]
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        guard let senderPKeyData = senderKeyMessagePack.dataValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Sender Key Timestamp
        guard let senderTimestampMessagePack = keyDictionary[.string(keyAttachmentSenderPublicKeyTimestampKey)]
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        guard let senderPKeyTimestamp = senderTimestampMessagePack.integerValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Recipient Public Key
        guard let recipientKeyMessagePack = keyDictionary[.string(keyAttachmentRecipientPublicKeyKey)]
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        guard let recipientPKeyData = recipientKeyMessagePack.dataValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        //Recipient Key Timestamp
        guard let recipientTimestampMessagePack = keyDictionary[.string(keyAttachmentRecipientPublicKeyTimestamp)]
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        guard let recipientPKeyTimestamp = recipientTimestampMessagePack.integerValue
            else
        {
            print("TimestampedPublicKeys deserialization error.")
            return nil
        }
        
        self.senderPublicKey = senderPKeyData
        self.senderKeyTimestamp = senderPKeyTimestamp
        self.recipientPublicKey = recipientPKeyData
        self.recipientKeyTimestamp = recipientPKeyTimestamp
    }
    
    func messagePackValue() -> MessagePackValue
    {
        let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
            MessagePackValue(keyAttachmentSenderPublicKeyKey): MessagePackValue(self.senderPublicKey),
            MessagePackValue(keyAttachmentSenderPublicKeyTimestampKey): MessagePackValue(self.senderKeyTimestamp),
            MessagePackValue(keyAttachmentRecipientPublicKeyKey): MessagePackValue(self.recipientPublicKey),
            MessagePackValue(keyAttachmentRecipientPublicKeyTimestamp): MessagePackValue(self.recipientKeyTimestamp)
        ]
        
        return MessagePackValue(keyDictionary)
    }
}

//MARK: Key Attachments
struct VersionedData: Packable
{
    var version: String
    var serializedData: Data
    
    init(version: String, serializedData: Data)
    {
        self.version = version
        self.serializedData = serializedData
    }
    
    init?(value: MessagePackValue)
    {
        guard let versionDictionary = value.dictionaryValue
            else
        {
            print("Version deserialization error.")
            return nil
        }
        
        //Version
        guard let versionMessagePack = versionDictionary[.string(versionKey)]
            else
        {
            print("Version deserialization error.")
            return nil
        }
        
        guard let versionValue = versionMessagePack.stringValue
            else
        {
            print("Version deserialization error.")
            return nil
        }
        
        //Serialized Data
        guard let dataMessagePack = versionDictionary[.string(serializedDataKey)]
            else
        {
            print("Version deserialization error.")
            return nil
        }
        
        guard let sData = dataMessagePack.dataValue
            else
        {
            print("Version deserialization error.")
            return nil
        }
        
        self.version = versionValue
        self.serializedData = sData
    }
    
    func messagePackValue() -> MessagePackValue
    {
        let versionDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
            MessagePackValue(versionKey): MessagePackValue(version),
            MessagePackValue(serializedDataKey): MessagePackValue(serializedData)
        ]
        
        return MessagePackValue(versionDictionary)
    }
}

struct TimestampedUserKeys: Packable
{
    var userPublicKey: Data
    var userPrivateKey: Data
    var userKeyTimestamp: Int64
    
    init(userPublicKey: Data, userPrivateKey: Data, userKeyTimestamp: Int64)
    {
        self.userPublicKey = userPublicKey
        self.userPrivateKey = userPrivateKey
        self.userKeyTimestamp = userKeyTimestamp
    }
    
    init?(keyData: Data)
    {
        do
        {
            let unpackResult = try unpack(keyData)
            let unpackValue: MessagePackValue = unpackResult.value
            self.init(value: unpackValue)
        }
        catch let unpackError as NSError
        {
            print("Unpack user keys error: \(unpackError.localizedDescription)")
            return nil
        }
    }
    
    init?(value: MessagePackValue)
    {
        guard let keyDictionary = value.dictionaryValue
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        //User Public Key
        guard let userPublicKeyMessagePack = keyDictionary[.string(userPublicKeyKey)]
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        guard let userPublicKeyData = userPublicKeyMessagePack.dataValue
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        //User Private Key
        guard let userPrivateKeyMessagePack = keyDictionary[.string(userPrivateKeyKey)]
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        guard let userPrivateKeyData = userPrivateKeyMessagePack.dataValue
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        //Sender Key Timestamp
        guard let userTimestampMessagePack = keyDictionary[.string(userKeyTimestampKey)]
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        guard let userKeyTimestamp = userTimestampMessagePack.integerValue
            else
        {
            print("TimestampedUserKeys deserialization error.")
            return nil
        }
        
        self.userPublicKey = userPublicKeyData
        self.userPrivateKey = userPrivateKeyData
        self.userKeyTimestamp = userKeyTimestamp
    }
    
    func messagePackValue() -> MessagePackValue
    {
        let keyDictionary: Dictionary<MessagePackValue, MessagePackValue> = [
            MessagePackValue(userPublicKeyKey): MessagePackValue(self.userPublicKey),
            MessagePackValue(userPrivateKeyKey): MessagePackValue(self.userPrivateKey),
            MessagePackValue(userKeyTimestampKey): MessagePackValue(self.userKeyTimestamp)
        ]
        
        return MessagePackValue(keyDictionary)
    }
    
    func dataValue() -> Data?
    {
        let keyMessagePack = self.messagePackValue()
        return pack(keyMessagePack)
    }
}

func dataToSenderPublicKeys(keyData: Data) -> TimestampedSenderPublicKey?
{
    do
    {
        let unpackResult = try unpack(keyData)
        let unpackValue: MessagePackValue = unpackResult.value
        return TimestampedSenderPublicKey.init(value: unpackValue)
    }
    catch let unpackError as NSError
    {
        print("Unpack error: \(unpackError.localizedDescription)")
        return nil
    }
    //        let messagePack = MessagePackValue(keyData)
    //        guard let versionedData = VersionedData.init(value: messagePack)
    //            else
    //        {
    //            print("could not get versioned data")
    //            return nil
    //        }
    //
    //        guard versionedData.version == keyFormatVersion
    //            else
    //        {
    //            print("Key format versions do not match.")
    //            return nil
    //        }
    //
    //        return TimestampedSenderPublicKey.init(value: MessagePackValue(versionedData.serializedData))
    
}

func dataToPublicKeys(keyData: Data) -> TimestampedPublicKeys?
{
    do
    {
        let unpackResult = try unpack(keyData)
        let unpackValue: MessagePackValue = unpackResult.value
        return TimestampedPublicKeys.init(value: unpackValue)
    }
    catch let unpackError as NSError
    {
        print("Unpack error: \(unpackError.localizedDescription)")
        return nil
    }
    
    //        let messagePack = MessagePackValue(keyData)
    //        guard let versionedData = VersionedData.init(value: messagePack)
    //            else
    //        {
    //            print("could not get versioned data")
    //            return nil
    //        }
    //
    //        guard versionedData.version == keyFormatVersion
    //            else
    //        {
    //            print("Key format versions do not match.")
    //            return nil
    //        }
    //
    //        return TimestampedPublicKeys.init(value: MessagePackValue(versionedData.serializedData))
}

func generateSenderPublicKeyAttachment(forPenPal penPal: PenPal) -> Data?
{
    guard let senderKey = KeyController.sharedInstance.mySharedKey else {
        return nil
    }
    
    guard let userKeyTimestamp = KeyController.sharedInstance.myKeyTimestamp else {
        return nil
    }
    
    let senderKeyTimestamp = Int64(userKeyTimestamp.timeIntervalSince1970)
    
    let timestampedKeys = TimestampedSenderPublicKey.init(senderKey: senderKey, senderKeyTimestamp: senderKeyTimestamp)
    
    ///TODO: Include Versioned Data
    let keyMessagePack = timestampedKeys.messagePackValue()
    return pack(keyMessagePack)
}

func generateKeyAttachment(forPenPal penPal: PenPal) -> Data?
{
    guard let recipientKey = penPal.key else {
        return nil
    }
    
    guard let senderKey = KeyController.sharedInstance.mySharedKey else {
        return nil
    }
    
    guard let userKeyTimestamp = KeyController.sharedInstance.myKeyTimestamp else {
        return nil
    }
    
    guard let penPalKeyTimestamp = penPal.keyTimestamp else {
        return nil
    }
    
    let senderKeyTimestamp = Int64(userKeyTimestamp.timeIntervalSince1970)
    let recipientKeyTimestamp = Int64(penPalKeyTimestamp.timeIntervalSince1970)
    
    let timestampedKeys = TimestampedPublicKeys.init(senderKey: senderKey,
                                                     senderKeyTimestamp: senderKeyTimestamp,
                                                     recipientKey: recipientKey as Data,
                                                     recipientKeyTimestamp: recipientKeyTimestamp)
    ///TODO: Include Versioned Data
    let keyMessagePack = timestampedKeys.messagePackValue()
    return pack(keyMessagePack)
}
