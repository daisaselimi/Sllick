//
//  IncomingMessages.swift
//  xChat
//
//  Created by Isa  Selimi on 23.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionVIew_: JSQMessagesCollectionView) {
        collectionView = collectionVIew_
    }
    
    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        
        var message: JSQMessage?
        
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT: createTextMessage(messageDicitionary: messageDictionary, chatRoomId: chatRoomId) {
                decryptedTxt in
                message = decryptedTxt
            }
        case kPICTURE: message = createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO: message = createVideoMessage(messageDictionary: messageDictionary)
        case kAUDIO: message = createAudioMessage(messageDictionary: messageDictionary)
        case kLOCATION: print("LOCATION")
        default: print("Unknown message type")
        }
        
        if message != nil {
            return message
        }
        
        return nil
    }
    
    
    func  createTextMessage(messageDicitionary: NSDictionary, chatRoomId: String, completion: @escaping (JSQMessage) -> Void) {
        
        let name = messageDicitionary[kSENDERNAME] as? String
        let userId = messageDicitionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDicitionary[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created)
            }
        }
        else {
            date = Date()
        }
        
        let text = messageDicitionary[kMESSAGE] as! String
        
         Encryption.decryptText(chatRoomId: chatRoomId, encryptedMessage: text) {
            decryptedTxt in
            
            completion(JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: decryptedTxt))
        }
       
    }
    
    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDictionary[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created)
            }
        }
        else {
            date = Date()
        }
        
        
        let mediaItem = PhotoMediaItem(image: nil)
        
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
            }
        }
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func createVideoMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDictionary[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created)
            }
        }
        else {
            date = Date()
        }
        
        
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        
        let mediaItem = VideoMessage(withFileURL: videoURL, maskOutgoing: returnOutgoingStatusForUser(senderId: userId!))
        
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isReadyToPlay, fileName) in
            
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String) { (image) in
                
                if image != nil {
                    mediaItem.image = image!
                    self.collectionView.reloadData()
                }
            }
            self.collectionView.reloadData()
        }
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func returnOutgoingStatusForUser(senderId: String) -> Bool {
        senderId == FUser.currentId()
    }
    
    func createAudioMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDictionary[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created)
            }
        }
        else {
            date = Date()
        }
        
        let audioItem = JSQAudioMediaItem(data: nil)
        
        audioItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        
        let audioMessage = JSQMessage(senderId: userId!, displayName: name!, media: audioItem)
        
        
        downloadAudio(audioUrl: messageDictionary[kAUDIO] as! String) { (fileName) in
            
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            
            let audioData =  try? Data(contentsOf: url as URL)
            audioItem.audioData = audioData
            self.collectionView.reloadData()
        }
        return audioMessage!
    }
}
