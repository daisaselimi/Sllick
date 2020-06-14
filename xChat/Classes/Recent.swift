//
//  Recent.swift
//  Sllick
//
//  Created by Isa  Selimi on 21.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
    let userId1 = user1.objectId
    let userId2 = user2.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    }
    else {
        chatRoomId = userId2 + userId1
    }
    
    let members = [userId1, userId2]
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUsername: user2.fullname, type: kPRIVATE, users: [user1, user2], avatarOfGroup: nil)
    return chatRoomId
}

func createRecent(members: [String], chatRoomId: String, withUserUsername: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    var tempMembers = members
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                
                if let currentUserId = currentRecent[kUSERID] {
                    if tempMembers.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.firstIndex(of: currentUserId as! String)!)
                    }
                }
            }
        }
        
        for userId in tempMembers {
            // create recent items
            createRecentItems(userId: userId, chatRoomId: chatRoomId, members: members, withUserUsername: withUserUsername, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
}

func updateRecent(thatContainsID: String, withValues: [String: Any]) {
    reference(.Recent).whereField(kMEMBERS, arrayContains: thatContainsID).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                if recent[kTYPE] as! String == kPRIVATE, recent[kWITHUSERUSERID] as! String == thatContainsID {
                    updateRecentAfterEdit(recentId: recent[kRECENTID] as! String, withValues: withValues)
                }
            }
        }
    }
}

func createRecentItems(userId: String, chatRoomId: String, members: [String], withUserUsername: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    
    let date = dateFormatter().string(from: Date())
    
    var recent: [String: Any]!
    
    if type == kPRIVATE {
        var withUser: FUser?
        
        if users != nil, users!.count > 0 {
            if userId == FUser.currentId() {
                withUser = users!.last!
            }
            else {
                withUser = users!.first!
            }
        }
        
        recent = [kRECENTID: recentId, kSENDERNAME: FUser.currentUser()!.firstname, kSENDERID: FUser.currentId(), kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kLASTMESSAGETYPE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar, kWITHUSERACCOUNTSTATUS: ""] as [String: Any]
    }
    else {
        if avatarOfGroup != nil {
            recent = [kRECENTID: recentId, kSENDERNAME: FUser.currentUser()!.firstname, kSENDERID: FUser.currentId(), kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUserUsername, kLASTMESSAGE: "No messages", kLASTMESSAGETYPE: "group_created", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String: Any]
        }
    }
    
    localReference.setData(recent)
}

func deleteRecentChat(recentChatDictionary: NSDictionary) {
    if let recentId = recentChatDictionary[kRECENTID] {
        reference(.Recent).document(recentId as! String).delete()
    }
}

func restartChat(recent: NSDictionary) {
    if recent[kTYPE] as! String == kPRIVATE {
        createRecent(members: recent[kMEMBERS] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUsername: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarOfGroup: nil)
    }
    
    if recent[kTYPE] as! String == kGROUP {
        createRecent(members: [kMEMBERS], chatRoomId: recent[kCHATROOMID] as! String, withUserUsername: recent[kWITHUSERFULLNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)
    }
}

func clearRecentCounter(chatRoomId: String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                
                if currentRecent[kUSERID] as! String == FUser.currentId() {
                    clearRecentCounterItem(recent: currentRecent)
                }
            }
        }
    }
}

func clearRecentCounterItem(recent: NSDictionary) {
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER: 0])
}

func updateRecentItem(recent: NSDictionary, lastMessage: String, lastMessageType: String) {
    let date = dateFormatter().string(from: Date())
    
    var values: [String: Any] = [:]
    if recent[kUSERID] as! String == FUser.currentId() {
        values = [kLASTMESSAGE: lastMessage, kLASTMESSAGETYPE: lastMessageType, kDATE: date] as [String: Any]
    }
    else {
        var counter = recent[kCOUNTER] as! Int
        counter += 1
        values = [kLASTMESSAGE: lastMessage, kLASTMESSAGETYPE: lastMessageType, kCOUNTER: counter, kDATE: date] as [String: Any]
    }
    
    values[kSENDERID] = FUser.currentId()
    values[kSENDERNAME] = FUser.currentUser()!.firstname
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}

func updateRecents(forMembers: [String], chatRoomId: String, lastMessage: String, lastMessageType: String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                if forMembers.contains(recent[kUSERID] as! String) {
                    updateRecentItem(recent: currentRecent, lastMessage: lastMessage, lastMessageType: lastMessageType)
                }
            }
        }
    }
}

func updateRecents(forMembers: [String], chatRoomId: String, withValues: NSDictionary) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).whereField(kUSERID, isEqualTo: forMembers[0]).setValuesForKeys(withValues as! [String: Any])
}

func updateExistingRecentWithNewValues(forMembers: [String], chatRoomId: String, withValues: [String: Any]) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                if forMembers.contains(recent[kUSERID] as! String) {
                    updateRecentAfterEdit(recentId: recent[kRECENTID] as! String, withValues: withValues)
                }
            }
        }
    }
}

func updateRecentAfterEdit(recentId: String, withValues: [String: Any]) {
    reference(.Recent).document(recentId).updateData(withValues)
}

func updateRecent(recentId: String, withValues: [String: Any]) {
    let addToWithValues = NSMutableDictionary(dictionary: withValues)
    addToWithValues.setValue(FUser.currentId(), forKey: kSENDERID)
    addToWithValues.setValue(FUser.currentUser()?.firstname, forKey: kSENDERNAME)
    let nsDict = NSDictionary(dictionary: addToWithValues)
    reference(.Recent).document(recentId).updateData(nsDict as! [AnyHashable: Any])
}

// Block user

func blockUser(userToBlock: FUser) {
    let userId1 = FUser.currentId()
    let userId2 = userToBlock.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    }
    else {
        chatRoomId = userId2 + userId1
    }
    
    deleteRecentsFor(chatRoomId: chatRoomId)
}

func deleteRecentsFor(chatRoomId: String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                deleteRecentChat(recentChatDictionary: currentRecent)
            }
        }
    }
}

// Group
func startGroupChat(group: Group) {
    let chatRoomId = group.groupDictionary[kGROUPID] as! String
    let members = group.groupDictionary[kMEMBERS] as! [String]
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUsername: group.groupDictionary[kNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: group.groupDictionary[kAVATAR] as? String)
}

func createRecentsForNewMembers(groupId: String, groupName: String, membersToPush: [String], avatar: String) {
    createRecent(members: membersToPush, chatRoomId: groupId, withUserUsername: groupName, type: kGROUP, users: nil, avatarOfGroup: avatar)
}
