//
//  Badges.swift
//  Sllick
//
//  Created by Isa  Selimi on 22.3.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import FirebaseFirestore
import Foundation

func recentBadgeCount(withBlock: @escaping (_ badgeNumber: Int) -> Void) {
    
    recentBadgeHandler = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener { snapshot, _ in
        
        var badge = 0
        var counter = 0
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            let recents = snapshot.documents
            
            for recent in recents {
                let currentRecent = recent.data() as NSDictionary
                
                if (UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId != (currentRecent["chatRoomID"] as! String) {
                    badge += currentRecent[kCOUNTER] as! Int
                }
                
                counter += 1
                
                if counter == recents.count {
                    withBlock(badge)
                }
            }
        } else {
            withBlock(badge)
        }
    }
}

func setBadges(controller: UITabBarController) {
    recentBadgeCount { badge in
        
        if badge != 0 {
            controller.tabBar.items![0].badgeValue = "\(badge)"
            UIApplication.shared.applicationIconBadgeNumber = badge
        } else {
            controller.tabBar.items![0].badgeValue = nil
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

func setTabItemTitle(controller: UITabBarController, title: String) {
    controller.tabBar.items![1].title = title
}
