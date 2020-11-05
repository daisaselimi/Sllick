//
//  ChatViewController+Messaging.swift
//  xChat
//
//  Created by Isa  Selimi on 14.8.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import Firebase
import Foundation
import JSQMessagesViewController

extension ChatViewController {
    
    func loadMessages() {
        // update message status
        if GeneralVariables.updatedChatListeners[chatRoomId] != nil {
            GeneralVariables.updatedChatListeners[chatRoomId]!.remove()
        }
        
        GeneralVariables.updatedChatListeners[chatRoomId] = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { diff in
                    
                    if diff.type == .modified {
                        let dict = diff.document.data()
                        let tempArray = self.objectMessages.filter { $0[kMESSAGEID] as! String == dict[kMESSAGEID] as! String }
                        let changedMessageDoc = tempArray.count > 0 ? tempArray[0] : nil
                        if changedMessageDoc != nil {
                            if dict[kSTATUS] as! String == kREAD, dict[kSENDERID] as! String == FUser.currentId() {
                                let index = self.objectMessages.firstIndex(of: changedMessageDoc!)
                                self.objectMessages.remove(at: index!)
                                self.messages.remove(at: index!)
                                self.objectMessages.insert(dict as NSDictionary, at: index!)
                                let incomingMessage = IncomingMessage(collectionVIew_: self.collectionView)
                                incomingMessage.isSendingMessage = true
                                let message = incomingMessage.createMessage(messageDictionary: dict as NSDictionary, chatRoomId: self.chatRoomId)
                                self.messages.insert(message!, at: index!)
                                self.collectionView.reloadData()
                            } else {
                                if dict[kSENDERID] as! String == FUser.currentId() {
                                    self.messageHasBeenSent(messageDict: dict as NSDictionary)
                                }
                            }
                        }
                        // self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }
                }
            }
        }
        
        // get last 21 messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kACTUALLYSENT, descending: true).limit(to: 21).getDocuments(completion: { snapshot, error in
            self.collectionView.emptyDataSetDelegate = self
            self.collectionView.emptyDataSetSource = self
            self.internetConnectionChanged()
            if let error = error {
                self.gradientLoadingBar.fadeOut(duration: 0)
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode.rawValue {
                    case 8: self.showMessage("Transaction limit exceeded. Try again later.", type: .error, options: [.autoHide(false), .hideOnTap(false)])
                    default: self.showMessage(kSOMETHINGWENTWRONG, type: .error, options: [.autoHide(false), .hideOnTap(false)]); print("LOCALIZED DESC: \(errorCode)")
                    }
                }
                self.inputToolbar.isUserInteractionEnabled = false
                return
            }
            
            guard let snapshot = snapshot else {
                self.initialLoadComplete = true
                self.listenForNewChat()
                return
            }
            
            var sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kACTUALLYSENT, ascending: true)]) as! [NSDictionary]
            
            var pendingMessages: [NSDictionary] = []
            
            sorted.forEach { dictionary in
                if dictionary[kSTATUS] as! String == kSENDING {
                    pendingMessages.append(dictionary)
                    let index = sorted.firstIndex(of: dictionary)
                    sorted.remove(at: index!)
                }
            }
            
            pendingMessages.sort { dateFormatter().date(from: $0[kDATE] as! String)! < dateFormatter().date(from: $1[kDATE] as! String)! }
            
            sorted.append(contentsOf: pendingMessages)
            
            self.loadedMessages = sorted
//            self.loadedMessages.forEach { (dict) in
//                if (dict[kACTUALLYSENT] as? Timestamp) == nil {
//                    let idx = self.loadedMessages.firstIndex(of: dict)
//                    self.loadedMessages.remove(at: idx!)
//                }
//            }
            self.insertMessages()
            self.finishReceivingMessage(animated: false)
            self.scrollToBottom(animated: false)
            // self.perform(Selector(("jsq_updateCollectionViewInsets")))
            //  self.topContentAdditionalInset = 0
            self.firstLoadingFinished = true
            self.initialLoadComplete = true
            print("we have \(self.messages.count) messages loaded")
            // get pictures
            
            self.listenForNewChat()
            self.getPictureMessages()
            // get old messages in background
            self.getOldMessagesInBackground()
            self.gradientLoadingBar.fadeOut()
            
        })
        
        //      firstMessagesListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kACTUALLYSENT, descending: true).limit(to: 21).addSnapshotListener(includeMetadataChanges: true) { (snapshot, error) in
        //            guard let snapshot = snapshot else { return }
        //
        //            if !snapshot.isEmpty {
        //
        //                for diff in snapshot.documentChanges(includeMetadataChanges: true) {
        //                    let item = diff.document.data() as NSDictionary
        //                    let messageDict: NSMutableDictionary = item as! NSMutableDictionary
        //                    if  diff.document.metadata.hasPendingWrites {
        //                        messageDict[kSTATUS] = kSENDING
        //
        //                    } else {
        //                        messageDict[kSTATUS] = kDELIVERED
        //                        //                                    OutgoingMessage.updateMessage(withId: messageDict[kMESSAGEID] as! String, chatRoomId: self.chatRoomId, memberIds: self.memberIds, values: [kDATE : dateFormatter().string(from: Date())])
        //
        //                        self.updateMessage(messageDictionary: messageDict)
        //                    }
        //                }
        //            }
        //        }
    }
    
    func updateMessage(messageDictionary: NSDictionary) {
        for index in 0..<objectMessages.count {
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessages[index] = messageDictionary
                // messages[index] = IncomingMessage.createMessage(messageDictionary)
                collectionView!.reloadData()
            }
        }
    }
    
    func listenForNewChat() {
        var lastMessageDate = ""
        
        if loadedMessages.count > 0 {
            if let timeStamp = (loadedMessages.last![kACTUALLYSENT] as? Timestamp) {
                lastMessageDate = dateFormatter().string(from: timeStamp.dateValue())
            } else {
                lastMessageDate = loadedMessages.last![kDATE] as! String
            }
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                for diff in snapshot.documentChanges {
                    //  if diff.type == .added {
                    let item = diff.document.data() as NSDictionary
                    
                    if let type = item[kTYPE] {
                        if self.legitTypes.contains(type as! String) {
                            if type as! String == kPICTURE {
                                self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                            }
                            let messageDict: NSMutableDictionary = item as! NSMutableDictionary
                            if diff.document.metadata.hasPendingWrites {
                                messageDict[kSTATUS] = kSENDING
                                
                            } else {
                                if messageDict[kSTATUS] as! String != kREAD, messageDict[kSENDERID] as! String == FUser.currentId() {
                                    messageDict[kSTATUS] = kDELIVERED
                                    // self.messageHasBeenSent(messageDict: messageDict)
                                }
                            }
                            if diff.type != .removed, diff.type != .modified {
                                if self.insertInitialLoadMessages(messageDictionary: messageDict, isSendingMessage: true) && type as! String != kSYSTEMMESSAGE {
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                self.finishReceivingMessage()
                            }
                        }
                    }
                    //   }
                }
            }
        }
    }
    
    func messageHasBeenSent(messageDict: NSDictionary) {
        print(messageDict)
        self.firstMessagesListener?.remove()
        //                                    OutgoingMessage.updateMessage(withId: messageDict[kMESSAGEID] as! String, chatRoomId: self.chatRoomId, memberIds: self.memberIds, values: [kDATE : dateFormatter().string(from: Date())])
        if messageDict[kTYPE] as! String == kSYSTEMMESSAGE {
            return
        }
        let objectMessage = self.objectMessages.first { (dict) -> Bool in
            dict[kMESSAGEID] as! String == messageDict[kMESSAGEID] as! String
        }
        
        let index = self.objectMessages.firstIndex(of: objectMessage!)
        self.objectMessages.remove(at: index!)
        self.messages.remove(at: index!)
        // self.insertInitialLoadMessages(messageDictionary: objectMessage!)
        let incomingMessage = IncomingMessage(collectionVIew_: self.collectionView!)
        incomingMessage.isSendingMessage = true
        let message = incomingMessage.createMessage(messageDictionary: messageDict, chatRoomId: self.chatRoomId)
        self.objectMessages.append(messageDict)
        
        self.messages.append(message!)
        collectionView.reloadData()
        
        updateRecents(forMembers: self.memberIds, chatRoomId: self.chatRoomId, lastMessage: messageDict[kMESSAGE] as! String, lastMessageType: messageDict[kTYPE] as! String)
        
        // send push notification
        var pushText = ""
        let plainMessage = messageDict[kMESSAGE] as! String
        
        switch messageDict[kTYPE] as! String {
        case kPICTURE: pushText = "Sent a picture."
        case kVIDEO: pushText = "Sent a video."
        case kAUDIO: pushText = "Sent an audio message."
        default:
            pushText = plainMessage != "" ? plainMessage : "Sent a message."
        }
        
        sendPushNotification(membersToPush: self.membersToPush, message: pushText, isGroup: self.isGroup!, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", memberIds: self.memberIds, chatRoomId: self.chatRoomId, titleName: self.titleLabel.text!)
    }
    
    // insert messages
    func insertMessages() {
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in minMessageNumber..<maxMessageNumber {
            let messageDictionary = loadedMessages[i]
            
            _ = self.insertInitialLoadMessages(messageDictionary: messageDictionary)
            
            loadedMessagesCount += 1
        }
        
        // showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
    }
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary, isSendingMessage: Bool = false) -> Bool {
        let incomingMessage = IncomingMessage(collectionVIew_: collectionView!)
        incomingMessage.isSendingMessage = isSendingMessage
        // check if incoming
        if ((UIApplication.getTopViewController() as? ChatViewController) != nil) {
            if messageDictionary[kSENDERID] as! String != FUser.currentId() {
                  if messageDictionary[kSTATUS] as! String == kDELIVERED {
                      OutgoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String,
                                                    chatRoomId: chatRoomId, memberIds: memberIds, values: [kSTATUS: kREAD, kREADDATE: dateFormatter().string(from: Date())])
                  }
              }
        }
  
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            if (objectMessages.filter { $0[kMESSAGEID] as! String == messageDictionary[kMESSAGEID] as! String }).count > 0 {
                if let index = objectMessages.firstIndex(of: objectMessages.filter { $0[kMESSAGEID] as! String == messageDictionary[kMESSAGEID] as! String }[0]) {
                    objectMessages.remove(at: index)
                    messages.remove(at: index)
                }
            }
            
            objectMessages.append(messageDictionary)
            
            messages.append(message!)
            // self.collectionView.reloadData()
        }
        
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    // MARK: Send messages
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        var outgoingMessage: OutgoingMessage?
        let currentUser = FUser.currentUser()
        if isGroup! {
            membersToPush = (group![kMEMBERSTOPUSH] as! [String])
            memberIds = (group![kMEMBERS] as! [String])
        }
        
        if text == nil {
            gradientForMessagesUploads.fadeIn()
        }
        
        if let text = text {
            //  let encryptedText = Encryption.encryptText(chatRoomId: chatRoomId, message: text)
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kTEXT)
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            finishSendingMessage()
            outgoingMessage!.sendMessage(chatRoomID: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush, lastMessageType: kTEXT, isGroup: isGroup! ? true : false, groupName: isGroup! ? (group![kNAME] as! String) : "", chatTitle: titleLabel.text!, plainMessage: text)
        } else if let pic = picture {
            uploadImage(image: pic, chatRoomId: chatRoomId, view: navigationController!.view) { imageLink in
                self.gradientForMessagesUploads.fadeOut()
                if imageLink != nil {
                    // let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kPICTURE)
                    let encryptedText = kPICTURE
                    outgoingMessage = OutgoingMessage(message: encryptedText, pictureLink: imageLink!, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMediaMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kPICTURE, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
        } else if let video = video {
            let videoData = NSData(contentsOfFile: video.path!)
            let dataThumbnail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: navigationController!.view) { videoLink in
                self.gradientForMessagesUploads.fadeOut()
                if videoLink != nil {
                    // let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kVIDEO)
                    let encryptedText = kVIDEO
                    outgoingMessage = OutgoingMessage(message: encryptedText, video: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMediaMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kVIDEO, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
        } else if let audio = audio {
            uploadAudio(audioPath: audio, chatRoomId: chatRoomId, view: navigationController!.view) { audioLink in
                self.gradientForMessagesUploads.fadeOut()
                if audioLink != nil {
                    // let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kAUDIO)
                    let encryptedText = kAUDIO
                    
                    outgoingMessage = OutgoingMessage(message: encryptedText, audio: audioLink!, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMediaMessage()
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kAUDIO, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
        }
    }
    
    func finishSendingMediaMessage() {
        let text = self.inputToolbar.contentView.textView?.text
        self.finishSendingMessage()
        self.inputToolbar.contentView.textView?.text = text
    }
}
