//
//  ActiveNowTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 9.4.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import DZNEmptyDataSet
import FirebaseFirestore
import UIKit

class ActiveNowTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var contacts: [String] = []
    var usersOnline: [String] = []
    var activeNow: [FUser] = []
    var firstFetchOfOnlineUsers: Bool = true
    var first: Bool = true
    var activeUsersListeners: [ListenerRegistration] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // getContacts()
        // self.title = "Active now"
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
        //  tableView.emptyDataSetSource = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onlineUsersChanged),
                                               name: .onlineUsersNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        usersOnline = GeneralVariables.usersOnline
//        loadUsers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//                if (self.tableView.contentOffset.y < 0 && self.tableView.isEmptyDataSetVisible) {
//            self.tableView.contentOffset = CGPoint.zero;
//        }
        tableView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView?.emptyDataSetSource == nil {
            tableView?.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
            tableView?.reloadEmptyDataSet()
        }
    }
    
    @objc func onlineUsersChanged() {
        usersOnline = GeneralVariables.usersOnline
        loadUsers()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = activeNow[indexPath.row]
        
        let chatVC = ChatViewController()
        chatVC.titleName = user.firstname
        chatVC.membersToPush = [FUser.currentId(), user.objectId]
        chatVC.memberIds = [FUser.currentId(), user.objectId]
        chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user)
        chatVC.isGroup = false
        chatVC.initialWithUser = user.fullname
        chatVC.initialImage = (tableView.cellForRow(at: indexPath) as! ActiveUserTableViewCell).avatarImageView.image
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func loadUsers() {
        print(usersOnline.count)
        if usersOnline.count == 0 {
            activeNow = []
            setTabItemTitle(controller: tabBarController!, title: "Active (0)")
            
            tableView.reloadData()
        } else {
            setTabItemTitle(controller: tabBarController!, title: "Active (\(usersOnline.count))")
            getUsersFromFirestore(withIds: usersOnline) { users in
                self.activeNow = users
                
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source\
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return activeNow.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ActiveUserTableViewCell
        
        let user: FUser = activeNow[indexPath.row]
        
        cell.selectionStyle = .none
        cell.generateCellWith(fUser: user, indexPath: indexPath, isOnline: true)
        return cell
    }
    
    // MARK: DZN data source/delegate methods
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "balloon")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "NO ACTIVE USERS", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "People who are active and in your contacts list will appear here.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}
