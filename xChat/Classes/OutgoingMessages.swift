//
//  OutgoingMessages.swift
//  Sllick
//
//  Created by Isa  Selimi on 23.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation

class OutgoingMessage {
    
    let messageDictionary: NSMutableDictionary
    
    // MARK: Initializers
    
    // text message
    init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), !MyVariables.internetConnectionState ? kWAITINGTOSEND : kDELIVERED, type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // picture message
    init(message: String, pictureLink: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [message, pictureLink, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // video message
    init(message: String, video: String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        let picThumb = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        messageDictionary = NSMutableDictionary(objects: [message, video, picThumb, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kVIDEO as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // audio message
    init(message: String, audio: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [message, audio, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kAUDIO as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // MARK: Send message
    
    func sendMessage(chatRoomID: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String], lastMessageType: String, isGroup: Bool = false, groupName: String = "", chatTitle: String, plainMessage: String = "") {
        let messageId = UUID().uuidString
        messageDictionary[kMESSAGEID] = messageId
        
        for memberId in memberIds {
            reference(.Message).document(memberId).collection(chatRoomID).document(messageId).setData(messageDictionary as! [String: Any])
        }
        
        // update recent chat
        updateRecents(forMembers: memberIds, chatRoomId: chatRoomID, lastMessage: messageDictionary[kMESSAGE] as! String, lastMessageType: lastMessageType)
        
        // send push notification
        var pushText = ""
        
        switch messageDictionary[kTYPE] as! String {
            case kPICTURE: pushText = "Sent a picture."
            case kVIDEO: pushText = "Sent a video."
            case kAUDIO: pushText = "Sent an audio message."
            default:
                pushText = plainMessage != "" ? plainMessage : "Sent a message."
        }
        
        sendPushNotification(membersToPush: membersToPush, message: pushText, isGroup: isGroup, groupName: groupName, memberIds: memberIds, chatRoomId: chatRoomID, titleName: chatTitle)
    }
    
    class func deleteMessage(withId: String, chatRoomId: String) {
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).document(withId).delete()
    }
    
    class func updateMessage(withId: String, chatRoomId: String, memberIds: [String], values: [String : String]) {
        for userId in memberIds {
            reference(.Message).document(userId).collection(chatRoomId).document(withId).getDocument { snapshot, _ in
                guard let snapshot = snapshot else { return }
                
                if snapshot.exists {
                    if snapshot.data()![kSTATUS] as! String != kREAD {
                       reference(.Message).document(userId).collection(chatRoomId).document(withId).updateData(values)
                    }
                }
            }
        }
    }
}
