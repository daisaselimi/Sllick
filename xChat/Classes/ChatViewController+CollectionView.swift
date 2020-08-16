//
//  ChatViewController+CollectionView.swift
//  xChat
//
//  Created by Isa  Selimi on 14.8.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import AVKit
import Foundation
import JSQMessagesViewController
import SKPhotoBrowser

extension ChatViewController {
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = messages[indexPath.row]
        let cell: JSQMessagesCollectionViewCell!
        
        if data.senderId == FUser.currentId() {
            cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MessageViewOutgoing
            cell.textView?.textColor = userDefaults.object(forKey: kBACKGROUNDIMAGE) != nil ? .white : .label
            if messages[indexPath.row].isMediaMessage {
                (cell as! MessageViewOutgoing).timeLabelForMediaMessages?.text = messages[indexPath.row].date.timeAgoInMessages()
                (cell as! MessageViewOutgoing).trailingAvatarConstraint.constant = -22
            } else {
                (cell as! MessageViewOutgoing).timeLabel?.text = messages[indexPath.row].date.timeAgoInMessages()
            }
            
        } else {
            cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MessageViewIncoming
            cell.textView?.textColor = .label
            // cell.textView?.textColor = userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil ? .white : .label
            if messages[indexPath.row].isMediaMessage {
                (cell as! MessageViewIncoming).timeLabelForMediaMessages?.text = messages[indexPath.row].date.timeAgoInMessages()
            } else {
                (cell as! MessageViewIncoming).timeLabel?.text = messages[indexPath.row].date.timeAgoInMessages()
            }
        }
        
        // cell.textView?.isSelectable = false
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        // self.collectionView.reloadData()
        
        loadMoreMessages(maxNumer: maxMessageNumber, minNumber: minMessageNumber)
        
        print("load more....")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if !isFirstInSet(indexOfMessage: indexPath), !firstMessageOfTheDay(indexOfMessage: indexPath) {
            return 0
        }
        if messages[indexPath.row].senderId != FUser.currentId(), isGroup! {
            return 30
        }
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if !isFirstInSet(indexOfMessage: indexPath) && !firstMessageOfTheDay(indexOfMessage: indexPath) {
            return nil
        }
        if messages[indexPath.row].senderId == FUser.currentId() || !isGroup! {
            return NSAttributedString(string: "")
        }
        return NSAttributedString(string: messages[indexPath.row].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        if firstMessageOfTheDay(indexOfMessage: indexPath) {
            return NSAttributedString(string: message.date.timeAgoInMessages(fullTimeAgo: true), attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]) // ])
        } else {
            return nil // NSAttributedString(string: message.date.timeAgoInMessages(fullTimeAgo: false))
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        
        var status: NSAttributedString = NSAttributedString(string: kWAITINGTOSEND)
        
        _ = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        // status = NSAttributedString(string: messages[indexPath.row].date.timeAgoInMessages())
        switch message[kSTATUS] as! String {
        case kWAITINGTOSEND:
            if MyVariables.internetConnectionState {
                OutgoingMessage.updateMessage(withId: message[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds!, values: [kSTATUS: kDELIVERED])
                //                if indexPath.row == messages.count - 1 {
                //                    updateExistingRecentWithNewValues(forMembers:[FUser.currentId()], chatRoomId: chatRoomId, withValues: [kLASTMESSAGE : message[kMESSAGE] as! String, kDATE : dateFormatter().string(from: Date())
                //                    ])
                //                }
            } else {
                status = NSAttributedString(string: kWAITINGTOSEND)
            }
            
        case kDELIVERED:
            //            status = NSAttributedString(string: messages[indexPath.row].date.timeAgoInMessages() + (indexPath.row == (messages.count - 1) && messages[indexPath.row].senderId == FUser.currentId() ? ("・" + kDELIVERED.capitalizingFirstLetter()) : ""))
            status = NSAttributedString(string: "Sent")
        case kREAD:
            let statusText = "Seen " + readTimeFrom(dateString: message[kREADDATE] as! String)
            //            status = NSAttributedString(string: messages[indexPath.row].date.timeAgoInMessages() + (indexPath.row == (messages.count - 1) && messages[indexPath.row].senderId == FUser.currentId() ? ("・" + statusText) : ""), attributes: attributetStringColor)
            status = NSAttributedString(string: statusText)
        default:
            status = NSAttributedString(string: "✔️⇢")
        }
        
        return status
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        if !isLastInSet(indexOfMessage: indexPath), !firstMessageOfTheDay(indexOfMessage: nextIndexPath) {
            return isGroup! ? JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(), diameter: 70) : nil
        }
        var avatar: JSQMessageAvatarImageDataSource
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId!) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarph"), diameter: 70)
        }
        
        return avatar
    }
    
    func isLastInSet(indexOfMessage: IndexPath) -> Bool {
        if indexOfMessage.item == messages.count - 1 {
            return true
        } else {
            return (messages[indexOfMessage.item].senderId != messages[indexOfMessage.item + 1].senderId)
        }
    }
    
    func isFirstInSet(indexOfMessage: IndexPath) -> Bool {
        if indexOfMessage.item == messages.count {
            return false
        }
        if indexOfMessage.item == 0 {
            return true
        } else {
            return messages[indexOfMessage.item].senderId != messages[indexOfMessage.item - 1].senderId
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId(), indexPath.row == objectMessages.count - 1 || objectMessages[indexPath.row][kSTATUS] as! String == kWAITINGTOSEND {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        //        if previousDate == nil {
        //            previousDate = messages[indexPath.row].date()
        //
        if firstMessageOfTheDay(indexOfMessage: indexPath) {
            return 40.0
        }
        
        if messages[indexPath.row].senderId != messages[indexPath.row - 1].senderId {
            return 20.0
        }
        
        return 0.0 // kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:
            let message = messages[indexPath.row]
            var images = [SKPhoto]()
            let mediaItem = message.media as! JSQPhotoMediaItem
            if mediaItem.image == nil {
                return
            }
            let photo = SKPhoto.photoWithImage(mediaItem.image!)
            images.append(photo)
            let browser = SKPhotoBrowser(photos: images)
            present(browser, animated: true, completion: nil)
        case kLOCATION: print("location message tapped")
        case kVIDEO:
            print("location message tapped")
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayer.player = player
            present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
        default: print("unknown message tapped")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        if withUsers.first == nil && !isGroup! {
            return
        }
        
        let senderID = messages[indexPath.row].senderId
        var selectedUser: FUser?
        
        if senderID == FUser.currentId() {
            selectedUser = FUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderID {
                    selectedUser = user
                }
            }
        }
        
        if selectedUser == nil || selectedUser == FUser.currentUser() {
            return
        }
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = selectedUser
        profileVC.fromGroup = isGroup! ? true : false
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // for multimedia messages delete option
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        // super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:" {
                return true
            } else {
                return false
            }
        } else {
            if action.description == "delete:" || action.description == "copy:" {
                return true
            } else {
                return false
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        // collectionView.reloadData()
//        UIView.animate(withDuration: 1) {
//             collectionView.reloadEmptyDataSet()
//        }
        
        if messages.count == 0 {
            UIView.transition(with: collectionView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                //Do the data reload here
                self.collectionView.reloadEmptyDataSet()
            }, completion: nil)
        }
        
        // delete message from firebase
        OutgoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)
        
        if indexPath.row == messages.count {
            updateExistingRecentWithNewValues(forMembers: [FUser.currentId()], chatRoomId: chatRoomId, withValues: [kLASTMESSAGETYPE: "removed_message", kDATE: dateFormatter().string(from: Date())])
        } else {
            collectionView.reloadData()
        }
    }
}

// JSQMessage delegates
extension ChatViewController {
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        if !MyVariables.internetConnectionState {
            showMessage(kNOINTERNETCONNECTION, type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
            return
        }
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = Camera(delegate_: self)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentMultyCamera(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentPhotoLibrary(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentVideoLibrary(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { _ in
            
            print("share location")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        
        takePhotoOrVideo.setValue(UIImage(systemName: "camera.viewfinder"), forKey: "image")
        sharePhoto.setValue(UIImage(systemName: "camera"), forKey: "image")
        shareVideo.setValue(UIImage(systemName: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(cancelAction)
        
        // for iPad compatibility mode
        optionMenu.view.tintColor = UIColor.getAppColor(.light)
        if UIDevice().userInterfaceIdiom == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true, completion: nil)
            }
        }
        present(optionMenu, animated: true, completion: nil)
    }
    
    // send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            print(text!)
            sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
            collectionView.reloadData()
            // self.view.layoutIfNeeded()
        } else {
            if !MyVariables.internetConnectionState {
                showMessage(kNOINTERNETCONNECTION, type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
                return
            }
            internetConnectionChanged()
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespaces).isEmpty  {
            updateSendButton(isSend: false)
        }
        else  if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
    
    func firstMessageOfTheDay(indexOfMessage: IndexPath) -> Bool {
        if indexOfMessage.item == 0 {
            return true
        }
        
        let messageDate = messages[indexOfMessage.item].date
        guard let previouseMessageDate = messages[indexOfMessage.item - 1].date else {
            return true // because there is no previous message so we need to show the date
        }
        let day = Calendar.current.component(.day, from: messageDate!)
        let previouseDay = Calendar.current.component(.day, from: previouseMessageDate)
        if day == previouseDay {
            return false
        } else {
            return true
        }
    }
}

class CustomCollectionViewFlowLayout: JSQMessagesCollectionViewFlowLayout {
    override func messageBubbleSizeForItem(at indexPath: IndexPath!) -> CGSize {
        var superSize = super.messageBubbleSizeForItem(at: indexPath)
        
        // let messageItem = collectionView.dataSource?.collectionView(collectionView, messageDataForItemAt: indexPath)
        if superSize.width > 300 {
            superSize = CGSize(width: 300, height: superSize.height)
        }
        
        return superSize
    }
}

extension JSQMessagesCellTextView {
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
