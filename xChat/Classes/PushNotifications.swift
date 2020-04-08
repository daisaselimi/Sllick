//
//  PushNotifications.swift
//  xChat
//
//  Created by Isa  Selimi on 14.3.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import Foundation
import OneSignal

func sendPushNotification(membersToPush: [String], message: String, isGroup: Bool, groupName: String = "", memberIds: [String], chatRoomId: String, titleName: String) {
    
    let updatedMembersToPush = membersToPush.filter { $0 != FUser.currentId() }
     print("UTP**************************************\(updatedMembersToPush)*************************************")
    getMembersToPush(members: updatedMembersToPush) { (usersPushIds) in
        
        if usersPushIds.filter( { $0 == "" }).count >= 1 {
            print("---- NIL PUSH IDS ----")
            return
        }
        let currentUser = FUser.currentUser()!
        print("UTP**************************************\(usersPushIds)*************************************")
        
        if !isGroup {
            OneSignal.postNotification([
                     "headings" : ["en" : currentUser.fullname],
                     "contents" : ["en" : message],
                     "thread_id" : currentUser.objectId,
                     "summary_arg" : currentUser.fullname,
                     "ios_badgeType" : "Increase",
                     "ios_badgeCount" : "1",
                     "include_player_ids" : usersPushIds,
                     "data" : ["chatRoomId" : chatRoomId, "membersToPush" : membersToPush, "memberIds" : memberIds, "titleName" : titleName, "isGroup" : isGroup, "withUser" : currentUser.fullname]
                 ])
        }
        else {
            OneSignal.postNotification([
                     "headings" : ["en" : "\(currentUser.fullname) in \(groupName)"],
                     "contents" : ["en" : message],
                     "thread_id" : currentUser.objectId,
                     "summary_arg" : currentUser.fullname,
                     "ios_badgeType" : "Increase",
                     "ios_badgeCount" : "1",
                     "include_player_ids" : usersPushIds,
                     "data" : ["chatRoomId" : chatRoomId, "membersToPush" : membersToPush, "memberIds" : memberIds, "titleName" : titleName, "isGroup" : isGroup, "withUser" : currentUser.fullname]
                 ])
        }
    }
}

func getMembersToPush(members: [String], completion: @escaping (_ usersArray: [String]) -> Void) {
    
    var pushIds: [String] = []
    var count = 0
    
    for memberId in members {
        reference(.User).document(memberId).getDocument { (snapshot, error) in
            
            guard let snapshot = snapshot else { completion(pushIds); return }
            
            if snapshot.exists {
                let userDictionary = snapshot.data()! as NSDictionary
                let fUser = FUser.init(_dictionary: userDictionary)
                pushIds.append(fUser.pushId!)
                count += 1
                
                print("pushIDsssss\(pushIds)")
                if members.count == count {
                    completion(pushIds)
                }
            }
        }
    }
}
