//
//  Group.swift
//  xChat
//
//  Created by Isa  Selimi on 10.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Group {
    
    let groupDictionary: NSMutableDictionary
    
    init(groupId: String, subject: String, ownerId: String, members: [String], avatar: String) {
        
        groupDictionary = NSMutableDictionary(objects: [groupId, subject, ownerId, members, members, avatar], forKeys: [kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying] )
    }
    
    func saveGroup() {
        
        let date = dateFormatter().string(from: Date())
        groupDictionary[kDATE] = date
        reference(.Group).document(groupDictionary[kGROUPID] as! String).setData(groupDictionary as! [String : Any])
    }
    
    class func updateGroup(groupId: String, withValues: [String : Any]) {
       reference(.Group).document(groupId).updateData(withValues)
    }
    

    
    class func getGroup(groupId: String, completion: @escaping(NSDictionary) -> Void) {
        reference(.Group).document(groupId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if snapshot.exists {

                let groupDict = snapshot.data()! as NSDictionary
                completion(groupDict)
            }
        }
    }
}
