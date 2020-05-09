//
//  ChatsViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 18.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD
import OneSignal
import Firebase
import GradientLoadingBar


class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatsTableViewCellDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var newChatButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var recentChatsTableView: UITableView!
    @IBOutlet weak var newGroupButtonOutlet: UIBarButtonItem!
    
    var recentListener: ListenerRegistration!
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    var searchController = UISearchController(searchResultsController: nil)
    var firstLoad = false
    var usersOnline: [String] = []
    var firstFetchOfOnlineUsers = true
    var contacts: [String] = []
    var updateActivityTabBar = true
    var loadActiveTabOnce = false
    var activeUsersListeners: [ListenerRegistration] = []
    private let gradientLoadingBar = GradientLoadingBar()
    var quotaDidExceed = false
    
    
    
    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    func getContacts()  {
        
        reference(.Contact).whereField("userID", isEqualTo: FUser.currentId()).addSnapshotListener { (snapshot, error) in
            
            if error != nil {
                return
            }
            guard snapshot != nil else {
                return
            }
            if !snapshot!.isEmpty {
                for userDictionary in snapshot!.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    
                    self.contacts = (userDictionary["contacts"] as! [String])
                    self.firstFetchOfOnlineUsers = true
                }
                
            } else {
                self.contacts = []
            }
            self.activeUsersListeners.forEach { $0.remove() }
            self.activeUsersListeners.removeAll()
            //self.activityListener?.remove()
            self.checkOnlineStatus()
        }
        
        
    }
    
    
    func checkOnlineStatus() {
        print("here")
        
        if !loadActiveTabOnce {
            let _ = (tabBarController?.viewControllers![1] as! UINavigationController).viewControllers[0].view
            let _ = (tabBarController?.viewControllers![2] as! UINavigationController).viewControllers[0].view
            loadActiveTabOnce = true
        }
        if contacts.isEmpty {
            self.usersOnline = []
            self.recentChatsTableView.reloadData()
            return
        }
        
        let contactsBy10 = contacts.chunked(into: 10)
        var index = 0
        
        for i in 0...contactsBy10.count - 1 {
            activeUsersListeners.append(Firestore.firestore().collection("status").whereField("userId", in: contactsBy10[i]).addSnapshotListener { (snapshot, error) in
               
                guard let snapshot = snapshot else {
                    print("NO SNAPSHOT -----------------_!!!")
                    return
                }
                 
                if !snapshot.isEmpty {
                    
                    if self.firstFetchOfOnlineUsers {
                        if index == 0  {
                            
                            self.usersOnline = []
                        }
                        let documents = snapshot.documents
                        
                        for doc in documents {
                            let userId = doc["userId"] as! String
                            
                            if doc["state"] as! String == "Online" {
                                self.usersOnline.append(userId)
                            }
                        }
                        if self.updateActivityTabBar {
                            if index == contactsBy10.count - 1 {
                                setTabItemTitle(controller: self.tabBarController!, title: "Active (\(self.usersOnline.count))")
                                self.updateActivityTabBar = false
                            }
                            
                        }
                        if index == contactsBy10.count - 1 {
                            
                            self.firstFetchOfOnlineUsers = false
                        }
                    } else {
                        snapshot.documentChanges.forEach { (docChange) in
                            if docChange.type == .modified {
                                print("-----------------------------------------User \(docChange.document.documentID) is \(docChange.document["state"] as! String)")
                                let userId = docChange.document["userId"] as! String
                                
                                if docChange.document["state"] as! String == "Online" {
                                    
                                    if !self.usersOnline.contains(userId) {
                                        self.usersOnline.append(userId)
                                    }
                                    
                                } else {
                                    
                                    if let idx = self.usersOnline.firstIndex(of: userId) {
                                        self.usersOnline.remove(at: idx)
                                        //                                        var x = (docChange.document["last_changed"] as! Timestamp)
                                        //                                        var timestamp = x.dateValue().timeIntervalSince1970
                                        //                                        var date = Date(timeIntervalSince1970: timestamp)
                                        //
                                        //                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        //                                              print(date.timeIntervalSinceNow)
                                        //                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                    if index == contactsBy10.count - 1 {
                        self.recentChatsTableView.reloadData()
                    }
                
                    
                } else {
                    print("SNAPSHOT EMPTY !!! -------")
                    if self.usersOnline.count > 0 {
                        self.recentChatsTableView.reloadData()
                    }
                    
                }
                    index += 1
            })
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
        //addNoInternetConnectionLabel(height: 0)
        
        navigationItem.largeTitleDisplayMode = .never
        loadUserDefaults()
        gradientLoadingBar.gradientColors =  [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        loadContacts()
        loadRecentChats()
        internetConnectionChanged()
        //setTabItemTitle(controller: self.tabBarController!, title: "Active (0)")
        
        
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "", style: .plain, target: nil, action: nil)
        
        
        
        
        
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(internetConnectionChanged),
                                               name: .internetConnectionState, object: nil)
        
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.50
        self.tabBarController?.tabBar.layer.borderColor = UIColor.clear.cgColor
        self.tabBarController?.tabBar.clipsToBounds = true
        
        
        //        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //        self.navigationController?.navigationBar.shadowImage = UIImage()
        //        self.navigationController?.navigationBar.backgroundColor = UIColor(named: "bwBackground")?.withAlphaComponent(0.9)
        //        self.navigationController?.navigationBar.isTranslucent = true
        
        self.tabBarController?.tabBar.backgroundImage = UIImage()
        self.tabBarController?.tabBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.backgroundColor = UIColor(named: "bwBackground")?.withAlphaComponent(0.9)
        self.tabBarController?.tabBar.isTranslucent = true
        
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
    
    func loadContacts() {
        reference(.Contact).document(FUser.currentId()).addSnapshotListener { (document, error) in
            
            let data = document?.data()
            let contacts = data?["contacts"] as? [String]
            MyVariables.globalContactsVariable = contacts ?? []
            
        }
    }
    
    @objc func setupLeftBarButtons() {
        //        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: UIImage(named: "avatarph")!)
        
        if let currentUser = FUser.currentUser() {
                       NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo:  [kUSERID : FUser.currentId()])
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
            navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(void), image: UIImage(named: "avatarph")!)
            //navigationItem.leftBarButtonItems?[0].image = UIImage()
        }
        
    }
    
    @objc func void() {
        
    }
    
    @objc func presentSettings() {
        if !quotaDidExceed {
            performSegue(withIdentifier: "presentSettingsNav", sender: self)
        }
        
    }
    
    @objc func updateProfilePicture(_ notification: Notification) {
        
        let img =  notification.userInfo!["picture"]  as! UIImage
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButton(self, action: #selector(presentSettings), image: img)
        
    }
    
    @objc func internetConnectionChanged() {
        if !MyVariables.internetConnectionState {
            self.recentChatsTableView.showTableHeaderView(header: getTableViewHeader(title: "No internet connection", backgroundColor: .systemGray6, textColor: .label))
        }
        else {
            self.recentChatsTableView.hideTableHeaderView()
        }
    }
    
    func getTableViewHeader(title: String, backgroundColor: UIColor, textColor: UIColor) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30))
        label.textAlignment = .center
        label.text = title
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.font =  UIFont.boldSystemFont(ofSize: 14)
        return label
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.gradientLoadingBar.fadeOut()
    }
    
    //    override func viewWillLayoutSubviews() {
    //             if #available(iOS 13, *)
    //              {
    //                  let statusBar = UIView(frame: (UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame)!)
    //                  statusBar.backgroundColor = UIColor(named: "bwBackground")?.withAlphaComponent(0.9)
    //                  UIApplication.shared.keyWindow?.addSubview(statusBar)
    //              }
    //    }
    override func viewDidLayoutSubviews() {
        // setTableViewHeader()
        
        recentChatsTableView.separatorStyle = .none
        recentChatsTableView.separatorColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //navigationItem.hidesSearchBarWhenScrolling = false
        
        self.tabBarController?.tabBar.isHidden = false
        
        recentChatsTableView.tableFooterView = UIView() //remove table lines when there's nothing to show
    }
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        navigationItem.hidesSearchBarWhenScrolling = true
    //    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // recentListener.remove()
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
        var isOnline = false
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
            
        }
        else {
            
            recent = recentChats[indexPath.row]
        }
        
        if recent[kTYPE] as! String != kGROUP {
            if usersOnline.contains(recent[kWITHUSERUSERID] as! String) {
                isOnline = true
            }
        }
        
        
        
        
        cell.generateCell(isGroup: recent[kTYPE] as! String == kGROUP, recentChat: recent, indexPath: indexPath, isOnline: isOnline, tabBarController: self.tabBarController!)
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
        self.tabBarController?.tabBar.isHidden = true
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
        chatVC.initialWithUser = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? "Sllick User" : (recent[kWITHUSERFULLNAME] as! String)
        chatVC.isUserDeleted = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? true : false
        
        let cell = tableView.cellForRow(at: indexPath) as! RecentChatsTableViewCell
        chatVC.initialImage = cell.img
        print(chatVC.memberIds.count)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //MARK: Load recent chats
    
    func loadRecentChats() {
        
        if !firstLoad {
            self.gradientLoadingBar.fadeIn()
            firstLoad = true
        }
        
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            if let error = error {
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode.rawValue {
                        
                    case 8:
                        self.quotaDidExceed = true
                        self.navigationController?.popToRootViewController(animated: false);
                        if !(UIApplication.getTopViewController() is ChatsViewController) {
                            UIApplication.getTopViewController()?.dismiss(animated: false, completion: nil)
                            
                        }
                        self.disableUserInterfaceWhenQuotaExceeds()
                    default: self.showMessage(kSOMETHINGWENTWRONG, type: .error, options: [.autoHide(false), .hideOnTap(false)])
                    }
                    
                }
                return
            }
            
            startActivityMonitoring()
            
            
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
                    self.getContacts()
                    self.recentChatsTableView.restore()
                    
                }
                if self.searchController.isActive && self.searchController.searchBar.text != "" {
                    self.updateSearchResults(for: self.searchController)
                }
                self.recentChatsTableView.reloadData()
                
                self.gradientLoadingBar.fadeOut()
            } else {
                self.recentChatsTableView.setEmptyMessage("No chats to show")
                self.gradientLoadingBar.fadeOut()
            }
        })
    }
    
    
    func disableUserInterfaceWhenQuotaExceeds() {
        
        //self.view.window?.isUserInteractionEnabled = false
        self.tabBarController?.selectedIndex = 0
        self.navigationController?.navigationBar.isUserInteractionEnabled = false;
        navigationItem.rightBarButtonItems?.forEach({ $0.isEnabled = false })
        navigationItem.leftBarButtonItems?.forEach({ $0.isEnabled = false })
        self.tabBarController?.tabBar.items?.forEach({ $0.isEnabled = false })
        //        if self.searchController.isActive {
        //            self.searchController.isActive = false
        //            self.searchController.definesPresentationContext = false
        //            self.searchController.dismiss(animated: false, completion: nil)
        //        }
        
        /// self.recentChatsTableView.isUserInteractionEnabled = false;
        self.recentListener.remove()
        //NotificationCenter.default.removeObserver(self, name: .internetConnectionState, object: nil)
        self.removeAllNotifications()
        if recentChatsTableView.numberOfRows(inSection: 0) > 0 {
              self.recentChatsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
      
        self.recentChatsTableView.showTableHeaderView(header: getTableViewHeader(title: "Transaction limt exceeded. Try again later.", backgroundColor: .systemPink, textColor: .white))
        
    }
    
    func removeAllNotifications() {
        NotificationCenter.default.removeObserver(self)
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
        
        if quotaDidExceed {
            return
        }
        
        
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
        
        if(recent[kTYPE] as! String == kPRIVATE) {
            
            //            reference(.User).document(recent[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
            //
            //                guard let snapshot = snapshot else { return }
            //
            //                if snapshot.exists {
            //
            //                    let userDictionary = snapshot.data()! as NSDictionary
            //                    let tempUser = FUser(_dictionary: userDictionary)
            //
            //
            //                    cell.isUserInteractionEnabled = true
            //
            //                    self.showUserProfile(userDictionary: userDictionary)
            //                  //      self.gradientLoadingBar.fadeOut()
            //                }
            //            }
            
            let fullNameArray = (recent[kWITHUSERFULLNAME] as! String).components(separatedBy: " ")
            let firstName = fullNameArray[0]
            let lastName = fullNameArray[fullNameArray.count-1]
            let userDictionary: [String : Any] = [
                kOBJECTID : recent[kWITHUSERUSERID] as! String, kFIRSTNAME : firstName, kLASTNAME : lastName, kAVATAR : ""]
            let profilePicture = (recentChatsTableView.cellForRow(at: indexPath) as! RecentChatsTableViewCell).avatarImageView.image!
            self.showUserProfile(userDictionary: userDictionary, profilePicture: profilePicture)
        }
        else if (recent[kTYPE] as! String == kGROUP) {
            //               self.gradientLoadingBar.fadeIn()
            //                         cell.isUserInteractionEnabled = false
            //            let groupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupTableViewController
            //            reference(.Group).document(recent[kCHATROOMID] as! String).getDocument { (snapshot, error) in
            //
            //                guard let snapshot = snapshot else { return }
            //
            //                if snapshot.exists {
            //                    groupVC.group = snapshot.data()! as NSDictionary
            //                    DispatchQueue.main.async {
            //
            //
            //                        cell.isUserInteractionEnabled = true
            //                        self.navigationController?.pushViewController(groupVC, animated: true)
            //                            self.gradientLoadingBar.fadeOut()
            //                    }
            //                }
            //            }
            self.tabBarController?.tabBar.isHidden = true
            restartChat(recent: recent)
            
            let chatVC = ChatViewController()
            
            chatVC.hidesBottomBarWhenPushed = true
            chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
            chatVC.memberIds = (recent[kMEMBERS] as? [String])!
            chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
            chatVC.titleName = recent[kWITHUSERFULLNAME] as? String
            chatVC.isGroup = recent[kTYPE] as! String == kGROUP
            chatVC.isPartOfGroup = (recent[kMEMBERS] as! [String]).contains(recent[kUSERID] as! String)
            chatVC.initialWithUser = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? "Sllick User" : (recent[kWITHUSERFULLNAME] as! String)
            chatVC.isUserDeleted = (recent[kWITHUSERACCOUNTSTATUS] as? String) == kDELETED ? true : false
            
            let cell = recentChatsTableView.cellForRow(at: indexPath) as! RecentChatsTableViewCell
            chatVC.initialImage = cell.img
            print(chatVC.memberIds.count)
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    func showUserProfile(userDictionary: [String : Any], profilePicture: UIImage) {
        
        let profileVS = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVS.userDictionary = userDictionary
        profileVS.profilePicture = profilePicture
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
        
        if let topVC = UIApplication.getTopViewController() {
            if (topVC is ChatsViewController) {
                return
            }
            
            //            if (topVC is ProfileTableViewController) {
            //                let i = navigationController?.viewControllers.firstIndex(of: self)
            //                if let previousViewController = navigationController?.viewControllers[i!-1] as? ChatViewController {
            //                    if ((topVC as! ProfileTableViewController).user!.objectId == previousViewController.withUsers[0].objectId) {
            //                        return
            //                    }
            //                }
            //            }
        }
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
                    content.body = "New message in \(additionalData!["titleName"] as! String)"
                } else {
                    content.body = "New message from \(additionalData!["withUser"] as! String)"
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
    
    func loadUserDefaults() {
        
        let darkModeStatus = userDefaults.bool(forKey: kDARKMODESTATUS)
        
        if darkModeStatus{
            UIApplication.shared.windows.forEach { (window) in
                window.overrideUserInterfaceStyle = .dark
            }
        } else {
            UIApplication.shared.windows.forEach { (window) in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
    }
    
}

extension UITableView {
    func hideTableHeaderView() -> Void {
        self.beginUpdates()
        UIView.animate(withDuration: 0.2, animations: {
            self.tableHeaderView = nil
        })
        self.endUpdates()
    }
    func showTableHeaderView(header: UIView) -> Void {
        let headerView = header
        self.beginUpdates()
        let headerFrame = headerView.frame
        headerView.frame = CGRect()
        self.tableHeaderView = headerView
        UIView.animate(withDuration: 0.2, animations: {
            self.tableHeaderView?.frame = headerFrame
            self.tableHeaderView?.alpha = 0
            self.endUpdates()
        }, completion: { (ok) in
            self.tableHeaderView?.alpha = 1
        })
    }
}
//
//extension UIApplication {
//
//    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
//
//        if let nav = base as? UINavigationController {
//            return getTopViewController(base: nav.visibleViewController)
//
//        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
//            return getTopViewController(base: selected)
//
//        } else if let presented = base?.presentedViewController {
//            return getTopViewController(base: presented)
//        }
//        return base
//    }
//}


