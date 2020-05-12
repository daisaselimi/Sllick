//
//  ActiveNowTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 9.4.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ActiveNowTableViewController: UITableViewController {
    
    var contacts: [String] = []
    var usersOnline: [String] = []
    var activeNow: [FUser] = []
    var firstFetchOfOnlineUsers: Bool = true
    var first: Bool = true
    //var activeUsersListener: ListenerRegistration?
    var activeUsersListeners: [ListenerRegistration] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // getContacts()
        //self.title = "Active now"
        self.tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onlineUsersChanged),
                                               name: .onlineUsersNotification, object: nil)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        usersOnline = MyVariables.usersOnline
        loadUsers()
        // getContacts()
        
    }
    
    
    @objc func onlineUsersChanged() {
        usersOnline = MyVariables.usersOnline
        loadUsers()
        //tableView.reloadData()
    }
    
    
//    func getContacts()  {
//
//        reference(.Contact).whereField("userID", isEqualTo: FUser.currentId()).addSnapshotListener { (snapshot, error) in
//
//            if error != nil {
//                return
//            }
//            guard snapshot != nil else {
//                return
//            }
//            if !snapshot!.isEmpty {
//                for userDictionary in snapshot!.documents {
//                    let userDictionary = userDictionary.data() as NSDictionary
//
//                    self.contacts = (userDictionary["contacts"] as! [String])
//
//                }
//                self.firstFetchOfOnlineUsers = true
//
//
//            } else {
//                self.contacts = []
//            }
//            // self.activeUsersListener?.remove()
//            self.activeUsersListeners.forEach({ $0.remove() })
//            self.activeUsersListeners.removeAll()
//            self.checkOnlineStatus()
//        }
//
//
//
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let user = activeNow[indexPath.row]
//
//
//        let chatVC = ChatViewController()
//        chatVC.titleName = user.firstname
//        chatVC.membersToPush = [FUser.currentId(), user.objectId]
//        chatVC.memberIds = [FUser.currentId(), user.objectId]
//        chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user)
//        chatVC.isGroup = false
//        chatVC.initialWithUser = user.fullname
//        chatVC.initialImage = (tableView.cellForRow(at: indexPath) as! ActiveUserTableViewCell).avatarImageView.image
//        chatVC.hidesBottomBarWhenPushed = true
//        self.navigationController?.pushViewController(chatVC, animated: true)
//    }
//
//    func checkOnlineStatus() {
//        print("here")
//
//        if  contacts.isEmpty {
//            self.usersOnline = []
//            loadUsers()
//            return
//        }
//
//
//        let contactsBy10 = contacts.chunked(into: 10)
//        var index = 0
//        for i in 0...contactsBy10.count - 1 {
//            print(" H E E E E R E E E E \(i)")
//            activeUsersListeners.append(Firestore.firestore().collection("status").whereField("userId", in: contactsBy10[i] ).order(by: "userId", descending: true).addSnapshotListener { (snapshot, error) in
//                print("CONTACTS::::::::::\(contactsBy10[i])")
//                guard let snapshot = snapshot else {
//                    print("NO SNAPSHOT -----------------_!!!")
//                    return
//                }
//
//                if !snapshot.isEmpty {
//
//                    if self.firstFetchOfOnlineUsers {
//                        if index == 0 {
//
//                            self.usersOnline = []
//                        }
//                        let documents = snapshot.documents
//
//                        for doc in documents {
//                            let userId = doc["userId"] as! String
//
//                            if doc["state"] as! String == "Online" {
//                                self.usersOnline.append(userId)
//                            }
//                        }
//                        if index == contactsBy10.count - 1 {
//                            self.firstFetchOfOnlineUsers = false
//                        }
//
//                    } else {
//                        snapshot.documentChanges.forEach { (docChange) in
//                            if docChange.type == .modified {
//                                print("-----------------------------------------User \(docChange.document.documentID) is \(docChange.document["state"] as! String)")
//                                let userId = docChange.document["userId"] as! String
//
//                                if docChange.document["state"] as! String == "Online" {
//
//                                    if !self.usersOnline.contains(userId) {
//                                        self.usersOnline.append(userId)
//                                    }
//
//                                } else {
//
//                                    if let idx = self.usersOnline.firstIndex(of: userId) {
//                                        print("RERERER ERE R E R E RE REMOVED")
//                                        self.usersOnline.remove(at: idx)
//                                    }
//                                }
//
//                            }
//                        }
//                    }
//                    print("U S E R S O N L I N E: \(self.usersOnline)")
//                    if index == contactsBy10.count - 1 {
//                        self.loadUsers()
//                    }
//
//
//                } else {
//                    print("SNAPSHOT EMPTY !!! -------")
//                    if self.usersOnline.count > 0 {
//                        self.loadUsers()
//                    }
//
//                }
//                index += 1
//            })
//        }
//
//
//    }
//
    func loadUsers() {
        print(usersOnline.count)
        if usersOnline.count == 0 {
            activeNow = []
            setTabItemTitle(controller: self.tabBarController!, title: "Active (0)")
            
            tableView.reloadData()
        } else {
            setTabItemTitle(controller: self.tabBarController!, title: "Active (\(self.usersOnline.count))")
            getUsersFromFirestore(withIds: usersOnline) { (users) in
                self.activeNow = users
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    // MARK: - Table view data source
    
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
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
