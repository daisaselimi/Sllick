//
//  ChatsViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 18.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD
import OneSignal

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatsTableViewCellDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var newChatButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var recentChatsTableView: UITableView!
    @IBOutlet weak var newGroupButtonOutlet: UIBarButtonItem!
    var recentListener: ListenerRegistration!
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    var searchController = UISearchController(searchResultsController: nil)
    var firstLoad = false
    var topbarHeight: CGFloat {
           return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
               (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(receivedNotification(_:)),
                                                   name: NSNotification.Name(rawValue: "ReceivedNotification"), object: nil)
        
        setupLeftBarButtons()
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(setupLeftBarButtons),
                                                   name: NSNotification.Name(rawValue: "UserSavedLocally"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateProfilePicture(_:)),
                                                         name: NSNotification.Name(rawValue: "UpdatedProfilePicture"), object: nil)
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.50
        self.tabBarController?.tabBar.layer.borderColor = UIColor.clear.cgColor
        self.tabBarController?.tabBar.clipsToBounds = true

       self.navigationController?.navigationBar.shadowImage = UIImage()
        
        setBadges(controller: self.tabBarController!)
        recentChatsTableView.delegate = self
        recentChatsTableView.dataSource = self
        navigationController?.viewControllers[0] = self
        //recentChatsTableView.separatorInset = UIEdgeInsets(top: 0, left: 93, bottom: 0, right: 0)
        recentChatsTableView.separatorStyle = .none
        recentChatsTableView.rowHeight = 75
        // let navBarAppearance = UINavigationBarAppearance()
        //        navBarAppearance.configureWithOpaqueBackground()
        //        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        //        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        //        navBarAppearance.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        //        navigationController?.navigationBar.standardAppearance = navBarAppearance
        //        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        //
        //        navigationItem.hidesSearchBarWhenScrolling = true
       // navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        // Do any additional setup after loading the view.
    }
    
    @objc func setupLeftBarButtons() {
//        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
        if let currentUser = FUser.currentUser() {
                    if currentUser.avatar != "" {
                        
                        imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
                            
                            if avatarImage != nil {
                                let avtImg = avatarImage!
                                navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: avtImg)
                            }
                        }
                    } else {
                       navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
            }
        } else {
              navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
            //navigationItem.leftBarButtonItems?[0].image = UIImage()
        }
      
    }
    
    @objc func presentSettings() {
        performSegue(withIdentifier: "presentSettingsNav", sender: self)
    }
    
    @objc func updateProfilePicture(_ notification: Notification) {
        
        let img =  notification.userInfo!["picture"]  as! UIImage
       
        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: img)
        
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    override func viewDidLayoutSubviews() {
       // setTableViewHeader()
        recentChatsTableView.separatorStyle = .none
        recentChatsTableView.separatorColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //navigationItem.hidesSearchBarWhenScrolling = false
    
        loadRecentChats()
        recentChatsTableView.tableFooterView = UIView() //remove table lines when there's nothing to show
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        navigationItem.hidesSearchBarWhenScrolling = true
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        
        selectUserForChat(isGroup: false)
        
    }
    
    //MARK Table view delegate/datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
        }
        else {
            
            return recentChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = recentChatsTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatsTableViewCell
        cell.delegate = self
        var recent: NSDictionary
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        }
        else {
            
            recent = recentChats[indexPath.row]
        }
        
        cell.generateCell(isGroup: recent[kTYPE] as! String == kGROUP, recentChat: recent, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    
    
    
//    private func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction] {
//
//        var tempRecent: NSDictionary
//
//        if searchController.isActive && searchController.searchBar.text != "" {
//            tempRecent = filteredChats[indexPath.row]
//        }
//        else {
//
//            tempRecent = recentChats[indexPath.row]
//        }
//
//        var muteTitle = "Unmute"
//        var mute = false
//
//        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
//            muteTitle = "Mute"
//            mute = true
//        }
//
//        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
//
//            if self.searchController.isActive && self.searchController.searchBar.text != "" {
//                deleteRecentChat(recentChatDictionary: self.filteredChats[indexPath.row])
//                self.filteredChats.remove(at: indexPath.row)
//                self.recentChatsTableView.reloadData()
//            }
//            else {
//                deleteRecentChat(recentChatDictionary: self.recentChats[indexPath.row])
//                self.recentChats.remove(at: indexPath.row)
//                self.recentChatsTableView.reloadData()
//            }
//
//        }
//
//        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
//
//
//        }
//
//        muteAction.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
//        return [deleteAction, muteAction]
//    }
//
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var tempRecent: NSDictionary
        
        if searchController.isActive && searchController.searchBar.text != "" {
            tempRecent = filteredChats[indexPath.row]
        }
        else {
            
            tempRecent = recentChats[indexPath.row]
        }
        
        let deleteRecent = UIContextualAction(style: .normal, title: nil) { (action, view, success) in
            if self.searchController.isActive && self.searchController.searchBar.text != "" {
                deleteRecentChat(recentChatDictionary: self.filteredChats[indexPath.row])
                self.filteredChats.remove(at: indexPath.row)
                self.recentChatsTableView.reloadData()
                
            }
            else {
                deleteRecentChat(recentChatDictionary: self.recentChats[indexPath.row])
                self.recentChats.remove(at: indexPath.row)
                self.recentChatsTableView.reloadData()
            }
        }
        
        var mute = false
        
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
            mute = true
        }
        
        let muteAction = UIContextualAction(style: .normal, title: nil) { (action, view, success) in
            self.updatePushMembers(recent: tempRecent, mute: mute)
             UIView.transition(with: tableView, duration: 0.1, options: .transitionCrossDissolve, animations: {self.recentChatsTableView.reloadData()}, completion: nil)
        }
        
        deleteRecent.backgroundColor = UIColor.systemBackground
        var img = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 28)).image {
            _ in
            UIImage(systemName: "trash")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 28))
        }
        img = img.imageWithColor(color1: .systemRed)
        deleteRecent.image = img
        
        muteAction.backgroundColor = UIColor.systemBackground
        var muteImg = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25)).image {
            _ in
            
            if mute {
                
                UIImage(systemName: "speaker")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
            } else {
                UIImage(systemName: "speaker.slash")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
            }
        }
        muteImg = muteImg.imageWithColor(color1: UIColor.getAppColor(.light))
        muteAction.image = muteImg
        
        return  UISwipeActionsConfiguration(actions: [deleteRecent, muteAction])
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var recent: NSDictionary
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        }
        else {
            
            recent = recentChats[indexPath.row]
        }
        
        //restart recent
        restartChat(recent: recent)
        
        let chatVC = ChatViewController()
        
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        chatVC.memberIds = (recent[kMEMBERS] as? [String])!
        chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        chatVC.titleName = recent[kWITHUSERFULLNAME] as? String
        chatVC.isGroup = recent[kTYPE] as! String == kGROUP
        chatVC.isPartOfGroup = (recent[kMEMBERS] as! [String]).contains(recent[kUSERID] as! String)
        chatVC.initialWithUser = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? "Sent User" : (recent[kWITHUSERFULLNAME] as! String)
        chatVC.isUserDeleted = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? true : false
        
        let cell = tableView.cellForRow(at: indexPath) as! RecentChatsTableViewCell
        chatVC.initialImage = cell.img
        print(chatVC.memberIds.count)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //MARK: Load recent chats
    
    func loadRecentChats() {
        
        if !firstLoad {
             ProgressHUD.show()
            firstLoad = true
        }
       
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            self.recentChats = []
            
            if !snapshot.isEmpty {
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray)).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                
                
                for recent in sorted {
                    if recent[kLASTMESSAGE] as! String != "" {
                        
                        self.recentChats.append(recent)
                    }
                }
                
                if self.recentChats.isEmpty {
                    
                    self.recentChatsTableView.setEmptyMessage("No chats to show")
                } else {
                    
                    self.recentChatsTableView.restore()
                }
                if self.searchController.isActive && self.searchController.searchBar.text != "" {
                                 self.updateSearchResults(for: self.searchController)
                             }
                self.recentChatsTableView.reloadData()
             
                ProgressHUD.dismiss()
            } else {
                self.recentChatsTableView.setEmptyMessage("No chats to show")
                ProgressHUD.dismiss()
            }
            })
    }
    
    
    
    //MARK: Custom table view header
    
    func setTableViewHeader() {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: recentChatsTableView.frame.width, height: 30))
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: recentChatsTableView.frame.width, height: 30))
        let groupButton = UIButton(frame: CGRect(x: recentChatsTableView.frame.width - 110, y: 0, width: 100, height: 30))
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        groupButton.setTitle("New Group", for: .normal)
        let buttonColor = UIColor.getAppColor(.light)
        groupButton.setTitleColor(buttonColor, for: .normal)
        
        //        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height-1, width: recentChatsTableView.frame.width, height: 1))
        //        lineView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        headerView.backgroundColor = .secondarySystemBackground
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        //headerView.addSubview(lineView)
        recentChatsTableView.tableHeaderView = headerView
        
    }
    
    @objc func groupButtonPressed() {
        selectUserForChat(isGroup: true)
    }
    
    @IBAction func newGroupButtonPressed(_ sender: Any) {
        selectUserForChat(isGroup: true)
    }
    
    //MARK: Recent chats delegate
    func didTapAvatarImage(indexPath: IndexPath) {
        
        
       
        let cell = recentChatsTableView.cellForRow(at: indexPath) as! RecentChatsTableViewCell
       
        var recent: NSDictionary
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        }
        else {
            
            recent = recentChats[indexPath.row]
        }
        if recent[kWITHUSERACCOUNTSTATUS] as? String == kDELETED || !(recent[kMEMBERS] as! [String]).contains(recent[kUSERID] as! String) {
                   return
               }
        ProgressHUD.show()
              cell.isUserInteractionEnabled = false
        if(recent[kTYPE] as! String == kPRIVATE) {
       
            reference(.User).document(recent[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                if snapshot.exists {
                    
                    let userDictionary = snapshot.data()! as NSDictionary
                    let tempUser = FUser(_dictionary: userDictionary)
                    

                    cell.isUserInteractionEnabled = true
                    
                    self.showUserProfile(user: tempUser)
                    ProgressHUD.dismiss()
                }
            }
        }
        else if (recent[kTYPE] as! String == kGROUP) {
            let groupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupTableViewController
            reference(.Group).document(recent[kCHATROOMID] as! String).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                if snapshot.exists {
                    groupVC.group = snapshot.data()! as NSDictionary
                    DispatchQueue.main.async {
                        

                        cell.isUserInteractionEnabled = true
                        self.navigationController?.pushViewController(groupVC, animated: true)
                        ProgressHUD.dismiss()
                    }
                }
            }
        }
    }
    
    func showUserProfile(user: FUser) {
        
        let profileVS = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVS.user = user
        
        DispatchQueue.main.async {

            self.navigationController?.pushViewController(profileVS, animated: true)
        }
    }
    
    //MARK: Search controller delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredChats = recentChats.filter({ (recentChat) -> Bool in
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        
        recentChatsTableView.reloadData()
    }
    
    
    func updatePushMembers(recent: NSDictionary, mute: Bool) {
        
        var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
        
        if mute {
            let index = membersToPush.firstIndex(of: FUser.currentId())
            membersToPush.remove(at: index!)
            
        } else {
            membersToPush.append(FUser.currentId())
        }
        
        if (recent[kTYPE] as! String) == kGROUP {
            Group.updateGroup(groupId: recent[kCHATROOMID] as! String, withValues: [kMEMBERSTOPUSH : membersToPush])
        }
        updateExistingRecentWithNewValues(chatRoomId: recent[kCHATROOMID] as! String, withValues: [kMEMBERSTOPUSH : membersToPush])
        
    }
    
    func updateExistingRecentWithNewValues(chatRoomId: String, withValues: [String : Any]) {
        
        reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                
                for recent in snapshot.documents {
                    let recent = recent.data() as NSDictionary
                    self.updateRecent(recentId: recent[kRECENTID] as! String, withValues: withValues)
                }
            }
        }
    }
    
    func updateRecent(recentId: String, withValues: [String : Any]) {
        reference(.Recent).document(recentId).updateData(withValues)
    }
    
    
    func selectUserForChat(isGroup: Bool) {
        
        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "contactsView") as! ContactsTableViewController
        contactsVC.isGroup = isGroup
        contactsVC.title = isGroup ? "New group" : "Contacts"
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }
    
    @objc func receivedNotification(_ notification: Notification) {
         let payload =  notification.userInfo!["notificationPayload"] as! OSNotificationPayload
         //check the message belongs to this room then if you want show your local notification , if you want do nothing
         if payload.additionalData != nil {
             let additionalData = payload.additionalData
                 if ((UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId ==  (additionalData!["chatRoomId"] as! String)) {
                     print("WOAHHHHH")
                 }else {
                     print("SHOWING NOTIFICATION!!!")
                     let center = UNUserNotificationCenter.current()
                     
                     let content = UNMutableNotificationContent()
                     
                     if (additionalData!["isGroup"] as! Bool) {
                          content.title = "New message in \(additionalData!["titleName"] as! String)"
                     } else {
                          content.title = "New message from \(additionalData!["withUser"] as! String)"
                     }
                    
                     //content.body = "New message"
                     content.sound = UNNotificationSound.default
                     
                     
                     let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                     let dictionary = ["chatRoomId" : (additionalData!["chatRoomId"] as! String), "membersToPush" : (additionalData!["membersToPush"] as! [String]), "memberIds" : (additionalData!["memberIds"] as! [String]), "titleName" : (additionalData!["titleName"] as! String), "isGroup" : (additionalData!["isGroup"] as! Bool), "withUser" : ((additionalData!["isGroup"] as! Bool) ? (additionalData!["titleName"] as! String) : (additionalData!["withUser"] as!
                         String)), "inApp" : true] as [String : Any]
                     
                     content.userInfo = ["additionalData" : dictionary]
                     let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                     
                     center.add(request) { (error) in
                         
                         if error != nil {
                             print("error on notification", error!.localizedDescription)
                         } else {
                             
                         }
                     }
                 }
             
         }
         
     }
    
}
