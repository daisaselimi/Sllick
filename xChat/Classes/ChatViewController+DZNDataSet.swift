//
//  ChatViewController+DZNDataSet.swift
//  xChat
//
//  Created by Isa  Selimi on 14.8.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import DZNEmptyDataSet
import Foundation
import JSQSystemSoundPlayer

extension ChatViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No messages yet", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12.0)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Wave at them, perhaps?\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return NSAttributedString(string: wavingHand, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 40.0)])
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        var outgoingMessage: OutgoingMessage?
        let currentUser = FUser.currentUser()
        outgoingMessage = OutgoingMessage(message: wavingHand, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: Date(), status: kDELIVERED, type: kTEXT)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        outgoingMessage!.sendMessage(chatRoomID: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush, lastMessageType: kTEXT, isGroup: isGroup! ? true : false, groupName: isGroup! ? (group![kNAME] as! String) : "", chatTitle: titleLabel.text!, plainMessage: wavingHand)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 5.0
    }
}
